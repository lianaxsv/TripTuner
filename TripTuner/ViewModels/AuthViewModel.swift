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
    
    func signUp(email: String, password: String, username: String, handle: String) {
        guard !email.isEmpty, !password.isEmpty, !username.isEmpty, !handle.isEmpty else {
            errorMessage = "Please fill in all fields."
            return
        }
        
        isLoading = true
        errorMessage = nil
        
        Auth.auth().createUser(withEmail: email, password: password) { [weak self] result, error in
            guard let self = self else { return }
            if let error = error {
                DispatchQueue.main.async {
                    self.isLoading = false
                    self.errorMessage = error.localizedDescription
                }
                return
            }
            
            guard let firebaseUser = result?.user else { return }
            let uid = firebaseUser.uid
            
            let userData: [String: Any] = [
                "username": username,
                "handle": handle,
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
                        username: username,
                        email: email,
                        profileImageURL: nil,
                        year: nil,
                        streak: 0,
                        points: 0,
                        achievements: [],
                        handle: handle
                    )
                    self.currentUser = newUser
                    self.isAuthenticated = true
                }
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
                let username = data["username"] as? String ?? "Traveler"
                let handle = data["handle"] as? String ?? "@traveler"
                let email = data["email"] as? String ?? fallbackEmail ?? ""
                let profileImageURL = data["profileImageURL"] as? String
                let year = data["year"] as? String
                let streak = data["streak"] as? Int ?? 0
                let points = data["points"] as? Int ?? 0
                
                let user = User(
                    id: uid,
                    username: username,
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
                let username = "Traveler"
                let handle = "@traveler"
                
                let user = User(
                    id: uid,
                    username: username,
                    email: email,
                    profileImageURL: nil,
                    year: nil,
                    streak: 0,
                    points: 0,
                    achievements: [],
                    handle: handle
                )
                
                try await db.collection("users").document(uid).setData([
                    "username": username,
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

