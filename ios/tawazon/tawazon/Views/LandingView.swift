//
//  LandingView.swift
//  tawazon
//

import SwiftUI

struct LandingView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var themeManager: ThemeManager

    var onLogin: () -> Void
    var onRegister: () -> Void
    var onBrowseCoaches: () -> Void

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 28) {
                HStack {
                    Spacer()
                    HStack(spacing: 12) {
                        Button(action: { languageManager.toggleLanguage() }) {
                            Image(systemName: "globe")
                                .foregroundColor(themeManager.dynamicColorTheme.currentPrimary)
                        }
                        Button(action: onLogin) {
                            Text(languageManager.localize("auth.login"))
                                .textStyle(Typography.Style.subheadlineBold, color: themeManager.dynamicColorTheme.currentPrimary)
                        }
                        Button(action: onRegister) {
                            Text(languageManager.localize("landing.getStarted"))
                                .textStyle(Typography.Style.subheadlineBold, color: ColorTheme.Background.primary)
                                .padding(.horizontal, 14)
                                .padding(.vertical, 8)
                                .background(themeManager.dynamicColorTheme.currentPrimary)
                                .clipShape(Capsule())
                        }
                    }
                }
                .padding(.horizontal, 20)
                .padding(.top, 8)

                VStack(alignment: .leading, spacing: 12) {
                    Text(languageManager.localize("app.name"))
                        .textStyle(Typography.Style.largeTitle, color: ColorTheme.adaptiveText(primary: true, isDarkMode: themeManager.isDarkMode))
                    Text(languageManager.localize("app.tagline"))
                        .textStyle(Typography.Style.body, color: ColorTheme.adaptiveText(primary: false, isDarkMode: themeManager.isDarkMode))
                }
                .padding(.horizontal, 20)

                VStack(spacing: 12) {
                    AppButton(
                        title: languageManager.localize("landing.startTraining"),
                        style: .primary,
                        icon: "figure.strengthtraining.traditional",
                        iconPosition: .trailing
                    ) {
                        onRegister()
                    }
                    AppButton(
                        title: languageManager.localize("home.browseCoaches"),
                        style: .outline,
                        icon: "person.2.fill",
                        iconPosition: .leading
                    ) {
                        onBrowseCoaches()
                    }
                }
                .padding(.horizontal, 20)

                Text(languageManager.localize("landing.featuresTitle"))
                    .textStyle(Typography.Style.title3, color: ColorTheme.adaptiveText(primary: true, isDarkMode: themeManager.isDarkMode))
                    .padding(.horizontal, 20)
                    .padding(.top, 24)

                VStack(spacing: 14) {
                    landingFeatureCard(
                        icon: "person.3.fill",
                        titleKey: "landing.feature.coaches",
                        subtitleKey: "landing.feature.coaches.sub"
                    )
                    landingFeatureCard(
                        icon: "play.circle.fill",
                        titleKey: "landing.feature.training",
                        subtitleKey: "landing.feature.training.sub"
                    )
                    landingFeatureCard(
                        icon: "fork.knife",
                        titleKey: "landing.feature.meals",
                        subtitleKey: "landing.feature.meals.sub"
                    )
                    landingFeatureCard(
                        icon: "chart.bar.fill",
                        titleKey: "landing.feature.progress",
                        subtitleKey: "landing.feature.progress.sub"
                    )
                }
                .padding(.horizontal, 20)
                .padding(.bottom, 40)
            }
        }
        .background(ColorTheme.adaptiveBackground(primary: true, isDarkMode: themeManager.isDarkMode).ignoresSafeArea())
    }

    private func landingFeatureCard(icon: String, titleKey: String, subtitleKey: String) -> some View {
        AppCard {
            HStack(alignment: .top, spacing: 14) {
                Image(systemName: icon)
                    .font(.system(size: 28))
                    .foregroundColor(themeManager.dynamicColorTheme.currentPrimary)
                    .frame(width: 44, height: 44)
                    .background(themeManager.dynamicColorTheme.currentPrimary.opacity(0.12))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                VStack(alignment: .leading, spacing: 6) {
                    Text(languageManager.localize(titleKey))
                        .textStyle(Typography.Style.headlineBold, color: ColorTheme.adaptiveText(primary: true, isDarkMode: themeManager.isDarkMode))
                    Text(languageManager.localize(subtitleKey))
                        .textStyle(Typography.Style.caption, color: ColorTheme.adaptiveText(primary: false, isDarkMode: themeManager.isDarkMode))
                        .fixedSize(horizontal: false, vertical: true)
                }
                Spacer(minLength: 0)
            }
        }
    }
}

#Preview {
    LandingView(onLogin: {}, onRegister: {}, onBrowseCoaches: {})
        .environmentObject(LanguageManager())
        .environmentObject(ThemeManager())
}
