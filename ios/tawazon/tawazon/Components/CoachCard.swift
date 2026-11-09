//
//  CoachCard.swift
//  tawazon
//
//  Created by Ahmed Farahat on 04/09/1447 AH.
//

import SwiftUI

// MARK: - Avatar (list + featured)

struct CoachAvatarView: View {
    @EnvironmentObject var themeManager: ThemeManager
    let urlString: String?
    var size: CGFloat = 56

    var body: some View {
        Group {
            if let s = urlString?.trimmingCharacters(in: .whitespacesAndNewlines),
               !s.isEmpty,
               let url = URL(string: s) {
                AsyncImage(url: url) { phase in
                    switch phase {
                    case .success(let image):
                        image
                            .resizable()
                            .scaledToFill()
                    case .failure:
                        placeholder
                    case .empty:
                        placeholder
                            .overlay {
                                ProgressView()
                                    .scaleEffect(0.7)
                            }
                    @unknown default:
                        placeholder
                    }
                }
                .frame(width: size, height: size)
                .clipShape(Circle())
            } else {
                placeholder
            }
        }
    }

    private var placeholder: some View {
        ZStack {
            Circle()
                .fill(
                    LinearGradient(
                        colors: [
                            themeManager.dynamicColorTheme.currentPrimary.opacity(0.35),
                            themeManager.dynamicColorTheme.currentPrimary.opacity(0.12)
                        ],
                        startPoint: .topLeading,
                        endPoint: .bottomTrailing
                    )
                )
            Image(systemName: "person.fill")
                .font(.system(size: size * 0.42))
                .foregroundColor(themeManager.dynamicColorTheme.currentPrimary)
        }
        .frame(width: size, height: size)
    }
}

// MARK: - Compact card (e.g. featured carousel)

struct CoachCard: View {
    @EnvironmentObject var themeManager: ThemeManager
    let name: String
    let specialty: String
    let rating: Double
    var avatarURL: String? = nil
    var action: (() -> Void)? = nil

    var body: some View {
        AppCard {
            VStack(spacing: 12) {
                CoachAvatarView(urlString: avatarURL, size: 80)

                VStack(spacing: 4) {
                    Text(name)
                        .font(.headline)
                        .foregroundColor(ColorTheme.adaptiveText(primary: true, isDarkMode: themeManager.isDarkMode))
                        .lineLimit(2)
                        .multilineTextAlignment(.center)
                        .fixedSize(horizontal: false, vertical: true)

                    Text(specialty)
                        .font(.caption)
                        .foregroundColor(ColorTheme.adaptiveText(primary: false, isDarkMode: themeManager.isDarkMode))
                        .lineLimit(1)

                    HStack(spacing: 4) {
                        Image(systemName: "star.fill")
                            .font(.system(size: 10))
                            .foregroundColor(themeManager.dynamicColorTheme.currentPrimary)
                        Text(String(format: "%.1f", rating))
                            .font(.caption)
                            .foregroundColor(ColorTheme.adaptiveText(primary: false, isDarkMode: themeManager.isDarkMode))
                    }
                }
            }
        }
        .onTapGesture {
            action?()
        }
    }
}

#Preview {
    HStack(spacing: 16) {
        CoachCard(
            name: "Sarah Johnson",
            specialty: "Strength Training",
            rating: 4.8,
            avatarURL: nil
        )
        CoachCard(
            name: "Mike Chen",
            specialty: "Cardio Expert",
            rating: 4.9,
            avatarURL: nil
        )
    }
    .padding()
    .background(ColorTheme.adaptiveBackground(primary: true, isDarkMode: ThemeManager().isDarkMode))
    .environmentObject(ThemeManager())
    .preferredColorScheme(.dark)
}
