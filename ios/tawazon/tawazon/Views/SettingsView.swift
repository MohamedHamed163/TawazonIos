//
//  SettingsView.swift
//  tawazon
//
//  Created by Ahmed Farahat on 04/09/1447 AH.
//

import SwiftUI
import LocalAuthentication

struct SettingsView: View {
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        NavigationStack {
            ZStack {
                ColorTheme.adaptiveBackground(primary: true, isDarkMode: themeManager.isDarkMode)
                    .ignoresSafeArea()
                
                ScrollView {
                    VStack(spacing: 24) {
                        // Language Section
                        languageSection
                        
                        // Gender Theme Section
                        genderThemeSection
                        
                        // Appearance Mode Section (Dark/Light)
                        appearanceModeSection
                        
                        // Security Section
                        if authManager.biometricsType != .none {
                            securitySection
                        }
                    }
                    .padding(.horizontal, 20)
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle(languageManager.localize("settings.language"))
            .navigationBarTitleDisplayMode(.large)
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(languageManager.localize("common.done")) {
                        dismiss()
                    }
                    .foregroundColor(themeManager.dynamicColorTheme.currentPrimary)
                }
            }
        }
    }
    
    private var languageSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(languageManager.localize("settings.language"))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(ColorTheme.adaptiveText(primary: true, isDarkMode: themeManager.isDarkMode))
            
            VStack(spacing: 12) {
                ForEach(LanguageManager.Language.allCases, id: \.self) { language in
                    LanguageRow(
                        language: language,
                        isSelected: languageManager.currentLanguage == language
                    ) {
                        languageManager.currentLanguage = language
                    }
                }
            }
        }
            .padding()
            .background(ColorTheme.adaptiveBackground(primary: false, isDarkMode: themeManager.isDarkMode))
            .cornerRadius(16)
    }
    
    private var genderThemeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(languageManager.localize("settings.genderTheme"))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(themeManager.isDarkMode ? .white : .black)
            
            VStack(spacing: 12) {
                ForEach(GenderTheme.allCases, id: \.self) { gender in
                    GenderThemeRow(
                        gender: gender,
                        isSelected: themeManager.currentGenderTheme == gender
                    ) {
                        // Update gender theme with animation
                        themeManager.setGenderTheme(gender)
                    }
                }
            }
        }
        .padding()
        .background(ColorTheme.adaptiveBackground(primary: false, isDarkMode: themeManager.isDarkMode))
        .cornerRadius(16)
    }
    
    private var appearanceModeSection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(languageManager.localize("settings.appearanceMode"))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(themeManager.isDarkMode ? .white : .black)
            
            VStack(spacing: 12) {
                AppearanceModeRow(
                    isDark: true,
                    isSelected: themeManager.isDarkMode
                ) {
                    themeManager.setDarkMode(true)
                }
                
                AppearanceModeRow(
                    isDark: false,
                    isSelected: !themeManager.isDarkMode
                ) {
                    themeManager.setDarkMode(false)
                }
            }
        }
        .padding()
        .background(ColorTheme.adaptiveBackground(primary: false, isDarkMode: themeManager.isDarkMode))
        .cornerRadius(16)
    }
    
    private var securitySection: some View {
        VStack(alignment: .leading, spacing: 16) {
            Text(languageManager.localize("profile.privacy"))
                .font(.title2)
                .fontWeight(.bold)
                .foregroundColor(themeManager.isDarkMode ? .white : .black)
            
            VStack(spacing: 12) {
                Toggle(isOn: Binding(
                    get: { authManager.biometricsEnabled },
                    set: { authManager.toggleBiometrics($0) }
                )) {
                    HStack {
                        Image(systemName: authManager.biometricsType == .faceID ? "faceid" : "touchid")
                            .foregroundColor(themeManager.dynamicColorTheme.currentPrimary)
                        VStack(alignment: .leading) {
                            Text(languageManager.localize(authManager.biometricsType == .faceID ? "auth.faceID" : "auth.touchID"))
                                .font(.headline)
                            Text("Use for faster login")
                                .font(.caption)
                                .foregroundColor(.gray)
                        }
                    }
                }
                .tint(themeManager.dynamicColorTheme.currentPrimary)
                .padding()
                .background(ColorTheme.adaptiveBackground(primary: true, isDarkMode: themeManager.isDarkMode))
                .cornerRadius(12)
            }
        }
        .padding()
        .background(ColorTheme.adaptiveBackground(primary: false, isDarkMode: themeManager.isDarkMode))
        .cornerRadius(16)
    }
}

struct LanguageRow: View {
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var themeManager: ThemeManager
    let language: LanguageManager.Language
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                action()
            }
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(language.displayName)
                        .font(.headline)
                        .foregroundColor(ColorTheme.adaptiveText(primary: true, isDarkMode: themeManager.isDarkMode))
                    Text(language.rawValue.uppercased())
                        .font(.caption)
                        .foregroundColor(ColorTheme.adaptiveText(primary: false, isDarkMode: themeManager.isDarkMode))
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(themeManager.dynamicColorTheme.currentPrimary)
                }
            }
            .padding()
            .background(isSelected ? themeManager.dynamicColorTheme.currentPrimary.opacity(0.1) : ColorTheme.adaptiveBackground(primary: true, isDarkMode: themeManager.isDarkMode))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? themeManager.dynamicColorTheme.currentPrimary : Color.clear, lineWidth: 2)
            )
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct ThemeRow: View {
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var themeManager: ThemeManager
    let theme: AppTheme
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                action()
            }
        }) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text(languageManager.localize("settings.theme.\(theme.rawValue)"))
                        .font(.headline)
                        .foregroundColor(ColorTheme.adaptiveText(primary: true, isDarkMode: themeManager.isDarkMode))
                    Text(theme.displayName)
                        .font(.caption)
                        .foregroundColor(ColorTheme.adaptiveText(primary: false, isDarkMode: themeManager.isDarkMode))
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(themeManager.dynamicColorTheme.currentPrimary)
                }
            }
            .padding()
            .background(isSelected ? themeManager.dynamicColorTheme.currentPrimary.opacity(0.1) : ColorTheme.adaptiveBackground(primary: true, isDarkMode: themeManager.isDarkMode))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? themeManager.dynamicColorTheme.currentPrimary : Color.clear, lineWidth: 2)
            )
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct GenderThemeRow: View {
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var themeManager: ThemeManager
    let gender: GenderTheme
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                action()
            }
        }) {
            HStack {
                // Color preview - larger and more visible
                Circle()
                    .fill(GenderColorTheme.getPrimary(gender: gender, isDarkMode: themeManager.isDarkMode))
                    .frame(width: 32, height: 32)
                    .overlay(
                        Circle()
                            .stroke(isSelected ? GenderColorTheme.getPrimary(gender: gender, isDarkMode: themeManager.isDarkMode) : Color.clear, lineWidth: 2)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(languageManager.localize("settings.genderTheme.\(gender.rawValue)"))
                        .font(.headline)
                        .foregroundColor(ColorTheme.adaptiveText(primary: true, isDarkMode: themeManager.isDarkMode))
                    Text(gender.displayName)
                        .font(.caption)
                        .foregroundColor(ColorTheme.adaptiveText(primary: false, isDarkMode: themeManager.isDarkMode))
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(GenderColorTheme.getPrimary(gender: gender, isDarkMode: themeManager.isDarkMode))
                }
            }
            .padding()
            .background(isSelected ? GenderColorTheme.getPrimary(gender: gender, isDarkMode: themeManager.isDarkMode).opacity(0.15) : ColorTheme.adaptiveBackground(primary: true, isDarkMode: themeManager.isDarkMode))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? GenderColorTheme.getPrimary(gender: gender, isDarkMode: themeManager.isDarkMode) : Color.clear, lineWidth: 2)
            )
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

struct AppearanceModeRow: View {
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var themeManager: ThemeManager
    let isDark: Bool
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: {
            withAnimation(.easeInOut(duration: 0.3)) {
                action()
            }
        }) {
            HStack {
                // Icon preview
                Image(systemName: isDark ? "moon.fill" : "sun.max.fill")
                    .font(.title3)
                    .foregroundColor(isDark ? .blue : .orange)
                    .frame(width: 32, height: 32)
                    .overlay(
                        Circle()
                            .stroke(isSelected ? (isDark ? .blue : .orange) : Color.clear, lineWidth: 2)
                    )
                
                VStack(alignment: .leading, spacing: 4) {
                    Text(isDark ? languageManager.localize("settings.theme.dark") : languageManager.localize("settings.theme.light"))
                        .font(.headline)
                        .foregroundColor(ColorTheme.adaptiveText(primary: true, isDarkMode: themeManager.isDarkMode))
                    Text(isDark ? "Dark appearance" : "Light appearance")
                        .font(.caption)
                        .foregroundColor(ColorTheme.adaptiveText(primary: false, isDarkMode: themeManager.isDarkMode))
                }
                
                Spacer()
                
                if isSelected {
                    Image(systemName: "checkmark.circle.fill")
                        .font(.title3)
                        .foregroundColor(isDark ? .blue : .orange)
                }
            }
            .padding()
            .background(isSelected ? (isDark ? Color.blue.opacity(0.15) : Color.orange.opacity(0.15)) : ColorTheme.adaptiveBackground(primary: true, isDarkMode: themeManager.isDarkMode))
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(isSelected ? (isDark ? .blue : .orange) : Color.clear, lineWidth: 2)
            )
            .cornerRadius(12)
        }
        .buttonStyle(PlainButtonStyle())
    }
}

#Preview {
    SettingsView()
        .environmentObject(LanguageManager())
        .environmentObject(ThemeManager())
        .preferredColorScheme(.dark)
}

