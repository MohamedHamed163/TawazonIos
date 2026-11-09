//
//  ProgramsView.swift
//  tawazon
//

import SwiftUI

struct ProgramsView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var themeManager: ThemeManager
    @State private var model = ProgramsViewModel()
    var onSelect: (String) -> Void

    private var textPrimary: Color { ColorTheme.adaptiveText(primary: true, isDarkMode: themeManager.isDarkMode) }
    private var textSecondary: Color { ColorTheme.adaptiveText(primary: false, isDarkMode: themeManager.isDarkMode) }

    var body: some View {
        ZStack {
            ColorTheme.adaptiveBackground(primary: true, isDarkMode: themeManager.isDarkMode)
                .ignoresSafeArea()

            if model.isLoading && model.programs.isEmpty {
                ProgressView()
            } else if let err = model.errorMessage, model.programs.isEmpty {
                Text(err).foregroundColor(.secondary).padding()
            } else if model.programs.isEmpty {
                EmptyStateView(
                    icon: "square.stack.3d.up",
                    title: languageManager.localize("programs.emptyTitle"),
                    message: languageManager.localize("programs.emptyBody")
                )
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(model.programs, id: \.id) { program in
                            Button { onSelect(program.id) } label: {
                                programCard(program)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(languageManager.localize("programs.title"))
        .navigationBarTitleDisplayMode(.large)
        .task { await model.load() }
        .refreshable { await model.load() }
    }

    private func programCard(_ p: ProgramResponse) -> some View {
        AppCard {
            VStack(alignment: .leading, spacing: 8) {
                HStack {
                    Text(p.name)
                        .textStyle(Typography.Style.headlineBold, color: textPrimary)
                    Spacer()
                    Image(systemName: "chevron.right")
                        .foregroundColor(textSecondary)
                }
                if let desc = p.description, !desc.isEmpty {
                    Text(desc)
                        .textStyle(Typography.Style.caption, color: textSecondary)
                        .lineLimit(2)
                }
                HStack(spacing: 12) {
                    Label("\(p.durationWeeks) \(languageManager.localize("programs.weeks"))", systemImage: "calendar")
                    Label(p.difficulty.capitalized, systemImage: "flame.fill")
                    Label("\(p.workouts.count) \(languageManager.localize("programs.workouts"))", systemImage: "dumbbell.fill")
                }
                .textStyle(Typography.Style.caption2, color: textSecondary)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}

struct ProgramDetailView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var themeManager: ThemeManager
    @State private var model = ProgramDetailViewModel()
    let programId: String
    var onPlayVideo: (String) -> Void

    private var textPrimary: Color { ColorTheme.adaptiveText(primary: true, isDarkMode: themeManager.isDarkMode) }
    private var textSecondary: Color { ColorTheme.adaptiveText(primary: false, isDarkMode: themeManager.isDarkMode) }

    var body: some View {
        ZStack {
            ColorTheme.adaptiveBackground(primary: true, isDarkMode: themeManager.isDarkMode)
                .ignoresSafeArea()

            if model.isLoading && model.program == nil {
                ProgressView()
            } else if let err = model.errorMessage, model.program == nil {
                Text(err).foregroundColor(.secondary).padding()
            } else if let p = model.program {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(p.name)
                                .textStyle(Typography.Style.title2, color: textPrimary)
                            if let desc = p.description, !desc.isEmpty {
                                Text(desc)
                                    .textStyle(Typography.Style.subheadline, color: textSecondary)
                            }
                            HStack(spacing: 12) {
                                Label("\(p.durationWeeks) \(languageManager.localize("programs.weeks"))", systemImage: "calendar")
                                Label(p.difficulty.capitalized, systemImage: "flame.fill")
                            }
                            .textStyle(Typography.Style.caption, color: textSecondary)
                        }

                        if !model.sortedWorkouts.isEmpty {
                            Text(languageManager.localize("programs.workoutsTitle"))
                                .textStyle(Typography.Style.headlineBold, color: textPrimary)
                            ForEach(model.sortedWorkouts, id: \.id) { workout in
                                workoutCard(workout)
                            }
                        }

                        if let diet = p.dietPlan {
                            Text(languageManager.localize("programs.dietTitle"))
                                .textStyle(Typography.Style.headlineBold, color: textPrimary)
                            AppCard {
                                VStack(alignment: .leading, spacing: 6) {
                                    Text(diet.name)
                                        .textStyle(Typography.Style.headline, color: textPrimary)
                                    if let c = diet.targetCalories {
                                        Text("\(c) kcal")
                                            .textStyle(Typography.Style.caption, color: textSecondary)
                                    }
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(languageManager.localize("programs.detailTitle"))
        .navigationBarTitleDisplayMode(.inline)
        .task { await model.load(id: programId) }
    }

    private func workoutCard(_ w: WorkoutResponse) -> some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(w.name)
                    .textStyle(Typography.Style.headline, color: textPrimary)
                if let desc = w.description, !desc.isEmpty {
                    Text(desc)
                        .textStyle(Typography.Style.caption, color: textSecondary)
                }
                ForEach(w.exercises ?? [], id: \.id) { ex in
                    HStack {
                        VStack(alignment: .leading, spacing: 4) {
                            Text(ex.exerciseTemplate.name)
                                .textStyle(Typography.Style.subheadlineBold, color: textPrimary)
                            Text("\(ex.sets)×\(ex.reps) · \(ex.restSeconds)s")
                                .textStyle(Typography.Style.caption, color: textSecondary)
                        }
                        Spacer()
                        if let url = ex.exerciseTemplate.videoUrl, !url.isEmpty {
                            Button(action: { onPlayVideo(url) }) {
                                Image(systemName: "play.circle.fill")
                                    .font(.title2)
                                    .foregroundColor(themeManager.dynamicColorTheme.currentPrimary)
                            }
                        }
                    }
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }
}
