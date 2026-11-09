//
//  AuthManager.swift
//  tawazon
//
//  Created by Ahmed Farahat on 04/09/1447 AH.
//

import Foundation
import SwiftUI
import Combine
import LocalAuthentication
import AuthenticationServices
import GoogleSignIn

@MainActor
class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var isAuthenticated = false
    @Published var currentUser: UserProfile?
    @Published var isLoading = false
    @Published var errorMessage: String?
    @Published var biometricsEnabled = false
    @Published var biometricsType: LABiometryType = .none
    /// Browse main app without signing in (coaches list, etc.).
    @Published var allowsGuestAccess = false
    
    private let apiService = APIService.shared
    private let keychain = KeychainService.shared
    private let biometricsEnabledKey = "com.tawazon.biometricsEnabled"
    
    init() {
        checkAuthenticationStatus()
        checkBiometricsAvailability()
    }
    
    // MARK: - Authentication Status
    func checkAuthenticationStatus() {
        if let accessToken = keychain.getAccessToken() {
            // Token exists, verify it's still valid
            // For now, we'll assume it's valid if it exists
            // In production, you'd decode and check expiration
            isAuthenticated = true
            Task {
                await loadUserProfile()
            }
        } else {
            isAuthenticated = false
        }
    }
    
    // MARK: - Register
    func register(email: String, password: String, fullName: String, role: String = "USER") async {
        isLoading = true
        errorMessage = nil
        
        // Validate input
        guard !email.isEmpty, !password.isEmpty, !fullName.isEmpty else {
            errorMessage = "Please fill in all required fields"
            isLoading = false
            return
        }
        
        guard email.contains("@") else {
            errorMessage = "Please enter a valid email address"
            isLoading = false
            return
        }
        
        guard password.count >= 8 else {
            errorMessage = "Password must be at least 8 characters"
            isLoading = false
            return
        }
        
        do {
            let request = RegisterRequest(
                email: email.lowercased().trimmingCharacters(in: .whitespacesAndNewlines),
                password: password,
                fullName: fullName.trimmingCharacters(in: .whitespacesAndNewlines),
                role: role
            )
            
            print("📤 Registering user: \(email)")
            let response = try await apiService.register(request)
            print("✅ Registration successful")
            
            // Store tokens
            keychain.saveAccessToken(response.accessToken)
            keychain.saveRefreshToken(response.refreshToken)
            
            isAuthenticated = true
            allowsGuestAccess = false
            await loadUserProfile()
        } catch let error as APIError {
            print("❌ Registration error: \(error)")
            switch error {
            case .httpError(let code):
                if code == 409 {
                    errorMessage = "This email is already registered"
                } else if code == 400 {
                    errorMessage = "Invalid registration data. Please check your information."
                } else {
                    errorMessage = "Registration failed. Please try again."
                }
            case .serverError(let message):
                errorMessage = message
            case .invalidURL:
                errorMessage = "Invalid server URL. Please check your connection."
            case .invalidResponse:
                errorMessage = "Server response error. Please try again."
            default:
                errorMessage = error.localizedDescription
            }
            isAuthenticated = false
        } catch {
            print("❌ Registration error: \(error)")
            errorMessage = error.localizedDescription.isEmpty ? "Registration failed. Please check your connection and try again." : error.localizedDescription
            isAuthenticated = false
        }
        
        isLoading = false
    }
    
    // MARK: - Login
    func login(email: String, password: String) async {
        isLoading = true
        errorMessage = nil
        
        do {
            let request = LoginRequest(email: email, password: password)
            let response = try await apiService.login(request)
            
            // Store tokens
            keychain.saveAccessToken(response.accessToken)
            keychain.saveRefreshToken(response.refreshToken)
            
            isAuthenticated = true
            allowsGuestAccess = false
            await loadUserProfile()
        } catch {
            errorMessage = error.localizedDescription
            isAuthenticated = false
        }
        
        isLoading = false
    }
    
    
    // MARK: - Biometrics
    func checkBiometricsAvailability() {
        let context = LAContext()
        var error: NSError?
        
        if context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) {
            biometricsType = context.biometryType
            biometricsEnabled = UserDefaults.standard.bool(forKey: biometricsEnabledKey)
        } else {
            biometricsType = .none
            biometricsEnabled = false
        }
    }
    
    func toggleBiometrics(_ enabled: Bool) {
        biometricsEnabled = enabled
        UserDefaults.standard.set(enabled, forKey: biometricsEnabledKey)
    }
    
    func authenticateWithBiometrics() async {
        let context = LAContext()
        var error: NSError?
        
        guard context.canEvaluatePolicy(.deviceOwnerAuthenticationWithBiometrics, error: &error) else {
            errorMessage = "Biometrics not available"
            return
        }
        
        do {
            let success = try await context.evaluatePolicy(
                .deviceOwnerAuthenticationWithBiometrics,
                localizedReason: "Sign in to your Tawazon account"
            )
            
            if success {
                // If biometrics succeed, we need to have a way to log in.
                // Usually this means retrieving a saved token or password.
                // For now, we'll try to use the stored access token if it's there.
                if keychain.getAccessToken() != nil {
                    isAuthenticated = true
                    allowsGuestAccess = false
                    await loadUserProfile()
                } else {
                    errorMessage = "Please login with password first to enable Biometrics"
                }
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }
    
    // MARK: - Social Authentication
    func loginWithApple(credential: ASAuthorizationAppleIDCredential) async {
        isLoading = true
        errorMessage = nil
        
        guard let identityTokenData = credential.identityToken,
              let identityToken = String(data: identityTokenData, encoding: .utf8) else {
            errorMessage = "Failed to get identity token from Apple"
            isLoading = false
            return
        }
        
        let fullName = [credential.fullName?.givenName, credential.fullName?.familyName]
            .compactMap { $0 }
            .joined(separator: " ")
        
        do {
            let response = try await apiService.loginWithApple(
                token: identityToken,
                fullName: fullName.isEmpty ? nil : fullName,
                email: credential.email
            )
            
            keychain.saveAccessToken(response.accessToken)
            keychain.saveRefreshToken(response.refreshToken)
            
            isAuthenticated = true
            allowsGuestAccess = false
            await loadUserProfile()
        } catch {
            errorMessage = error.localizedDescription
            isAuthenticated = false
        }
        
        isLoading = false
    }
    
    func loginWithGoogle() async {
        isLoading = true
        errorMessage = nil
        
        guard let rootViewController = await MainActor.run(body: {
            guard let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene,
                  let rootViewController = windowScene.windows.first?.rootViewController else {
                return nil as UIViewController?
            }
            return rootViewController
        }) else {
            errorMessage = "Could not find root view controller"
            isLoading = false
            return
        }
        
        do {
            let result = try await GIDSignIn.sharedInstance.signIn(withPresenting: rootViewController)
            guard let idToken = result.user.idToken?.tokenString else {
                errorMessage = "Failed to get ID token from Google"
                isLoading = false
                return
            }
            
            let response = try await apiService.loginWithGoogle(token: idToken)
            
            keychain.saveAccessToken(response.accessToken)
            keychain.saveRefreshToken(response.refreshToken)
            
            isAuthenticated = true
            allowsGuestAccess = false
            await loadUserProfile()
        } catch {
            errorMessage = error.localizedDescription
            isAuthenticated = false
        }
        
        isLoading = false
    }
    
    func loginWithGoogle(idToken: String) async {
        // Already implemented, kept for direct token login if needed
        isLoading = true
        errorMessage = nil
        
        do {
            let response = try await apiService.loginWithGoogle(token: idToken)
            
            keychain.saveAccessToken(response.accessToken)
            keychain.saveRefreshToken(response.refreshToken)
            
            isAuthenticated = true
            allowsGuestAccess = false
            await loadUserProfile()
        } catch {
            errorMessage = error.localizedDescription
            isAuthenticated = false
        }
        
        isLoading = false
    }
    
    func beginGuestBrowsing() {
        allowsGuestAccess = true
    }

    // MARK: - Logout
    func logout() {
        keychain.deleteAccessToken()
        keychain.deleteRefreshToken()
        isAuthenticated = false
        currentUser = nil
        allowsGuestAccess = false
    }
    
    // MARK: - Load User Profile
    func loadUserProfile() async {
        guard let token = keychain.getAccessToken() else {
            return
        }
        
        do {
            let profile = try await apiService.getUserProfile(token: token)
            await MainActor.run {
                currentUser = profile
            }
        } catch {
            print("Failed to load user profile: \(error)")
        }
    }
}

// MARK: - User Profile Model
typealias UserProfile = UserProfileResponse

