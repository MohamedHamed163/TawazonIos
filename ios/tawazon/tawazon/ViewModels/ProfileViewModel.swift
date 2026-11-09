//
//  ProfileViewModel.swift
//  tawazon
//

import Foundation
import Observation

@MainActor
@Observable
final class ProfileViewModel {
    private let api = APIService.shared

    var subscriptions: [SubscriptionDetailDTO] = []
    var latestHealth: HealthRecord?
    var isLoading = false
    var errorMessage: String?

    func load(token: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let subPage = try await api.getSubscriptions(page: 0, size: 20, token: token)
            subscriptions = subPage.content
        } catch {
            errorMessage = error.localizedDescription
        }
        latestHealth = try? await api.getLatestHealthRecord(token: token)
    }
}
