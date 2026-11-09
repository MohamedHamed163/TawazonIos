//
//  KeychainService.swift
//  tawazon
//
//  Created by Ahmed Farahat on 04/09/1447 AH.
//

import Foundation
import Security

class KeychainService {
    static let shared = KeychainService()
    
    private let accessTokenKey = "com.tawazon.accessToken"
    private let refreshTokenKey = "com.tawazon.refreshToken"
    
    private init() {}
    
    // MARK: - Save Access Token
    func saveAccessToken(_ token: String) {
        save(token, forKey: accessTokenKey)
    }
    
    // MARK: - Get Access Token
    func getAccessToken() -> String? {
        return get(forKey: accessTokenKey)
    }
    
    // MARK: - Save Refresh Token
    func saveRefreshToken(_ token: String) {
        save(token, forKey: refreshTokenKey)
    }
    
    // MARK: - Get Refresh Token
    func getRefreshToken() -> String? {
        return get(forKey: refreshTokenKey)
    }
    
    // MARK: - Delete Access Token
    func deleteAccessToken() {
        delete(forKey: accessTokenKey)
    }
    
    // MARK: - Delete Refresh Token
    func deleteRefreshToken() {
        delete(forKey: refreshTokenKey)
    }
    
    // MARK: - Private Keychain Methods
    private func save(_ value: String, forKey key: String) {
        let data = value.data(using: .utf8)!
        
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecValueData as String: data
        ]
        
        // Delete existing item first
        SecItemDelete(query as CFDictionary)
        
        // Add new item
        SecItemAdd(query as CFDictionary, nil)
    }
    
    private func get(forKey key: String) -> String? {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key,
            kSecReturnData as String: true,
            kSecMatchLimit as String: kSecMatchLimitOne
        ]
        
        var result: AnyObject?
        let status = SecItemCopyMatching(query as CFDictionary, &result)
        
        guard status == errSecSuccess,
              let data = result as? Data,
              let value = String(data: data, encoding: .utf8) else {
            return nil
        }
        
        return value
    }
    
    private func delete(forKey key: String) {
        let query: [String: Any] = [
            kSecClass as String: kSecClassGenericPassword,
            kSecAttrAccount as String: key
        ]
        
        SecItemDelete(query as CFDictionary)
    }
}

