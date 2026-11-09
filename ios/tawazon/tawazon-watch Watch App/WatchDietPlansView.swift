//
//  WatchDietPlansView.swift
//  tawazon-watch Watch App
//
//  Diet plans view for watchOS
//

import SwiftUI

struct WatchDietPlansView: View {
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var authManager: AuthManager
    
    @State private var dietPlans: [DietPlanResponse] = []
    @State private var isLoading = true
    @State private var errorMessage: String?
    
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
            } else if dietPlans.isEmpty {
                VStack(spacing: 12) {
                    Image(systemName: "fork.knife")
                        .font(.title2)
                        .foregroundColor(ColorTheme.adaptiveText(primary: false, isDarkMode: themeManager.isDarkMode))
                    Text(languageManager.localize("watch.noDietPlans"))
                        .font(.caption)
                        .foregroundColor(ColorTheme.adaptiveText(primary: false, isDarkMode: themeManager.isDarkMode))
                        .multilineTextAlignment(.center)
                        .padding(.horizontal)
                }
            } else {
                ScrollView {
                    VStack(spacing: 8) {
                        ForEach(dietPlans, id: \.id) { dietPlan in
                            DietPlanCard(
                                dietPlan: dietPlan,
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
        .navigationTitle(languageManager.localize("nav.meals"))
        .onAppear {
            loadData()
        }
    }
    
    private func loadData() {
        #if targetEnvironment(simulator)
        // On simulator, load dummy data
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
            self.dietPlans = Self.getDummyDietPlans()
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
                // Load subscriptions to get user's subscribed coaches
                let subscriptionsPage = try await apiService.getSubscriptions(page: 0, size: 50, token: token)
                let subscriptions = subscriptionsPage.content
                
                // Load all programs
                let programsPage = try await apiService.getPrograms(page: 0, size: 50)
                
                await MainActor.run {
                    // Filter to show only diet plans from subscribed coaches
                    if subscriptions.isEmpty {
                        // If no subscriptions, show all diet plans
                        dietPlans = programsPage.content.flatMap { $0.dietPlans }
                    } else {
                        let subscribedCoachIds = Set(subscriptions.map { $0.coachProfileId })
                        let filteredPrograms = programsPage.content.filter { subscribedCoachIds.contains($0.coachProfileId) }
                        dietPlans = filteredPrograms.flatMap { $0.dietPlans }
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
    static func getDummyDietPlans() -> [DietPlanResponse] {
        return [
            DietPlanResponse(
                id: "diet-1",
                name: "High Protein Plan",
                description: "200g protein daily for muscle building",
                targetCalories: 2500
            ),
            DietPlanResponse(
                id: "diet-2",
                name: "Weight Loss Plan",
                description: "Calorie deficit diet for fat loss",
                targetCalories: 1800
            ),
            DietPlanResponse(
                id: "diet-3",
                name: "Maintenance Plan",
                description: "Balanced nutrition for maintaining weight",
                targetCalories: 2200
            ),
            DietPlanResponse(
                id: "diet-4",
                name: "Keto Plan",
                description: "Low carb, high fat diet",
                targetCalories: 2000
            )
        ]
    }
}

struct DietPlanCard: View {
    let dietPlan: DietPlanResponse
    @ObservedObject var themeManager: ThemeManager
    @ObservedObject var languageManager: LanguageManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack {
                Image(systemName: "fork.knife")
                    .font(.title3)
                    .foregroundColor(themeManager.dynamicColorTheme.currentPrimary)
                
                VStack(alignment: .leading, spacing: 2) {
                    Text(dietPlan.name)
                        .font(.headline)
                        .foregroundColor(ColorTheme.adaptiveText(primary: true, isDarkMode: themeManager.isDarkMode))
                    
                    if let description = dietPlan.description, !description.isEmpty {
                        Text(description)
                            .font(.caption2)
                            .foregroundColor(ColorTheme.adaptiveText(primary: false, isDarkMode: themeManager.isDarkMode))
                            .lineLimit(2)
                    }
                }
                
                Spacer()
            }
            
            if let calories = dietPlan.targetCalories {
                HStack {
                    Label("\(calories) \(languageManager.localize("watch.calories"))", systemImage: "flame.fill")
                        .font(.caption)
                        .foregroundColor(ColorTheme.adaptiveText(primary: false, isDarkMode: themeManager.isDarkMode))
                }
            }
        }
        .padding(8)
        .background(ColorTheme.adaptiveBackground(primary: false, isDarkMode: themeManager.isDarkMode))
        .cornerRadius(8)
    }
}

#Preview {
    WatchDietPlansView()
        .environmentObject(ThemeManager.shared)
        .environmentObject(LanguageManager.shared)
        .environmentObject(AuthManager.shared)
}

