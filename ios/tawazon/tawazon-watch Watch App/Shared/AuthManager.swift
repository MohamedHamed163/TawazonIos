//
//  AuthManager.swift
//  tawazon
//
//  Created by Ahmed Farahat on 04/09/1447 AH.
//

import Foundation
import SwiftUI
import Combine

@MainActor
class AuthManager: ObservableObject {
    static let shared = AuthManager()
    
    @Published var isAuthenticated = false
    @Published var currentUser: UserProfile?
    @Published var isLoading = false
    @Published var errorMessage: String?
    
    private let apiService = APIService.shared
    private let keychain = KeychainService.shared
    
    init() {
        checkAuthenticationStatus()
    }
    
    // MARK: - Authentication Status
    func checkAuthenticationStatus() {
        // On simulator, auto-authenticate for testing
        #if targetEnvironment(simulator)
        isAuthenticated = true
        // Create a mock user for simulator
        if currentUser == nil {
            currentUser = UserProfile(
                id: "simulator-user-id",
                email: "test@tawazon.com",
                fullName: "Test User",
                role: "USER",
                height: nil,
                weight: nil,
                age: nil,
                gender: nil,
                fitnessGoal: nil,
                avatarUrl: nil,
                createdAt: nil,
                updatedAt: nil
            )
        }
        #else
        // On real device, check actual token
        if let accessToken = keychain.getAccessToken(), !accessToken.isEmpty {
            // Token exists, verify it's still valid
            // For now, we'll assume it's valid if it exists
            // In production, you'd decode and check expiration
            isAuthenticated = true
            Task {
                await loadUserProfile()
            }
        } else {
            isAuthenticated = false
            currentUser = nil
        }
        #endif
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
            await loadUserProfile()
        } catch {
            errorMessage = error.localizedDescription
            isAuthenticated = false
        }
        
        isLoading = false
    }
    
    // MARK: - Logout
    func logout() {
        keychain.deleteAccessToken()
        keychain.deleteRefreshToken()
        isAuthenticated = false
        currentUser = nil
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

