//
//  HealthKitPermissionView.swift
//  tawazon
//
//  Created by Ahmed Farahat on 04/09/1447 AH.
//

import SwiftUI
import HealthKit

struct HealthKitPermissionView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var themeManager: ThemeManager
    @StateObject private var healthKitService = HealthKitService.shared
    @State private var isRequesting = false
    @State private var errorMessage: String?
    
    var body: some View {
        VStack(spacing: 24) {
            Image(systemName: "heart.fill")
                .font(.system(size: 60))
                .foregroundColor(themeManager.dynamicColorTheme.currentPrimary)
            
            Text(languageManager.localize("health.connect"))
                .font(.title)
                .fontWeight(.bold)
                .foregroundColor(.white)
            
            Text(languageManager.localize("health.connectDescription"))
                .font(.subheadline)
                .foregroundColor(.gray)
                .multilineTextAlignment(.center)
                .padding(.horizontal)
            
            if let errorMessage = errorMessage {
                Text(errorMessage)
                    .font(.caption)
                    .foregroundColor(.red)
                    .padding(.horizontal)
            }
            
            Button(action: {
                requestPermission()
            }) {
                HStack {
                    if isRequesting {
                        ProgressView()
                            .progressViewStyle(CircularProgressViewStyle(tint: themeManager.dynamicColorTheme.currentPrimaryDark))
                    } else {
                        Text(languageManager.localize("health.connect"))
                            .fontWeight(.semibold)
                    }
                }
                .frame(maxWidth: .infinity)
                .padding()
                .background(themeManager.dynamicColorTheme.currentPrimary)
                .foregroundColor(themeManager.dynamicColorTheme.currentPrimaryDark)
                .cornerRadius(12)
            }
            .disabled(isRequesting)
            .padding(.horizontal)
            
            Button(action: {
                // Skip for now
            }) {
                Text(languageManager.localize("health.skip"))
                    .font(.subheadline)
                    .foregroundColor(.gray)
            }
        }
        .padding()
    }
    
    private func requestPermission() {
        isRequesting = true
        errorMessage = nil
        
        Task {
            do {
                try await healthKitService.requestAuthorization()
                await MainActor.run {
                    isRequesting = false
                }
            } catch {
                await MainActor.run {
                    isRequesting = false
                    errorMessage = error.localizedDescription
                }
            }
        }
    }
}

#Preview {
    HealthKitPermissionView()
        .environmentObject(LanguageManager())
        .environmentObject(ThemeManager())
        .preferredColorScheme(.dark)
}

