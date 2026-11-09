//
//  MealsView.swift
//  tawazon
//

import SwiftUI

struct MealsView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var themeManager: ThemeManager
    @State private var model = MealsViewModel()

    private var textPrimary: Color { ColorTheme.adaptiveText(primary: true, isDarkMode: themeManager.isDarkMode) }
    private var textSecondary: Color { ColorTheme.adaptiveText(primary: false, isDarkMode: themeManager.isDarkMode) }

    var body: some View {
        ZStack {
            ColorTheme.adaptiveBackground(primary: true, isDarkMode: themeManager.isDarkMode)
                .ignoresSafeArea()

            if model.isLoading && model.schedule == nil {
                ScrollView {
                    SkeletonList(count: 3, lines: 4)
                        .padding()
                }
            } else if model.awaitingProgramAssignment {
                EmptyStateView(
                    icon: "fork.knife",
                    title: languageManager.localize("meals.noPlanTitle"),
                    message: languageManager.localize("meals.noPlanBody")
                )
            } else if let err = model.errorMessage, model.schedule == nil {
                EmptyStateView(
                    icon: "exclamationmark.triangle",
                    title: languageManager.localize("common.error"),
                    message: err,
                    actionTitle: languageManager.localize("common.retry"),
                    action: { Task { await model.load() } }
                )
            } else if model.dietPlans.isEmpty {
                EmptyStateView(
                    icon: "fork.knife",
                    title: languageManager.localize("meals.noMealsTitle"),
                    message: languageManager.localize("meals.noMealsBody")
                )
            } else {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        daySelector
                        ForEach(model.dietPlans) { plan in
                            dietPlanSection(plan)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(languageManager.localize("meals.title"))
        .navigationBarTitleDisplayMode(.inline)
        .task { await model.load() }
        .refreshable { await model.load() }
    }

    private var daySelector: some View {
        Picker("", selection: $model.selectedDay) {
            ForEach(1...7, id: \.self) { day in
                Text(dayShortLabel(day)).tag(day)
            }
        }
        .pickerStyle(.segmented)
        .onChange(of: model.selectedDay) { _, _ in
            Haptics.selection()
        }
    }

    @ViewBuilder
    private func dietPlanSection(_ plan: ScheduledDietPlan) -> some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(alignment: .firstTextBaseline) {
                Text(plan.name)
                    .textStyle(Typography.Style.title3, color: textPrimary)
                Spacer()
                if let cals = plan.targetCalories {
                    Text("\(cals) kcal")
                        .textStyle(Typography.Style.captionBold, color: themeManager.dynamicColorTheme.currentPrimary)
                }
            }
            if let desc = plan.description, !desc.isEmpty {
                Text(desc)
                    .textStyle(Typography.Style.caption, color: textSecondary)
            }

            let groups = model.groupedMeals(plan)
            if groups.isEmpty {
                Text(languageManager.localize("meals.noMealsForDay"))
                    .textStyle(Typography.Style.caption, color: textSecondary)
            } else {
                ForEach(groups, id: \.type) { group in
                    Text(mealTypeLabel(group.type))
                        .textStyle(Typography.Style.captionBold, color: textSecondary)
                        .padding(.top, 4)
                    ForEach(group.meals) { dpm in
                        mealCard(dpm.meal)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private func mealCard(_ meal: MealResponse) -> some View {
        AppCard {
            VStack(alignment: .leading, spacing: 10) {
                Text(meal.name)
                    .textStyle(Typography.Style.headline, color: textPrimary)

                macrosRow(meal)

                if let items = meal.items, !items.isEmpty {
                    Divider().background(textSecondary.opacity(0.2))
                    ForEach(items, id: \.id) { item in
                        VStack(alignment: .leading, spacing: 4) {
                            HStack {
                                Text(item.foodName ?? languageManager.localize("meals.item"))
                                    .textStyle(Typography.Style.subheadline, color: textPrimary)
                                Spacer()
                                Text(formatQuantity(item))
                                    .textStyle(Typography.Style.caption, color: textSecondary)
                            }
                            ForEach(item.alternatives) { alt in
                                HStack(alignment: .firstTextBaseline, spacing: 4) {
                                    Text(languageManager.localize("meals.or"))
                                        .textStyle(Typography.Style.caption, color: textSecondary)
                                    Text(alt.foodName ?? languageManager.localize("meals.item"))
                                        .textStyle(Typography.Style.caption, color: textSecondary)
                                    Spacer()
                                    Text(formatAlternativeQuantity(alt))
                                        .textStyle(Typography.Style.caption2, color: textSecondary)
                                }
                                .padding(.leading, 12)
                            }
                        }
                    }
                }

                if let steps = meal.cookingSteps?.compactMap({ $0.instructionText }).filter({ !$0.isEmpty }), !steps.isEmpty {
                    Divider().background(textSecondary.opacity(0.2))
                    Text(languageManager.localize("meals.howToPrepare"))
                        .textStyle(Typography.Style.subheadlineBold, color: textPrimary)
                    ForEach(Array(steps.enumerated()), id: \.offset) { idx, step in
                        HStack(alignment: .top, spacing: 8) {
                            Text("\(idx + 1).")
                                .textStyle(Typography.Style.caption, color: themeManager.dynamicColorTheme.currentPrimary)
                            Text(step)
                                .textStyle(Typography.Style.caption, color: textSecondary)
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    @ViewBuilder
    private func macrosRow(_ meal: MealResponse) -> some View {
        HStack(spacing: 16) {
            if let c = meal.calories { macroPill(value: "\(Int(c))", unit: "kcal") }
            if let p = meal.protein { macroPill(value: "\(Int(p))g", unit: languageManager.localize("meals.protein")) }
            if let c = meal.carbs { macroPill(value: "\(Int(c))g", unit: languageManager.localize("meals.carbs")) }
            if let f = meal.fat { macroPill(value: "\(Int(f))g", unit: languageManager.localize("meals.fat")) }
        }
    }

    private func macroPill(value: String, unit: String) -> some View {
        VStack(spacing: 2) {
            Text(value)
                .textStyle(Typography.Style.subheadlineBold, color: textPrimary)
            Text(unit)
                .textStyle(Typography.Style.caption2, color: textSecondary)
        }
    }

    private func formatQuantity(_ item: MealItemResponse) -> String {
        formatQuantity(item.quantity, unit: item.unit)
    }

    private func formatAlternativeQuantity(_ alt: MealItemAlternative) -> String {
        formatQuantity(alt.quantity, unit: alt.unit)
    }

    private func formatQuantity(_ quantity: Double, unit: String) -> String {
        let qStr = quantity.truncatingRemainder(dividingBy: 1) == 0 ? "\(Int(quantity))" : String(format: "%.1f", quantity)
        return "\(qStr) \(unit.lowercased())"
    }

    private func dayShortLabel(_ day: Int) -> String {
        switch day {
        case 1: return languageManager.localize("meals.day.mon")
        case 2: return languageManager.localize("meals.day.tue")
        case 3: return languageManager.localize("meals.day.wed")
        case 4: return languageManager.localize("meals.day.thu")
        case 5: return languageManager.localize("meals.day.fri")
        case 6: return languageManager.localize("meals.day.sat")
        case 7: return languageManager.localize("meals.day.sun")
        default: return "\(day)"
        }
    }

    private func mealTypeLabel(_ type: String) -> String {
        switch type.uppercased() {
        case "BREAKFAST": return languageManager.localize("meals.breakfast")
        case "LUNCH": return languageManager.localize("meals.lunch")
        case "DINNER": return languageManager.localize("meals.dinner")
        case "SNACK": return languageManager.localize("meals.snack")
        default: return type.capitalized
        }
    }
}
