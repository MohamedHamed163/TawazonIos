//
//  AppCard.swift
//  tawazon
//
//  Created by Ahmed Farahat on 04/09/1447 AH.
//

import SwiftUI

struct AppCard<Content: View>: View {
    @EnvironmentObject var themeManager: ThemeManager
    let content: Content
    var padding: CGFloat
    var cornerRadius: CGFloat
    var backgroundColor: Color?
    var borderColor: Color?
    var borderWidth: CGFloat
    var shadowRadius: CGFloat
    var shadowColor: Color?
    
    init(
        padding: CGFloat = 16,
        cornerRadius: CGFloat = 16,
        backgroundColor: Color? = nil,
        borderColor: Color? = nil,
        borderWidth: CGFloat = 0,
        shadowRadius: CGFloat = 4,
        shadowColor: Color? = nil,
        @ViewBuilder content: () -> Content
    ) {
        self.padding = padding
        self.cornerRadius = cornerRadius
        self.backgroundColor = backgroundColor
        self.borderColor = borderColor
        self.borderWidth = borderWidth
        self.shadowRadius = shadowRadius
        self.shadowColor = shadowColor
        self.content = content()
    }
    
    private var adaptiveBackground: Color {
        backgroundColor ?? ColorTheme.adaptiveBackground(primary: false, isDarkMode: themeManager.isDarkMode)
    }
    
    private var adaptiveBorderColor: Color {
        borderColor ?? (themeManager.isDarkMode ? ColorTheme.Card.border : ColorTheme.Card.borderLight)
    }
    
    private var adaptiveShadowColor: Color {
        shadowColor ?? (themeManager.isDarkMode ? ColorTheme.Card.shadow : ColorTheme.Card.shadowLight)
    }
    
    var body: some View {
        content
            .padding(padding)
            .background(adaptiveBackground)
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius)
                    .stroke(adaptiveBorderColor, lineWidth: borderWidth)
            )
            .cornerRadius(cornerRadius)
            .shadow(color: adaptiveShadowColor, radius: shadowRadius, x: 0, y: 2)
    }
}

// MARK: - Convenience initializers as free functions
func DefaultCard<Content: View>(@ViewBuilder content: () -> Content) -> AppCard<Content> {
    AppCard(content: content)
}

func OutlinedCard<Content: View>(@ViewBuilder content: () -> Content) -> AppCard<Content> {
    AppCard(borderWidth: 1, content: content)
}

func ElevatedCard<Content: View>(@ViewBuilder content: () -> Content) -> AppCard<Content> {
    AppCard(shadowRadius: 8, shadowColor: ColorTheme.Card.shadow.opacity(0.5), content: content)
}

#Preview {
    VStack(spacing: 20) {
        AppCard {
            VStack(alignment: .leading, spacing: 8) {
                Text("Default Card")
                    .font(.headline)
                    .foregroundColor(ColorTheme.adaptiveText(primary: true, isDarkMode: ThemeManager().isDarkMode))
                Text("This is a default card with standard styling")
                    .font(.body)
                    .foregroundColor(ColorTheme.adaptiveText(primary: false, isDarkMode: ThemeManager().isDarkMode))
            }
        }
        
        AppCard(borderWidth: 1) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Outlined Card")
                    .font(.headline)
                    .foregroundColor(ColorTheme.adaptiveText(primary: true, isDarkMode: ThemeManager().isDarkMode))
                Text("This card has a border")
                    .font(.body)
                    .foregroundColor(ColorTheme.adaptiveText(primary: false, isDarkMode: ThemeManager().isDarkMode))
            }
        }
        
        AppCard(shadowRadius: 8) {
            VStack(alignment: .leading, spacing: 8) {
                Text("Elevated Card")
                    .font(.headline)
                    .foregroundColor(ColorTheme.adaptiveText(primary: true, isDarkMode: ThemeManager().isDarkMode))
                Text("This card has enhanced shadow")
                    .font(.body)
                    .foregroundColor(ColorTheme.adaptiveText(primary: false, isDarkMode: ThemeManager().isDarkMode))
            }
        }
    }
    .padding()
    .background(ColorTheme.adaptiveBackground(primary: true, isDarkMode: ThemeManager().isDarkMode))
    .environmentObject(ThemeManager())
    .preferredColorScheme(.dark)
}

