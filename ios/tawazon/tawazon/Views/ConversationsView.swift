//
//  ConversationsView.swift
//  tawazon
//

import SwiftUI

struct ConversationsView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var themeManager: ThemeManager
    @State private var model = ConversationsViewModel()
    var onOpen: (_ conversationId: String, _ coachName: String) -> Void

    private var textPrimary: Color { ColorTheme.adaptiveText(primary: true, isDarkMode: themeManager.isDarkMode) }
    private var textSecondary: Color { ColorTheme.adaptiveText(primary: false, isDarkMode: themeManager.isDarkMode) }

    var body: some View {
        ZStack {
            ColorTheme.adaptiveBackground(primary: true, isDarkMode: themeManager.isDarkMode)
                .ignoresSafeArea()

            if model.isLoading && model.conversations.isEmpty {
                ProgressView()
            } else if let err = model.errorMessage, model.conversations.isEmpty {
                Text(err).foregroundColor(.secondary).padding()
            } else if model.conversations.isEmpty {
                Text(languageManager.localize("chat.empty"))
                    .textStyle(Typography.Style.subheadline, color: textSecondary)
                    .padding()
            } else {
                ScrollView {
                    VStack(spacing: 12) {
                        ForEach(model.conversations) { convo in
                            Button {
                                onOpen(convo.id, convo.coachName ?? languageManager.localize("chat.coach"))
                            } label: {
                                conversationRow(convo)
                            }
                            .buttonStyle(.plain)
                        }
                    }
                    .padding()
                }
            }
        }
        .navigationTitle(languageManager.localize("chat.title"))
        .navigationBarTitleDisplayMode(.large)
        .task { await model.load() }
        .refreshable { await model.load() }
    }

    private func conversationRow(_ c: UserConversationDTO) -> some View {
        AppCard {
            HStack(spacing: 12) {
                avatar(c.coachAvatarUrl)
                VStack(alignment: .leading, spacing: 4) {
                    Text(c.coachName ?? languageManager.localize("chat.coach"))
                        .textStyle(Typography.Style.headline, color: textPrimary)
                    if let last = c.lastMessage?.content, !last.isEmpty {
                        Text(last)
                            .textStyle(Typography.Style.caption, color: textSecondary)
                            .lineLimit(1)
                    } else {
                        Text(languageManager.localize("chat.attachment"))
                            .textStyle(Typography.Style.caption, color: textSecondary)
                            .lineLimit(1)
                    }
                }
                Spacer()
                if c.unreadCount > 0 {
                    Text("\(c.unreadCount)")
                        .font(.caption2).bold()
                        .foregroundColor(.white)
                        .padding(6)
                        .background(Color.red)
                        .clipShape(Circle())
                }
            }
            .frame(maxWidth: .infinity, alignment: .leading)
        }
    }

    private func avatar(_ url: String?) -> some View {
        Group {
            if let url, let u = URL(string: url) {
                AsyncImage(url: u) { phase in
                    switch phase {
                    case .success(let img): img.resizable().aspectRatio(contentMode: .fill)
                    default: Image(systemName: "person.crop.circle.fill").resizable().foregroundColor(textSecondary)
                    }
                }
            } else {
                Image(systemName: "person.crop.circle.fill").resizable().foregroundColor(textSecondary)
            }
        }
        .frame(width: 48, height: 48)
        .clipShape(Circle())
    }
}
