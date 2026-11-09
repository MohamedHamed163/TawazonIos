//
//  TawazonWatchApp.swift
//  TawazonWatch
//
//  Created for watchOS app
//

import SwiftUI

@main
struct TawazonWatchApp: App {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var languageManager = LanguageManager.shared
    
    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(authManager)
                .environmentObject(themeManager)
                .environmentObject(languageManager)
        }
    }
}

