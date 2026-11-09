//
//  SignUpView.swift
//  tawazon
//
//  Created by Ahmed Farahat on 04/09/1447 AH.
//

import SwiftUI
import AuthenticationServices

struct SignUpView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss
    /// When set (e.g. root auth flow), replaces dismiss() for Cancel.
    var onDismissFlow: (() -> Void)? = nil
    
    @State private var fullName = ""
    @State private var email = ""
    @State private var password = ""
    @State private var confirmPassword = ""
    @State private var selectedRole = "USER"
    
    var body: some View {
        NavigationStack {
            ZStack {
                ColorTheme.adaptiveBackground(primary: true, isDarkMode: themeManager.isDarkMode)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Header
                        VStack(spacing: 8) {
                            Text(languageManager.localize("auth.createAccount"))
                                .font(.title)
                                .fontWeight(.bold)
                                .foregroundColor(ColorTheme.adaptiveText(primary: true, isDarkMode: themeManager.isDarkMode))
                            
                            Text(languageManager.localize("auth.joinMessage"))
                                .font(.subheadline)
                                .foregroundColor(ColorTheme.adaptiveText(primary: false, isDarkMode: themeManager.isDarkMode))
                                .multilineTextAlignment(.center)
                        }
                        .padding(.top, 20)
                        
                        // Sign Up Form
                        VStack(spacing: 20) {
                            // Full Name Field
                            AppTextField(
                                title: languageManager.localize("auth.fullName"),
                                text: $fullName,
                                placeholder: languageManager.localize("auth.enterFullName"),
                                isRequired: true
                            )
                            
                            // Email Field
                            AppTextField(
                                title: languageManager.localize("auth.email"),
                                text: $email,
                                placeholder: languageManager.localize("auth.enterEmail"),
                                keyboardType: .emailAddress,
                                autocapitalization: .never,
                                isRequired: true
                            )
                            
                            // Password Field
                            AppTextField(
                                title: languageManager.localize("auth.password"),
                                text: $password,
                                placeholder: languageManager.localize("auth.enterPassword"),
                                isSecure: true,
                                isRequired: true
                            )
                            
                            // Confirm Password Field
                            AppTextField(
                                title: languageManager.localize("auth.confirmPassword"),
                                text: $confirmPassword,
                                placeholder: languageManager.localize("auth.enterPassword"),
                                isSecure: true,
                                errorMessage: password != confirmPassword && !confirmPassword.isEmpty ? languageManager.localize("auth.passwordsNotMatch") : nil,
                                isRequired: true
                            )
                            
                            // Role Selection
                            VStack(alignment: .leading, spacing: 8) {
                                Text(languageManager.localize("auth.iWantTo"))
                                    .font(.subheadline)
                                    .fontWeight(.semibold)
                                    .foregroundColor(.white)
                                
                                Picker("Role", selection: $selectedRole) {
                                    Text(languageManager.localize("auth.role.user")).tag("USER")
                                    Text(languageManager.localize("auth.role.coach")).tag("COACH")
                                }
                                .pickerStyle(SegmentedPickerStyle())
                                .background(ColorTheme.adaptiveBackground(primary: false, isDarkMode: themeManager.isDarkMode))
                                .cornerRadius(12)
                            }
                            
                            // Error Message
                            if let errorMessage = authManager.errorMessage {
                                VStack(alignment: .leading, spacing: 4) {
                                    HStack {
                                        Image(systemName: "exclamationmark.triangle.fill")
                                            .foregroundColor(.red)
                                        Text(errorMessage)
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    }
                                }
                                .padding()
                                .frame(maxWidth: .infinity, alignment: .leading)
                                .background(Color.red.opacity(0.1))
                                .cornerRadius(8)
                            }
                            
                            // Sign Up Button
                            AppButton(
                                title: languageManager.localize("auth.signup"),
                                style: .primary,
                                isLoading: authManager.isLoading,
                                isDisabled: !isFormValid || authManager.isLoading
                            ) {
                                // Clear previous errors
                                authManager.errorMessage = nil
                                
                                Task {
                                    await authManager.register(
                                        email: email.trimmingCharacters(in: .whitespacesAndNewlines),
                                        password: password,
                                        fullName: fullName.trimmingCharacters(in: .whitespacesAndNewlines),
                                        role: selectedRole
                                    )
                                    
                                    // Check if registration was successful
                                    if authManager.isAuthenticated {
                                        try? await Task.sleep(nanoseconds: 500_000_000)
                                        if onDismissFlow == nil {
                                            dismiss()
                                        }
                                    }
                                }
                            }
                            
                            // OR Divider
                            HStack {
                                VStack { Divider().background(Color.gray) }
                                Text(languageManager.localize("auth.or"))
                                    .font(.caption)
                                    .foregroundColor(.gray)
                                    .padding(.horizontal, 8)
                                VStack { Divider().background(Color.gray) }
                            }
                            .padding(.vertical, 8)
                            
                            // Social Login Buttons
                            VStack(spacing: 12) {
                                SignInWithAppleButton(
                                    .signUp,
                                    onRequest: { request in
                                        request.requestedScopes = [.fullName, .email]
                                    },
                                    onCompletion: { result in
                                        switch result {
                                        case .success(let authorization):
                                            if let appleIDCredential = authorization.credential as? ASAuthorizationAppleIDCredential {
                                                Task {
                                                    await authManager.loginWithApple(credential: appleIDCredential)
                                                }
                                            }
                                        case .failure(let error):
                                            authManager.errorMessage = error.localizedDescription
                                        }
                                    }
                                )
                                .signInWithAppleButtonStyle(themeManager.isDarkMode ? .white : .black)
                                .frame(height: 50)
                                .cornerRadius(12)
                                
                                Button(action: {
                                    Task {
                                        await authManager.loginWithGoogle()
                                    }
                                }) {
                                    HStack {
                                        Image(systemName: "g.circle.fill")
                                        Text(languageManager.localize("auth.signUpGoogle"))
                                    }
                                    .frame(maxWidth: .infinity)
                                    .padding()
                                    .background(Color.white)
                                    .foregroundColor(.black)
                                    .cornerRadius(12)
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 12)
                                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                                    )
                                }
                            }
                        }
                        .padding(.horizontal, 24)
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    HStack(spacing: 16) {
                        Button(action: {
                            // Toggle language without dismissing
                            languageManager.toggleLanguage()
                        }) {
                            Image(systemName: "globe")
                                .font(.system(size: 18))
                                .foregroundColor(themeManager.dynamicColorTheme.currentPrimary)
                        }
                        .buttonStyle(PlainButtonStyle())
                        
                        Button(languageManager.localize("common.cancel")) {
                            if let onDismissFlow {
                                onDismissFlow()
                            } else {
                                dismiss()
                            }
                        }
                        .foregroundColor(themeManager.dynamicColorTheme.currentPrimary)
                    }
                }
            }
        }
    }
    
    private var isFormValid: Bool {
        let valid = !fullName.isEmpty &&
        !email.isEmpty &&
        email.contains("@") &&
        password.count >= 8 &&
        password == confirmPassword
        
        // Debug logging
        if !valid {
            print("🔍 Form validation failed:")
            print("  - Full Name: \(fullName.isEmpty ? "empty" : "filled")")
            print("  - Email: \(email.isEmpty ? "empty" : email.contains("@") ? "valid" : "invalid")")
            print("  - Password length: \(password.count) (min: 8)")
            print("  - Passwords match: \(password == confirmPassword)")
        }
        
        return valid
    }
}

#Preview {
    SignUpView()
        .environmentObject(AuthManager())
        .environmentObject(LanguageManager())
        .environmentObject(ThemeManager())
        .preferredColorScheme(.dark)
}

