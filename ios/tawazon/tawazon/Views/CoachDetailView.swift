//
//  CoachDetailView.swift
//  tawazon
//

import SwiftUI

struct CoachDetailView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var authManager: AuthManager
    @Environment(\.openURL) private var openURL
    @Environment(\.scenePhase) private var scenePhase
    @State private var model: CoachDetailViewModel
    @State private var subscribeAlert: String?

    init(coachId: String) {
        _model = State(initialValue: CoachDetailViewModel(coachId: coachId))
    }

    var body: some View {
        ZStack {
            ColorTheme.adaptiveBackground(primary: true, isDarkMode: themeManager.isDarkMode)
                .ignoresSafeArea()
            if model.isLoading && model.coach == nil {
                ProgressView()
            } else if let c = model.coach {
                ScrollView {
                    VStack(alignment: .leading, spacing: 20) {
                        Text(c.displayName.isEmpty ? "—" : c.displayName)
                            .textStyle(Typography.Style.title1, color: ColorTheme.adaptiveText(primary: true, isDarkMode: themeManager.isDarkMode))
                        if let bio = c.bio, !bio.isEmpty {
                            Text(bio)
                                .textStyle(Typography.Style.body, color: ColorTheme.adaptiveText(primary: false, isDarkMode: themeManager.isDarkMode))
                        }
                        if !c.specialties.isEmpty {
                            FlowTags(title: languageManager.localize("coaches.specialty"), tags: c.specialties)
                        }
                        if !c.certifications.isEmpty {
                            FlowTags(title: languageManager.localize("coach.certifications"), tags: c.certifications.map { $0.displayName })
                        }
                        if let r = c.rating {
                            HStack {
                                Image(systemName: "star.fill")
                                    .foregroundColor(themeManager.dynamicColorTheme.currentPrimary)
                                Text(String(format: "%.1f", r))
                                if let rc = c.ratingCount {
                                    Text("(\(rc))")
                                        .foregroundColor(.secondary)
                                }
                            }
                        }

                        Text(languageManager.localize("coach.plans"))
                            .textStyle(Typography.Style.title3, color: ColorTheme.adaptiveText(primary: true, isDarkMode: themeManager.isDarkMode))
                        if model.plansLoading {
                            ProgressView()
                        } else {
                            ForEach(model.plans, id: \.id) { plan in
                                AppCard {
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text(plan.name)
                                            .textStyle(Typography.Style.headlineBold, color: ColorTheme.adaptiveText(primary: true, isDarkMode: themeManager.isDarkMode))
                                        if let d = plan.description {
                                            Text(d)
                                                .textStyle(Typography.Style.caption, color: ColorTheme.adaptiveText(primary: false, isDarkMode: themeManager.isDarkMode))
                                        }
                                        Text(String(format: languageManager.localize("coach.planPrice"), plan.durationMonths, plan.priceEgp))
                                            .textStyle(Typography.Style.subheadlineBold, color: themeManager.dynamicColorTheme.currentPrimary)
                                        if authManager.isAuthenticated, !model.isSubscribedToThisCoach {
                                            AppButton(
                                                title: languageManager.localize("coach.subscribe"),
                                                style: .primary,
                                                isLoading: model.checkoutLoadingPlanId == plan.id
                                            ) {
                                                Task { await subscribe(plan) }
                                            }
                                        }
                                    }
                                    .frame(maxWidth: .infinity, alignment: .leading)
                                }
                                .frame(maxWidth: .infinity, alignment: .leading)
                            }
                        }

                    }
                    .frame(maxWidth: .infinity, alignment: .leading)
                    .padding()
                }
            } else if let err = model.errorMessage {
                Text(err).padding()
            }
        }
        .navigationTitle(languageManager.localize("coaches.title"))
        .navigationBarTitleDisplayMode(.inline)
        .task {
            let tok = KeychainService.shared.getAccessToken()
            await model.load(token: tok)
        }
        .onChange(of: scenePhase) { _, phase in
            guard phase == .active, authManager.isAuthenticated,
                  let token = KeychainService.shared.getAccessToken() else { return }
            Task { await model.refreshSubscriptionState(token: token) }
        }
        .alert("Subscribe", isPresented: Binding(
            get: { subscribeAlert != nil },
            set: { if !$0 { subscribeAlert = nil } }
        )) {
            Button("OK", role: .cancel) {}
        } message: {
            Text(subscribeAlert ?? "")
        }
    }

    private func subscribe(_ plan: CoachPlan) async {
        print("🟢 Subscribe tapped — planId=\(plan.id) coachId=\(model.coach?.id ?? "?")")

        guard let token = KeychainService.shared.getAccessToken() else {
            print("❌ Subscribe aborted: no access token in keychain")
            subscribeAlert = "You're signed out. Please log in again."
            return
        }

        do {
            let url = try await model.checkoutURL(for: plan.id, token: token)
            print("✅ Checkout URL received: \(url.absoluteString)")
            let opened = await openURLSafely(url)
            if !opened {
                subscribeAlert = "Couldn't open the checkout page. URL: \(url.absoluteString)"
            }
        } catch {
            print("❌ Checkout failed: \(error)")
            subscribeAlert = "Subscribe failed: \(error.localizedDescription)"
        }
    }

    @MainActor
    private func openURLSafely(_ url: URL) async -> Bool {
        await withCheckedContinuation { cont in
            openURL(url) { accepted in
                cont.resume(returning: accepted)
            }
        }
    }
}

private struct FlowTags: View {
    let title: String
    let tags: [String]
    @EnvironmentObject var themeManager: ThemeManager
    @EnvironmentObject var languageManager: LanguageManager

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .fontWeight(.semibold)
                .foregroundColor(ColorTheme.adaptiveText(primary: true, isDarkMode: themeManager.isDarkMode))
            LazyVGrid(columns: [GridItem(.adaptive(minimum: 100))], spacing: 8) {
                ForEach(tags, id: \.self) { t in
                    Text(t)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 6)
                        .background(themeManager.dynamicColorTheme.currentPrimary.opacity(0.15))
                        .foregroundColor(themeManager.dynamicColorTheme.currentPrimary)
                        .clipShape(Capsule())
                }
            }
        }
    }
}
