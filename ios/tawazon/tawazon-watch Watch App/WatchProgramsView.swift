//
//  WatchProgramsView.swift
//  tawazon-watch Watch App
//
//  Programs and workouts view for watchOS
//

import SwiftUI

struct WatchProgramsView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var authManager: AuthManager
    
    @State private var programs: [ProgramResponse] = []
    @State private var subscriptions: [SubscriptionResponse] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    @State private var selectedProgram: ProgramResponse?
    
    private let apiService = APIService.shared
    private let keychain = KeychainService.shared
    
    var body: some View {
        Group {
            if isLoading {
                ProgressView()
                    .tint(themeManager.dynamicColorTheme.currentPrimary)
            } else if let error = errorMessage {
                VStack(spacing: 12) {
                    Image(systemName: "exclamationmark.triangle")
                        .font(.title2)
                        .foregroundColor(.red)
                    Text(error)
                        .font(.caption)
                        .foregroundColor(ColorTheme.adaptiveText(primary: false, isDarkMode: themeManager.isDarkMode))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            } else if programs.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "list.bullet")
                        .font(.title2)
                        .foregroundColor(ColorTheme.adaptiveText(primary: false, isDarkMode: themeManager.isDarkMode))
                    Text(languageManager.localize("watch.noPrograms"))
                        .font(.caption)
                        .foregroundColor(ColorTheme.adaptiveText(primary: false, isDarkMode: themeManager.isDarkMode))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(programs, id: \.id) { program in
                            ProgramCard(
                                program: program,
                                themeManager: themeManager,
                                languageManager: languageManager
                            )
                        }
                    }
                    .padding(.horizontal, 4)
                    .padding(.vertical, 8)
                }
            }
        }
        .navigationTitle(languageManager.localize("nav.training"))
        .onAppear {
            loadData()
        }
    }
    
    private func loadData() {
        #if targetEnvironment(simulator)
        // On simulator, load dummy data
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.programs = Self.getDummyPrograms()
            self.isLoading = false
        }
        #else
        // On real device, load from API
        guard let token = keychain.getAccessToken() else {
            errorMessage = languageManager.localize("watch.loginRequired")
            isLoading = false
            return
        }
        
        Task {
            isLoading = true
            errorMessage = nil
            
            do {
                // Load subscriptions to get user's subscribed programs
                let subscriptionsPage = try await apiService.getSubscriptions(page: 0, size: 50, token: token)
                await MainActor.run {
                    subscriptions = subscriptionsPage.content
                }
                
                // Load all programs
                let programsPage = try await apiService.getPrograms(page: 0, size: 50)
                await MainActor.run {
                    // Filter to show only subscribed programs, or all if no subscriptions
                    if subscriptions.isEmpty {
                        programs = programsPage.content
                    } else {
                        let subscribedCoachIds = Set(subscriptions.map { $0.coachProfileId })
                        programs = programsPage.content.filter { subscribedCoachIds.contains($0.coachProfileId) }
                    }
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMessage = languageManager.localize("common.error") + ": \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
        #endif
    }
    
    // MARK: - Dummy Data for Simulator
    static func getDummyPrograms() -> [ProgramResponse] {
        return [
            ProgramResponse(
                id: "dummy-1",
                coachProfileId: "coach-1",
                name: "8-Week Strength Builder",
                description: "Progressive overload program for building muscle mass",
                durationWeeks: 8,
                difficulty: "INTERMEDIATE",
                workouts: [
                    WorkoutResponse(
                        id: "workout-1",
                        name: "Push Day",
                        description: "Chest, shoulders, and triceps",
                        dayOfWeek: 1,
                        orderIndex: 1
                    ),
                    WorkoutResponse(
                        id: "workout-2",
                        name: "Pull Day",
                        description: "Back and biceps",
                        dayOfWeek: 3,
                        orderIndex: 2
                    ),
                    WorkoutResponse(
                        id: "workout-3",
                        name: "Leg Day",
                        description: "Quads, hamstrings, and glutes",
                        dayOfWeek: 5,
                        orderIndex: 3
                    )
                ],
                dietPlans: [
                    DietPlanResponse(
                        id: "diet-1",
                        name: "High Protein Plan",
                        description: "200g protein daily",
                        targetCalories: 2500
                    )
                ],
                createdAt: nil,
                updatedAt: nil
            ),
            ProgramResponse(
                id: "dummy-2",
                coachProfileId: "coach-2",
                name: "Cardio Blast",
                description: "High-intensity cardio workouts",
                durationWeeks: 4,
                difficulty: "BEGINNER",
                workouts: [
                    WorkoutResponse(
                        id: "workout-4",
                        name: "Morning Run",
                        description: "30-minute steady pace",
                        dayOfWeek: 2,
                        orderIndex: 1
                    ),
                    WorkoutResponse(
                        id: "workout-5",
                        name: "HIIT Session",
                        description: "20 minutes high intensity",
                        dayOfWeek: 4,
                        orderIndex: 2
                    )
                ],
                dietPlans: [
                    DietPlanResponse(
                        id: "diet-2",
                        name: "Weight Loss Plan",
                        description: "Calorie deficit diet",
                        targetCalories: 1800
                    )
                ],
                createdAt: nil,
                updatedAt: nil
            )
        ]
    }
}

struct ProgramCard: View {
    let program: ProgramResponse
    @ObservedObject var themeManager: ThemeManager
    @ObservedObject var languageManager: LanguageManager
    @State private var isExpanded = false
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            // Program Header
            HStack {
                VStack(alignment: .leading, spacing: 2) {
                    Text(program.name)
                        .font(.headline)
                        .foregroundColor(ColorTheme.adaptiveText(primary: true, isDarkMode: themeManager.isDarkMode))
                    
                    if let description = program.description, !description.isEmpty {
                        Text(description)
                            .font(.caption2)
                            .foregroundColor(ColorTheme.adaptiveText(primary: false, isDarkMode: themeManager.isDarkMode))
                            .lineLimit(2)
                    }
                }
                
                Spacer()
                
                Button(action: {
                    withAnimation {
                        isExpanded.toggle()
                    }
                }) {
                    Image(systemName: isExpanded ? "chevron.up" : "chevron.down")
                        .font(.caption)
                        .foregroundColor(themeManager.dynamicColorTheme.currentPrimary)
                }
            }
            
            // Program Info
            HStack(spacing: 8) {
                Label("\(program.durationWeeks)", systemImage: "calendar")
                    .font(.caption2)
                    .foregroundColor(ColorTheme.adaptiveText(primary: false, isDarkMode: themeManager.isDarkMode))
                
                Label(program.difficulty, systemImage: "chart.bar")
                    .font(.caption2)
                    .foregroundColor(ColorTheme.adaptiveText(primary: false, isDarkMode: themeManager.isDarkMode))
            }
            
            // Expanded Content
            if isExpanded {
                VStack(alignment: .leading, spacing: 8) {
                    // Workouts
                    if !program.workouts.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(languageManager.localize("watch.workouts"))
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(themeManager.dynamicColorTheme.currentPrimary)
                            
                            ForEach(program.workouts, id: \.id) { workout in
                                WorkoutRow(workout: workout, themeManager: themeManager, languageManager: languageManager)
                            }
                        }
                    }
                    
                    // Diet Plans
                    if !program.dietPlans.isEmpty {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(languageManager.localize("watch.dietPlans"))
                                .font(.caption)
                                .fontWeight(.semibold)
                                .foregroundColor(themeManager.dynamicColorTheme.currentPrimary)
                            
                            ForEach(program.dietPlans, id: \.id) { dietPlan in
                                DietPlanRow(dietPlan: dietPlan, themeManager: themeManager, languageManager: languageManager)
                            }
                        }
                    }
                }
                .padding(.top, 4)
            }
        }
        .padding(8)
        .background(ColorTheme.adaptiveBackground(primary: false, isDarkMode: themeManager.isDarkMode))
        .cornerRadius(8)
    }
}

struct WorkoutRow: View {
    let workout: WorkoutResponse
    @ObservedObject var themeManager: ThemeManager
    @ObservedObject var languageManager: LanguageManager
    
    private var dayName: String {
        let days = ["", "Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]
        return days[min(workout.dayOfWeek, 7)]
    }
    
    var body: some View {
        HStack {
            Image(systemName: "figure.run")
                .font(.caption2)
                .foregroundColor(themeManager.dynamicColorTheme.currentPrimary)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(workout.name)
                    .font(.caption)
                    .foregroundColor(ColorTheme.adaptiveText(primary: true, isDarkMode: themeManager.isDarkMode))
                
                if let description = workout.description, !description.isEmpty {
                    Text(description)
                        .font(.caption2)
                        .foregroundColor(ColorTheme.adaptiveText(primary: false, isDarkMode: themeManager.isDarkMode))
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            Text(dayName)
                .font(.caption2)
                .foregroundColor(ColorTheme.adaptiveText(primary: false, isDarkMode: themeManager.isDarkMode))
        }
        .padding(.vertical, 2)
    }
}

struct DietPlanRow: View {
    let dietPlan: DietPlanResponse
    @ObservedObject var themeManager: ThemeManager
    @ObservedObject var languageManager: LanguageManager
    
    var body: some View {
        HStack {
            Image(systemName: "fork.knife")
                .font(.caption2)
                .foregroundColor(themeManager.dynamicColorTheme.currentPrimary)
            
            VStack(alignment: .leading, spacing: 1) {
                Text(dietPlan.name)
                    .font(.caption)
                    .foregroundColor(ColorTheme.adaptiveText(primary: true, isDarkMode: themeManager.isDarkMode))
                
                if let description = dietPlan.description, !description.isEmpty {
                    Text(description)
                        .font(.caption2)
                        .foregroundColor(ColorTheme.adaptiveText(primary: false, isDarkMode: themeManager.isDarkMode))
                        .lineLimit(1)
                }
            }
            
            Spacer()
            
            if let calories = dietPlan.targetCalories {
                Text("\(calories) cal")
                    .font(.caption2)
                    .foregroundColor(ColorTheme.adaptiveText(primary: false, isDarkMode: themeManager.isDarkMode))
            }
        }
        .padding(.vertical, 2)
    }
}

#Preview {
    WatchProgramsView()
        .environmentObject(ThemeManager.shared)
        .environmentObject(LanguageManager.shared)
        .environmentObject(AuthManager.shared)
}

