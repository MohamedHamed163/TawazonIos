//
//  TodayWorkoutViewModel.swift
//  tawazon
//

import Foundation
import Observation

@MainActor
@Observable
final class TodayWorkoutViewModel {
    private let api = APIService.shared

    var schedule: TodayScheduleResponse?
    /// API succeeded but returned no schedule (coach has not assigned a program yet).
    var awaitingProgramAssignment = false
    var isLoading = false
    var actionInProgress = false
    var errorMessage: String?

    func load() async {
        guard let token = KeychainService.shared.getAccessToken() else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            if let s = try await api.getTodaySchedule(token: token) {
                schedule = s
                awaitingProgramAssignment = false
            } else {
                schedule = nil
                awaitingProgramAssignment = true
            }
        } catch {
            awaitingProgramAssignment = false
            errorMessage = error.localizedDescription
        }
    }

    func complete() async {
        guard let token = KeychainService.shared.getAccessToken() else { return }
        actionInProgress = true
        errorMessage = nil
        defer { actionInProgress = false }
        do {
            schedule = try await api.completeTodayWorkout(token: token)
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func skip() async {
        guard let token = KeychainService.shared.getAccessToken() else { return }
        actionInProgress = true
        errorMessage = nil
        defer { actionInProgress = false }
        do {
            schedule = try await api.skipTodayWorkout(token: token)
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
