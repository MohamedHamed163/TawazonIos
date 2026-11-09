//
//  WatchContentView.swift
//  tawazon-watch Watch App
//
//  Created by Ahmed Farahat on 04/09/1447 AH.
//

import SwiftUI

struct WatchContentView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var authManager: AuthManager
    @State private var selectedTab = 0
    
    var body: some View {
        Group {
            if authManager.isAuthenticated {
                TabView(selection: $selectedTab) {
                    WatchStatsView()
                        .tag(0)
                    
                    WatchProgramsView()
                        .tag(1)
                    
                    WatchDietPlansView()
                        .tag(2)
                    
                    WatchWorkoutView()
                        .tag(3)
                    
                    WatchSettingsView()
                        .tag(4)
                }
                .tabViewStyle(.page)
            } else {
                WatchLoginPromptView()
            }
        }
        .background(ColorTheme.adaptiveBackground(primary: true, isDarkMode: themeManager.isDarkMode))
        .onAppear {
            // Check authentication status when view appears
            authManager.checkAuthenticationStatus()
        }
    }
}

#Preview {
    WatchContentView()
        .environmentObject(ThemeManager.shared)
        .environmentObject(LanguageManager.shared)
        .environmentObject(AuthManager.shared)
}
