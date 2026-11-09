//
//  SkeletonView.swift
//  tawazon
//
//  Shimmering placeholders shown while content loads, replacing bare spinners.
//

import SwiftUI

struct Shimmer: ViewModifier {
    @State private var phase: CGFloat = -1
    var active: Bool = true

    func body(content: Content) -> some View {
        if active {
            content
                .overlay(
                    GeometryReader { geo in
                        LinearGradient(
                            colors: [.clear, Color.white.opacity(0.35), .clear],
                            startPoint: .leading,
                            endPoint: .trailing
                        )
                        .frame(width: geo.size.width * 1.5)
                        .offset(x: geo.size.width * phase)
                        .blendMode(.plusLighter)
                    }
                )
                .mask(content)
                .onAppear {
                    withAnimation(.linear(duration: 1.25).repeatForever(autoreverses: false)) {
                        phase = 1.5
                    }
                }
        } else {
            content
        }
    }
}

extension View {
    func shimmering(active: Bool = true) -> some View {
        modifier(Shimmer(active: active))
    }
}

/// A single rounded placeholder block.
struct SkeletonBlock: View {
    @EnvironmentObject var themeManager: ThemeManager
    var height: CGFloat = 16
    var width: CGFloat? = nil
    var cornerRadius: CGFloat = 8

    var body: some View {
        RoundedRectangle(cornerRadius: cornerRadius)
            .fill(ColorTheme.adaptiveText(primary: false, isDarkMode: themeManager.isDarkMode).opacity(0.18))
            .frame(width: width, height: height)
            .frame(maxWidth: width == nil ? .infinity : nil, alignment: .leading)
    }
}

/// A card-shaped skeleton with a few placeholder lines, matching AppCard.
struct SkeletonCard: View {
    var lines: Int = 3

    var body: some View {
        AppCard {
            VStack(alignment: .leading, spacing: 12) {
                SkeletonBlock(height: 20, width: 140)
                ForEach(0..<max(lines, 1), id: \.self) { i in
                    SkeletonBlock(height: 12, width: i == lines - 1 ? 180 : nil)
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
        .shimmering()
    }
}

/// Convenience: a vertical stack of skeleton cards for list/loading states.
struct SkeletonList: View {
    var count: Int = 3
    var lines: Int = 3

    var body: some View {
        VStack(spacing: 16) {
            ForEach(0..<count, id: \.self) { _ in
                SkeletonCard(lines: lines)
            }
        }
    }
}
