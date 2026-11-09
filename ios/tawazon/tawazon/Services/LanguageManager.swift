//
//  LanguageManager.swift
//  tawazon
//
//  Created by Ahmed Farahat on 04/09/1447 AH.
//

import Foundation
import SwiftUI
import Combine

class LanguageManager: ObservableObject {
    static let shared = LanguageManager()
    
    @Published var currentLanguage: Language = .english {
        didSet {
            SharedDefaultsHelper.shared.set(currentLanguage.rawValue, forKey: SharedDefaultsHelper.Keys.currentLanguage)
            updateLanguage()
        }
    }
    
    @Published var isRTL: Bool = false
    
    // This ID changes when language changes, forcing views to refresh
    @Published var refreshID: UUID = UUID()
    
    private let defaults = SharedDefaultsHelper.shared
    
    enum Language: String, CaseIterable {
        case english = "en"
        case arabic = "ar"
        
        var displayName: String {
            switch self {
            case .english: return "English"
            case .arabic: return "العربية"
            }
        }
        
        var locale: Locale {
            Locale(identifier: rawValue)
        }
    }
    
    init() {
        if let savedLanguage = defaults.string(forKey: SharedDefaultsHelper.Keys.currentLanguage),
           let language = Language(rawValue: savedLanguage) {
            currentLanguage = language
        }
        updateLanguage()
    }
    
    private func updateLanguage() {
        isRTL = currentLanguage == .arabic
        // Set app language
        defaults.set([currentLanguage.rawValue], forKey: "AppleLanguages")
        defaults.synchronize()
        // Update refresh ID to force view updates
        refreshID = UUID()
    }
    
    func localize(_ key: String) -> String {
        return LocalizedString.key(key, language: currentLanguage)
    }
    
    // Toggle between languages
    func toggleLanguage() {
        currentLanguage = currentLanguage == .english ? .arabic : .english
    }
}

// MARK: - Localized String Helper
struct LocalizedString {
    static func key(_ key: String, language: LanguageManager.Language) -> String {
        let bundle = Bundle.main

        func translation(inLang lang: String) -> String? {
            guard let path = bundle.path(forResource: lang, ofType: "lproj"),
                  let langBundle = Bundle(path: path) else { return nil }
            let s = langBundle.localizedString(forKey: key, value: nil, table: nil)
            return s == key ? nil : s
        }

        if let s = translation(inLang: language.rawValue) { return s }
        if language != .english, let s = translation(inLang: "en") { return s }

        return key
    }
}

// MARK: - String Extension
extension String {
    func localized(_ language: LanguageManager.Language? = nil) -> String {
        let lang = language ?? LanguageManager().currentLanguage
        return LocalizedString.key(self, language: lang)
    }
}

