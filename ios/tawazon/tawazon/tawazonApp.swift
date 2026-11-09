//
//  tawazonApp.swift
//  tawazon
//

import SwiftUI
import GoogleSignIn

private enum UnauthenticatedRoute {
    case landing
    case login
    case register
}

@main
struct tawazonApp: App {
    @StateObject private var authManager = AuthManager()
    @StateObject private var languageManager = LanguageManager()
    @StateObject private var themeManager = ThemeManager()
    @State private var unauthenticatedRoute: UnauthenticatedRoute = .landing

    var body: some Scene {
        WindowGroup {
            Group {
                if authManager.isAuthenticated || authManager.allowsGuestAccess {
                    MainView()
                } else {
                    switch unauthenticatedRoute {
                    case .landing:
                        LandingView(
                            onLogin: { unauthenticatedRoute = .login },
                            onRegister: { unauthenticatedRoute = .register },
                            onBrowseCoaches: { authManager.beginGuestBrowsing() }
                        )
                    case .login:
                        LoginView(
                            onBack: { unauthenticatedRoute = .landing },
                            onNavigateToSignUp: { unauthenticatedRoute = .register }
                        )
                    case .register:
                        SignUpView(onDismissFlow: { unauthenticatedRoute = .landing })
                    }
                }
            }
            .environmentObject(authManager)
            .environmentObject(languageManager)
            .environmentObject(themeManager)
            .preferredColorScheme(themeManager.colorScheme)
            .environment(\.layoutDirection, languageManager.isRTL ? .rightToLeft : .leftToRight)
            .environment(\.locale, languageManager.currentLanguage.locale)
            .onAppear {
                themeManager.dynamicColorTheme.setDarkMode(themeManager.isDarkMode)
                DispatchQueue.main.async {
                    UIApplication.shared.registerKeyboardDismissGesture()
                }
            }
            .onOpenURL { url in
                GIDSignIn.sharedInstance.handle(url)
            }
        }
    }
}
