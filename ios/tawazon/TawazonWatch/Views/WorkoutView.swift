//
//  WorkoutView.swift
//  TawazonWatch
//
//  Workout control view
//

import SwiftUI

struct WorkoutView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var languageManager: LanguageManager
    @State private var isWorkoutActive = false
    @State private var workoutTime: TimeInterval = 0
    
    var body: some View {
        VStack(spacing: 16) {
            if isWorkoutActive {
                // Active workout
                VStack(spacing: 12) {
                    Text(formatTime(workoutTime))
                        .font(.system(size: 48, weight: .bold))
                        .monospacedDigit()
                    
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
        .navigationTitle(languageManager.localize("nav.training"))
        .padding()
    }
    
    private func startWorkout() {
        isWorkoutActive = true
        // Start HealthKit workout session
        // This will be implemented with HealthKitService
    }
    
    private func stopWorkout() {
        isWorkoutActive = false
        workoutTime = 0
        // Stop HealthKit workout session
    }
    
    private func formatTime(_ time: TimeInterval) -> String {
        let minutes = Int(time) / 60
        let seconds = Int(time) % 60
        return String(format: "%02d:%02d", minutes, seconds)
    }
}

#Preview {
    WorkoutView()
        .environmentObject(ThemeManager.shared)
        .environmentObject(LanguageManager.shared)
}

