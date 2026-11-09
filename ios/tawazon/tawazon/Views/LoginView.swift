//
//  LoginView.swift
//  tawazon
//
//  Created by Ahmed Farahat on 04/09/1447 AH.
//

import SwiftUI
import AuthenticationServices
import LocalAuthentication

struct LoginView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var themeManager: ThemeManager
    var onBack: (() -> Void)? = nil
    var onNavigateToSignUp: (() -> Void)? = nil
    @State private var email = ""
    @State private var password = ""
    @State private var showPassword = false
    @State private var showSignUp = false
    @FocusState private var focusedField: Field?
    
    enum Field {
        case email, password
    }
    
    var body: some View {
        ZStack {
            ColorTheme.adaptiveBackground(primary: true, isDarkMode: themeManager.isDarkMode)
                .ignoresSafeArea()
            
            ScrollView {
                VStack(spacing: 32) {
                    // Logo and Title
                    VStack(spacing: 16) {
                        Image(systemName: "dumbbell.fill")
                            .font(.system(size: 60))
                            .foregroundColor(themeManager.dynamicColorTheme.currentPrimary)
                        
                        Text(languageManager.localize("app.name"))
                            .font(.system(size: 42, weight: .bold))
                            .foregroundColor(ColorTheme.adaptiveText(primary: true, isDarkMode: themeManager.isDarkMode))
                        
                        Text(languageManager.localize("app.tagline"))
                            .font(.subheadline)
                            .foregroundColor(ColorTheme.adaptiveText(primary: false, isDarkMode: themeManager.isDarkMode))
                            .multilineTextAlignment(.center)
                    }
                    .padding(.top, 100)
                    
                    // Login Form
                    VStack(spacing: 24) {
                        // Email Field
                        AppTextField(
                            title: languageManager.localize("auth.email"),
                            text: $email,
                            placeholder: languageManager.localize("auth.enterEmail"),
                            keyboardType: .emailAddress,
                            autocapitalization: .never,
                            errorMessage: authManager.errorMessage,
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
                        
                        // Login Button
                        AppButton(
                            title: languageManager.localize("auth.login"),
                            style: .primary,
                            icon: "arrow.right",
                            isLoading: authManager.isLoading,
                            isDisabled: !isFormValid
                        ) {
                            Task {
                                await authManager.login(email: email, password: password)
                            }
                        }
                        
                        // Sign Up Link
                        HStack {
                            Text(languageManager.localize("auth.noAccount"))
                                .foregroundColor(.gray)
                            Button(languageManager.localize("auth.signup")) {
                                if let onNavigateToSignUp {
                                    onNavigateToSignUp()
                                } else {
                                    showSignUp = true
                                }
                            }
                            .foregroundColor(themeManager.dynamicColorTheme.currentPrimary)
                        }
                        .font(.subheadline)
                        
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
                        
                        // Biometric Login (if available)
                        if authManager.biometricsType != .none {
                            Button(action: {
                                Task {
                                    await authManager.authenticateWithBiometrics()
                                }
                            }) {
                                HStack {
                                    Image(systemName: authManager.biometricsType == .faceID ? "faceid" : "touchid")
                                    Text(languageManager.localize(authManager.biometricsType == .faceID ? "auth.faceID" : "auth.touchID"))
                                }
                                .frame(maxWidth: .infinity)
                                .padding()
                                .background(themeManager.dynamicColorTheme.currentPrimary.opacity(0.1))
                                .foregroundColor(themeManager.dynamicColorTheme.currentPrimary)
                                .cornerRadius(12)
                                .overlay(
                                    RoundedRectangle(cornerRadius: 12)
                                        .stroke(themeManager.dynamicColorTheme.currentPrimary, lineWidth: 1)
                                )
                            }
                        }
                        
                        // Social Login Buttons
                        VStack(spacing: 12) {
                            SignInWithAppleButton(
                                .signIn,
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
                                    Text(languageManager.localize("auth.signInGoogle"))
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
            
            // Language Toggle Button at top right - Overlay to ensure it's clickable
            VStack {
                HStack {
                    if let onBack {
                        Button(action: onBack) {
                            Image(systemName: languageManager.isRTL ? "chevron.right" : "chevron.left")
                                .font(.system(size: 18, weight: .semibold))
                                .foregroundColor(themeManager.dynamicColorTheme.currentPrimary)
                                .frame(width: 44, height: 44)
                                .background(themeManager.dynamicColorTheme.currentPrimary.opacity(0.15))
                                .clipShape(Circle())
                        }
                        .buttonStyle(.plain)
                        .padding(.leading, 20)
                    }
                    Spacer()
                    Button(action: {
                        // Toggle language directly
                        languageManager.toggleLanguage()
                    }) {
                        Image(systemName: "globe")
                            .font(.system(size: 22))
                            .foregroundColor(themeManager.dynamicColorTheme.currentPrimary)
                            .frame(width: 44, height: 44)
                            .background(themeManager.dynamicColorTheme.currentPrimary.opacity(0.15))
                            .clipShape(Circle())
                    }
                    .buttonStyle(PlainButtonStyle())
                    .contentShape(Circle())
                    .padding(.trailing, 20)
                    .padding(.top, 60)
                }
                Spacer()
            }
            .allowsHitTesting(true)
        }
        .sheet(isPresented: $showSignUp) {
            SignUpView()
                .environmentObject(authManager)
                .environmentObject(languageManager)
                .environmentObject(themeManager)
        }
        .onAppear {
            if onNavigateToSignUp != nil {
                showSignUp = false
            }
        }
    }
    
    private var isFormValid: Bool {
        !email.isEmpty && !password.isEmpty && email.contains("@")
    }
}


#Preview {
    LoginView()
        .environmentObject(AuthManager())
        .environmentObject(LanguageManager())
        .environmentObject(ThemeManager())
        .preferredColorScheme(.dark)
}

