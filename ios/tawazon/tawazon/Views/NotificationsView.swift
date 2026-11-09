//
//  NotificationsView.swift
//  tawazon
//

import SwiftUI

struct NotificationsView: View {
    @EnvironmentObject var languageManager: LanguageManager
    @EnvironmentObject var themeManager: ThemeManager
    @State private var model = NotificationsViewModel()

    var body: some View {
        ZStack {
            ColorTheme.adaptiveBackground(primary: true, isDarkMode: themeManager.isDarkMode)
                .ignoresSafeArea()
            if model.pagination.isLoading && model.pagination.items.isEmpty {
                ProgressView()
            } else if model.pagination.items.isEmpty {
                EmptyStateView(
                    icon: "bell.badge",
                    title: languageManager.localize("notifications.emptyTitle"),
                    message: languageManager.localize("notifications.emptyBody")
                )
            } else {
                List {
                    ForEach(model.pagination.items, id: \.id) { n in
                        notificationRow(n)
                            .listRowBackground(Color.clear)
                            .onAppear {
                                if n.id == model.pagination.items.last?.id {
                                    Task {
                                        if let t = KeychainService.shared.getAccessToken() {
                                            await model.loadMore(token: t)
                                        }
                                    }
                                }
                            }
                    }
                }
                .listStyle(.plain)
                .scrollContentBackground(.hidden)
            }
        }
        .navigationTitle(languageManager.localize("notifications.title"))
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(languageManager.localize("notifications.markAll")) {
                    Task {
                        if let t = KeychainService.shared.getAccessToken() {
                            await model.markAllRead(token: t)
                        }
                    }
                }
                .disabled(model.markAllLoading)
            }
        }
        .task {
            if let t = KeychainService.shared.getAccessToken() {
                await model.load(token: t)
            }
        }
        .refreshable {
            if let t = KeychainService.shared.getAccessToken() {
                await model.load(token: t)
            }
        }
    }

    private func notificationRow(_ n: AppNotificationDTO) -> some View {
        AppCard {
            VStack(alignment: .leading, spacing: 6) {
                HStack {
                    Text(n.title)
                        .font(.headline)
                        .foregroundColor(ColorTheme.adaptiveText(primary: true, isDarkMode: themeManager.isDarkMode))
                    Spacer()
                    if n.read != true {
                        Circle()
                            .fill(themeManager.dynamicColorTheme.currentPrimary)
                            .frame(width: 8, height: 8)
                    }
                }
                Text(n.message)
                    .font(.subheadline)
                    .foregroundColor(ColorTheme.adaptiveText(primary: false, isDarkMode: themeManager.isDarkMode))
            }
            .padding(.vertical, 4)
        }
        .contentShape(Rectangle())
        .onTapGesture {
            Task {
                if let t = KeychainService.shared.getAccessToken(), n.read != true {
                    await model.markRead(n.id, token: t)
                }
            }
        }
    }
}
