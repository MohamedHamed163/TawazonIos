//
//  NotificationsViewModel.swift
//  tawazon
//

import Foundation
import Observation

@MainActor
@Observable
final class NotificationsViewModel {
    private let api = APIService.shared
    var pagination = PaginatedListState<AppNotificationDTO>(pageSize: 20)
    var markAllLoading = false

    func load(token: String) async {
        await pagination.loadFirstPage { page, size in
            try await api.getNotifications(page: page, size: size, token: token)
        }
    }

    func loadMore(token: String) async {
        await pagination.loadMore { page, size in
            try await api.getNotifications(page: page, size: size, token: token)
        }
    }

    func markRead(_ id: String, token: String) async {
        do {
            _ = try await api.markNotificationRead(id: id, token: token)
            await load(token: token)
        } catch { }
    }

    func markAllRead(token: String) async {
        markAllLoading = true
        defer { markAllLoading = false }
        do {
            try await api.markAllNotificationsRead(token: token)
            await load(token: token)
        } catch { }
    }
}
