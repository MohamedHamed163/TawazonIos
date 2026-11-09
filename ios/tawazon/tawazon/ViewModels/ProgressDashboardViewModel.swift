//
//  ProgressDashboardViewModel.swift
//  tawazon
//

import Foundation
import Observation

struct WeightPoint: Identifiable {
    let id = UUID()
    let date: Date
    let weight: Double
}

@MainActor
@Observable
final class ProgressDashboardViewModel {
    private let api = APIService.shared

    var summary: ProgressSummary?
    var logs: [ProgressLogResponse] = []
    var latestRecord: HealthRecord?
    var isLoading = false
    var errorMessage: String?

    /// Chronological weight points parsed from the progress logs.
    var weightSeries: [WeightPoint] {
        let df = DateFormatter()
        df.locale = Locale(identifier: "en_US_POSIX")
        df.dateFormat = "yyyy-MM-dd"
        return logs.compactMap { log -> WeightPoint? in
            guard let d = df.date(from: String(log.logDate.prefix(10))) else { return nil }
            return WeightPoint(date: d, weight: log.weight)
        }
        .sorted { $0.date < $1.date }
    }

    var progressPhotos: [String] { latestRecord?.progressPhotoUrls ?? [] }

    func load() async {
        guard let token = KeychainService.shared.getAccessToken() else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            async let summaryTask = api.getProgressSummary(token: token)
            async let historyTask = api.getProgressHistory(page: 0, size: 100, token: token)
            summary = try await summaryTask
            logs = try await historyTask.content
            // Health record is optional; a missing one shouldn't fail the screen.
            latestRecord = try? await api.getLatestHealthRecord(token: token)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
