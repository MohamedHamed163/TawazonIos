//
//  ActiveWorkoutView.swift
//  tawazon
//
//  The active, set-by-set logging experience launched from the workout
//  overview. Lets the user enter weight/reps per set, runs a rest timer
//  between sets, swap an exercise for an alternative, and jot per-exercise
//  notes — then finish to mark the day complete.
//

import SwiftUI
import Combine

struct ActiveWorkoutView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var themeManager: ThemeManager
    @Environment(\.dismiss) private var dismiss
    @State private var model = ActiveWorkoutViewModel()

    var onPlayVideo: (String) -> Void

    @State private var restRemaining: Int?
    @State private var restTotal: Int = 0
    @State private var showSwap = false

    private let restTimer = Timer.publish(every: 1, on: .main, in: .common).autoconnect()

    private var textPrimary: Color { ColorTheme.adaptiveText(primary: true, isDarkMode: themeManager.isDarkMode) }
    private var textSecondary: Color { ColorTheme.adaptiveText(primary: false, isDarkMode: themeManager.isDarkMode) }
    private var accent: Color { themeManager.dynamicColorTheme.currentPrimary }
    private var heroFg: Color { HeroCard<EmptyView>.foreground }
    private var heroFgSecondary: Color { HeroCard<EmptyView>.foregroundSecondary }

    var body: some View {
        ZStack {
            ColorTheme.adaptiveBackground(primary: true, isDarkMode: themeManager.isDarkMode)
                .ignoresSafeArea()

            if model.finished {
                summary
            } else if model.isLoading && model.exercises.isEmpty {
                ScrollView { SkeletonList(count: 3, lines: 4).padding() }
            } else if model.exercises.isEmpty {
                EmptyStateView(
                    icon: "dumbbell",
                    title: languageManager.localize("log.title"),
                    message: languageManager.localize("log.empty")
                )
            } else {
                logging
            }

            if let remaining = restRemaining, !model.finished {
                VStack {
                    Spacer()
                    restBanner(remaining: remaining)
                        .padding(.horizontal)
                        .padding(.bottom, 96)
                }
            }
        }
        .navigationTitle(languageManager.localize("log.title"))
        .navigationBarTitleDisplayMode(.inline)
        .task { await model.load() }
        .onReceive(restTimer) { _ in tickRest() }
        .sheet(isPresented: $showSwap) { swapSheet }
    }

    // MARK: - Logging

    @ViewBuilder
    private var logging: some View {
        @Bindable var model = model
        let ci = model.currentIndex

        VStack(spacing: 0) {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    progressHeader

                    if let ex = model.current {
                        exerciseCard(ex)
                        setsSection(ci: ci, ex: ex)
                        notesSection(ci: ci)
                    }
                }
                .padding()
                .padding(.bottom, 24)
            }

            bottomBar
        }
    }

    private var progressHeader: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(String(format: languageManager.localize("log.exerciseProgress"), model.currentIndex + 1, model.exercises.count))
                .textStyle(Typography.Style.caption, color: textSecondary)
            ProgressView(value: Double(model.currentIndex + 1), total: Double(max(model.exercises.count, 1)))
                .tint(accent)
        }
    }

    private func exerciseCard(_ ex: ActiveWorkoutViewModel.Exercise) -> some View {
        HeroCard {
            VStack(alignment: .leading, spacing: 10) {
                HStack(alignment: .top) {
                    VStack(alignment: .leading, spacing: 6) {
                        Text(ex.name)
                            .textStyle(Typography.Style.title2, color: heroFg)
                        Text(String(format: languageManager.localize("log.target"), ex.targetSets, ex.targetReps))
                            .textStyle(Typography.Style.subheadlineBold, color: heroFgSecondary)
                    }
                    Spacer()
                    Button(action: { Haptics.selection(); showSwap = true }) {
                        Image(systemName: "arrow.triangle.2.circlepath")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(heroFg)
                            .padding(8)
                            .background(heroFg.opacity(0.12), in: Circle())
                    }
                    .accessibilityLabel(languageManager.localize("log.swap"))
                }

                if let muscle = ex.muscleGroup, !muscle.isEmpty {
                    Text(muscle.capitalized)
                        .textStyle(Typography.Style.caption, color: heroFg)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 4)
                        .background(heroFg.opacity(0.14), in: Capsule())
                }

                if let url = ex.videoUrl, !url.isEmpty {
                    Button(action: { Haptics.tap(); onPlayVideo(url) }) {
                        HStack(spacing: 6) {
                            Image(systemName: "play.circle.fill")
                            Text(languageManager.localize("log.watchVideo"))
                                .textStyle(Typography.Style.subheadlineBold, color: heroFg)
                        }
                        .foregroundColor(heroFg)
                    }
                    .accessibilityLabel(languageManager.localize("a11y.playVideo"))
                }
            }
        }
    }

    @ViewBuilder
    private func setsSection(ci: Int, ex: ActiveWorkoutViewModel.Exercise) -> some View {
        @Bindable var model = model
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text(languageManager.localize("log.set"))
                    .frame(width: 36, alignment: .leading)
                Text(languageManager.localize("log.weight"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                Text(languageManager.localize("log.reps"))
                    .frame(maxWidth: .infinity, alignment: .leading)
                Spacer().frame(width: 36)
            }
            .textStyle(Typography.Style.caption, color: textSecondary)

            ForEach(Array(ex.sets.enumerated()), id: \.element.id) { si, set in
                HStack(spacing: 12) {
                    Text("\(si + 1)")
                        .textStyle(Typography.Style.subheadlineBold, color: set.done ? accent : textPrimary)
                        .frame(width: 36, alignment: .leading)

                    fieldBox {
                        TextField(languageManager.localize("log.kg"), text: $model.exercises[ci].sets[si].weight)
                            .keyboardType(.decimalPad)
                            .textStyle(Typography.Style.body, color: textPrimary)
                    }

                    fieldBox {
                        TextField(languageManager.localize("log.reps"), text: $model.exercises[ci].sets[si].reps)
                            .keyboardType(.numberPad)
                            .textStyle(Typography.Style.body, color: textPrimary)
                    }

                    Button(action: { toggleDone(si, ci: ci) }) {
                        Image(systemName: set.done ? "checkmark.circle.fill" : "circle")
                            .font(.system(size: 24))
                            .foregroundColor(set.done ? accent : textSecondary)
                    }
                    .frame(width: 36)
                    .accessibilityLabel(languageManager.localize("log.setDone"))
                }
            }

            Button(action: { Haptics.tap(); model.addSet() }) {
                HStack(spacing: 6) {
                    Image(systemName: "plus")
                    Text(languageManager.localize("log.addSet"))
                }
                .textStyle(Typography.Style.subheadlineBold, color: accent)
            }
            .padding(.top, 2)
        }
    }

    @ViewBuilder
    private func notesSection(ci: Int) -> some View {
        @Bindable var model = model
        VStack(alignment: .leading, spacing: 8) {
            Text(languageManager.localize("log.notes"))
                .textStyle(Typography.Style.subheadlineBold, color: textPrimary)
            fieldBox {
                TextField(
                    languageManager.localize("log.notesHint"),
                    text: $model.exercises[ci].notes,
                    axis: .vertical
                )
                .lineLimit(2...4)
                .textStyle(Typography.Style.body, color: textPrimary)
            }
        }
    }

    private var bottomBar: some View {
        HStack(spacing: 12) {
            AppButton(
                title: languageManager.localize("log.previous"),
                style: .text,
                isDisabled: model.currentIndex == 0
            ) {
                Haptics.selection()
                restRemaining = nil
                model.goPrevious()
            }

            if model.isOnLastExercise {
                AppButton(
                    title: languageManager.localize("log.finish"),
                    style: .primary,
                    icon: "flag.checkered",
                    isLoading: model.isFinishing
                ) {
                    Haptics.success()
                    Task { await model.finish() }
                }
            } else {
                AppButton(
                    title: languageManager.localize("log.next"),
                    style: .primary,
                    icon: "arrow.right",
                    iconPosition: .trailing
                ) {
                    Haptics.tap()
                    restRemaining = nil
                    model.goNext()
                }
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 12)
        .background(ColorTheme.adaptiveBackground(primary: true, isDarkMode: themeManager.isDarkMode))
    }

    // MARK: - Rest timer

    private func restBanner(remaining: Int) -> some View {
        AppCard(padding: 14, backgroundColor: accent.opacity(0.12)) {
            HStack(spacing: 14) {
                ZStack {
                    Circle()
                        .stroke(accent.opacity(0.25), lineWidth: 4)
                    Circle()
                        .trim(from: 0, to: restTotal > 0 ? CGFloat(remaining) / CGFloat(restTotal) : 0)
                        .stroke(accent, style: StrokeStyle(lineWidth: 4, lineCap: .round))
                        .rotationEffect(.degrees(-90))
                    Text("\(remaining)")
                        .textStyle(Typography.Style.subheadlineBold, color: textPrimary)
                }
                .frame(width: 44, height: 44)

                VStack(alignment: .leading, spacing: 2) {
                    Text(languageManager.localize("log.rest"))
                        .textStyle(Typography.Style.subheadlineBold, color: textPrimary)
                }
                Spacer()
                Button(action: { restRemaining = (restRemaining ?? 0) + 15; restTotal += 15 }) {
                    Text(String(format: languageManager.localize("log.addRest"), 15))
                        .textStyle(Typography.Style.subheadlineBold, color: accent)
                }
                Button(action: { Haptics.selection(); restRemaining = nil }) {
                    Text(languageManager.localize("log.skipRest"))
                        .textStyle(Typography.Style.subheadlineBold, color: textSecondary)
                }
            }
        }
    }

    private func tickRest() {
        guard let r = restRemaining else { return }
        if r <= 1 {
            restRemaining = nil
            Haptics.success()
        } else {
            restRemaining = r - 1
        }
    }

    private func toggleDone(_ si: Int, ci: Int) {
        guard model.exercises.indices.contains(ci),
              model.exercises[ci].sets.indices.contains(si) else { return }
        let nowDone = !model.exercises[ci].sets[si].done
        model.exercises[ci].sets[si].done = nowDone
        if nowDone {
            Haptics.success()
            let rest = model.exercises[ci].restSeconds
            if rest > 0 {
                restTotal = rest
                restRemaining = rest
            }
        }
    }

    // MARK: - Swap

    private var swapSheet: some View {
        let alternatives = model.pool.filter { $0.name != model.current?.name }
        return NavigationStack {
            ZStack {
                ColorTheme.adaptiveBackground(primary: true, isDarkMode: themeManager.isDarkMode)
                    .ignoresSafeArea()
                if alternatives.isEmpty {
                    EmptyStateView(
                        icon: "arrow.triangle.2.circlepath",
                        title: languageManager.localize("log.swap"),
                        message: languageManager.localize("log.noAlternatives")
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 10) {
                            ForEach(alternatives, id: \.id) { template in
                                Button(action: {
                                    Haptics.selection()
                                    model.swap(to: template)
                                    showSwap = false
                                }) {
                                    AppCard {
                                        HStack {
                                            VStack(alignment: .leading, spacing: 4) {
                                                Text(template.name)
                                                    .textStyle(Typography.Style.headline, color: textPrimary)
                                                if let m = template.muscleGroup, !m.isEmpty {
                                                    Text(m.capitalized)
                                                        .textStyle(Typography.Style.caption, color: textSecondary)
                                                }
                                            }
                                            Spacer()
                                            Image(systemName: "arrow.left.arrow.right")
                                                .foregroundColor(accent)
                                        }
                                    }
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding()
                    }
                }
            }
            .navigationTitle(languageManager.localize("log.swapTitle"))
            .navigationBarTitleDisplayMode(.inline)
        }
        .presentationDetents([.medium, .large])
    }

    // MARK: - Summary

    private var summary: some View {
        VStack(spacing: 20) {
            Spacer()
            Image(systemName: "checkmark.seal.fill")
                .font(.system(size: 72))
                .foregroundColor(accent)
            Text(languageManager.localize("log.summaryTitle"))
                .textStyle(Typography.Style.title1, color: textPrimary)
            Text(String(format: languageManager.localize("log.summarySets"), model.totalSetsLogged))
                .textStyle(Typography.Style.headline, color: textSecondary)
            Spacer()
            AppButton(title: languageManager.localize("log.summaryDone"), style: .primary, icon: "checkmark") {
                dismiss()
            }
            .padding(.horizontal)
            .padding(.bottom, 24)
        }
        .padding()
    }

    // MARK: - Helpers

    private func fieldBox<Content: View>(@ViewBuilder _ content: () -> Content) -> some View {
        content()
            .padding(.horizontal, 12)
            .padding(.vertical, 10)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(ColorTheme.adaptiveBackground(primary: false, isDarkMode: themeManager.isDarkMode))
            .clipShape(RoundedRectangle(cornerRadius: 10))
    }
}
