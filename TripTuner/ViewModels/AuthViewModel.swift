//
//  AuthViewModel.swift
//  TripTuner
//
//  Created for TripTuner
//

import Foundation
import SwiftUI
import FirebaseAuth
import FirebaseFirestore
import FirebaseCore
import GoogleSignIn

class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let db = Firestore.firestore()
    
    init() {
        // Restore existing Firebase session if available
        if let user = Auth.auth().currentUser {
            Task { await loadUser(uid: user.uid) }
        }
    }
    
    // MARK: - Public API
    
    func login(email: String, password: String) {
        guard !email.isEmpty, !password.isEmpty else {
            errorMessage = "Please enter email and password."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Auth.auth().signIn(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }
            DispatchQueue.main.async {
                self.isLoading = false
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    self.isAuthenticated = false
                    return
                }
                guard let user = result?.user else { return }
                Task { 
                    await self.loadUser(uid: user.uid, fallbackEmail: email)
                    // Reload itineraries after successful login
                    await MainActor.run {
                        ItinerariesManager.shared.reloadItineraries()
                    }
                }
            }
        }
    }
    
    func signUp(email: String, password: String, name: String, handle: String) {
        guard !email.isEmpty, !password.isEmpty, !name.isEmpty, !handle.isEmpty else {
            errorMessage = "Please fill in all fields."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        let normalizedHandle = handle.lowercased()
        
        // 1️⃣ Create Firebase Auth user FIRST (this doesn't require Firestore permissions)
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }
            
            if let error = error {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                }
                return
            }
            
            guard let firebaseUser = result?.user else {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Failed to create user account."
                }
                return
            }
            
            let uid = firebaseUser.uid
            
            // 2️⃣ Now that user is authenticated, check if handle is available
            // Check in "users" collection
            self.db.collection("users")
                .whereField("handle", isEqualTo: normalizedHandle)
                .getDocuments { snapshot, error in
                    
                    if let error = error {
                        // If error, delete the auth user and show error
                        firebaseUser.delete { _ in }
                        DispatchQueue.main.async {
                            self.isLoading = false
                            self.errorMessage = error.localizedDescription
                        }
                        return
                    }
                    
                    // If handle exists in users collection, reject
                    if let snapshot = snapshot, !snapshot.documents.isEmpty {
                        firebaseUser.delete { _ in }
                        DispatchQueue.main.async {
                            self.isLoading = false
                            self.errorMessage = "Handle already taken."
                        }
                        return
                    }
                    
                    // 3️⃣ Check in "handles" collection
                    let handleRef = self.db.collection("handles").document(normalizedHandle)
                    handleRef.getDocument { snapshot, error in
                        
                        if let error = error {
                            firebaseUser.delete { _ in }
                            DispatchQueue.main.async {
                                self.isLoading = false
                                self.errorMessage = error.localizedDescription
                            }
                            return
                        }
                        
                        // If handle is already reserved, reject
                        if let snapshot = snapshot, snapshot.exists {
                            let existingUID = snapshot.data()?["uid"] as? String
                            // If it's not this user's UID, reject
                            if existingUID != uid && existingUID != "TEMP" {
                                firebaseUser.delete { _ in }
                                DispatchQueue.main.async {
                                    self.isLoading = false
                                    self.errorMessage = "Handle already taken."
                                }
                                return
                            }
                        }
                        
                        // 4️⃣ Reserve the handle
                        handleRef.setData(["uid": uid]) { error in
                            if let error = error {
                                firebaseUser.delete { _ in }
                                DispatchQueue.main.async {
                                    self.isLoading = false
                                    self.errorMessage = "Could not reserve handle: \(error.localizedDescription)"
                                }
                                return
                            }
                            
                            // 5️⃣ Create user document in Firestore
                            let userData: [String: Any] = [
                                "name": name,
                                "handle": normalizedHandle,
                                "email": email,
                                "profileImageURL": NSNull(),
                                "year": NSNull(),
                                "streak": 0,
                                "points": 0,
                                "createdAt": FieldValue.serverTimestamp()
                            ]
                            
                            self.db.collection("users").document(uid).setData(userData) { error in
                                DispatchQueue.main.async {
                                    self.isLoading = false
                                    if let error = error {
                                        // Cleanup: delete handle reservation and auth user
                                        handleRef.delete { _ in }
                                        firebaseUser.delete { _ in }
                                        self.errorMessage = error.localizedDescription
                                        return
                                    }
                                    
                                    // Success! Create user object
                                    let newUser = User(
                                        id: uid,
                                        name: name,
                                        email: email,
                                        profileImageURL: nil,
                                        year: nil,
                                        streak: 0,
                                        points: 0,
                                        achievements: [],
                                        handle: normalizedHandle
                                    )
                                    
                                    self.currentUser = newUser
                                    self.isAuthenticated = true
                                    // Reload itineraries after successful signup
                                    ItinerariesManager.shared.reloadItineraries()
                                }
                            }
                        }
                    }
                }
        }
    }


    
    func signInWithGoogle() async {
        guard let clientID = FirebaseApp.app()?.options.clientID else { return }
        
        let config = GIDConfiguration(clientID: clientID)
        GIDSignIn.sharedInstance.configuration = config
        
        // SAFELY get the presenting view controller for iOS 15+
        guard let windowScene = await UIApplication.shared.connectedScenes.first as? UIWindowScene,
              let rootVC = await windowScene.windows.first?.rootViewController else {
            print("No root view controller found.")
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootVC)
            
            guard let idToken = result.user.idToken?.tokenString else {
                errorMessage = "Unable to fetch Google ID token."
                isLoading = false
                return
            }
            
            let accessToken = result.user.accessToken.tokenString
            let credential = GoogleAuthProvider.credential(withIDToken: idToken,
                                                           accessToken: accessToken)
            
            let authResult = try await Auth.auth().signIn(with: credential)
            let firebaseUser = authResult.user
            
            await loadUser(uid: firebaseUser.uid, fallbackEmail: firebaseUser.email)
            await MainActor.run { 
                self.isLoading = false
                // Reload itineraries after Google sign-in
                ItinerariesManager.shared.reloadItineraries()
            }
            
        } catch {
            await MainActor.run {
                self.errorMessage = error.localizedDescription
                self.isLoading = false
            }
        }
    }

    
    func logout() {
        try? Auth.auth().signOut()
        currentUser = nil
        isAuthenticated = false
        // Clear itineraries when user logs out
        ItinerariesManager.shared.clearItineraries()
    }
    
    // MARK: - Private helpers
    
    @MainActor
    private func loadUser(uid: String, fallbackEmail: String? = nil) async {
        do {
            let snapshot = try await db.collection("users").document(uid).getDocument()
            if let data = snapshot.data() {
                let name = data["name"] as? String ?? "Traveler"
                let handle = data["handle"] as? String ?? "@traveler"
                let email = data["email"] as? String ?? fallbackEmail ?? ""
                let profileImageURL = data["profileImageURL"] as? String
                let year = data["year"] as? String
                let streak = data["streak"] as? Int ?? 0
                let points = data["points"] as? Int ?? 0
                
                let user = User(
                    id: uid,
                    name: name,
                    email: email,
                    profileImageURL: profileImageURL,
                    year: year,
                    streak: streak,
                    points: points,
                    achievements: [],
                    handle: handle
                )
                self.currentUser = user
                self.isAuthenticated = true
                // Reload itineraries after loading user
                ItinerariesManager.shared.reloadItineraries()
            } else {
                // If there's no user document yet, create a minimal one
                let email = fallbackEmail ?? Auth.auth().currentUser?.email ?? ""
                let name = "Traveler"
                let handle = "@traveler"
                
                let user = User(
                    id: uid,
                    name: name,
                    email: email,
                    profileImageURL: nil,
                    year: nil,
                    streak: 0,
                    points: 0,
                    achievements: [],
                    handle: handle
                )
                
                try await db.collection("users").document(uid).setData([
                    "name": name,
                    "handle": handle,
                    "email": email,
                    "streak": 0,
                    "points": 0,
                    "createdAt": FieldValue.serverTimestamp()
                ])
                
                self.currentUser = user
                self.isAuthenticated = true
                // Reload itineraries after creating user document
                ItinerariesManager.shared.reloadItineraries()
            }
        } catch {
            self.errorMessage = error.localizedDescription
            self.isAuthenticated = false
        }
    }
}

