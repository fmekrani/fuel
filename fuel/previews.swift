//
//  previews.swift
//  fuel
//
//  Created by faheem mekrani on 27/10/25.
//

import Foundation
import SwiftUI

#Preview("Calorie Grid") {
    NavigationStack { CalorieView() }
        .environmentObject(CalorieStore())
}

#Preview("Count Calories") {
    NavigationStack { CountCaloriesView() }
        .environmentObject(CalorieStore())
}

#Preview("Calorie Calculation") {
    NavigationStack { CalorieCalculationView() }
        .environmentObject(CalorieStore())
}

#Preview("Overall Stats") {
    NavigationStack { OverallStatsView() }
        .environmentObject(CalorieStore())
}

#Preview("Hydration") {
    NavigationStack { HydrationView() }
}

#Preview("Workout View") {
    NavigationStack { WorkoutView() }
        .environmentObject(WorkoutHistoryStore())
}

#Preview("Root ContentView") {
    ContentView()
        .environmentObject(CalorieStore())
        .environmentObject(WorkoutHistoryStore())
}
