//
//  AuthViewModel.swift
//  TripTuner
//
//  Created for TripTuner
//

import Foundation
import SwiftUI

class AuthViewModel: ObservableObject {
    @Published var isAuthenticated = false
    @Published var currentUser: User?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    func login(email: String, password: String) {
        isLoading = true
        errorMessage = nil
        
        // Mock authentication - replace with actual API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.currentUser = MockData.currentUser
            self.isAuthenticated = true
            self.isLoading = false
        }
    }
    
    func signUp(email: String, password: String, username: String, handle: String) {
        isLoading = true
        errorMessage = nil
        
        // Mock signup - replace with actual API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.0) {
            self.currentUser = User(username: username, email: email, handle: handle)
            self.isAuthenticated = true
            self.isLoading = false
        }
    }
    
    func logout() {
        currentUser = nil
        isAuthenticated = false
    }
}

