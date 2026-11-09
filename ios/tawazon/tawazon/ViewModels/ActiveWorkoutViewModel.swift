//
//  ActiveWorkoutViewModel.swift
//  tawazon
//
//  Drives the active, set-by-set workout logging session. The plan is loaded
//  from the same `today` schedule the overview uses; logged sets live only in
//  this session and finishing marks the day's workout complete via the existing
//  endpoint (the backend has no per-set logging API yet).
//

import Foundation
import Observation

@MainActor
@Observable
final class ActiveWorkoutViewModel {
    private let api = APIService.shared

    struct SetEntry: Identifiable {
        let id = UUID()
        var weight: String = ""
        var reps: String = ""
        var done: Bool = false
    }

    struct Exercise: Identifiable {
        let id: String
        var name: String
        var muscleGroup: String?
        var videoUrl: String?
        var targetSets: Int
        var targetReps: Int
        var restSeconds: Int
        var sets: [SetEntry]
        var notes: String = ""
    }

    var exercises: [Exercise] = []
    /// Distinct exercise templates from today's plan, offered as swap alternatives.
    var pool: [ExerciseTemplateDTO] = []
    var currentIndex: Int = 0

    var isLoading = false
    var errorMessage: String?
    var isFinishing = false
    var finished = false

    var current: Exercise? {
        exercises.indices.contains(currentIndex) ? exercises[currentIndex] : nil
    }

    var totalSetsLogged: Int {
        exercises.reduce(0) { $0 + $1.sets.filter { $0.done }.count }
    }

    var isOnLastExercise: Bool {
        currentIndex >= exercises.count - 1
    }

    func load() async {
        guard exercises.isEmpty else { return }
        guard let token = KeychainService.shared.getAccessToken() else { return }
        isLoading = true
        errorMessage = nil
        defer { isLoading = false }
        do {
            guard let schedule = try await api.getTodaySchedule(token: token) else {
                exercises = []
                return
            }
            let flattened = schedule.todayWorkouts
                .flatMap { $0.exercises }
                .sorted { $0.orderIndex < $1.orderIndex }

            exercises = flattened.map { ex in
                Exercise(
                    id: ex.id,
                    name: ex.exerciseTemplate.name,
                    muscleGroup: ex.exerciseTemplate.muscleGroup,
                    videoUrl: ex.exerciseTemplate.videoUrl,
                    targetSets: ex.sets,
                    targetReps: ex.reps,
                    restSeconds: ex.restSeconds,
                    sets: (0..<max(ex.sets, 1)).map { _ in
                        SetEntry(weight: "", reps: String(ex.reps), done: false)
                    }
                )
            }

            var seen = Set<String>()
            pool = flattened.compactMap { ex in
                seen.insert(ex.exerciseTemplate.id).inserted ? ex.exerciseTemplate : nil
            }
        } catch {
            errorMessage = error.localizedDescription
        }
    }

    func addSet() {
        guard exercises.indices.contains(currentIndex) else { return }
        let lastReps = exercises[currentIndex].sets.last?.reps ?? String(exercises[currentIndex].targetReps)
        let lastWeight = exercises[currentIndex].sets.last?.weight ?? ""
        exercises[currentIndex].sets.append(SetEntry(weight: lastWeight, reps: lastReps, done: false))
    }

    func goNext() {
        if currentIndex < exercises.count - 1 { currentIndex += 1 }
    }

    func goPrevious() {
        if currentIndex > 0 { currentIndex -= 1 }
    }

    /// Replaces the current exercise's template with an alternative from the pool,
    /// keeping the already-entered set rows in place.
    func swap(to template: ExerciseTemplateDTO) {
        guard exercises.indices.contains(currentIndex) else { return }
        exercises[currentIndex].name = template.name
        exercises[currentIndex].muscleGroup = template.muscleGroup
        exercises[currentIndex].videoUrl = template.videoUrl
    }

    func finish() async {
        guard let token = KeychainService.shared.getAccessToken() else {
            finished = true
            return
        }
        isFinishing = true
        errorMessage = nil
        defer { isFinishing = false }
        do {
            _ = try await api.completeTodayWorkout(token: token)
            finished = true
        } catch {
            errorMessage = error.localizedDescription
        }
    }
}
