//
//  TodayWorkoutView.swift
//  tawazon
//

import SwiftUI

struct TodayWorkoutView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var themeManager: ThemeManager
    @State private var model = TodayWorkoutViewModel()
    var onPlayVideo: (String) -> Void
    var onStartWorkout: () -> Void

    var body: some View {
        ZStack {
            ColorTheme.adaptiveBackground(primary: true, isDarkMode: themeManager.isDarkMode)
                .ignoresSafeArea()
            if model.isLoading && model.schedule == nil {
                ScrollView {
                    SkeletonList(count: 3, lines: 4)
                        .padding()
                }
            } else if model.awaitingProgramAssignment, model.schedule == nil, model.errorMessage == nil {
                EmptyStateView(
                    icon: "calendar.badge.clock",
                    title: languageManager.localize("today.noProgramTitle"),
                    message: languageManager.localize("today.noProgramBody")
                )
            } else if let err = model.errorMessage, model.schedule == nil {
                EmptyStateView(
                    icon: "exclamationmark.triangle",
                    title: languageManager.localize("common.error"),
                    message: err,
                    actionTitle: languageManager.localize("common.retry"),
                    action: { Task { await model.load() } }
                )
            } else if let s = model.schedule {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text(s.programName)
                            .textStyle(Typography.Style.title2, color: ColorTheme.adaptiveText(primary: true, isDarkMode: themeManager.isDarkMode))
                        if let coach = s.coachName, !coach.isEmpty {
                            Text(coach)
                                .textStyle(Typography.Style.subheadline, color: ColorTheme.adaptiveText(primary: false, isDarkMode: themeManager.isDarkMode))
                        }

                        Text(languageManager.localize("today.workouts"))
                            .textStyle(Typography.Style.headlineBold, color: ColorTheme.adaptiveText(primary: true, isDarkMode: themeManager.isDarkMode))
                        ForEach(Array(s.todayWorkouts.enumerated()), id: \.offset) { _, w in
                            workoutBlock(w)
                        }

                        Text(languageManager.localize("today.meals"))
                            .textStyle(Typography.Style.headlineBold, color: ColorTheme.adaptiveText(primary: true, isDarkMode: themeManager.isDarkMode))
                        ForEach(Array(s.dietPlans.enumerated()), id: \.offset) { _, d in
                            AppCard {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(d.name)
                                        .textStyle(Typography.Style.headline, color: ColorTheme.adaptiveText(primary: true, isDarkMode: themeManager.isDarkMode))
                                    if let c = d.targetCalories {
                                        Text("\(c) kcal")
                                            .textStyle(Typography.Style.caption, color: ColorTheme.adaptiveText(primary: false, isDarkMode: themeManager.isDarkMode))
                                    }
                                }
                            }
                        }

                        VStack(spacing: 8) {
                            if !s.todayWorkouts.isEmpty {
                                AppButton(title: languageManager.localize("log.start"), style: .primary, icon: "figure.strengthtraining.traditional") {
                                    Haptics.tap()
                                    onStartWorkout()
                                }
                            }
                            AppButton(title: languageManager.localize("today.complete"), style: .secondary, icon: "checkmark", isLoading: model.actionInProgress) {
                                Haptics.success()
                                Task { await model.complete() }
                            }
                            AppButton(title: languageManager.localize("today.skip"), style: .text, isLoading: model.actionInProgress) {
                                Haptics.selection()
                                Task { await model.skip() }
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(languageManager.localize("home.todaysWorkout"))
        .navigationBarTitleDisplayMode(.inline)
        .task { await model.load() }
        .refreshable { await model.load() }
    }

    private func workoutBlock(_ w: ScheduledWorkout) -> some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(w.name)
                    .textStyle(Typography.Style.headline, color: ColorTheme.adaptiveText(primary: true, isDarkMode: themeManager.isDarkMode))
                ForEach(w.exercises, id: \.id) { ex in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(ex.exerciseTemplate.name)
                                .textStyle(Typography.Style.subheadlineBold, color: ColorTheme.adaptiveText(primary: true, isDarkMode: themeManager.isDarkMode))
                            Text("\(ex.sets)×\(ex.reps) · \(ex.restSeconds)s")
                                .textStyle(Typography.Style.caption, color: ColorTheme.adaptiveText(primary: false, isDarkMode: themeManager.isDarkMode))
                        }
                        Spacer()
                        if let url = ex.exerciseTemplate.videoUrl, !url.isEmpty {
                            Button(action: { Haptics.tap(); onPlayVideo(url) }) {
                                Image(systemName: "play.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(themeManager.dynamicColorTheme.currentPrimary)
                            }
                            .accessibilityLabel(languageManager.localize("a11y.playVideo"))
                        }
                    }
                }
            }
        }
    }
}
