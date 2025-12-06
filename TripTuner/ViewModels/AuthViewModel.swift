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
                Task { await self.loadUser(uid: user.uid, fallbackEmail: email) }
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
        
        db.collection("users")
            .whereField("handle", isEqualTo: handle)
            .getDocuments { snapshot, error in
                
                if let error = error {
                    self.errorMessage = error.localizedDescription
                    self.isLoading = false
                    return
                }
                
                // If ANY user has this handle → reject
                if let snapshot = snapshot, !snapshot.documents.isEmpty {
                    self.errorMessage = "Handle already taken."
                    self.isLoading = false
                    return
                }
                
                // Handle is available → continue with Firebase Auth sign-up
                self.createFirebaseUser(email: email, password: password, name: name, handle: handle)
            }
    }
    
    private func createFirebaseUser(email: String, password: String, name: String, handle: String) {

        let normalizedHandle = handle.lowercased()
        let handleRef = db.collection("handles").document(normalizedHandle)

        // 1️⃣ First: Check if handle is already taken
        handleRef.getDocument { snapshot, error in
            if let snapshot = snapshot, snapshot.exists {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = "Handle already taken."
                }
                return
            }

            // 2️⃣ Reserve the handle (TEMP until user account is created)
            handleRef.setData(["uid": "TEMP"]) { error in
                if let error = error {
                    DispatchQueue.main.async {
                        self.isLoading = false
                        self.errorMessage = "Could not reserve handle."
                    }
                    return
                }

                // 3️⃣ Create Firebase account
                Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
                    guard let self = self else { return }

                    if let error = error {
                        // Cleanup reservation
                        handleRef.delete()
                        DispatchQueue.main.async {
                            self.isLoading = false
                            self.errorMessage = error.localizedDescription
                        }
                        return
                    }

                    guard let firebaseUser = result?.user else { return }
                    let uid = firebaseUser.uid

                    // 4️⃣ Finalize reservation
                    handleRef.setData(["uid": uid])

                    // 5️⃣ Create user document
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
                                self.errorMessage = error.localizedDescription
                                return
                            }

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
            await MainActor.run { self.isLoading = false }
            
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
            }
        } catch {
            self.errorMessage = error.localizedDescription
            self.isAuthenticated = false
        }
    }
}

