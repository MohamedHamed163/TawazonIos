//
//  WatchLoginPromptView.swift
//  tawazon-watch Watch App
//
//  Login prompt view for watchOS
//

import SwiftUI

struct WatchLoginPromptView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var authManager: AuthManager
    
    var body: some View {
        VStack(spacing: 16) {
            Image(systemName: "lock.fill")
                .font(.system(size: 40))
                .foregroundColor(themeManager.dynamicColorTheme.currentPrimary)
            
            Text(languageManager.localize("watch.loginRequired"))
                .font(.headline)
                .multilineTextAlignment(.center)
                .foregroundColor(ColorTheme.adaptiveText(primary: true, isDarkMode: themeManager.isDarkMode))
                .padding(.horizontal)
            
            Text(languageManager.localize("watch.loginMessage"))
                .font(.caption)
                .multilineTextAlignment(.center)
                .foregroundColor(ColorTheme.adaptiveText(primary: false, isDarkMode: themeManager.isDarkMode))
                .padding(.horizontal)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ColorTheme.adaptiveBackground(primary: true, isDarkMode: themeManager.isDarkMode))
    }
}

#Preview {
    WatchLoginPromptView()
        .environmentObject(ThemeManager.shared)
        .environmentObject(LanguageManager.shared)
        .environmentObject(AuthManager.shared)
}

