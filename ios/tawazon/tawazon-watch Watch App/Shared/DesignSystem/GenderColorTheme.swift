//
//  GenderColorTheme.swift
//  tawazon
//
//  Created by Ahmed Farahat on 04/09/1447 AH.
//

import SwiftUI
import Combine

enum GenderTheme: String, CaseIterable {
    case male = "male"
    case female = "female"
    case neutral = "neutral"
    
    var displayName: String {
        switch self {
        case .male: return "Male"
        case .female: return "Female"
        case .neutral: return "Neutral"
        }
    }
}

// Combined Gender Theme with Dark/Light Mode
enum GenderThemeMode: String, CaseIterable {
    case maleDark = "male_dark"
    case maleLight = "male_light"
    case femaleDark = "female_dark"
    case femaleLight = "female_light"
    case neutralDark = "neutral_dark"
    case neutralLight = "neutral_light"
    
    var gender: GenderTheme {
        switch self {
        case .maleDark, .maleLight: return .male
        case .femaleDark, .femaleLight: return .female
        case .neutralDark, .neutralLight: return .neutral
        }
    }
    
    var isDarkMode: Bool {
        switch self {
        case .maleDark, .femaleDark, .neutralDark: return true
        case .maleLight, .femaleLight, .neutralLight: return false
        }
    }
    
    var displayName: String {
        switch self {
        case .maleDark: return "Male (Dark)"
        case .maleLight: return "Male (Light)"
        case .femaleDark: return "Female (Dark)"
        case .femaleLight: return "Female (Light)"
        case .neutralDark: return "Neutral (Dark)"
        case .neutralLight: return "Neutral (Light)"
        }
    }
}

struct GenderColorTheme {
    // MARK: - Male Theme Colors
    struct Male {
        // Dark Mode
        struct Dark {
            static let primary = Color(red: 0.0, green: 0.6, blue: 1.0) // Blue
            static let primaryDark = Color(red: 0.0, green: 0.5, blue: 0.9)
            static let primaryLight = Color(red: 0.2, green: 0.7, blue: 1.0)
            static let accent = Color(red: 0.0, green: 0.8, blue: 1.0)
        }
        
        // Light Mode
        struct Light {
            static let primary = Color(red: 0.0, green: 0.4, blue: 0.8) // Vibrant blue for light mode
            static let primaryDark = Color(red: 0.0, green: 0.3, blue: 0.7)
            static let primaryLight = Color(red: 0.2, green: 0.5, blue: 0.9)
            static let accent = Color(red: 0.0, green: 0.5, blue: 1.0)
        }
    }
    
    // MARK: - Female Theme Colors
    struct Female {
        // Dark Mode
        struct Dark {
            static let primary = Color(red: 1.0, green: 0.4, blue: 0.7) // Pink
            static let primaryDark = Color(red: 0.9, green: 0.3, blue: 0.6)
            static let primaryLight = Color(red: 1.0, green: 0.5, blue: 0.8)
            static let accent = Color(red: 1.0, green: 0.6, blue: 0.9)
        }
        
        // Light Mode
        struct Light {
            static let primary = Color(red: 0.8, green: 0.2, blue: 0.5) // Vibrant pink for light mode
            static let primaryDark = Color(red: 0.7, green: 0.15, blue: 0.4)
            static let primaryLight = Color(red: 0.9, green: 0.3, blue: 0.6)
            static let accent = Color(red: 0.9, green: 0.4, blue: 0.7)
        }
    }
    
    // MARK: - Neutral Theme Colors (Default)
    struct Neutral {
        // Dark Mode
        struct Dark {
            static let primary = Color(red: 0.5, green: 1.0, blue: 0.0) // Lime green
            static let primaryDark = Color(red: 0.4, green: 0.9, blue: 0.0)
            static let primaryLight = Color(red: 0.6, green: 1.0, blue: 0.2)
            static let accent = Color(red: 0.5, green: 1.0, blue: 0.0)
        }
        
        // Light Mode
        struct Light {
            static let primary = Color(red: 0.3, green: 0.7, blue: 0.0) // Vibrant green for light mode
            static let primaryDark = Color(red: 0.25, green: 0.6, blue: 0.0)
            static let primaryLight = Color(red: 0.4, green: 0.8, blue: 0.1)
            static let accent = Color(red: 0.35, green: 0.8, blue: 0.0)
        }
    }
    
    // MARK: - Get Primary Color Based on Gender and Theme
    static func getPrimary(gender: GenderTheme, isDarkMode: Bool) -> Color {
        switch gender {
        case .male:
            return isDarkMode ? Male.Dark.primary : Male.Light.primary
        case .female:
            return isDarkMode ? Female.Dark.primary : Female.Light.primary
        case .neutral:
            return isDarkMode ? Neutral.Dark.primary : Neutral.Light.primary
        }
    }
    
    static func getPrimaryDark(gender: GenderTheme, isDarkMode: Bool) -> Color {
        switch gender {
        case .male:
            return isDarkMode ? Male.Dark.primaryDark : Male.Light.primaryDark
        case .female:
            return isDarkMode ? Female.Dark.primaryDark : Female.Light.primaryDark
        case .neutral:
            return isDarkMode ? Neutral.Dark.primaryDark : Neutral.Light.primaryDark
        }
    }
    
    static func getPrimaryLight(gender: GenderTheme, isDarkMode: Bool) -> Color {
        switch gender {
        case .male:
            return isDarkMode ? Male.Dark.primaryLight : Male.Light.primaryLight
        case .female:
            return isDarkMode ? Female.Dark.primaryLight : Female.Light.primaryLight
        case .neutral:
            return isDarkMode ? Neutral.Dark.primaryLight : Neutral.Light.primaryLight
        }
    }
    
    static func getAccent(gender: GenderTheme, isDarkMode: Bool) -> Color {
        switch gender {
        case .male:
            return isDarkMode ? Male.Dark.accent : Male.Light.accent
        case .female:
            return isDarkMode ? Female.Dark.accent : Female.Light.accent
        case .neutral:
            return isDarkMode ? Neutral.Dark.accent : Neutral.Light.accent
        }
    }
}

// MARK: - Dynamic Color Theme Manager
class DynamicColorTheme: ObservableObject {
    @Published var genderTheme: GenderTheme = .neutral {
        didSet {
            UserDefaults.standard.set(genderTheme.rawValue, forKey: "gender_theme")
            updateColors()
        }
    }
    
    @Published var currentPrimary: Color = ColorTheme.primary
    @Published var currentPrimaryDark: Color = ColorTheme.primaryDark
    @Published var currentPrimaryLight: Color = ColorTheme.primaryLight
    @Published var currentAccent: Color = ColorTheme.primary
    
    private var isDarkMode: Bool = true
    
    init() {
        if let savedGender = UserDefaults.standard.string(forKey: "gender_theme"),
           let gender = GenderTheme(rawValue: savedGender) {
            genderTheme = gender
        }
        updateColors()
    }
    
    func setDarkMode(_ dark: Bool) {
        isDarkMode = dark
        updateColors()
    }
    
    func setGenderTheme(_ gender: GenderTheme) {
        genderTheme = gender
        updateColors()
    }
    
    private func updateColors() {
        currentPrimary = GenderColorTheme.getPrimary(gender: genderTheme, isDarkMode: isDarkMode)
        currentPrimaryDark = GenderColorTheme.getPrimaryDark(gender: genderTheme, isDarkMode: isDarkMode)
        currentPrimaryLight = GenderColorTheme.getPrimaryLight(gender: genderTheme, isDarkMode: isDarkMode)
        currentAccent = GenderColorTheme.getAccent(gender: genderTheme, isDarkMode: isDarkMode)
    }
}

