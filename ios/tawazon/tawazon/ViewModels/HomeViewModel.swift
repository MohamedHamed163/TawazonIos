//
//  HomeViewModel.swift
//  tawazon
//

import Foundation
import Observation

@MainActor
@Observable
final class HomeViewModel {
    private let api = APIService.shared

    var dashboard: DashboardResponse?
    var featuredCoaches: [CoachProfileDTO] = []
    var progressSummary: ProgressSummary?
    var isLoading = false
    var errorMessage: String?

    func load(isAuthenticated: Bool) async {
        guard isAuthenticated, let token = KeychainService.shared.getAccessToken() else {
            dashboard = nil
            featuredCoaches = []
            progressSummary = nil
            errorMessage = nil
            return
        }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            async let dash = api.getDashboard(token: token)
            async let progress = api.getProgressSummary(token: token)
            async let coaches = api.getFeaturedCoaches(token: token)
            dashboard = try await dash
            progressSummary = try await progress
            featuredCoaches = try await coaches
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
