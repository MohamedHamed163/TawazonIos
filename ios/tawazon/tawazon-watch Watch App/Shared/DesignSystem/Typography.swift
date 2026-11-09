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
    struct Style {
        // Large Title
        static let largeTitle = Font.system(size: Size.largeTitle, weight: Weight.bold, design: .default)
        
        // Titles
        static let title1 = Font.system(size: Size.title1, weight: Weight.bold, design: .default)
        static let title2 = Font.system(size: Size.title2, weight: Weight.bold, design: .default)
        static let title3 = Font.system(size: Size.title3, weight: Weight.semibold, design: .default)
        
        // Headlines
        static let headline = Font.system(size: Size.headline, weight: Weight.semibold, design: .default)
        static let headlineBold = Font.system(size: Size.headline, weight: Weight.bold, design: .default)
        
        // Body
        static let body = Font.system(size: Size.body, weight: Weight.regular, design: .default)
        static let bodyBold = Font.system(size: Size.body, weight: Weight.semibold, design: .default)
        static let bodyMedium = Font.system(size: Size.body, weight: Weight.medium, design: .default)
        
        // Subheadline
        static let subheadline = Font.system(size: Size.subheadline, weight: Weight.regular, design: .default)
        static let subheadlineBold = Font.system(size: Size.subheadline, weight: Weight.semibold, design: .default)
        static let subheadlineMedium = Font.system(size: Size.subheadline, weight: Weight.medium, design: .default)
        
        // Caption
        static let caption = Font.system(size: Size.caption1, weight: Weight.regular, design: .default)
        static let captionBold = Font.system(size: Size.caption1, weight: Weight.semibold, design: .default)
        static let caption2 = Font.system(size: Size.caption2, weight: Weight.regular, design: .default)
        
        // Footnote
        static let footnote = Font.system(size: Size.footnote, weight: Weight.regular, design: .default)
        static let footnoteBold = Font.system(size: Size.footnote, weight: Weight.semibold, design: .default)
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

