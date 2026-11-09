//
//  SharedDefaultsHelper.swift
//  tawazon
//
//  Helper for sharing UserDefaults between iOS and watchOS via App Groups
//

import Foundation

struct SharedDefaultsHelper {
    // Replace with your actual App Group ID
    static let appGroupID = "group.com.yourcompany.tawazon"
    
    static var shared: UserDefaults {
        return UserDefaults(suiteName: appGroupID) ?? UserDefaults.standard
    }
    
    // Keys for shared data
    struct Keys {
        static let accessToken = "access_token"
        static let refreshToken = "refresh_token"
        static let currentLanguage = "app_language"
        static let currentTheme = "app_theme"
        static let isDarkMode = "is_dark_mode"
        static let genderTheme = "gender_theme"
    }
}

