//
//  WatchSettingsView.swift
//  tawazon-watch Watch App
//
//  Watch settings view
//

import SwiftUI

struct WatchSettingsView: View {
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
                        .foregroundColor(ColorTheme.adaptiveText(primary: true, isDarkMode: themeManager.isDarkMode))
                    Spacer()
                    Text(languageManager.currentLanguage.displayName)
                        .foregroundColor(ColorTheme.adaptiveText(primary: false, isDarkMode: themeManager.isDarkMode))
                }
            }
            .listRowBackground(ColorTheme.adaptiveBackground(primary: false, isDarkMode: themeManager.isDarkMode))
            
            // Theme
            Section(languageManager.localize("settings.appearanceMode")) {
                Button(action: {
                    themeManager.setDarkMode(true)
                }) {
                    HStack {
                        Text(languageManager.localize("settings.theme.dark"))
                            .foregroundColor(ColorTheme.adaptiveText(primary: true, isDarkMode: themeManager.isDarkMode))
                        Spacer()
                        if themeManager.isDarkMode {
                            Image(systemName: "checkmark")
                                .foregroundColor(themeManager.dynamicColorTheme.currentPrimary)
                        }
                    }
                }
                .listRowBackground(ColorTheme.adaptiveBackground(primary: false, isDarkMode: themeManager.isDarkMode))
                
                Button(action: {
                    themeManager.setDarkMode(false)
                }) {
                    HStack {
                        Text(languageManager.localize("settings.theme.light"))
                            .foregroundColor(ColorTheme.adaptiveText(primary: true, isDarkMode: themeManager.isDarkMode))
                        Spacer()
                        if !themeManager.isDarkMode {
                            Image(systemName: "checkmark")
                                .foregroundColor(themeManager.dynamicColorTheme.currentPrimary)
                        }
                    }
                }
                .listRowBackground(ColorTheme.adaptiveBackground(primary: false, isDarkMode: themeManager.isDarkMode))
            }
        }
        .background(ColorTheme.adaptiveBackground(primary: true, isDarkMode: themeManager.isDarkMode))
        .scrollContentBackground(.hidden)
        .navigationTitle(languageManager.localize("settings.title"))
    }
}

#Preview {
    WatchSettingsView()
        .environmentObject(ThemeManager.shared)
        .environmentObject(LanguageManager.shared)
}

