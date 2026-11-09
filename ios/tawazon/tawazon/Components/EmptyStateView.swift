//
//  EmptyStateView.swift
//  tawazon
//
//  Branded, optionally-actionable empty state to replace the bare
//  "icon + two grey lines" pattern used across screens.
//

import SwiftUI

struct EmptyStateView: View {
    @EnvironmentObject var themeManager: ThemeManager

    let icon: String
    let title: String
    let message: String
    var actionTitle: String? = nil
    var action: (() -> Void)? = nil

    private var primary: Color { themeManager.dynamicColorTheme.currentPrimary }

    var body: some View {
        VStack(spacing: 16) {
            ZStack {
                Circle()
                    .fill(primary.opacity(0.12))
                    .frame(width: 96, height: 96)
                Image(systemName: icon)
                    .font(.system(size: 40, weight: .semibold))
                    .foregroundColor(primary)
            }
            .accessibilityHidden(true)

            Text(title)
                .textStyle(Typography.Style.title3, color: ColorTheme.adaptiveText(primary: true, isDarkMode: themeManager.isDarkMode))
                .multilineTextAlignment(.center)

            Text(message)
                .textStyle(Typography.Style.subheadline, color: ColorTheme.adaptiveText(primary: false, isDarkMode: themeManager.isDarkMode))
                .multilineTextAlignment(.center)
                .fixedSize(horizontal: false, vertical: true)

            if let actionTitle, let action {
                AppButton(title: actionTitle, style: .primary) {
                    Haptics.tap()
                    action()
                }
                .padding(.top, 4)
                .frame(maxWidth: 260)
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.horizontal, 32)
        .padding(.vertical, 40)
        .accessibilityElement(children: .combine)
    }
}

#Preview {
    EmptyStateView(
        icon: "calendar.badge.clock",
        title: "No program yet",
        message: "Your coach hasn't assigned a program. Message your coach to get started.",
        actionTitle: "Browse coaches",
        action: {}
    )
    .environmentObject(ThemeManager())
}
