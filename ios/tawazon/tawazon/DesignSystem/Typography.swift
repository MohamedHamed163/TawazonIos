//
//  Typography.swift
//  tawazon
//
//  Created by Ahmed Farahat on 04/09/1447 AH.
//

import SwiftUI

struct Typography {
    // MARK: - Font Family
    static let fontFamily = "System" // Can be changed to custom font
    
    // MARK: - Font Sizes
    struct Size {
        static let largeTitle: CGFloat = 34
        static let title1: CGFloat = 28
        static let title2: CGFloat = 22
        static let title3: CGFloat = 20
        static let headline: CGFloat = 17
        static let body: CGFloat = 17
        static let callout: CGFloat = 16
        static let subheadline: CGFloat = 15
        static let footnote: CGFloat = 13
        static let caption1: CGFloat = 12
        static let caption2: CGFloat = 11
    }
    
    // MARK: - Font Weights
    struct Weight {
        static let ultraLight = Font.Weight.ultraLight
        static let thin = Font.Weight.thin
        static let light = Font.Weight.light
        static let regular = Font.Weight.regular
        static let medium = Font.Weight.medium
        static let semibold = Font.Weight.semibold
        static let bold = Font.Weight.bold
        static let heavy = Font.Weight.heavy
        static let black = Font.Weight.black
    }
    
    // MARK: - Predefined Text Styles
    // Styles are anchored to a system Font.TextStyle so they scale with the
    // user's Dynamic Type setting. The default content size matches the fixed
    // point sizes in `Size` above, so the look is unchanged at the default size.
    struct Style {
        // Large Title
        static let largeTitle = Font.system(.largeTitle, design: .default, weight: Weight.bold)

        // Titles
        static let title1 = Font.system(.title, design: .default, weight: Weight.bold)
        static let title2 = Font.system(.title2, design: .default, weight: Weight.bold)
        static let title3 = Font.system(.title3, design: .default, weight: Weight.semibold)

        // Headlines
        static let headline = Font.system(.headline, design: .default, weight: Weight.semibold)
        static let headlineBold = Font.system(.headline, design: .default, weight: Weight.bold)

        // Body
        static let body = Font.system(.body, design: .default, weight: Weight.regular)
        static let bodyBold = Font.system(.body, design: .default, weight: Weight.semibold)
        static let bodyMedium = Font.system(.body, design: .default, weight: Weight.medium)

        // Subheadline
        static let subheadline = Font.system(.subheadline, design: .default, weight: Weight.regular)
        static let subheadlineBold = Font.system(.subheadline, design: .default, weight: Weight.semibold)
        static let subheadlineMedium = Font.system(.subheadline, design: .default, weight: Weight.medium)

        // Caption
        static let caption = Font.system(.caption, design: .default, weight: Weight.regular)
        static let captionBold = Font.system(.caption, design: .default, weight: Weight.semibold)
        static let caption2 = Font.system(.caption2, design: .default, weight: Weight.regular)

        // Footnote
        static let footnote = Font.system(.footnote, design: .default, weight: Weight.regular)
        static let footnoteBold = Font.system(.footnote, design: .default, weight: Weight.semibold)
    }
}

// MARK: - Text Style Modifier
struct TextStyleModifier: ViewModifier {
    let style: Font
    let color: Color
    
    func body(content: Content) -> some View {
        content
            .font(style)
            .foregroundColor(color)
    }
}

extension View {
    func textStyle(_ style: Font, color: Color = ColorTheme.Text.primary) -> some View {
        modifier(TextStyleModifier(style: style, color: color))
    }
}

