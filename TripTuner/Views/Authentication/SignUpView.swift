//
//  SignUpView.swift
//  TripTuner
//
//  Created for TripTuner
//

import SwiftUI

struct SignUpView: View {
    @Environment(\.dismiss) var dismiss
    @EnvironmentObject var viewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var username = ""
    @State private var handle = ""
    @State private var showPassword = false
    @State private var showConfirmPassword = false
    
    var body: some View {
        NavigationView {
            ZStack {
                // Background gradient matching app theme
                LinearGradient(
                    colors: [Color.pennRed.opacity(0.1), Color.pennBlue.opacity(0.1)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
                .ignoresSafeArea()
                
                ScrollView {
                VStack(spacing: 0) {
                    // Logo
                    ZStack {
                        RoundedRectangle(cornerRadius: 16)
                            .fill(
                                LinearGradient(
                                    colors: [Color.pennRed, Color.pennBlue],
                                    startPoint: .topLeading,
                                    endPoint: .bottomTrailing
                                )
                            )
                            .frame(width: 80, height: 80)
                        
                        Image(systemName: "map.fill")
                            .font(.system(size: 40))
                            .foregroundColor(.white)
                    }
                    .padding(.top, 60)
                    
                    // Header Text
                    VStack(spacing: 8) {
                        Text("Create Account")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.pennRed)
                        
                        Text("Join the TripTuner community")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                    }
                    .padding(.top, 24)
                    
                    // Input Fields
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
                        
                        // Password Field
                        VStack(alignment: .trailing, spacing: 4) {
                            if showPassword {
                                TextField("Password", text: $password)
                                    .autocapitalization(.none)
                            } else {
                                SecureField("Password", text: $password)
                            }
                            
                            Button(action: { showPassword.toggle() }) {
                                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 14))
                            }
                        }
                        .textFieldStyle(LoginTextFieldStyle())
                        
                        // Confirm Password Field
                        VStack(alignment: .trailing, spacing: 4) {
                            if showConfirmPassword {
                                TextField("Confirm Password", text: $confirmPassword)
                                    .autocapitalization(.none)
                            } else {
                                SecureField("Confirm Password", text: $confirmPassword)
                            }
                            
                            Button(action: { showConfirmPassword.toggle() }) {
                                Image(systemName: showConfirmPassword ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 14))
                            }
                        }
                        .textFieldStyle(LoginTextFieldStyle())
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    
                    // Sign Up Button
                    Button(action: {
                        viewModel.signUp(email: email, password: password, username: username, handle: handle)
                    }) {
                        Text("Sign Up")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(
                                LinearGradient(
                                    colors: [Color.pennRed, Color.pennBlue],
                                    startPoint: .leading,
                                    endPoint: .trailing
                                )
                            )
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 24)
                    .disabled(viewModel.isLoading)
                    
                    // Error message
                    if let error = viewModel.errorMessage {
                        Text(error)
                            .foregroundColor(.red)
                            .font(.system(size: 14))
                            .multilineTextAlignment(.center)
                            .padding(.horizontal, 20)
                            .padding(.top, 8)
                    }
                    
                    // Sign In Link
                    HStack(spacing: 4) {
                        Text("Already have an account?")
                            .foregroundColor(.gray)
                            .font(.system(size: 14))
                        Button("Sign In") {
                            dismiss()
                        }
                        .foregroundColor(.pennRed)
                        .font(.system(size: 14, weight: .medium))
                    }
                    .padding(.top, 16)
                    .padding(.bottom, 40)
                }
                .background(Color.white)
                .cornerRadius(24)
                .padding(.horizontal, 20)
                .padding(.top, 20)
                .padding(.bottom, 40)
                }
            }
            .navigationTitle("Sign Up")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        dismiss()
                    }
                    .foregroundColor(.pennRed)
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
        .environmentObject(AuthViewModel())
}

