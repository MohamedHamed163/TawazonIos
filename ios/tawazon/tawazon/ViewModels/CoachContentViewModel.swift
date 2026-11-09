//
//  CoachContentViewModel.swift
//  tawazon
//

import Foundation
import Observation

@MainActor
@Observable
final class CoachContentViewModel {
    private let api = APIService.shared

    var videos: [VideoMetadataResponse] = []
    var isLoading = false
    var errorMessage: String?

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let token = KeychainService.shared.getAccessToken()
            let page = try await api.getVideos(page: 0, size: 50, token: token)
            videos = page.content
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
