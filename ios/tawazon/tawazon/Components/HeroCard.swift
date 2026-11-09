//
//  HeroCard.swift
//  tawazon
//
//  A high-emphasis card used for the single most important action on a screen
//  (e.g. today's workout). Uses a brand gradient + elevated shadow so it reads
//  as the primary CTA above the uniform AppCards around it.
//

import SwiftUI

struct HeroCard<Content: View>: View {
    @EnvironmentObject var themeManager: ThemeManager
    var content: () -> Content

    init(@ViewBuilder content: @escaping () -> Content) {
        self.content = content
    }

    /// Text/icon color to use on top of the hero gradient (dark, since the
    /// brand primary is a bright lime).
    static var foreground: Color { Color(red: 0.07, green: 0.07, blue: 0.08) }
    static var foregroundSecondary: Color { Color(red: 0.07, green: 0.07, blue: 0.08).opacity(0.7) }

    var body: some View {
        let primary = themeManager.dynamicColorTheme.currentPrimary
        content()
            .padding(20)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                LinearGradient(
                    colors: [primary, primary.opacity(0.72)],
                    startPoint: .topLeading,
                    endPoint: .bottomTrailing
                )
            )
            .clipShape(RoundedRectangle(cornerRadius: 24, style: .continuous))
            .shadow(color: primary.opacity(0.35), radius: 16, x: 0, y: 8)
    }
}
