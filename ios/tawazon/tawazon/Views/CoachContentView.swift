//
//  CoachContentView.swift
//  tawazon
//

import SwiftUI

struct CoachContentView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var themeManager: ThemeManager
    @State private var model = CoachContentViewModel()
    var onPlay: (String) -> Void

    private var textPrimary: Color { ColorTheme.adaptiveText(primary: true, isDarkMode: themeManager.isDarkMode) }
    private var textSecondary: Color { ColorTheme.adaptiveText(primary: false, isDarkMode: themeManager.isDarkMode) }

    var body: some View {
        ZStack {
            ColorTheme.adaptiveBackground(primary: true, isDarkMode: themeManager.isDarkMode)
                .ignoresSafeArea()

            if model.isLoading && model.videos.isEmpty {
                ProgressView()
            } else if let err = model.errorMessage, model.videos.isEmpty {
                Text(err).foregroundColor(.secondary).padding()
            } else if model.videos.isEmpty {
                EmptyStateView(
                    icon: "play.rectangle.on.rectangle",
                    title: languageManager.localize("content.emptyTitle"),
                    message: languageManager.localize("content.emptyBody")
                )
            } else {
                ScrollView {
                    VStack(spacing: 16) {
                        ForEach(model.videos, id: \.id) { video in
                            Button { onPlay(video.streamUrl) } label: {
                                videoCard(video)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(languageManager.localize("content.title"))
        .navigationBarTitleDisplayMode(.large)
        .task { await model.load() }
        .refreshable { await model.load() }
    }

    private func videoCard(_ v: VideoMetadataResponse) -> some View {
        AppCard(padding: 0) {
            VStack(alignment: .leading, spacing: 0) {
                ZStack {
                    if let thumb = v.thumbnailUrl, let url = URL(string: thumb) {
                        AsyncImage(url: url) { phase in
                            switch phase {
                            case .success(let img):
                                img.resizable().aspectRatio(contentMode: .fill)
                            default:
                                Rectangle().fill(textSecondary.opacity(0.15))
                            }
                        }
                    } else {
                        Rectangle().fill(textSecondary.opacity(0.15))
                    }
                    Image(systemName: "play.circle.fill")
                        .font(.system(size: 48))
                        .foregroundColor(.white.opacity(0.9))
                        .shadow(radius: 4)
                }
                .frame(height: 180)
                .frame(maxWidth: .infinity)
                .clipped()

                VStack(alignment: .leading, spacing: 6) {
                    Text(v.title)
                        .textStyle(Typography.Style.headline, color: textPrimary)
                    if let desc = v.description, !desc.isEmpty {
                        Text(desc)
                            .textStyle(Typography.Style.caption, color: textSecondary)
                            .lineLimit(2)
                    }
                    HStack(spacing: 12) {
                        if let duration = v.duration {
                            Label(formatDuration(duration), systemImage: "clock")
                        }
                        if let difficulty = v.difficulty, !difficulty.isEmpty {
                            Label(difficulty.capitalized, systemImage: "flame.fill")
                        }
                    }
                    .textStyle(Typography.Style.caption2, color: textSecondary)
                }
                .padding(16)
            }
        }
    }

    private func formatDuration(_ seconds: Int) -> String {
        let m = seconds / 60
        let s = seconds % 60
        return String(format: "%d:%02d", m, s)
    }
}
