//
//  ColorTheme.swift
//  tawazon
//
//  Created by Ahmed Farahat on 04/09/1447 AH.
//

import SwiftUI

struct ColorTheme {
    // MARK: - Brand Colors
    static let primary = Color(red: 0.5, green: 1.0, blue: 0.0) // Lime green
    static let primaryDark = Color(red: 0.4, green: 0.9, blue: 0.0)
    static let primaryLight = Color(red: 0.6, green: 1.0, blue: 0.2)
    
    // MARK: - Background Colors
    struct Background {
        static let primary = Color(red: 0.1, green: 0.1, blue: 0.1) // Dark background
        static let secondary = Color(red: 0.15, green: 0.15, blue: 0.15)
        static let tertiary = Color(red: 0.2, green: 0.2, blue: 0.2)
        
        // Light mode
        static let primaryLight = Color(red: 0.98, green: 0.98, blue: 0.98)
        static let secondaryLight = Color(red: 0.95, green: 0.95, blue: 0.95)
        static let tertiaryLight = Color(red: 0.9, green: 0.9, blue: 0.9)
    }
    
    // MARK: - Text Colors
    struct Text {
        static let primary = Color.white
        static let secondary = Color.gray
        static let tertiary = Color(red: 0.6, green: 0.6, blue: 0.6)
        static let accent = ColorTheme.primary
        
        // Light mode
        static let primaryLight = Color.black
        static let secondaryLight = Color(red: 0.4, green: 0.4, blue: 0.4)
        static let tertiaryLight = Color(red: 0.5, green: 0.5, blue: 0.5)
    }
    
    // MARK: - Semantic Colors
    struct Semantic {
        static let success = Color.green
        static let error = Color.red
        static let warning = Color.orange
        static let info = Color.blue
        
        // Light mode variants
        static let successLight = Color(red: 0.0, green: 0.7, blue: 0.0)
        static let errorLight = Color(red: 0.9, green: 0.0, blue: 0.0)
        static let warningLight = Color(red: 1.0, green: 0.6, blue: 0.0)
        static let infoLight = Color(red: 0.0, green: 0.5, blue: 1.0)
    }
    
    // MARK: - Card Colors
    struct Card {
        static let background = Background.secondary
        static let border = Color(red: 0.25, green: 0.25, blue: 0.25)
        static let shadow = Color.black.opacity(0.3)
        
        // Light mode
        static let backgroundLight = Background.secondaryLight
        static let borderLight = Color(red: 0.8, green: 0.8, blue: 0.8)
        static let shadowLight = Color.black.opacity(0.1)
    }
    
    // MARK: - Button Colors
    struct Button {
        static let primary = ColorTheme.primary
        static let primaryText = ColorTheme.Background.primary
        static let secondary = Color.clear
        static let secondaryText = ColorTheme.primary
        static let disabled = Color.gray
        static let disabledText = Color.white
        
        // Light mode
        static let primaryLight = ColorTheme.primary
        static let primaryTextLight = Color.white
        static let secondaryLight = Color.clear
        static let secondaryTextLight = ColorTheme.primary
    }
    
    // MARK: - Input Field Colors
    struct Input {
        static let background = Background.secondary
        static let border = Color(red: 0.3, green: 0.3, blue: 0.3)
        static let borderFocused = ColorTheme.primary
        static let text = Text.primary
        static let placeholder = Text.secondary
        
        // Light mode
        static let backgroundLight = Background.secondaryLight
        static let borderLight = Color(red: 0.7, green: 0.7, blue: 0.7)
        static let borderFocusedLight = ColorTheme.primary
        static let textLight = Text.primaryLight
        static let placeholderLight = Text.secondaryLight
    }
    
    // MARK: - Divider Colors
    struct Divider {
        static let color = Color(red: 0.3, green: 0.3, blue: 0.3)
        static let colorLight = Color(red: 0.8, green: 0.8, blue: 0.8)
    }
}

// MARK: - Environment-based Color Extension
extension ColorTheme {
    // Helper functions to get adaptive colors based on dark mode
    static func adaptiveBackground(primary: Bool, isDarkMode: Bool) -> Color {
        if primary {
            return isDarkMode ? Background.primary : Background.primaryLight
        } else {
            return isDarkMode ? Background.secondary : Background.secondaryLight
        }
    }
    
    static func adaptiveText(primary: Bool, isDarkMode: Bool) -> Color {
        if primary {
            return isDarkMode ? Text.primary : Text.primaryLight
        } else {
            return isDarkMode ? Text.secondary : Text.secondaryLight
        }
    }
}

extension Color {
    static func adaptive(_ dark: Color, light: Color) -> Color {
        // This will be handled by the theme manager
        return dark
    }
    
    // Convenience accessors
    static var appPrimary: Color { ColorTheme.primary }
    static var appBackground: Color { ColorTheme.Background.primary }
    static var appBackgroundSecondary: Color { ColorTheme.Background.secondary }
    static var appTextPrimary: Color { ColorTheme.Text.primary }
    static var appTextSecondary: Color { ColorTheme.Text.secondary }
}

// MARK: - Legacy Support (Deprecated - Use ColorTheme instead)
extension Color {
    static var fitForgeLime: Color { 
        // Try to get from dynamic theme if available
        // Dynamic color theme is handled through environment objects
        return ColorTheme.primary
    }
    static var fitForgeDark: Color { ColorTheme.Background.primary }
    static var fitForgeDarkSecondary: Color { ColorTheme.Background.secondary }
}

