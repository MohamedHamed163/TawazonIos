//
//  tawazon_watchApp.swift
//  tawazon-watch Watch App
//
//  Created by Ahmed Farahat on 04/09/1447 AH.
//

import SwiftUI

@main
struct tawazon_watch_Watch_AppApp: App {
    @StateObject private var authManager = AuthManager.shared
    @StateObject private var themeManager = ThemeManager.shared
    @StateObject private var languageManager = LanguageManager.shared
    
    var body: some Scene {
        WindowGroup {
            WatchContentView()
                .environmentObject(authManager)
                .environmentObject(themeManager)
                .environmentObject(languageManager)
                .preferredColorScheme(themeManager.colorScheme)
                .environment(\.layoutDirection, languageManager.isRTL ? .rightToLeft : .leftToRight)
                .environment(\.locale, languageManager.currentLanguage.locale)
        }
    }
}
