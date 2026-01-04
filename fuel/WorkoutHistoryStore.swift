//
//  WorkoutHistoryStore.swift
//  fuel
//
//  Created by faheem mekrani
//

import SwiftUI
import Foundation

// MARK: - Workout Models
struct WPSetEntry: Identifiable, Hashable {
    let id = UUID()
    var reps: Int
    var weight: Double      // <- NEW
    var done: Bool = false

    init(reps: Int, weight: Double = 0, done: Bool = false) {
        self.reps = reps
        self.weight = weight
        self.done = done
    }
}
struct WPExercisePlan: Identifiable, Hashable { let id = UUID(); var name: String; var sets: [WPSetEntry] }
struct WPDayPlan: Identifiable, Hashable {
    let id = UUID()
    var name: String
    var exercises: [WPExercisePlan] = []
}
enum WPWorkoutKind: String, Identifiable { case push = "Push", pull = "Pull", legs = "Legs", custom = "Custom"; var id: String { rawValue } }

// MARK: - WorkoutSession Model (UPDATE TO BE CODABLE)
struct WorkoutSession: Identifiable, Codable {
    let id: UUID
    let exerciseName: String
    let date: Date
    let topWeight: Double
    let volume: Double

    init(id: UUID = UUID(), exerciseName: String, date: Date, topWeight: Double, volume: Double = 0) {
        self.id = id
        self.exerciseName = exerciseName
        self.date = date
        self.topWeight = topWeight
        self.volume = volume
    }

    // Backward-compatible decode so older saves (without volume) still load
    enum CodingKeys: String, CodingKey { case id, exerciseName, date, topWeight, volume }

    init(from decoder: Decoder) throws {
        let container = try decoder.container(keyedBy: CodingKeys.self)
        id = try container.decode(UUID.self, forKey: .id)
        exerciseName = try container.decode(String.self, forKey: .exerciseName)
        date = try container.decode(Date.self, forKey: .date)
        topWeight = try container.decode(Double.self, forKey: .topWeight)
        volume = (try? container.decode(Double.self, forKey: .volume)) ?? 0
    }
}

// MARK: - WorkoutHistoryStore (ADD PERSISTENCE)
@MainActor
class WorkoutHistoryStore: ObservableObject {
    // UPDATED: Now saves to UserDefaults automatically
    @Published var sessions: [WorkoutSession] = [] {
        didSet { saveSessions() }
    }
    
    // UPDATED: Load saved data on init
    init() {
        self.sessions = loadSessions()
    }
    
    // NEW: Save sessions to UserDefaults
    private func saveSessions() {
        if let encoded = try? JSONEncoder().encode(sessions) {
            UserDefaults.standard.set(encoded, forKey: "workoutSessions")
        }
    }
    
    // NEW: Load sessions from UserDefaults
    private func loadSessions() -> [WorkoutSession] {
        guard let data = UserDefaults.standard.data(forKey: "workoutSessions"),
              let decoded = try? JSONDecoder().decode([WorkoutSession].self, from: data) else {
            return []
        }
        return decoded
    }
    
    // Log a new session from an exercise plan
    func logSession(for exercise: WPExercisePlan, at date: Date = Date()) {
        let topWeight = exercise.sets.map(\.weight).max() ?? 0
        let volume = exercise.sets.reduce(0) { $0 + ($1.weight * Double($1.reps)) }
        let session = WorkoutSession(
            exerciseName: exercise.name,
            date: date,
            topWeight: topWeight,
            volume: volume
        )
        sessions.append(session)
    }
    
    // Get the last N top weights for a specific exercise
    func lastSessionTopWeights(for exerciseName: String, count: Int) -> [Double] {
        sessions
            .filter { $0.exerciseName == exerciseName }
            .sorted { $0.date > $1.date }  // most recent first
            .prefix(count)
            .map(\.topWeight)
    }
}
