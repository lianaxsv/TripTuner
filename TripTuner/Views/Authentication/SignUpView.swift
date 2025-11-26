//
//  SignUpView.swift
//  TripTuner
//
//  Created for TripTuner
//

import SwiftUI

struct SignUpView: View {
    @Environment(\.dismiss) var dismiss
    @StateObject private var viewModel = AuthViewModel()
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var username = ""
    @State private var handle = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 24) {
                    // Logo
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [Color.purple, Color.blue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "apple.logo")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 40)
                    
                    Text("Create Account")
                        .font(.system(size: 32, weight: .bold))
                    
                    VStack(spacing: 16) {
                        TextField("Username", text: $username)
                            .textFieldStyle(LoginTextFieldStyle())
                        
                        TextField("Handle (e.g., @username)", text: $handle)
                            .textFieldStyle(LoginTextFieldStyle())
                            .autocapitalization(.none)
                        
                        TextField("Email", text: $email)
                            .textFieldStyle(LoginTextFieldStyle())
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                        
                        HStack {
                            if showPassword {
                                TextField("Password", text: $password)
                                    .autocapitalization(.none)
                            } else {
                                SecureField("Password", text: $password)
                            }
                            
                            Button(action: { showPassword.toggle() }) {
                                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                        .textFieldStyle(LoginTextFieldStyle())
                        
                        HStack {
                            if showConfirmPassword {
                                TextField("Confirm Password", text: $confirmPassword)
                                    .autocapitalization(.none)
                            } else {
                                SecureField("Confirm Password", text: $confirmPassword)
                            }
                            
                            Button(action: { showConfirmPassword.toggle() }) {
                                Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                        .textFieldStyle(LoginTextFieldStyle())
                    }
                    .padding(.horizontal, 20)
                    
                    Button(action: {
                        viewModel.signUp(email: email, password: password, username: username, handle: handle)
                    }) {
                        Text("Sign Up")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
                    .disabled(viewModel.isLoading)
                }
                .padding(.vertical, 20)
            }
            .navigationTitle("Sign Up")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
            }
        }
        .fullScreenCover(isPresented: $viewModel.isAuthenticated) {
            MainTabView()
        }
    }
}

#Preview {
    SignUpView()
}

