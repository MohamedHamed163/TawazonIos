//
//  WatchWorkoutView.swift
//  tawazon-watch Watch App
//
//  Workout control view
//

import SwiftUI
import HealthKit

struct WatchWorkoutView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var languageManager: LanguageManager
    @StateObject private var healthKitService = HealthKitService.shared
    @State private var isWorkoutActive = false
    @State private var workoutTime: TimeInterval = 0
    @State private var timer: Timer?
    @State private var workoutSession: HKWorkoutSession?
    @State private var workoutBuilder: HKLiveWorkoutBuilder?
    private let healthStore = HKHealthStore()
    
    var body: some View {
        VStack(spacing: 16) {
            if isWorkoutActive {
                // Active workout
                VStack(spacing: 12) {
                    Text(formatTime(workoutTime))
                        .font(.system(size: 48, weight: .bold))
                        .monospacedDigit()
                        .foregroundColor(ColorTheme.adaptiveText(primary: true, isDarkMode: themeManager.isDarkMode))
                    
                    Button(action: stopWorkout) {
                        Text(languageManager.localize("workout.stop"))
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.red)
                            .cornerRadius(12)
                    }
                }
            } else {
                // Start workout
                VStack(spacing: 12) {
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 60))
                        .foregroundColor(themeManager.dynamicColorTheme.currentPrimary)
                    
                    Button(action: startWorkout) {
                        Text(languageManager.localize("workout.start"))
                            .font(.headline)
                            .foregroundColor(.white)
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(themeManager.dynamicColorTheme.currentPrimary)
                            .cornerRadius(12)
                    }
                }
            }
        }
        .background(ColorTheme.adaptiveBackground(primary: true, isDarkMode: themeManager.isDarkMode))
        .navigationTitle(languageManager.localize("nav.training"))
        .padding()
        .onDisappear {
            if isWorkoutActive {
                stopWorkout()
            }
        }
    }
    
    private func startWorkout() {
        guard HKHealthStore.isHealthDataAvailable() else {
            return
        }
        
        // Request authorization if needed
        Task {
            if !healthKitService.isAuthorized {
                try? await healthKitService.requestAuthorization()
            }
            
            await MainActor.run {
                isWorkoutActive = true
                workoutTime = 0
                startTimer()
            }
        }
    }
    
    private func startTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
            workoutTime += 1
        }
    }
    
    private func stopWorkout() {
        timer?.invalidate()
        timer = nil
        isWorkoutActive = false
        workoutTime = 0
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    WatchWorkoutView()
        .environmentObject(ThemeManager.shared)
        .environmentObject(LanguageManager.shared)
}

