//
//  LoginView.swift
//  TripTuner
//
//  Created for TripTuner
//

import SwiftUI

struct LoginView: View {
    @EnvironmentObject var viewModel: AuthViewModel
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var showSignUp = false
    
    var body: some View {
        ZStack {
            Color.black.ignoresSafeArea()
            
            VStack(spacing: 0) {
                // Header
                HStack {
                    Text("Login Page")
                        .foregroundColor(.gray)
                        .font(.system(size: 14))
                    Spacer()
                }
                .padding(.horizontal, 20)
                .padding(.top, 10)
                
                // Main Card
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
                    
                    // Welcome Text
                    VStack(spacing: 8) {
                        Text("Welcome Back")
                            .font(.system(size: 32, weight: .bold))
                            .foregroundColor(.black)
                        
                        Text("Sign in to continue")
                            .font(.system(size: 16))
                            .foregroundColor(.gray)
                    }
                    
                    // Input Fields
                    VStack(spacing: 16) {
                        // Email Field
                        TextField("Email", text: $email)
                            .textFieldStyle(LoginTextFieldStyle())
                            .autocapitalization(.none)
                            .keyboardType(.emailAddress)
                        
                        // Password Field
                        VStack(alignment: .trailing, spacing: 8) {
                            if showPassword {
                                TextField("Password", text: $password)
                                    .autocapitalization(.none)
                            } else {
                                SecureField("Password", text: $password)
                            }
                            
                            Button(action: { showPassword.toggle() }) {
                                Image(systemName: showPassword ? "eye.slash.fill" : "eye.fill")
                                    .foregroundColor(.gray)
                                    .font(.system(size: 16))
                            }
                        }
                        .textFieldStyle(LoginTextFieldStyle())
                    }
                    .padding(.horizontal, 20)
                    
                    // Forgot Password
                    HStack {
                        Spacer()
                        Button("Forgot Password?") {
                            // Handle forgot password
                        }
                        .foregroundColor(.blue)
                        .font(.system(size: 14))
                    }
                    .padding(.horizontal, 20)
                    
                    // Sign In Button
                    Button(action: {
                        viewModel.login(email: email, password: password)
                    }) {
                        Text("Sign In")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .frame(height: 50)
                            .background(Color.blue)
                            .cornerRadius(12)
                    }
                    .padding(.horizontal, 20)
                    .disabled(viewModel.isLoading)
                    
                    // Separator
                    HStack {
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)
                        Text("or")
                            .foregroundColor(.gray)
                            .font(.system(size: 14))
                            .padding(.horizontal, 12)
                        Rectangle()
                            .fill(Color.gray.opacity(0.3))
                            .frame(height: 1)
                    }
                    .padding(.horizontal, 20)
                    
                    // Social Login Buttons
                    VStack(spacing: 12) {
                        // Google Button
                        Button(action: {
                            // Handle Google login
                        }) {
                            HStack {
                                Image(systemName: "globe")
                                    .font(.system(size: 20))
                                    .foregroundColor(.blue)
                                Text("Continue with Google")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.black)
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 50)
                            .background(Color.white)
                            .overlay(
                                RoundedRectangle(cornerRadius: 12)
                                    .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                            )
                            .cornerRadius(12)
                        }
                        
                        // Apple Button
                        Button(action: {
                            // Handle Apple login
                        }) {
                            HStack {
                                Image(systemName: "apple.logo")
                                    .font(.system(size: 20))
                                    .foregroundColor(.white)
                                Text("Continue with Apple")
                                    .font(.system(size: 16, weight: .medium))
                                    .foregroundColor(.white)
                                Spacer()
                            }
                            .padding(.horizontal, 16)
                            .frame(height: 50)
                            .background(Color.black)
                            .cornerRadius(12)
                        }
                    }
                    .padding(.horizontal, 20)
                    
                    // Sign Up Link
                    HStack(spacing: 4) {
                        Text("Don't have an account?")
                            .foregroundColor(.gray)
                            .font(.system(size: 14))
                        Button("Sign Up") {
                            showSignUp = true
                        }
                        .foregroundColor(.blue)
                        .font(.system(size: 14, weight: .medium))
                    }
                    .padding(.bottom, 40)
                }
                .background(Color.white)
                .cornerRadius(24)
                .padding(.horizontal, 20)
                .padding(.top, 20)
                
                Spacer()
            }
        }
        .sheet(isPresented: $showSignUp) {
            SignUpView()
        }
        .fullScreenCover(isPresented: $viewModel.isAuthenticated) {
            MainTabView()
        }
    }
}

struct LoginTextFieldStyle: TextFieldStyle {
    func _body(configuration: TextField<Self._Label>) -> some View {
        configuration
            .padding(.horizontal, 16)
            .padding(.vertical, 14)
            .background(Color.white)
            .cornerRadius(12)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(Color.gray.opacity(0.2), lineWidth: 1)
            )
    }
}

#Preview {
    LoginView()
        .environmentObject(AuthViewModel())
}

