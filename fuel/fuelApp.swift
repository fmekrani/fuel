import SwiftUI

@main
struct fuelApp: App {
    @StateObject private var calorieStore = CalorieStore()
    @StateObject private var workoutHistory = WorkoutHistoryStore()
    @StateObject private var weightStore = WeightStore()  // ADD THIS LINE

    var body: some Scene {
        WindowGroup {
            ContentView()
                .environmentObject(calorieStore)
                .environmentObject(workoutHistory)
                .environmentObject(weightStore)  // ADD THIS LINE
        }
    }
}
