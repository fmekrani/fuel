//
//  CalorieStore.swift
//  fuel
//
//  Created by faheem mekrani
//

import SwiftUI

// MARK: - CalorieEntry Model (UPDATE THIS)
struct CalorieEntry: Identifiable, Hashable, Codable {
    let id: UUID
    let date: Date
    let calories: Int
    let protein: Double?    // grams
    let carbs: Double?      // grams
    let fats: Double?       // grams
    
    init(id: UUID = UUID(), date: Date, calories: Int, protein: Double? = nil, carbs: Double? = nil, fats: Double? = nil) {
        self.id = id
        self.date = date
        self.calories = calories
        self.protein = protein
        self.carbs = carbs
        self.fats = fats
    }
}

// MARK: - CalorieStore (REPLACE ENTIRE CLASS)
@MainActor
class CalorieStore: ObservableObject {
    // UPDATED: Now saves to UserDefaults automatically
    @Published var dailyGoal: Int? {
        didSet { UserDefaults.standard.set(dailyGoal, forKey: "dailyGoal") }
    }
    
    // UPDATED: Now saves to UserDefaults automatically
    @Published var entries: [CalorieEntry] = [] {
        didSet { saveEntries() }
    }
    
    // UPDATED: Load saved data on init
    init() {
        self.dailyGoal = UserDefaults.standard.object(forKey: "dailyGoal") as? Int
        self.entries = loadEntries()
    }
    
    // NEW: Save entries to UserDefaults
    private func saveEntries() {
        if let encoded = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(encoded, forKey: "calorieEntries")
        }
    }
    
    // NEW: Load entries from UserDefaults
    private func loadEntries() -> [CalorieEntry] {
        guard let data = UserDefaults.standard.data(forKey: "calorieEntries"),
              let decoded = try? JSONDecoder().decode([CalorieEntry].self, from: data) else {
            return []
        }
        return decoded
    }
    
    // MARK: - Derived values (KEEP ALL YOUR EXISTING CODE BELOW)
    
    private var calendar: Calendar { .current }

    // Sum for a specific day (ignores time component)
    func total(for day: Date) -> Int {
        let start = calendar.startOfDay(for: day)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return 0 }

        return entries
            .filter { $0.date >= start && $0.date < end }
            .map(\.calories)
            .reduce(0, +)
    }

    // Last 7 days totals (Mon..Sun order based on current week)
    func last7DaysTotals() -> [(label: String, value: Int)] {
        let cal = calendar
        let today = cal.startOfDay(for: Date())
        let monSun = ["Mon", "Tue", "Wed", "Thu", "Fri", "Sat", "Sun"]

        let days: [Date] = (0..<7).reversed().compactMap {
            cal.date(byAdding: .day, value: -$0, to: today)
        }

        return days.map { day in
            let w = cal.component(.weekday, from: day)  // 1=Sun ... 7=Sat
            let monBasedIndex = (w + 5) % 7            // map to 0=Mon ... 6=Sun
            return (monSun[monBasedIndex], total(for: day))
        }
    }

    var consumedToday: Int {
        total(for: Date())
    }

    var todayLeft: Int? {
        guard let goal = dailyGoal else { return nil }
        return max(goal - consumedToday, 0)
    }

    var weekTotal: Int {
        last7DaysTotals().map(\.value).reduce(0, +)
    }

    var dailyAverage: Int {
        let vals = last7DaysTotals().map(\.value)
        guard !vals.isEmpty else { return 0 }

        let avg = Double(vals.reduce(0, +)) / Double(vals.count)
        return Int(avg.rounded())
    }

    var todayName: String {
        let fmt = DateFormatter()
        fmt.locale = .current
        fmt.dateFormat = "EEEE"
        return fmt.string(from: Date())
    }
    
    // MARK: - Macro Tracking
    
    func macrosForDay(_ day: Date) -> (protein: Double, carbs: Double, fats: Double) {
        let start = calendar.startOfDay(for: day)
        guard let end = calendar.date(byAdding: .day, value: 1, to: start) else { return (0, 0, 0) }
        
        let dayEntries = entries.filter { $0.date >= start && $0.date < end }
        let protein = dayEntries.compactMap(\.protein).reduce(0, +)
        let carbs = dayEntries.compactMap(\.carbs).reduce(0, +)
        let fats = dayEntries.compactMap(\.fats).reduce(0, +)
        
        return (protein, carbs, fats)
    }
    
    var macrosToday: (protein: Double, carbs: Double, fats: Double) {
        macrosForDay(Date())
    }
    
    var macros7DayAverage: (protein: Double, carbs: Double, fats: Double) {
        let cal = calendar
        let today = cal.startOfDay(for: Date())
        
        var totalProtein: Double = 0
        var totalCarbs: Double = 0
        var totalFats: Double = 0
        
        for i in 0..<7 {
            guard let day = cal.date(byAdding: .day, value: -i, to: today) else { continue }
            let macros = macrosForDay(day)
            totalProtein += macros.protein
            totalCarbs += macros.carbs
            totalFats += macros.fats
        }
        
        return (totalProtein / 7, totalCarbs / 7, totalFats / 7)
    }
}
