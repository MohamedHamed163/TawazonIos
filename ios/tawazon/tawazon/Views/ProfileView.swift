//
//  ProfileView.swift
//  tawazon
//

import SwiftUI

struct ProfileView: View {
    @Environment(\.horizontalSizeClass) var horizontalSizeClass
    @EnvironmentObject var authManager: AuthManager
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var themeManager: ThemeManager
    @State private var showSettings = false
    @State private var showAllSubscriptions = false
    @State private var model = ProfileViewModel()
    var onHealthRecord: () -> Void

    var isIPad: Bool { horizontalSizeClass == .regular }

    var body: some View {
        Group {
            if !authManager.isAuthenticated {
                guestBlock
            } else {
                ZStack {
                    ColorTheme.adaptiveBackground(primary: true, isDarkMode: themeManager.isDarkMode)
                        .ignoresSafeArea()
                    ScrollView {
                        VStack(spacing: 20) {
                            headerCard
                            healthRecordCard
                            subscriptionsSection
                            themeSection
                            settingsRows
                            logoutButton
                        }
                        .padding(.horizontal, isIPad ? 40 : 20)
                        .padding(.vertical, 20)
                    }
                }
            }
        }
        .navigationTitle(languageManager.localize("profile.title"))
        .navigationBarTitleDisplayMode(.large)
        .sheet(isPresented: $showSettings) {
            SettingsView()
                .environmentObject(languageManager)
                .environmentObject(themeManager)
        }
        .task {
            if let t = KeychainService.shared.getAccessToken() {
                await model.load(token: t)
            }
        }
        .refreshable {
            if let t = KeychainService.shared.getAccessToken() {
                await model.load(token: t)
            }
        }
    }

    private var guestBlock: some View {
        VStack(spacing: 16) {
            Text(languageManager.localize("guest.profileTitle"))
                .font(.headline)
            Text(languageManager.localize("guest.profileBody"))
                .multilineTextAlignment(.center)
                .foregroundColor(.secondary)
        }
        .padding()
        .frame(maxWidth: .infinity, maxHeight: .infinity)
        .background(ColorTheme.adaptiveBackground(primary: true, isDarkMode: themeManager.isDarkMode))
    }

    private var headerCard: some View {
        AppCard {
            VStack(spacing: 12) {
                Image(systemName: "person.fill")
                    .font(.system(size: 48))
                    .foregroundColor(themeManager.dynamicColorTheme.currentPrimary)
                Text(authManager.currentUser?.fullName ?? "—")
                    .textStyle(Typography.Style.title2, color: ColorTheme.adaptiveText(primary: true, isDarkMode: themeManager.isDarkMode))
                Text(authManager.currentUser?.email ?? "")
                    .textStyle(Typography.Style.caption, color: ColorTheme.adaptiveText(primary: false, isDarkMode: themeManager.isDarkMode))
            }
            .frame(maxWidth: .infinity)
        }
    }

    private var healthRecordCard: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 10) {
                Text(languageManager.localize("profile.healthRecord"))
                    .textStyle(Typography.Style.headlineBold, color: ColorTheme.adaptiveText(primary: true, isDarkMode: themeManager.isDarkMode))
                Text(
                    model.latestHealth != nil
                        ? languageManager.localize("profile.healthRecordUpdate")
                        : languageManager.localize("profile.healthRecordAdd")
                )
                .textStyle(Typography.Style.caption, color: ColorTheme.adaptiveText(primary: false, isDarkMode: themeManager.isDarkMode))
                AppButton(title: languageManager.localize("profile.healthRecordCta"), style: .primary, icon: "heart.text.square") {
                    onHealthRecord()
                }
            }
        }
    }

    private var subscriptionsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(languageManager.localize("profile.subscriptions"))
                .textStyle(Typography.Style.title3, color: ColorTheme.adaptiveText(primary: true, isDarkMode: themeManager.isDarkMode))
            if model.subscriptions.isEmpty {
                Text(languageManager.localize("profile.noSubscriptions"))
                    .font(.caption)
                    .foregroundColor(.secondary)
            } else if model.subscriptions.count <= 2 || showAllSubscriptions {
                ForEach(model.subscriptions, id: \.id) { sub in
                    subscriptionCard(sub, fadedPeek: false)
                }
                if model.subscriptions.count > 2 && showAllSubscriptions {
                    subscriptionsExpandCollapseButton(showLess: true)
                }
            } else {
                ForEach(Array(model.subscriptions.prefix(2)), id: \.id) { sub in
                    subscriptionCard(sub, fadedPeek: false)
                }
                if let third = model.subscriptions.dropFirst(2).first {
                    subscriptionCard(third, fadedPeek: true)
                }
                subscriptionsExpandCollapseButton(showLess: false)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    @ViewBuilder
    private func subscriptionCard(_ sub: SubscriptionDetailDTO, fadedPeek: Bool) -> some View {
        let pageBg = ColorTheme.adaptiveBackground(primary: true, isDarkMode: themeManager.isDarkMode)
        ZStack {
            AppCard {
                VStack(alignment: .leading, spacing: 6) {
                    Text(sub.plan?.name ?? languageManager.localize("profile.plan"))
                        .font(.headline)
                        .foregroundColor(ColorTheme.adaptiveText(primary: true, isDarkMode: themeManager.isDarkMode))
                    Text(sub.coachProfile?.displayName ?? "")
                        .font(.caption)
                        .foregroundColor(.secondary)
                    Text(sub.status)
                        .font(.caption2)
                        .foregroundColor(themeManager.dynamicColorTheme.currentPrimary)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            if fadedPeek {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(
                        LinearGradient(
                            colors: [
                                .clear,
                                pageBg.opacity(0.55),
                                pageBg.opacity(0.98)
                            ],
                            startPoint: UnitPoint(x: 0.5, y: 0.35),
                            endPoint: .bottom
                        )
                    )
                    .allowsHitTesting(false)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .compositingGroup()
        .opacity(fadedPeek ? 0.48 : 1)
    }

    private func subscriptionsExpandCollapseButton(showLess: Bool) -> some View {
        HStack(spacing: 6) {
            Button {
                withAnimation(.easeInOut(duration: 0.25)) {
                    showAllSubscriptions.toggle()
                }
            } label: {
                HStack(spacing: 6) {
                    Text(languageManager.localize(showLess ? "common.showLess" : "common.showAll"))
                        .textStyle(Typography.Style.subheadlineBold, color: themeManager.dynamicColorTheme.currentPrimary)
                    Image(systemName: showLess ? "chevron.up" : "chevron.down")
                        .font(.caption.weight(.bold))
                        .foregroundColor(themeManager.dynamicColorTheme.currentPrimary)
                }
            }
            .buttonStyle(.plain)
            Spacer(minLength: 0)
        }
        .padding(.top, 4)
    }

    private var themeSection: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                Text(languageManager.localize("profile.appearance"))
                    .textStyle(Typography.Style.headlineBold, color: ColorTheme.adaptiveText(primary: true, isDarkMode: themeManager.isDarkMode))
                HStack(spacing: 8) {
                    themeChip(title: languageManager.localize("theme.dark"), dark: true)
                    themeChip(title: languageManager.localize("theme.light"), dark: false)
                    Spacer(minLength: 0)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .frame(maxWidth: .infinity, alignment: .leading)
    }

    private func themeChip(title: String, dark: Bool) -> some View {
        Button(action: {
            themeManager.isDarkMode = dark
        }) {
            Text(title)
                .font(.caption)
                .fontWeight(.semibold)
                .padding(.horizontal, 14)
                .padding(.vertical, 8)
                .background(themeManager.isDarkMode == dark ? themeManager.dynamicColorTheme.currentPrimary : Color.gray.opacity(0.2))
                .foregroundColor(themeManager.isDarkMode == dark ? .black : .primary)
                .clipShape(Capsule())
        }
    }

    private var settingsRows: some View {
        VStack(spacing: 12) {
            MenuRow(icon: "gearshape.fill", title: languageManager.localize("settings.title"), color: .gray) {
                showSettings = true
            }
        }
    }

    private var logoutButton: some View {
        AppButton(title: languageManager.localize("profile.signOut"), style: .outline, icon: "rectangle.portrait.and.arrow.right") {
            authManager.logout()
        }
    }
}

private struct MenuRow: View {
    let icon: String
    let title: String
    let color: Color
    let action: () -> Void
    @EnvironmentObject var themeManager: ThemeManager

    var body: some View {
        Button(action: action) {
            HStack {
                Image(systemName: icon).foregroundColor(color)
                Text(title)
                    .foregroundColor(ColorTheme.adaptiveText(primary: true, isDarkMode: themeManager.isDarkMode))
                Spacer()
                Image(systemName: "chevron.right").foregroundColor(.gray)
            }
            .padding()
            .background(ColorTheme.adaptiveBackground(primary: false, isDarkMode: themeManager.isDarkMode))
            .cornerRadius(12)
        }
    }
}

#Preview {
    NavigationStack {
        ProfileView(onHealthRecord: {})
    }
    .environmentObject(AuthManager())
    .environmentObject(LanguageManager())
    .environmentObject(ThemeManager())
}
