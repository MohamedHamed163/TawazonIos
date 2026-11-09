//
//  WatchStatsView.swift
//  tawazon-watch Watch App
//
//  Quick stats view for watch
//

import SwiftUI
import HealthKit

struct WatchStatsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var languageManager: LanguageManager
    @StateObject private var healthKitService = HealthKitService.shared
    private let apiService = APIService.shared
    private let keychain = KeychainService.shared
    @State private var steps: Int = 0
    @State private var calories: Int = 0
    @State private var heartRate: Int = 0
    @State private var isLoading = true
    @State private var showPermissionAlert = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                if isLoading {
                    ProgressView()
                        .padding()
                        .tint(themeManager.dynamicColorTheme.currentPrimary)
                } else {
                    // Steps
                    StatRow(
                        icon: "figure.walk",
                        value: "\(steps)",
                        label: languageManager.localize("progress.steps"),
                        color: themeManager.dynamicColorTheme.currentPrimary,
                        themeManager: themeManager
                    )
                    
                    // Calories
                    StatRow(
                        icon: "flame.fill",
                        value: "\(calories)",
                        label: languageManager.localize("progress.calories"),
                        color: .orange,
                        themeManager: themeManager
                    )
                    
                    // Heart Rate
                    StatRow(
                        icon: "heart.fill",
                        value: heartRate > 0 ? "\(heartRate)" : "--",
                        label: languageManager.localize("progress.heartRate"),
                        color: .red,
                        themeManager: themeManager
                    )
                }
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .background(ColorTheme.adaptiveBackground(primary: true, isDarkMode: themeManager.isDarkMode))
        .navigationTitle(languageManager.localize("progress.title"))
        .onAppear {
            loadHealthData()
        }
        .alert(languageManager.localize("healthkit.permissionRequired"), isPresented: $showPermissionAlert) {
            Button(languageManager.localize("common.ok")) {
                Task {
                    await requestHealthKitPermission()
                }
            }
        } message: {
            Text(languageManager.localize("healthkit.permissionMessage"))
        }
    }
    
    private func loadHealthData() {
        #if targetEnvironment(simulator)
        // On simulator, use dummy data
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.steps = 8542
            self.calories = 1240
            self.heartRate = 72
            self.isLoading = false
        }
        #else
        // On real device, load from HealthKit
        Task {
            isLoading = true
            
            // Check if HealthKit is authorized
            if !healthKitService.isAuthorized {
                if healthKitService.authorizationStatus == .notDetermined {
                    await requestHealthKitPermission()
                } else {
                    showPermissionAlert = true
                    isLoading = false
                    return
                }
            }
            
            do {
                let summary = try await healthKitService.getTodaySummary()
                await MainActor.run {
                    steps = summary.steps
                    calories = summary.calories
                    heartRate = summary.averageHeartRate ?? 0
                    isLoading = false
                }
                syncWearableStats(summary)
            } catch {
                print("Failed to load health data: \(error)")
                await MainActor.run {
                    isLoading = false
                }
            }
        }
        #endif
    }

    /// Best-effort push of the just-read HealthKit stats to the backend so they persist
    /// and coaches can see them. Fire-and-forget: never blocks the UI or surfaces errors.
    /// The upsert is idempotent, so double-syncing from phone + watch is harmless.
    private func syncWearableStats(_ summary: HealthSummary) {
        guard let token = keychain.getAccessToken() else { return }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        let request = WearableStatsRequest(
            date: today,
            avgHeartRate: summary.averageHeartRate,
            steps: summary.steps,
            activeCalories: summary.calories
        )
        Task {
            try? await apiService.syncWearableStats(request, token: token)
        }
    }
    
    private func requestHealthKitPermission() async {
        do {
            try await healthKitService.requestAuthorization()
            await loadHealthData()
        } catch {
            print("Failed to request HealthKit permission: \(error)")
            await MainActor.run {
                isLoading = false
                showPermissionAlert = true
            }
        }
    }
}

struct StatRow: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    @ObservedObject var themeManager: ThemeManager
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                    .foregroundColor(ColorTheme.adaptiveText(primary: true, isDarkMode: themeManager.isDarkMode))
                
                Text(label)
                    .font(.caption2)
                    .foregroundColor(ColorTheme.adaptiveText(primary: false, isDarkMode: themeManager.isDarkMode))
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    WatchStatsView()
        .environmentObject(ThemeManager.shared)
        .environmentObject(LanguageManager.shared)
}

