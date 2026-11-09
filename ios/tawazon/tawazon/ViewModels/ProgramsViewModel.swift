//
//  ProgramsViewModel.swift
//  tawazon
//

import Foundation
import Observation

@MainActor
@Observable
final class ProgramsViewModel {
    private let api = APIService.shared

    var programs: [ProgramResponse] = []
    var isLoading = false
    var errorMessage: String?

    func load() async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let token = KeychainService.shared.getAccessToken()
            let page = try await api.getPrograms(page: 0, size: 50, token: token)
            programs = page.content
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}

@MainActor
@Observable
final class ProgramDetailViewModel {
    private let api = APIService.shared

    var program: ProgramResponse?
    var isLoading = false
    var errorMessage: String?

    func load(id: String) async {
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            let token = KeychainService.shared.getAccessToken()
            program = try await api.getProgram(id: id, token: token)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    /// Workouts ordered by day then orderIndex for stable display.
    var sortedWorkouts: [WorkoutResponse] {
        (program?.workouts ?? []).sorted {
            $0.dayOfWeek != $1.dayOfWeek ? $0.dayOfWeek < $1.dayOfWeek : $0.orderIndex < $1.orderIndex
        }
    }
}
