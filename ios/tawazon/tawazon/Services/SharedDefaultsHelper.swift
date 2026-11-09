//
//  SharedDefaultsHelper.swift
//  tawazon
//
//  Helper for sharing UserDefaults between iOS and watchOS via App Groups
//

import Foundation

struct SharedDefaultsHelper {
    // Replace with your actual App Group ID
    // Format: group.com.yourcompany.appname
    static let appGroupID = "group.com.tawazon.app"
    
    static var shared: UserDefaults {
        // Try to use App Group UserDefaults, fallback to standard if not available
        if let sharedDefaults = UserDefaults(suiteName: appGroupID) {
            return sharedDefaults
        }
        // Fallback to standard UserDefaults if App Group is not configured
        return UserDefaults.standard
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

