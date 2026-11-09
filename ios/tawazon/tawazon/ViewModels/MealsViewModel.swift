//
//  MealsViewModel.swift
//  tawazon
//

import Foundation
import Observation

@MainActor
@Observable
final class MealsViewModel {
    private let api = APIService.shared

    var schedule: TodayScheduleResponse?
    var awaitingProgramAssignment = false
    var isLoading = false
    var errorMessage: String?

    /// Currently displayed day of week (backend convention: 1 = Monday … 7 = Sunday).
    var selectedDay: Int = MealsViewModel.currentDayOfWeek()

    var dietPlans: [ScheduledDietPlan] { schedule?.dietPlans ?? [] }

    /// Today's day of week in the backend convention (1 = Monday … 7 = Sunday).
    /// Apple's `Calendar` uses 1 = Sunday … 7 = Saturday, so convert accordingly.
    static func currentDayOfWeek() -> Int {
        let appleWeekday = Calendar.current.component(.weekday, from: Date())
        return appleWeekday == 1 ? 7 : appleWeekday - 1
    }

    func load() async {
        guard let token = KeychainService.shared.getAccessToken() else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            if let s = try await api.getTodaySchedule(token: token) {
                schedule = s
                awaitingProgramAssignment = false
            } else {
                schedule = nil
                awaitingProgramAssignment = true
            }
        } catch {
            awaitingProgramAssignment = false
            errorMessage = error.localizedDescription
        }
    }

    /// Meals of a diet plan for the selected day, grouped and ordered by meal type
    /// (Breakfast → Lunch → Dinner → Snack).
    func groupedMeals(_ plan: ScheduledDietPlan) -> [(type: String, meals: [DietPlanMealResponse])] {
        let order = ["BREAKFAST", "LUNCH", "DINNER", "SNACK"]
        let items = (plan.meals ?? []).filter { $0.dayOfWeek == selectedDay }
        let grouped = Dictionary(grouping: items) { $0.mealType.uppercased() }
        return order.compactMap { key in
            guard let meals = grouped[key], !meals.isEmpty else { return nil }
            return (type: key, meals: meals.sorted { $0.orderIndex < $1.orderIndex })
        }
    }
}
