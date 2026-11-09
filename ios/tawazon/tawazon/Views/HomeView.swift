//
//  HomeView.swift
//  tawazon
//

import SwiftUI

struct HomeView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var authManager: AuthManager
    @StateObject private var healthKitService = HealthKitService.shared
    @State private var healthSummary: HealthSummary?
    @State private var homeModel = HomeViewModel()

    var onNotifications: () -> Void
    var onTodayWorkout: () -> Void
    var onCoach: (String) -> Void
    var onHealthRecord: () -> Void
    var onBrowseCoachesTab: () -> Void
    var onMeals: () -> Void
    var onPrograms: () -> Void
    var onCoachContent: () -> Void
    var onProgress: () -> Void
    var onMessageCoach: (_ coachProfileId: String?, _ coachName: String) -> Void

    var isIPad: Bool { horizontalSizeClass == .regular }

    private var heroFg: Color { HeroCard<EmptyView>.foreground }
    private var heroFgSecondary: Color { HeroCard<EmptyView>.foregroundSecondary }

    var body: some View {
        ZStack {
            ColorTheme.adaptiveBackground(primary: true, isDarkMode: themeManager.isDarkMode)
                .ignoresSafeArea()

            ScrollView {
                VStack(spacing: 24) {
                    headerSection
                    if authManager.isAuthenticated && homeModel.isLoading && homeModel.dashboard == nil {
                        SkeletonList(count: 4, lines: 3)
                    } else {
                        if authManager.isAuthenticated {
                            quickStatsSection
                            subscriptionCard
                            quickLinksSection
                            healthBanner
                            todayWorkoutCard
                            progressCard
                        } else {
                            guestCallout
                        }
                        featuredCoachesSection
                    }
                }
                .padding(.horizontal, isIPad ? 40 : 20)
                .padding(.vertical, 20)
            }
        }
        .navigationTitle(languageManager.localize("nav.home"))
        .navigationBarTitleDisplayMode(.large)
        .toolbar {
            ToolbarItem(placement: .navigationBarLeading) {
                Button(action: { Haptics.selection(); languageManager.toggleLanguage() }) {
                    Image(systemName: "globe")
                        .foregroundColor(themeManager.dynamicColorTheme.currentPrimary)
                }
                .accessibilityLabel(languageManager.localize("a11y.toggleLanguage"))
            }
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: { Haptics.tap(); onNotifications() }) {
                    ZStack(alignment: .topTrailing) {
                        Image(systemName: "bell.fill")
                            .foregroundColor(themeManager.dynamicColorTheme.currentPrimary)
                        let c = homeModel.dashboard?.unreadNotifications ?? 0
                        if c > 0 {
                            Text("\(min(c, 99))")
                                .font(.caption2)
                                .foregroundColor(.white)
                                .padding(4)
                                .background(Color.red)
                                .clipShape(Circle())
                                .offset(x: 8, y: -8)
                        }
                    }
                }
                .accessibilityLabel(languageManager.localize("a11y.notifications"))
                .disabled(!authManager.isAuthenticated)
                .opacity(authManager.isAuthenticated ? 1 : 0.4)
            }
        }
        .task {
            await homeModel.load(isAuthenticated: authManager.isAuthenticated)
        }
        .refreshable {
            await homeModel.load(isAuthenticated: authManager.isAuthenticated)
        }
        .onChange(of: authManager.isAuthenticated) { _, _ in
            Task { await homeModel.load(isAuthenticated: authManager.isAuthenticated) }
        }
        .onAppear {
            loadHealthData()
        }
    }

    private var headerSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(languageManager.localize("home.welcome"))
                .textStyle(Typography.Style.title2, color: ColorTheme.adaptiveText(primary: false, isDarkMode: themeManager.isDarkMode))
            if let name = homeModel.dashboard?.user.fullName ?? authManager.currentUser?.fullName {
                Text(name)
                    .textStyle(Typography.Style.title1, color: ColorTheme.adaptiveText(primary: true, isDarkMode: themeManager.isDarkMode))
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var guestCallout: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(languageManager.localize("guest.signInTitle"))
                    .textStyle(Typography.Style.headlineBold, color: ColorTheme.adaptiveText(primary: true, isDarkMode: themeManager.isDarkMode))
                Text(languageManager.localize("guest.signInBody"))
                    .textStyle(Typography.Style.subheadline, color: ColorTheme.adaptiveText(primary: false, isDarkMode: themeManager.isDarkMode))
                AppButton(title: languageManager.localize("nav.coaches"), style: .primary, icon: "person.2.fill") {
                    onBrowseCoachesTab()
                }
            }
        }
    }

    private var subscriptionCard: some View {
        Group {
            if let sub = homeModel.dashboard?.activeSubscription {
                AppCard {
                    VStack(alignment: .leading, spacing: 8) {
                        Text(languageManager.localize("home.activePlan"))
                            .textStyle(Typography.Style.captionBold, color: themeManager.dynamicColorTheme.currentPrimary)
                        Text(sub.planName)
                            .textStyle(Typography.Style.headlineBold, color: ColorTheme.adaptiveText(primary: true, isDarkMode: themeManager.isDarkMode))
                        Text(sub.coachName)
                            .textStyle(Typography.Style.subheadline, color: ColorTheme.adaptiveText(primary: false, isDarkMode: themeManager.isDarkMode))
                        Text(
                            String(
                                format: languageManager.localize("home.daysRemaining"),
                                sub.daysRemaining
                            )
                        )
                        .textStyle(Typography.Style.caption, color: ColorTheme.adaptiveText(primary: false, isDarkMode: themeManager.isDarkMode))

                        HStack(spacing: 12) {
                            AppButton(title: languageManager.localize("home.viewMeals"), style: .primary, icon: "fork.knife") {
                                onMeals()
                            }
                            AppButton(title: languageManager.localize("home.messageCoach"), style: .outline, icon: "message.fill") {
                                onMessageCoach(sub.coachProfile?.id, sub.coachName)
                            }
                        }
                        .padding(.top, 4)
                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private var quickLinksSection: some View {
        HStack(spacing: 12) {
            quickLink(icon: "list.bullet.rectangle.portrait", title: languageManager.localize("home.programs"), action: onPrograms)
            quickLink(icon: "play.rectangle.on.rectangle", title: languageManager.localize("home.content"), action: onCoachContent)
            quickLink(icon: "chart.line.uptrend.xyaxis", title: languageManager.localize("home.progress"), action: onProgress)
        }
    }

    private func quickLink(icon: String, title: String, action: @escaping () -> Void) -> some View {
        Button(action: { Haptics.tap(); action() }) {
            AppCard {
                VStack(spacing: 8) {
                    Image(systemName: icon)
                        .font(.system(size: 24))
                        .foregroundColor(themeManager.dynamicColorTheme.currentPrimary)
                    Text(title)
                        .textStyle(Typography.Style.caption, color: ColorTheme.adaptiveText(primary: true, isDarkMode: themeManager.isDarkMode))
                        .multilineTextAlignment(.center)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .buttonStyle(.plain)
    }

    private var healthBanner: some View {
        Group {
            if homeModel.dashboard?.pendingHealthUpdate == true {
                AppCard {
                    HStack {
                        VStack(alignment: .leading, spacing: 6) {
                            Text(languageManager.localize("home.healthUpdateTitle"))
                                .textStyle(Typography.Style.headlineBold, color: ColorTheme.adaptiveText(primary: true, isDarkMode: themeManager.isDarkMode))
                            Text(languageManager.localize("home.healthUpdateBody"))
                                .textStyle(Typography.Style.caption, color: ColorTheme.adaptiveText(primary: false, isDarkMode: themeManager.isDarkMode))
                        }
                        Spacer()
                        Button(languageManager.localize("common.next")) {
                            onHealthRecord()
                        }
                        .foregroundColor(themeManager.dynamicColorTheme.currentPrimary)
                    }
                }
            }
        }
    }

    @ViewBuilder
    private var todayWorkoutCard: some View {
        if let w = homeModel.dashboard?.todayWorkout {
            HeroCard {
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text(languageManager.localize("home.todaysWorkout").uppercased())
                            .textStyle(Typography.Style.captionBold, color: heroFgSecondary)
                        Spacer()
                        Image(systemName: "dumbbell.fill")
                            .font(.system(size: 18, weight: .semibold))
                            .foregroundColor(heroFgSecondary)
                    }
                    Text(w.name)
                        .textStyle(Typography.Style.title2, color: heroFg)
                    Text(
                        String(
                            format: languageManager.localize("home.exerciseCountFormat"),
                            w.exerciseCount
                        )
                    )
                    .textStyle(Typography.Style.subheadline, color: heroFgSecondary)
                    Button {
                        Haptics.tap()
                        onTodayWorkout()
                    } label: {
                        HStack(spacing: 8) {
                            Image(systemName: "play.fill")
                            Text(languageManager.localize("home.startWorkout"))
                                .textStyle(Typography.Style.subheadlineBold, color: themeManager.dynamicColorTheme.currentPrimary)
                        }
                        .foregroundColor(themeManager.dynamicColorTheme.currentPrimary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 14)
                        .background(heroFg)
                        .clipShape(RoundedRectangle(cornerRadius: 14, style: .continuous))
                    }
                    .buttonStyle(.plain)
                    .padding(.top, 4)
                }
            }
        } else {
            AppCard {
                VStack(alignment: .leading, spacing: 12) {
                    Text(languageManager.localize("home.todaysWorkout"))
                        .textStyle(Typography.Style.title3, color: ColorTheme.adaptiveText(primary: true, isDarkMode: themeManager.isDarkMode))
                    Text(languageManager.localize("home.noWorkoutToday"))
                        .textStyle(Typography.Style.subheadline, color: ColorTheme.adaptiveText(primary: false, isDarkMode: themeManager.isDarkMode))
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
        }
    }

    private var progressCard: some View {
        Group {
            if let p = homeModel.progressSummary {
                AppCard {
                    VStack(alignment: .leading, spacing: 12) {
                        Text(languageManager.localize("home.recentProgress"))
                            .textStyle(Typography.Style.title3, color: ColorTheme.adaptiveText(primary: true, isDarkMode: themeManager.isDarkMode))
                        if let cw = p.currentWeight {
                            ProgressRow(
                                metric: languageManager.localize("progress.weight"),
                                value: String(format: "%.1f kg", cw),
                                change: formattedChange(p.weightChange),
                                isPositive: (p.weightChange ?? 0) <= 0,
                                themeManager: themeManager
                            )
                        }
                        if let bf = p.latestBodyFat {
                            HStack {
                                Text(languageManager.localize("progress.bodyFat"))
                                    .foregroundColor(ColorTheme.adaptiveText(primary: false, isDarkMode: themeManager.isDarkMode))
                                Spacer()
                                Text(String(format: "%.1f%%", bf))
                                    .foregroundColor(ColorTheme.adaptiveText(primary: true, isDarkMode: themeManager.isDarkMode))
                            }
                        }
                        HStack {
                            Text(languageManager.localize("home.streakDays"))
                                .foregroundColor(ColorTheme.adaptiveText(primary: false, isDarkMode: themeManager.isDarkMode))
                            Spacer()
                            Text("\(p.streakDays ?? 0)")
                                .foregroundColor(themeManager.dynamicColorTheme.currentPrimary)
                                .fontWeight(.bold)
                        }
                    }
                }
            }
        }
    }

    private func formattedChange(_ delta: Double?) -> String {
        guard let d = delta else { return "—" }
        let sign = d > 0 ? "+" : ""
        return "\(sign)\(String(format: "%.1f", d)) kg"
    }

    @ViewBuilder
    private var featuredCoachesSection: some View {
        if !homeModel.featuredCoaches.isEmpty {
            VStack(alignment: .leading, spacing: 16) {
                HStack {
                    Text(languageManager.localize("home.featuredCoaches"))
                        .textStyle(Typography.Style.title3, color: ColorTheme.adaptiveText(primary: true, isDarkMode: themeManager.isDarkMode))
                    Spacer()
                    Button(languageManager.localize("home.seeAll")) {
                        onBrowseCoachesTab()
                    }
                    .foregroundColor(themeManager.dynamicColorTheme.currentPrimary)
                }
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 16) {
                        ForEach(homeModel.featuredCoaches, id: \.id) { coach in
                            CoachCard(
                                name: coach.displayName.isEmpty ? "—" : coach.displayName,
                                specialty: coach.specialties.first ?? languageManager.localize("coaches.specialty"),
                                rating: coach.rating ?? 0,
                                avatarURL: coach.avatarUrl
                            ) {
                                onCoach(coach.id)
                            }
                        }
                    }
                    .padding(.horizontal, isIPad ? 0 : -20)
                }
            }
        }
    }

    private var quickStatsSection: some View {
        HStack(spacing: 16) {
            StatCard(
                icon: "flame.fill",
                value: healthSummary != nil ? "\(healthSummary!.calories)" : "0",
                label: languageManager.localize("stats.calories"),
                color: .orange
            )
            StatCard(
                icon: "figure.run",
                value: healthSummary != nil ? "\(healthSummary!.steps)" : "0",
                label: languageManager.localize("stats.steps"),
                color: themeManager.dynamicColorTheme.currentPrimary
            )
            StatCard(
                icon: "target",
                value: healthSummary?.averageHeartRate != nil ? "\(healthSummary!.averageHeartRate!)" : "--",
                label: languageManager.localize("stats.heartRate"),
                color: .red
            )
        }
    }

    private func loadHealthData() {
        guard healthKitService.isAuthorized else { return }
        Task {
            do {
                let summary = try await healthKitService.getTodaySummary()
                await MainActor.run { healthSummary = summary }
                syncWearableStats(summary)
            } catch { }
        }
    }

    /// Best-effort push of the just-read HealthKit stats to the backend so they persist
    /// and coaches can see them. Fire-and-forget: never blocks the UI or surfaces errors.
    private func syncWearableStats(_ summary: HealthSummary) {
        guard let token = KeychainService.shared.getAccessToken() else { return }
        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.dateFormat = "yyyy-MM-dd"
        let today = formatter.string(from: Date())
        let request = WearableStatsRequest(
            date: today,
            avgHeartRate: summary.averageHeartRate,
            steps: summary.steps,
            activeCalories: summary.calories
        )
        Task {
            try? await APIService.shared.syncWearableStats(request, token: token)
        }
    }
}

struct ProgressRow: View {
    let metric: String
    let value: String
    let change: String
    let isPositive: Bool
    let themeManager: ThemeManager

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(metric)
                    .font(.subheadline)
                    .foregroundColor(ColorTheme.adaptiveText(primary: false, isDarkMode: themeManager.isDarkMode))
                Text(value)
                    .font(.headline)
                    .foregroundColor(ColorTheme.adaptiveText(primary: true, isDarkMode: themeManager.isDarkMode))
            }
            Spacer()
            HStack(spacing: 4) {
                Image(systemName: isPositive ? "arrow.down.right" : "arrow.up.right")
                    .font(.caption)
                Text(change)
                    .font(.subheadline)
                    .fontWeight(.semibold)
            }
            .foregroundColor(themeManager.dynamicColorTheme.currentPrimary)
        }
    }
}

#Preview {
    NavigationStack {
        HomeView(
            onNotifications: {},
            onTodayWorkout: {},
            onCoach: { _ in },
            onHealthRecord: {},
            onBrowseCoachesTab: {},
            onMeals: {},
            onPrograms: {},
            onCoachContent: {},
            onProgress: {},
            onMessageCoach: { _, _ in }
        )
    }
    .environmentObject(LanguageManager())
    .environmentObject(ThemeManager())
    .environmentObject(AuthManager())
}
