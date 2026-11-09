//
//  AppButton.swift
//  tawazon
//
//  Created by Ahmed Farahat on 04/09/1447 AH.
//

import SwiftUI

enum AppButtonStyle {
    case primary
    case secondary
    case outline
    case text
}

struct AppButton: View {
    @EnvironmentObject var themeManager: ThemeManager
    let title: String
    let style: AppButtonStyle
    var icon: String? = nil
    var iconPosition: IconPosition = .leading
    var isLoading: Bool = false
    var isDisabled: Bool = false
    var action: () -> Void
    
    enum IconPosition {
        case leading
        case trailing
    }
    
    var body: some View {
        Button(action: {
            if !isDisabled && !isLoading {
                action()
            }
        }) {
            HStack(spacing: 8) {
                if isLoading {
                    ProgressView()
                        .progressViewStyle(CircularProgressViewStyle(tint: buttonTextColor))
                } else {
                    if let icon = icon, iconPosition == .leading {
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .semibold))
                    }
                    
                    Text(title)
                        .textStyle(Typography.Style.subheadlineBold, color: buttonTextColor)
                    
                    if let icon = icon, iconPosition == .trailing {
                        Image(systemName: icon)
                            .font(.system(size: 16, weight: .semibold))
                    }
                }
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 16)
            .padding(.horizontal, 24)
            .background(backgroundColor)
            .overlay(
                RoundedRectangle(cornerRadius: 12)
                    .stroke(borderColor, lineWidth: borderWidth)
            )
            .cornerRadius(12)
        }
        .disabled(isDisabled || isLoading)
        .opacity(isDisabled ? 0.6 : 1.0)
    }
    
    private var backgroundColor: Color {
        if isDisabled {
            return ColorTheme.Button.disabled
        }
        
        switch style {
        case .primary:
            return themeManager.dynamicColorTheme.currentPrimary
        case .secondary:
            return ColorTheme.Button.secondary
        case .outline:
            return Color.clear
        case .text:
            return Color.clear
        }
    }
    
    private var buttonTextColor: Color {
        if isDisabled {
            return ColorTheme.Button.disabledText
        }
        
        switch style {
        case .primary:
            return ColorTheme.Button.primaryText
        case .secondary:
            return themeManager.dynamicColorTheme.currentPrimary
        case .outline:
            return themeManager.dynamicColorTheme.currentPrimary
        case .text:
            return themeManager.dynamicColorTheme.currentPrimary
        }
    }
    
    private var borderColor: Color {
        switch style {
        case .outline:
            return themeManager.dynamicColorTheme.currentPrimary
        default:
            return Color.clear
        }
    }
    
    private var borderWidth: CGFloat {
        switch style {
        case .outline:
            return 1.5
        default:
            return 0
        }
    }
}

#Preview {
    VStack(spacing: 20) {
        AppButton(
            title: "Primary Button",
            style: .primary,
            icon: "arrow.right"
        ) {}
        
        AppButton(
            title: "Secondary Button",
            style: .secondary
        ) {}
        
        AppButton(
            title: "Outline Button",
            style: .outline
        ) {}
        
        AppButton(
            title: "Loading Button",
            style: .primary,
            isLoading: true
        ) {}
        
        AppButton(
            title: "Disabled Button",
            style: .primary,
            isDisabled: true
        ) {}
    }
    .padding()
    .background(ColorTheme.adaptiveBackground(primary: true, isDarkMode: ThemeManager().isDarkMode))
    .environmentObject(ThemeManager())
    .preferredColorScheme(.dark)
}

