//
//  SettingsView.swift
//  TawazonWatch
//
//  Watch settings view
//

import SwiftUI

struct SettingsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var languageManager: LanguageManager
    
    var body: some View {
        List {
            // Language
            Button(action: {
                languageManager.toggleLanguage()
            }) {
                HStack {
                    Text(languageManager.localize("settings.language"))
                    Spacer()
                    Text(languageManager.currentLanguage.displayName)
                        .foregroundColor(.secondary)
                }
            }
            
            // Theme
            Section(languageManager.localize("settings.appearanceMode")) {
                Button(action: {
                    themeManager.setDarkMode(true)
                }) {
                    HStack {
                        Text(languageManager.localize("settings.theme.dark"))
                        Spacer()
                        if themeManager.isDarkMode {
                            Image(systemName: "checkmark")
                                .foregroundColor(themeManager.dynamicColorTheme.currentPrimary)
                        }
                    }
                }
                
                Button(action: {
                    themeManager.setDarkMode(false)
                }) {
                    HStack {
                        Text(languageManager.localize("settings.theme.light"))
                        Spacer()
                        if !themeManager.isDarkMode {
                            Image(systemName: "checkmark")
                                .foregroundColor(themeManager.dynamicColorTheme.currentPrimary)
                        }
                    }
                }
            }
        }
        .navigationTitle(languageManager.localize("settings.title"))
    }
}

#Preview {
    SettingsView()
        .environmentObject(ThemeManager.shared)
        .environmentObject(LanguageManager.shared)
}

