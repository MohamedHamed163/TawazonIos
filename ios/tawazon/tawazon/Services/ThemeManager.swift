//
//  ThemeManager.swift
//  tawazon
//
//  Created by Ahmed Farahat on 04/09/1447 AH.
//

import Foundation
import SwiftUI
import Combine

enum AppTheme: String, CaseIterable {
    case system = "system"
    case light = "light"
    case dark = "dark"
    
    var displayName: String {
        switch self {
        case .system: return "System"
        case .light: return "Light"
        case .dark: return "Dark"
        }
    }
}

class ThemeManager: ObservableObject {
    static let shared = ThemeManager()
    
    @Published var colorScheme: ColorScheme? = nil
    @Published var currentGenderTheme: GenderTheme = .neutral {
        didSet {
            SharedDefaultsHelper.shared.set(currentGenderTheme.rawValue, forKey: SharedDefaultsHelper.Keys.genderTheme)
            updateTheme()
        }
    }
    
    @Published var isDarkMode: Bool = true {
        didSet {
            SharedDefaultsHelper.shared.set(isDarkMode, forKey: SharedDefaultsHelper.Keys.isDarkMode)
            updateTheme()
        }
    }
    
    @Published var dynamicColorTheme: DynamicColorTheme
    
    private let defaults = SharedDefaultsHelper.shared
    
    // Computed property for combined mode
    var currentGenderThemeMode: GenderThemeMode {
        get {
            switch (currentGenderTheme, isDarkMode) {
            case (.male, true): return .maleDark
            case (.male, false): return .maleLight
            case (.female, true): return .femaleDark
            case (.female, false): return .femaleLight
            case (.neutral, true): return .neutralDark
            case (.neutral, false): return .neutralLight
            }
        }
        set {
            currentGenderTheme = newValue.gender
            isDarkMode = newValue.isDarkMode
        }
    }
    
    // Legacy support - keep for backward compatibility
    var currentTheme: AppTheme {
        get {
            return currentGenderThemeMode.isDarkMode ? .dark : .light
        }
        set {
            // When setting theme, preserve current gender
            let currentGender = currentGenderThemeMode.gender
            switch newValue {
            case .system:
                // For system, detect and use current gender
                #if os(iOS)
                if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                    let systemIsDark = windowScene.windows.first?.traitCollection.userInterfaceStyle == .dark
                    currentGenderThemeMode = systemIsDark ? 
                        (currentGender == .male ? .maleDark : currentGender == .female ? .femaleDark : .neutralDark) :
                        (currentGender == .male ? .maleLight : currentGender == .female ? .femaleLight : .neutralLight)
                }
                #else
                // watchOS: default to dark mode
                currentGenderThemeMode = currentGender == .male ? .maleDark : currentGender == .female ? .femaleDark : .neutralDark
                #endif
            case .light:
                currentGenderThemeMode = currentGender == .male ? .maleLight : currentGender == .female ? .femaleLight : .neutralLight
            case .dark:
                currentGenderThemeMode = currentGender == .male ? .maleDark : currentGender == .female ? .femaleDark : .neutralDark
            }
        }
    }
    
    init() {
        dynamicColorTheme = DynamicColorTheme()
        
        // Load saved gender theme
        if let savedGender = defaults.string(forKey: SharedDefaultsHelper.Keys.genderTheme),
           let gender = GenderTheme(rawValue: savedGender) {
            currentGenderTheme = gender
        }
        
        // Load saved dark mode preference
        if defaults.object(forKey: SharedDefaultsHelper.Keys.isDarkMode) != nil {
            isDarkMode = defaults.bool(forKey: SharedDefaultsHelper.Keys.isDarkMode)
        } else {
            // Fallback: detect system preference (only on iOS)
            #if os(iOS)
            if let windowScene = UIApplication.shared.connectedScenes.first as? UIWindowScene {
                isDarkMode = windowScene.windows.first?.traitCollection.userInterfaceStyle == .dark
            }
            #else
            // watchOS defaults to dark mode
            isDarkMode = true
            #endif
        }
        
        updateTheme()
    }
    
    private func updateTheme() {
        // Set color scheme based on selected mode
        colorScheme = isDarkMode ? .dark : .light
        
        // Update dynamic color theme with both gender and mode
        dynamicColorTheme.setGenderTheme(currentGenderTheme)
        dynamicColorTheme.setDarkMode(isDarkMode)
    }
    
    func setGenderTheme(_ gender: GenderTheme) {
        currentGenderTheme = gender
    }
    
    func setDarkMode(_ dark: Bool) {
        isDarkMode = dark
    }
    
    func setGenderThemeMode(_ mode: GenderThemeMode) {
        currentGenderTheme = mode.gender
        isDarkMode = mode.isDarkMode
    }
}

