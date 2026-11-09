//
//  StatsView.swift
//  TawazonWatch
//
//  Quick stats view for watch
//

import SwiftUI

struct StatsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var languageManager: LanguageManager
    @State private var steps: Int = 0
    @State private var calories: Int = 0
    @State private var heartRate: Int = 0
    
    var body: some View {
        ScrollView {
            VStack(spacing: 12) {
                // Steps
                StatRow(
                    icon: "figure.walk",
                    value: "\(steps)",
                    label: languageManager.localize("progress.steps"),
                    color: themeManager.dynamicColorTheme.currentPrimary
                )
                
                // Calories
                StatRow(
                    icon: "flame.fill",
                    value: "\(calories)",
                    label: languageManager.localize("progress.calories"),
                    color: .orange
                )
                
                // Heart Rate
                StatRow(
                    icon: "heart.fill",
                    value: "\(heartRate)",
                    label: languageManager.localize("progress.heartRate"),
                    color: .red
                )
            }
            .padding(.horizontal, 8)
            .padding(.vertical, 4)
        }
        .navigationTitle(languageManager.localize("progress.title"))
        .onAppear {
            loadHealthData()
        }
    }
    
    private func loadHealthData() {
        // Load from HealthKit or shared data
        // This will be implemented with HealthKitService
        steps = 5420
        calories = 320
        heartRate = 72
    }
}

struct StatRow: View {
    let icon: String
    let value: String
    let label: String
    let color: Color
    
    var body: some View {
        HStack {
            Image(systemName: icon)
                .foregroundColor(color)
                .font(.title3)
            
            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.bold)
                
                Text(label)
                    .font(.caption2)
                    .foregroundColor(.secondary)
            }
            
            Spacer()
        }
        .padding(.vertical, 8)
    }
}

#Preview {
    StatsView()
        .environmentObject(ThemeManager.shared)
        .environmentObject(LanguageManager.shared)
}

