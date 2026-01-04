import SwiftUI
import UIKit
import PhotosUI
import Charts

// MARK: - Theme

struct Theme {
    static let bg       = Color(.systemGray6)
    static let ink      = Color(.label)
    static let accent   = Color(red: 0.86, green: 0.18, blue: 0.18)
    static let accent2  = Color(red: 1.00, green: 0.34, blue: 0.28)
    static let card     = Material.ultraThin
    static let gradient = LinearGradient(colors: [accent, accent2],
                                         startPoint: .topLeading,
                                         endPoint: .bottomTrailing)
}

extension View {
    @ViewBuilder func fuelButton() -> some View { self.tint(Theme.accent) }
}

struct ContentView: View {
    enum Tab { case home, calorie, coach, settings, workout }
    @State private var selected: Tab = .home
    @StateObject private var store = CalorieStore()
    @StateObject private var workoutHistory = WorkoutHistoryStore()

    init() {
        let tabBar = UITabBar.appearance()
        tabBar.unselectedItemTintColor = .gray

        let nav = UINavigationBar.appearance()
        nav.largeTitleTextAttributes = [.foregroundColor: UIColor.label]
        nav.titleTextAttributes      = [.foregroundColor: UIColor.label]
    }

    var body: some View {
        TabView(selection: $selected) {
            NavigationStack {
                HomeView()
                    .environmentObject(store)
                    .environmentObject(workoutHistory)
            }
            .tabItem { Label("Home", systemImage: "house.fill") }
            .tag(Tab.home)

            NavigationStack {
                CalorieView()
                    .environmentObject(store)
                    .environmentObject(workoutHistory)
            }
            .tabItem { Label("Calories", systemImage: "flame.fill") }
            .tag(Tab.calorie)

            NavigationStack {
                CoachView()
                    .environmentObject(store)
                    .environmentObject(workoutHistory)
            }
            .tabItem { Label("Coach", systemImage: "message.fill") }
            .tag(Tab.coach)

            NavigationStack {
                WorkoutView()
                    .environmentObject(workoutHistory)
            }
            .tabItem { Label("Workout", systemImage: "dumbbell.fill") }
            .tag(Tab.workout)

            NavigationStack {
                SettingsView()
            }
            .tabItem { Label("Settings", systemImage: "gear") }
            .tag(Tab.settings)
        }
    }
}

// MARK: - Home

struct HomeView: View {
    @EnvironmentObject var store: CalorieStore
    @EnvironmentObject var workoutHistory: WorkoutHistoryStore

    private var caloriesToday: Int { store.consumedToday }
    private var caloriesLeft: Int {
        guard let goal = store.dailyGoal else { return 0 }
        return max(goal - caloriesToday, 0)
    }
    private var dailyGoal: Int { store.dailyGoal ?? 0 }
    private var macros: (protein: Double, carbs: Double, fats: Double) { store.macrosToday }
    private var lastFood: CalorieEntry? {
        store.entries.sorted { $0.date > $1.date }.first
    }
    private var lastWorkout: WorkoutSession? {
        workoutHistory.sessions.sorted { $0.date > $1.date }.first
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                HomeSummaryCard(
                    caloriesToday: caloriesToday,
                    caloriesLeft: caloriesLeft,
                    dailyGoal: dailyGoal,
                    macros: macros
                )
                .padding(.horizontal)

                HomeQuickActions(store: store, workoutHistory: workoutHistory)
                    .padding(.horizontal)

                HomeActivitySection(lastFood: lastFood, lastWorkout: lastWorkout)
                    .padding(.horizontal)

                HomeMotivationCard()
                    .padding(.horizontal)
                    .padding(.bottom, 20)
            }
            .padding(.top, 24)
        }
        .navigationTitle("Home")
        .navigationBarTitleDisplayMode(.large)
    }
}

private struct HomeSummaryCard: View {
    let caloriesToday: Int
    let caloriesLeft: Int
    let dailyGoal: Int
    let macros: (protein: Double, carbs: Double, fats: Double)

    var body: some View {
        VStack(spacing: 14) {
            HStack {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Today's Summary")
                        .font(.headline)
                        .foregroundColor(.primary)
                    Text("Calories left: \(caloriesLeft) / \(dailyGoal)")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                Spacer()

                VStack(alignment: .trailing, spacing: 4) {
                    Text("\(caloriesToday)")
                        .font(.system(size: 28, weight: .bold))
                        .foregroundColor(Color(red: 0.86, green: 0.18, blue: 0.18))
                    Text("kcal today")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            HStack(spacing: 10) {
                MacroChip(label: "Protein", value: Int(macros.protein), color: .blue)
                MacroChip(label: "Carbs", value: Int(macros.carbs), color: .orange)
                MacroChip(label: "Fats", value: Int(macros.fats), color: .red)
            }
        }
        .padding(16)
        .background(.ultraThinMaterial)
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.06), radius: 10, x: 0, y: 4)
    }
}

private struct HomeQuickActions: View {
    let store: CalorieStore
    let workoutHistory: WorkoutHistoryStore

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Quick actions")
                .font(.headline)
                .foregroundColor(.primary)

            HStack(spacing: 10) {
                NavigationLink {
                    CountCaloriesView()
                        .environmentObject(store)
                } label: {
                    ActionPill(title: "Log food", icon: "plus.circle.fill", gradient: [Color(red: 0.86, green: 0.18, blue: 0.18), Color(red: 1, green: 0.34, blue: 0.36)])
                }

                NavigationLink {
                    WorkoutView()
                        .environmentObject(workoutHistory)
                } label: {
                    ActionPill(title: "Log workout", icon: "figure.strengthtraining.functional", gradient: [Color(red: 0.24, green: 0.48, blue: 1.0), Color(red: 0.35, green: 0.72, blue: 1.0)])
                }
            }

            HStack(spacing: 10) {
                NavigationLink {
                    CoachView()
                        .environmentObject(store)
                        .environmentObject(workoutHistory)
                } label: {
                    ActionPill(title: "Ask coach", icon: "message.fill", gradient: [Color(red: 0.32, green: 0.35, blue: 0.95), Color(red: 0.54, green: 0.56, blue: 1.0)])
                }

                NavigationLink {
                    HydrationView()
                } label: {
                    ActionPill(title: "Add water", icon: "drop.fill", gradient: [Color(red: 0.14, green: 0.74, blue: 0.98), Color(red: 0.08, green: 0.53, blue: 0.9)])
                }
            }
        }
    }
}

private struct HomeActivitySection: View {
    let lastFood: CalorieEntry?
    let lastWorkout: WorkoutSession?

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Today")
                .font(.headline)

            VStack(spacing: 10) {
                if let lastFood {
                    ActivityRow(title: lastFood.calories == 0 ? "Food logged" : "Food: \(lastFood.calories) kcal", subtitle: "Most recent entry", icon: "fork.knife")
                } else {
                    ActivityRow(title: "No food logged yet", subtitle: "Start with breakfast", icon: "fork.knife")
                }

                if let lastWorkout {
                    let topWeightText = String(format: "Top weight %.1f", lastWorkout.topWeight)
                    ActivityRow(title: "Workout: \(lastWorkout.exerciseName)", subtitle: topWeightText, icon: "dumbbell.fill")
                } else {
                    ActivityRow(title: "No workout logged", subtitle: "Crush a quick session", icon: "dumbbell.fill")
                }
            }
            .padding(12)
            .background(Color(.systemBackground).opacity(0.9))
            .cornerRadius(14)
            .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 4)
        }
    }
}

private struct HomeMotivationCard: View {
    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Stay consistent")
                .font(.headline)
            Text("Small wins stack into big results. Log one meal, drink one glass, move for five minutes.")
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(
            LinearGradient(colors: [Color(red: 0.86, green: 0.18, blue: 0.18), Color(red: 1, green: 0.34, blue: 0.36)], startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .cornerRadius(16)
        .shadow(color: Color.black.opacity(0.08), radius: 10, x: 0, y: 6)
        .foregroundColor(.white)
    }
}

// MARK: - Home Components
private struct MacroChip: View {
    let label: String
    let value: Int
    let color: Color

    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            Text("\(value)g")
                .font(.headline)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(10)
        .background(color.opacity(0.08))
        .cornerRadius(12)
    }
}

private struct ActionPill: View {
    let title: String
    let icon: String
    let gradient: [Color]

    var body: some View {
        HStack(spacing: 8) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
            Text(title)
                .font(.system(size: 14, weight: .semibold))
        }
        .foregroundColor(.white)
        .padding(.vertical, 12)
        .frame(maxWidth: .infinity)
        .background(
            LinearGradient(colors: gradient, startPoint: .topLeading, endPoint: .bottomTrailing)
        )
        .cornerRadius(12)
        .shadow(color: Color.black.opacity(0.08), radius: 8, x: 0, y: 4)
    }
}

private struct ActivityRow: View {
    let title: String
    let subtitle: String
    let icon: String

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 16, weight: .semibold))
                .foregroundColor(Color(red: 0.86, green: 0.18, blue: 0.18))
                .frame(width: 32, height: 32)
                .background(Color(red: 0.86, green: 0.18, blue: 0.18).opacity(0.12))
                .clipShape(RoundedRectangle(cornerRadius: 8))

            VStack(alignment: .leading, spacing: 4) {
                Text(title)
                    .font(.subheadline.weight(.semibold))
                    .foregroundColor(.primary)
                Text(subtitle)
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
            Spacer()
            Image(systemName: "chevron.right")
                .font(.caption)
                .foregroundColor(.secondary)
        }
    }
}


struct CalorieView: View {
    @EnvironmentObject var store: CalorieStore
    @EnvironmentObject var workoutHistory: WorkoutHistoryStore
    private let hPad: CGFloat = 18
    private let vPad: CGFloat = 18
    private let inter: CGFloat = 18
    private let cardHeight: CGFloat = 170

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: vPad) {
                    GeometryReader { geo in
                        let totalWidth = geo.size.width
                        let cardWidth = (totalWidth - (hPad * 2) - inter) / 2

                        VStack(spacing: vPad) {

                            // TOP ROW: Count Calories + Calorie Calculation
                            HStack(spacing: inter) {
                                NavigationLink {
                                    CountCaloriesView()
                                } label: {
                                    DashboardCard(
                                        title: "Count Calories",
                                        subtitle: "Log foods & total",
                                        systemImage: "plus.circle"
                                    )
                                }
                                .frame(width: cardWidth, height: cardHeight)

                                NavigationLink {
                                    CalorieCalculationView()
                                } label: {
                                    DashboardCard(
                                        title: "Calorie Calculation",
                                        subtitle: "BMR estimate",
                                        systemImage: "calculator"
                                    )
                                }
                                .frame(width: cardWidth, height: cardHeight)
                            }

                            // MIDDLE ROW: Overall Stats + Hydration
                            HStack(spacing: inter) {
                                NavigationLink {
                                    OverallStatsView()
                                } label: {
                                    DashboardCard(
                                        title: "Overall Stats",
                                        subtitle: "Weekly summary",
                                        systemImage: "chart.bar"
                                    )
                                }
                                .frame(width: cardWidth, height: cardHeight)

                                NavigationLink {
                                    HydrationView()
                                } label: {
                                    DashboardCard(
                                        title: "Hydration",
                                        subtitle: "Track water",
                                        systemImage: "drop.fill"
                                    )
                                }
                                .frame(width: cardWidth, height: cardHeight)
                            }
                            
                            // BOTTOM ROW: Weight Tracker (ADD THIS)
                            HStack(spacing: inter) {
                                NavigationLink {
                                    WeightTrackerView()
                                } label: {
                                    DashboardCard(
                                        title: "Weight Tracker",
                                        subtitle: "Track progress",
                                        systemImage: "scalemass"
                                    )
                                }
                                .frame(width: cardWidth, height: cardHeight)
                                
                                // Empty space to maintain grid
                                Color.clear
                                    .frame(width: cardWidth, height: cardHeight)
                            }
                        }
                        .padding(.horizontal, hPad)
                        .padding(.vertical, vPad)
                    }
                    // UPDATE THIS: Changed from 2 rows to 3 rows
                    .frame(minHeight: 3 * 170 + 4 * vPad)
                    
                    // Hungry Card
                    HungryCardView()
                        .environmentObject(store)
                        .padding(.horizontal)
                        .padding(.bottom, vPad)
                }
            }
            .navigationTitle("Calorie")
        }
    }
}


/// Reusable card
struct DashboardCard: View {
    var title: String
    var subtitle: String? = nil
    var systemImage: String

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Image(systemName: systemImage)
                .symbolRenderingMode(.monochrome)
                .foregroundColor(.primary)
                .font(.system(size: 28, weight: .semibold))

            Text(title)
                .font(.headline)
                .foregroundColor(.primary)

            if let subtitle {
                Text(subtitle)
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }

            Spacer(minLength: 0)
        }
        .padding(16)
        .frame(height: 120)
        .background(
            // Soft, modern card style
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
        )
    }
}


// MARK: - Calorie Subpages

struct CountCaloriesView: View {
    @EnvironmentObject var store: CalorieStore
    
    @State private var selectedFood: CommonFood? = nil
    @State private var foodWeight: String = "100"
    @State private var searchText: String = ""
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var showCustomFoodForm = false
    @State private var selectedImage: UIImage?
    @State private var showingCamera = false

    var filteredFoods: [CommonFood] {
        guard !searchText.isEmpty else { return FoodDatabase.foods }
        return FoodDatabase.foods.filter { $0.name.lowercased().contains(searchText.lowercased()) }
    }
    
    func addFoodEntry() {
        guard let food = selectedFood,
              let weight = Double(foodWeight), weight > 0 else { return }
        
        // Calculate macros based on weight (assuming base values are for 100g)
        let weightMultiplier = weight / 100.0
        let calories = Int(Double(food.calories) * weightMultiplier)
        let protein = food.protein * weightMultiplier
        let carbs = food.carbs * weightMultiplier
        let fats = food.fats * weightMultiplier
        
        store.entries.append(CalorieEntry(
            date: Date(),
            calories: calories,
            protein: protein,
            carbs: carbs,
            fats: fats
        ))
        
        selectedFood = nil
        foodWeight = "100"
        searchText = ""
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Count Calories")
                    .font(.title2.bold())
                    .padding(.horizontal)
                
                // Food Scanner Section
                ScannerQuickSection(
                    selectedPhoto: $selectedPhoto,
                    selectedImage: $selectedImage,
                    showingCamera: $showingCamera,
                    store: store
                )

                FoodSearchSection(searchText: $searchText, filteredFoods: filteredFoods, selectedFood: $selectedFood, showCustomFoodForm: $showCustomFoodForm)
                
                if let food = selectedFood {
                    FoodWeightSection(food: food, foodWeight: $foodWeight, addAction: addFoodEntry)
                }
                
                TodaysEntriesSection(store: store)
            }
            .padding(.top)
        }
        .navigationTitle("Count Calories")
        .sheet(isPresented: $showingCamera) {
            CameraPicker(image: $selectedImage)
        }
        .sheet(isPresented: $showCustomFoodForm) {
            CustomFoodFormView(isPresented: $showCustomFoodForm, store: store)
        }
        .onChange(of: selectedPhoto) { newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    selectedImage = uiImage
                }
            }
        }
        .onChange(of: searchText) { _ in
            selectedFood = nil
        }
    }
}

// MARK: - Quick Scanner Section
struct ScannerQuickSection: View {
    @Binding var selectedPhoto: PhotosPickerItem?
    @Binding var selectedImage: UIImage?
    @Binding var showingCamera: Bool
    var store: CalorieStore
    
    var body: some View {
        VStack(spacing: 12) {
            HStack(spacing: 10) {
                // Camera Button
                Button(action: { showingCamera = true }) {
                    HStack(spacing: 8) {
                        Image(systemName: "camera.fill")
                        Text("Scan Food")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(
                        LinearGradient(
                            gradient: Gradient(colors: [Color(red: 0.86, green: 0.18, blue: 0.18), Color(red: 1, green: 0.34, blue: 0.36)]),
                            startPoint: .topLeading,
                            endPoint: .bottomTrailing
                        )
                    )
                    .cornerRadius(10)
                }
                
                // Photo Library Button
                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                    HStack(spacing: 8) {
                        Image(systemName: "photo.fill")
                        Text("Choose Photo")
                    }
                    .foregroundColor(.white)
                    .frame(maxWidth: .infinity)
                    .padding(12)
                    .background(Color.gray)
                    .cornerRadius(10)
                }
            }
        }
        .padding(.horizontal)
    }
}

// MARK: - Food Search Section
struct FoodSearchSection: View {
    @Binding var searchText: String
    let filteredFoods: [CommonFood]
    @Binding var selectedFood: CommonFood?
    @Binding var showCustomFoodForm: Bool
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Select Food")
                    .font(.headline)
                
                Spacer()
                
                Button(action: { showCustomFoodForm = true }) {
                    HStack(spacing: 4) {
                        Image(systemName: "plus.circle.fill")
                        Text("Custom")
                    }
                    .font(.caption)
                    .foregroundColor(.white)
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background(Color(red: 0.86, green: 0.18, blue: 0.18))
                    .cornerRadius(8)
                }
            }
            
            TextField("Search foods...", text: $searchText)
                .textFieldStyle(.roundedBorder)
            
            if !filteredFoods.isEmpty {
                ScrollView(.horizontal, showsIndicators: false) {
                    HStack(spacing: 8) {
                        ForEach(filteredFoods.prefix(10)) { food in
                            FoodButton(food: food, isSelected: selectedFood?.id == food.id) {
                                selectedFood = food
                            }
                        }
                    }
                    .padding(.horizontal, 2)
                }
                .frame(height: 80)
            }
        }
        .padding(.horizontal)
    }
}

struct FoodButton: View {
    let food: CommonFood
    let isSelected: Bool
    let action: () -> Void
    
    var body: some View {
        Button(action: action) {
            VStack(spacing: 4) {
                Text(food.name)
                    .font(.caption.weight(.semibold))
                    .lineLimit(2)
                
                Text("\(food.calories) cal")
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            .padding(8)
            .frame(width: 100)
            .background(
                RoundedRectangle(cornerRadius: 10)
                    .fill(isSelected ? Color(red: 0.86, green: 0.18, blue: 0.18) : Color(.systemGray5))
            )
            .foregroundColor(isSelected ? .white : .primary)
        }
    }
}

// MARK: - Food Weight Section
struct FoodWeightSection: View {
    let food: CommonFood
    @Binding var foodWeight: String
    let addAction: () -> Void
    
    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            Text("Selected: \(food.name)")
                .font(.subheadline.weight(.semibold))
            
            HStack(spacing: 12) {
                WeightInputField(foodWeight: $foodWeight)
                CalorieDisplayField(food: food, foodWeight: foodWeight)
            }
            
            MacroPreviewRow(food: food, foodWeight: foodWeight)
            
            Button(action: addAction) {
                Label("Add to Log", systemImage: "plus.circle.fill")
                    .frame(maxWidth: .infinity)
            }
            .buttonStyle(.borderedProminent)
        }
        .padding(12)
        .background(RoundedRectangle(cornerRadius: 12).fill(.ultraThinMaterial))
        .padding(.horizontal)
    }
}

struct WeightInputField: View {
    @Binding var foodWeight: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Weight (g)")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            TextField("100", text: $foodWeight)
                .textFieldStyle(.roundedBorder)
                .keyboardType(.decimalPad)
        }
    }
}

struct CalorieDisplayField: View {
    let food: CommonFood
    let foodWeight: String
    
    var body: some View {
        VStack(alignment: .leading, spacing: 4) {
            Text("Est. Calories")
                .font(.caption)
                .foregroundStyle(.secondary)
            
            let mult = (Double(foodWeight) ?? 100) / 100.0
            let cals = Int(Double(food.calories) * mult)
            Text("\(cals) kcal")
                .font(.headline)
        }
    }
}

struct MacroPreviewRow: View {
    let food: CommonFood
    let foodWeight: String
    
    var body: some View {
        HStack(spacing: 8) {
            let mult = (Double(foodWeight) ?? 100) / 100.0
            MacroPill(label: "P", value: food.protein * mult, color: .blue)
            MacroPill(label: "C", value: food.carbs * mult, color: .orange)
            MacroPill(label: "F", value: food.fats * mult, color: .red)
        }
    }
}

struct MacroPill: View {
    let label: String
    let value: Double
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2.weight(.bold))
                .foregroundColor(.white)
            
            Text("\(String(format: "%.0f", value))g")
                .font(.caption2)
                .foregroundColor(.white)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 8)
        .background(color.opacity(0.7))
        .cornerRadius(8)
    }
}

// MARK: - Todays Entries Section
struct TodaysEntriesSection: View {
    @ObservedObject var store: CalorieStore
    
    var body: some View {
        let today = Calendar.current.startOfDay(for: Date())
        let entries = store.entries.filter {
            Calendar.current.isDate($0.date, inSameDayAs: today)
        }
        
        VStack(alignment: .leading, spacing: 12) {
            Text("Today's Entries")
                .font(.headline)
                .padding(.horizontal)
            
            if entries.isEmpty {
                VStack(alignment: .center) {
                    Text("No entries yet")
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding()
            } else {
                VStack(spacing: 8) {
                    ForEach(Array(entries.enumerated()), id: \.element.id) { index, entry in
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text("\(entry.calories) kcal")
                                    .font(.headline)
                                
                                HStack(spacing: 12) {
                                    if let protein = entry.protein {
                                        Text("P: \(Int(protein))g")
                                            .font(.caption)
                                            .foregroundColor(.blue)
                                    }
                                    if let carbs = entry.carbs {
                                        Text("C: \(Int(carbs))g")
                                            .font(.caption)
                                            .foregroundColor(.orange)
                                    }
                                    if let fats = entry.fats {
                                        Text("F: \(Int(fats))g")
                                            .font(.caption)
                                            .foregroundColor(.red)
                                    }
                                }
                            }
                            
                            Spacer()
                            
                            VStack(alignment: .trailing, spacing: 4) {
                                Text(DateFormatter.localizedString(from: entry.date, dateStyle: .none, timeStyle: .short))
                                    .foregroundStyle(.secondary)
                                    .font(.caption)
                                
                                Button(action: {
                                    if let globalIndex = store.entries.firstIndex(where: { $0.id == entry.id }) {
                                        store.entries.remove(at: globalIndex)
                                    }
                                }) {
                                    Image(systemName: "trash.fill")
                                        .foregroundColor(.red)
                                        .font(.caption)
                                }
                            }
                        }
                        .padding(.vertical, 8)
                        .padding(.horizontal)
                        .background(Color(.systemGray6))
                        .cornerRadius(10)
                    }
                }
                .padding(.horizontal)
                
                // Daily Totals
                VStack(alignment: .leading, spacing: 8) {
                    Divider()
                        .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text("Daily Total")
                                .font(.headline)
                            Spacer()
                            Text("\(entries.map(\.calories).reduce(0, +)) kcal")
                                .font(.headline)
                                .foregroundColor(.red)
                        }
                        
                        HStack(spacing: 12) {
                            let totalProtein = entries.compactMap(\.protein).reduce(0, +)
                            let totalCarbs = entries.compactMap(\.carbs).reduce(0, +)
                            let totalFats = entries.compactMap(\.fats).reduce(0, +)
                            
                            if totalProtein > 0 {
                                Text("P: \(Int(totalProtein))g")
                                    .font(.caption)
                                    .foregroundColor(.blue)
                            }
                            if totalCarbs > 0 {
                                Text("C: \(Int(totalCarbs))g")
                                    .font(.caption)
                                    .foregroundColor(.orange)
                            }
                            if totalFats > 0 {
                                Text("F: \(Int(totalFats))g")
                                    .font(.caption)
                                    .foregroundColor(.red)
                            }
                        }
                    }
                    .padding(.horizontal)
                }
            }
        }
    }
}


struct CalorieCalculationView: View {
    @EnvironmentObject var store: CalorieStore
    // Inputs
    @State private var sex: Sex = .male
    @State private var age = ""
    @State private var weight = ""   // kg
    @State private var height = ""   // cm
    @State private var activity: Activity = .moderate

    // Results
    @State private var maintenance: Int?
    @State private var cut: Int?
    @State private var bulk: Int?

    // Selected daily goal
    enum Goal: String, CaseIterable, Identifiable {
        case maintenance = "Maintenance"
        case cut = "Deficit"
        case bulk = "Bulk"
        var id: String { rawValue }
    }
    @State private var selectedGoal: Goal?

    var body: some View {
        ScrollView {
            VStack(spacing: 16) {
                Text("Calorie Calculation")
                    .font(.title2.bold())

                // MARK: Inputs
                HStack(spacing: 12) {
                    Picker("Sex", selection: $sex) {
                        Text("Male").tag(Sex.male)
                        Text("Female").tag(Sex.female)
                    }
                    .pickerStyle(.segmented)
                }

                VStack(spacing: 10) {
                    TextField("Age (years)", text: $age)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)

                    TextField("Weight (kg)", text: $weight)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.decimalPad)

                    TextField("Height (cm)", text: $height)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.decimalPad)

                    VStack(alignment: .leading, spacing: 6) {
                        Text("Activity Level")
                            .font(.subheadline).foregroundStyle(.secondary)
                        Picker("", selection: $activity) {
                            ForEach(Activity.allCases) { level in
                                Text(level.label).tag(level)
                            }
                        }
                        .pickerStyle(.menu)
                    }
                }
                .padding(.horizontal)

                // MARK: Calculate button
                Button("Calculate Stats", action: calculate)
                    .buttonStyle(.borderedProminent)

                // MARK: Results
                if let maintenance, let cut, let bulk {
                    VStack(alignment: .leading, spacing: 12) {
                        resultRow(title: "Maintenance", value: maintenance, caption: activity.caption)
                        resultRow(title: "Deficit", value: cut, caption: "≈ −500 kcal/day (steady fat loss)")
                        resultRow(title: "Bulk", value: bulk, caption: "≈ +300 kcal/day (lean gain)")

                        // Choose daily goal
                        Text("Choose Daily Goal")
                            .font(.headline)
                            .padding(.top, 8)

                        Picker("Goal", selection: $selectedGoal) {
                            Text("Maintenance (\(maintenance) kcal)").tag(Goal.maintenance as Goal?)
                            Text("Deficit (\(cut) kcal)").tag(Goal.cut as Goal?)
                            Text("Bulk (\(bulk) kcal)").tag(Goal.bulk as Goal?)
                        }
                        .pickerStyle(.inline)

                        // Daily Goal headline under the button (nice font)
                        if let goalText = dailyGoalText(maintenance: maintenance, cut: cut, bulk: bulk) {
                            VStack(alignment: .leading, spacing: 6) {
                                Text("Daily Goal")
                                    .font(.custom("Montserrat-Bold", size: 24))
                                Text(goalText)
                                    .font(.custom("Lato-Regular", size: 20))
                            }
                            .padding(.top, 6)
                        }
                    }
                    .padding(.horizontal)
                }

                // Quote
                Text("“Small consistent choices compound into big results.”")
                    .font(.custom("Lato-Regular", size: 16))
                    .italic()
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 10)

                Spacer(minLength: 12)
            }
            .padding(.top)
        }
        .navigationTitle("Calorie Calculation")
    }

    // MARK: - Helpers

    private func calculate() {
        // your existing BMR math
        guard let a = Double(age),
              let w = Double(weight),
              let h = Double(height) else { return }

        let base = 10*w + 6.25*h - 5*a
        let bmr = sex == .male ? base + 5 : base - 161
        let maintenanceValue = Int((bmr * activity.multiplier).rounded())
        let cutValue = max(1200, maintenanceValue - 500)
        let bulkValue = maintenanceValue + 300

        maintenance = maintenanceValue
        cut = cutValue
        bulk = bulkValue

        if selectedGoal == nil { selectedGoal = .maintenance }

        // ✅ now this compiles because 'store' is in scope
        switch selectedGoal ?? .maintenance {
        case .maintenance: store.dailyGoal = maintenanceValue
        case .cut:         store.dailyGoal = cutValue
        case .bulk:        store.dailyGoal = bulkValue
        }
    }

    private func resultRow(title: String, value: Int, caption: String) -> some View {
        VStack(alignment: .leading, spacing: 2) {
            HStack {
                Text(title).font(.headline)
                Spacer()
                Text("\(value) kcal").font(.headline)
            }
            Text(caption).font(.caption).foregroundStyle(.secondary)
        }
        .padding(12)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .shadow(color: .black.opacity(0.06), radius: 6, x: 0, y: 3)
        )
    }

    private func dailyGoalText(maintenance: Int, cut: Int, bulk: Int) -> String? {
        guard let selectedGoal else { return nil }
        switch selectedGoal {
        case .maintenance: return "\(maintenance) kcal/day (maintenance)"
        case .cut:         return "\(cut) kcal/day (deficit)"
        case .bulk:        return "\(bulk) kcal/day (bulk)"
        }
    }

    enum Sex: String, CaseIterable, Identifiable { case male, female; var id: String { rawValue } }
    enum Activity: CaseIterable, Identifiable {
        case sedentary, light, moderate, active, veryActive
        var id: Self { self }
        var multiplier: Double {
            switch self {
            case .sedentary: 1.2
            case .light: 1.375
            case .moderate: 1.55
            case .active: 1.725
            case .veryActive: 1.9
            }
        }
        var label: String {
            switch self {
            case .sedentary: "Sedentary (little/no exercise)"
            case .light: "Light (1–3 days/wk)"
            case .moderate: "Moderate (3–5 days/wk)"
            case .active: "Active (6–7 days/wk)"
            case .veryActive: "Very Active (hard exercise + physical job)"
            }
        }
        var caption: String {
            "Activity factor \(String(format: "%.3f", multiplier))"
        }
    }
}


struct OverallStatsView: View {
    @EnvironmentObject var store: CalorieStore
    @EnvironmentObject var workoutHistory: WorkoutHistoryStore
    @State private var showingMacroBreakdown = false

    private var calendar: Calendar { .current }
    private var chartStartDate: Date? {
        workoutHistory.sessions.map(\.date).min()
    }

    private var workoutDailyStats: [WorkoutDayStat] {
        guard let start = chartStartDate else { return [] }
        var map: [Date: (top: Double, volume: Double)] = [:]
        let anchor = calendar.startOfDay(for: start)

        for session in workoutHistory.sessions {
            let day = calendar.startOfDay(for: session.date)
            guard day >= anchor else { continue }
            let current = map[day] ?? (0, 0)
            map[day] = (max(current.top, session.topWeight), current.volume + session.volume)
        }

        return map
            .map { WorkoutDayStat(date: $0.key, topWeight: $0.value.top, volume: $0.value.volume) }
            .sorted { $0.date < $1.date }
    }

    private var macroSeries: [MacroPoint] {
        guard let start = chartStartDate else { return [] }
        let anchor = calendar.startOfDay(for: start)
        var dayMap: [Date: (p: Double, c: Double, f: Double)] = [:]

        for entry in store.entries {
            let day = calendar.startOfDay(for: entry.date)
            guard day >= anchor else { continue }
            var current = dayMap[day] ?? (0, 0, 0)
            current.p += entry.protein ?? 0
            current.c += entry.carbs ?? 0
            current.f += entry.fats ?? 0
            dayMap[day] = current
        }

        return dayMap
            .flatMap { day, macros -> [MacroPoint] in
                [
                    MacroPoint(date: day, macro: "Protein", grams: macros.p),
                    MacroPoint(date: day, macro: "Carbs", grams: macros.c),
                    MacroPoint(date: day, macro: "Fats", grams: macros.f)
                ]
            }
            .sorted { $0.date < $1.date }
    }

    private var hydrationSeries: [HydrationPoint] {
        guard let start = chartStartDate else { return [] }
        let anchor = calendar.startOfDay(for: start)
        let goal = max(UserDefaults.standard.integer(forKey: "hydrationDailyGoal"), 1)
        let effectiveGoal = goal == 1 ? 2500 : goal

        let entries = HydrationView.loadEntriesStatic()
        var dayMap: [Date: Int] = [:]

        for entry in entries {
            let day = calendar.startOfDay(for: entry.date)
            guard day >= anchor else { continue }
            dayMap[day, default: 0] += entry.ml
        }

        return dayMap
            .map { HydrationPoint(date: $0.key, percent: (Double($0.value) / Double(effectiveGoal)) * 100) }
            .sorted { $0.date < $1.date }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {
                    calorieHeroCard
                    macrosCard
                    weekSummaryCard
                    nutritionAverageCard
                    hydrationStatusCard
                    weightStatusCard
                    workoutTrendCard
                    macroTrendCard
                    hydrationTrendCard
                    Spacer(minLength: 20)
                }
                .padding(16)
            }
            .navigationTitle("Overall Stats")
        }
    }
    
    // MARK: - Calorie Hero
    private var calorieHeroCard: some View {
        let hasGoal = store.dailyGoal != nil
        let consumed = store.consumedToday
        let left = store.todayLeft ?? 0
        
        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Calories Left")
                        .font(.headline)
                        .foregroundColor(.white)
                    
                    Text(hasGoal ? "\(left) kcal" : "No Goal")
                        .font(.system(size: 36, weight: .bold))
                        .foregroundColor(.white)
                }
                
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text("Goal: \(store.dailyGoal ?? 0)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                    
                    Text("Consumed: \(consumed)")
                        .font(.caption)
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
        .padding(20)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20)
                .fill(LinearGradient(colors: [Color(red: 0.86, green: 0.18, blue: 0.18), Color(red: 1.00, green: 0.34, blue: 0.28)], startPoint: .topLeading, endPoint: .bottomTrailing))
        )
        .shadow(color: .black.opacity(0.1), radius: 8, x: 0, y: 4)
    }
    
    // MARK: - Workout Trend
    private var workoutTrendCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 16, weight: .semibold))
                Text("Workouts: Weight & Volume")
                    .font(.headline)
                Spacer()
            }

            if workoutDailyStats.isEmpty {
                Text("Log a workout to see your trend.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Chart(workoutDailyStats) {
                    BarMark(
                        x: .value("Date", $0.date, unit: .day),
                        y: .value("Volume", $0.volume)
                    )
                    .foregroundStyle(Color.red.opacity(0.28))

                    LineMark(
                        x: .value("Date", $0.date, unit: .day),
                        y: .value("Top Weight", $0.topWeight)
                    )
                    .interpolationMethod(.monotone)
                    .lineStyle(.init(lineWidth: 2))
                    .foregroundStyle(Color.red)
                    .symbol(Circle())
                    .symbolSize(30)
                }
                .frame(height: 200)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial))
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }

    // MARK: - Macros Breakdown (original summary card)
    private var macrosCard: some View {
        let macros = store.macrosToday

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.pie.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)

                Text("Today's Macros")
                    .font(.headline)

                Spacer()

                Button(action: { showingMacroBreakdown.toggle() }) {
                    Image(systemName: "info.circle")
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(.primary.opacity(0.65))
                        .padding(8)
                        .background(Circle().strokeBorder(Color.primary.opacity(0.12), lineWidth: 1))
                }
            }

            HStack(spacing: 12) {
                macroBarColumn(label: "Protein", value: macros.protein, unit: "g", color: .blue, target: 150)
                macroBarColumn(label: "Carbs", value: macros.carbs, unit: "g", color: .orange, target: 200)
                macroBarColumn(label: "Fats", value: macros.fats, unit: "g", color: .red, target: 65)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial))
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }

    private func macroBarColumn(label: String, value: Double, unit: String, color: Color, target: Double) -> some View {
        // Cap the percentage to avoid oversized bars and ensure non-negative dimensions
        let percentage = max(0, min(value / target, 1.25))

        return VStack(spacing: 8) {
            VStack(spacing: 6) {
                GeometryReader { geo in
                    let totalHeight = geo.size.height
                    let fillHeight = max(8, CGFloat(percentage) * totalHeight)
                    let capHeight = min(12, fillHeight)

                    ZStack(alignment: .bottom) {
                        RoundedRectangle(cornerRadius: 10)
                            .fill(color.opacity(0.2))

                        VStack(spacing: 0) {
                            Rectangle()
                                .fill(color)
                                .frame(height: capHeight)
                            Rectangle()
                                .fill(color.opacity(0.85))
                        }
                        .frame(height: fillHeight)
                        .clipShape(RoundedRectangle(cornerRadius: 10))
                    }
                }
                .frame(height: 120)

                Text("\(String(format: "%.0f", value))\(unit)")
                    .font(.headline.weight(.semibold))
                    .foregroundColor(.primary)
            }

            Text(label)
                .font(.caption.weight(.semibold))
                .foregroundColor(.secondary)

            Text("/ \(Int(target))\(unit)")
                .font(.caption2)
                .foregroundColor(.secondary)
        }
    }

    // MARK: - Week Summary (original bar stack)
    private var weekSummaryCard: some View {
        let series = store.last7DaysTotals()
        let maxVal = max(series.map(\.value).max() ?? 1, 1)
        let weekAvg = store.dailyAverage

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "calendar")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)

                Text("Weekly Summary")
                    .font(.headline)

                Spacer()

                Text("Avg: \(weekAvg) kcal")
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(.secondary)
            }

            HStack(alignment: .bottom, spacing: 8) {
                ForEach(series, id: \.label) { item in
                    VStack(spacing: 4) {
                        RoundedRectangle(cornerRadius: 3)
                            .fill(LinearGradient(colors: [Color(red: 0.86, green: 0.18, blue: 0.18), Color(red: 1.00, green: 0.34, blue: 0.28)], startPoint: .top, endPoint: .bottom))
                            .frame(height: max(8, CGFloat(item.value) / CGFloat(maxVal) * 80))

                        Text(item.label.prefix(2))
                            .font(.caption2.weight(.semibold))
                            .foregroundColor(.secondary)
                    }
                }
            }
            .frame(height: 100)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial))
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }

    // MARK: - Nutrition Average (original summary)
    private var nutritionAverageCard: some View {
        let macros = store.macros7DayAverage

        return VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.line.uptrend.xyaxis")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)

                Text("7-Day Macro Average")
                    .font(.headline)

                Spacer()
            }

            VStack(spacing: 10) {
                HStack {
                    Label("Protein", systemImage: "bolt.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.blue)

                    Spacer()

                    Text("\(String(format: "%.1f", macros.protein))g/day")
                        .font(.subheadline.weight(.semibold))
                }
                .padding(.bottom, 5)

                HStack {
                    Label("Carbs", systemImage: "bolt.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.orange)

                    Spacer()

                    Text("\(String(format: "%.1f", macros.carbs))g/day")
                        .font(.subheadline.weight(.semibold))
                }
                .padding(.bottom, 5)

                HStack {
                    Label("Fats", systemImage: "bolt.fill")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.red)

                    Spacer()

                    Text("\(String(format: "%.1f", macros.fats))g/day")
                        .font(.subheadline.weight(.semibold))
                }
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial))
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }

    // MARK: - Hydration Status (original summary)
    private var hydrationStatusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "drop.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.cyan)

                Text("Hydration")
                    .font(.headline)

                Spacer()

                NavigationLink(destination: HydrationView()) {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Text("Track your water intake to stay hydrated")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(.cyan.opacity(0.1)))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.cyan.opacity(0.3), lineWidth: 1))
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }

    // MARK: - Weight Tracking (original summary)
    private var weightStatusCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "scalemass.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.purple)

                Text("Weight Tracking")
                    .font(.headline)

                Spacer()

                NavigationLink(destination: WeightTrackerView()) {
                    Image(systemName: "chevron.right")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            Text("Monitor your weight progress over time")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(.purple.opacity(0.1)))
        .overlay(RoundedRectangle(cornerRadius: 16).stroke(Color.purple.opacity(0.3), lineWidth: 1))
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }

    // MARK: - Macro Trend
    private var macroTrendCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "chart.bar.doc.horizontal.fill")
                    .font(.system(size: 16, weight: .semibold))
                Text("Macros over time")
                    .font(.headline)
                Spacer()
            }

            if macroSeries.isEmpty {
                Text("Macros will appear after you log food.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Chart(macroSeries) {
                    BarMark(
                        x: .value("Date", $0.date, unit: .day),
                        y: .value("Grams", $0.grams)
                    )
                    .foregroundStyle(by: .value("Macro", $0.macro))
                    .position(by: .value("Macro", $0.macro))
                }
                .chartLegend(.visible)
                .frame(height: 220)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial))
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }

    // MARK: - Hydration Trend
    private var hydrationTrendCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "drop.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.cyan)
                Text("Hydration compliance")
                    .font(.headline)
                Spacer()
            }

            if hydrationSeries.isEmpty {
                Text("Log water to see hydration % versus goal.")
                    .font(.subheadline)
                    .foregroundColor(.secondary)
            } else {
                Chart(hydrationSeries) {
                    BarMark(
                        x: .value("Date", $0.date, unit: .day),
                        y: .value("Goal %", $0.percent)
                    )
                    .foregroundStyle(Color.cyan.opacity(0.6))

                    RuleMark(y: .value("Goal", 100))
                        .lineStyle(.init(lineWidth: 1, dash: [4]))
                        .foregroundStyle(Color.cyan)
                }
                .chartYAxis {
                    AxisMarks(position: .leading)
                }
                .chartYScale(domain: 0...120)
                .frame(height: 200)
            }
        }
        .padding(16)
        .background(RoundedRectangle(cornerRadius: 16).fill(.ultraThinMaterial))
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 2)
    }
}

private struct WorkoutDayStat: Identifiable {
    var id: Date { date }
    let date: Date
    let topWeight: Double
    let volume: Double
}

private struct MacroPoint: Identifiable {
    let id = UUID()
    let date: Date
    let macro: String
    let grams: Double
}

private struct HydrationPoint: Identifiable {
    let id = UUID()
    let date: Date
    let percent: Double
}

import SwiftUI

struct HydrationEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    let ml: Int
    
    init(id: UUID = UUID(), date: Date, ml: Int) {
        self.id = id
        self.date = date
        self.ml = ml
    }
}

struct HydrationView: View {
    // Daily goal (ml) - NOW PERSISTED
    @AppStorage("hydrationDailyGoal") private var dailyGoalMl: Int = 2500
    @State private var isEditingGoal: Bool = false
    @State private var goalInput: String = ""

    // Intake logging - NOW PERSISTED
    @State private var entries: [HydrationEntry] = [] {
        didSet { saveEntries() }
    }
    @State private var intakeInput: String = ""
    
    // Load entries on appear
    init() {
        _entries = State(initialValue: HydrationView.loadEntries())
    }
    private var consumedToday: Int {
        todayEntries.reduce(0) { $0 + $1.ml }
    }
    
    // Save entries to UserDefaults
    private func saveEntries() {
        if let encoded = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(encoded, forKey: "hydrationEntries")
        }
    }
    
    // Load entries from UserDefaults
    static func loadEntries() -> [HydrationEntry] {
        guard let data = UserDefaults.standard.data(forKey: "hydrationEntries"),
              let decoded = try? JSONDecoder().decode([HydrationEntry].self, from: data) else {
            return []
        }
        return decoded
    }

    static func loadEntriesStatic() -> [HydrationEntry] {
        loadEntries()
    }

    private var remainingToday: Int {
        max(dailyGoalMl - consumedToday, 0)
    }

    var body: some View {
        ScrollView {
            VStack(spacing: 20) {

                // 1) Daily water goal card
                goalCard

                // 2) Remaining today card
                remainingCard

                // 3) Intake logging + history
                intakeSection

                // 4) Positive quote
                quoteSection
            }
            .padding(16)
        }
        .navigationTitle("Hydration")
    }

    // MARK: - Sections

    private var goalCard: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack {
                Text("Daily Water Goal")
                    .font(.headline)

                Spacer()

                Button(isEditingGoal ? "Done" : "Edit") {
                    if isEditingGoal {
                        if let value = Int(goalInput), value > 0 {
                            dailyGoalMl = value
                        }
                    } else {
                        goalInput = String(dailyGoalMl)
                    }
                    isEditingGoal.toggle()
                }
                .font(.subheadline.weight(.semibold))
            }

            if isEditingGoal {
                HStack(spacing: 8) {
                    TextField("2500", text: $goalInput)
                        .textFieldStyle(.roundedBorder)
                        .keyboardType(.numberPad)
                        .frame(width: 90)

                    Text("ml / day")
                        .foregroundStyle(.secondary)
                        .font(.subheadline)
                }

                Text("Tip: A common rule of thumb is around 30–35 ml of water per kg of body weight, or about 2–3 L per day for many adults. Your needs can be higher if you’re active, in hot weather, or sweating a lot.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                HStack(alignment: .firstTextBaseline, spacing: 8) {
                    Text("\(dailyGoalMl)")
                        .font(.system(size: 34, weight: .bold, design: .rounded))
                    Text("ml / day")
                        .font(.title3.weight(.semibold))
                }

                Text(String(format: "%.2f L per day", Double(dailyGoalMl) / 1000.0))
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .shadow(color: .black.opacity(0.07), radius: 8, x: 0, y: 4)
    }

    private var remainingCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Remaining Today")
                .font(.headline)

            HStack(alignment: .firstTextBaseline, spacing: 8) {
                Text("\(remainingToday)")
                    .font(.system(size: 34, weight: .bold, design: .rounded))
                Text("ml")
                    .font(.title3.weight(.semibold))
            }

            Text("Goal \(dailyGoalMl) ml • Consumed \(consumedToday) ml")
                .font(.subheadline)
                .foregroundStyle(.secondary)
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .shadow(color: .black.opacity(0.07), radius: 8, x: 0, y: 4)
    }

    private var intakeSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Log Intake")
                .font(.headline)

            HStack(spacing: 10) {
                TextField("e.g. 250", text: $intakeInput)
                    .textFieldStyle(.roundedBorder)
                    .keyboardType(.numberPad)

                Text("ml")
                    .foregroundStyle(.secondary)

                Button("Add") {
                    if let value = Int(intakeInput), value > 0 {
                        entries.append(HydrationEntry(date: Date(), ml: value))
                        intakeInput = ""
                    }
                }
                .buttonStyle(.borderedProminent)
            }

            if !todayEntries.isEmpty {
                VStack(alignment: .leading, spacing: 6) {
                    Text("Today")
                        .font(.subheadline.weight(.semibold))

                    ForEach(todayEntries) { entry in
                        HStack {
                            Text("+\(entry.ml) ml")
                            Spacer()
                            Text(timeString(for: entry.date))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                    }
                }
            }
        }
        .padding(18)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
    }

    private var quoteSection: some View {
        Text("“Every sip is a small act of self-care. Keep going.”")
            .font(.custom("Lato-Regular", size: 16))
            .italic()
            .foregroundStyle(.secondary)
            .multilineTextAlignment(.center)
            .padding(.top, 8)
            .frame(maxWidth: .infinity)
    }

    // MARK: - Helpers

    private var todayEntries: [HydrationEntry] {
        let today = Calendar.current.startOfDay(for: Date())
        return entries.filter { Calendar.current.isDate($0.date, inSameDayAs: today) }
    }

    private func timeString(for date: Date) -> String {
        DateFormatter.localizedString(from: date, dateStyle: .none, timeStyle: .short)
    }
}


// MARK: - Other Tabs

struct SettingsView: View {
    @State private var isDarkMode = UserDefaults.standard.bool(forKey: "darkMode")
    
    var body: some View {
        NavigationStack {
            List {
                Section("Profile") {
                    NavigationLink("Edit profile") { Text("Profile editor") }
                    Toggle("Dark Mode", isOn: $isDarkMode)
                        .onChange(of: isDarkMode) { newValue in
                            UserDefaults.standard.set(newValue, forKey: "darkMode")
                            
                            // Apply appearance
                            if newValue {
                                UIApplication.shared.connectedScenes.forEach { scene in
                                    if let windowScene = scene as? UIWindowScene {
                                        windowScene.windows.forEach { window in
                                            window.overrideUserInterfaceStyle = .dark
                                        }
                                    }
                                }
                            } else {
                                UIApplication.shared.connectedScenes.forEach { scene in
                                    if let windowScene = scene as? UIWindowScene {
                                        windowScene.windows.forEach { window in
                                            window.overrideUserInterfaceStyle = .light
                                        }
                                    }
                                }
                            }
                        }
                }
                Section("App") {
                    NavigationLink("Notifications") { Text("Notification settings") }
                    NavigationLink("About") {
                        VStack(alignment: .leading, spacing: 16) {
                            ScrollView {
                                VStack(alignment: .leading, spacing: 16) {
                                    // App Title
                                    HStack {
                                        Image(systemName: "flame.fill")
                                            .font(.system(size: 32))
                                            .foregroundColor(Color(red: 0.86, green: 0.18, blue: 0.18))
                                        
                                        Text("FUEL")
                                            .font(.system(size: 32, weight: .bold))
                                            .foregroundColor(.primary)
                                    }
                                    .padding(.bottom, 8)
                                    
                                    // Description
                                    VStack(alignment: .leading, spacing: 12) {
                                        Text("About FUEL")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                        
                                        Text("FUEL is your all-in-one fitness companion designed to help you achieve your health goals. Whether you're tracking calories, logging workouts, or seeking personalized nutrition advice, FUEL makes it simple and intuitive.")
                                            .font(.body)
                                            .foregroundColor(.primary)
                                            .lineLimit(nil)
                                        
                                        Text("Features:")
                                            .font(.headline)
                                            .foregroundColor(.primary)
                                            .padding(.top, 8)
                                        
                                        VStack(alignment: .leading, spacing: 8) {
                                            HStack(spacing: 12) {
                                                Image(systemName: "flame.fill")
                                                    .foregroundColor(.orange)
                                                    .frame(width: 24)
                                                Text("Count & track daily calories and macros")
                                                    .foregroundColor(.primary)
                                            }
                                            
                                            HStack(spacing: 12) {
                                                Image(systemName: "camera.fill")
                                                    .foregroundColor(.blue)
                                                    .frame(width: 24)
                                                Text("AI-powered food scanner")
                                                    .foregroundColor(.primary)
                                            }
                                            
                                            HStack(spacing: 12) {
                                                Image(systemName: "person.fill")
                                                    .foregroundColor(.red)
                                                    .frame(width: 24)
                                                Text("Personal AI trainer for fitness advice")
                                                    .foregroundColor(.primary)
                                            }
                                            
                                            HStack(spacing: 12) {
                                                Image(systemName: "fork.knife")
                                                    .foregroundColor(.green)
                                                    .frame(width: 24)
                                                Text("AI recipe generator by your macros")
                                                    .foregroundColor(.primary)
                                            }
                                            
                                            HStack(spacing: 12) {
                                                Image(systemName: "chart.bar")
                                                    .foregroundColor(.purple)
                                                    .frame(width: 24)
                                                Text("Track workouts & progress")
                                                    .foregroundColor(.primary)
                                            }
                                        }
                                        .padding(.vertical, 12)
                                    }
                                    
                                    Divider()
                                        .padding(.vertical, 12)
                                    
                                    // Footer
                                    VStack(alignment: .center, spacing: 8) {
                                        Text("Version 1.0")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        Text("Made by daddy faheem 👨‍💻")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                    }
                                    .frame(maxWidth: .infinity)
                                }
                                .padding(16)
                            }
                            .navigationTitle("About FUEL")
                        }
                    }
                }
            }
            .navigationTitle("Settings")
        }
        .onAppear {
            // Apply saved dark mode on appear
            if isDarkMode {
                UIApplication.shared.connectedScenes.forEach { scene in
                    if let windowScene = scene as? UIWindowScene {
                        windowScene.windows.forEach { window in
                            window.overrideUserInterfaceStyle = .dark
                        }
                    }
                }
            }
        }
    }
}

// ====== Workout page (4 cards in one row + editors) ======

import SwiftUI

// Prefixed models to avoid name clashes
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
// MARK: - Exercise catalog
enum ExerciseCatalog {
    static let all: [String] = [
        // Chest
        "Barbell Bench Press","Incline Barbell Press","Incline Dumbbell Press",
        "Dumbbell Bench Press","Machine Chest Press","Chest Fly","Cable Fly",
        "Push-up","Dips",
        // Shoulders
        "Overhead Press (Barbell)","Overhead Press (Dumbbell)","Seated Shoulder Press",
        "Lateral Raise","Front Raise","Reverse Pec Deck",
        // Back
        "Pull-ups","Chin-ups","Lat Pulldown","Barbell Row","Pendlay Row","Dumbbell Row",
        "Chest-Supported Row","Cable Row","Face Pull",
        // Arms
        "EZ-Bar Curl","Barbell Curl","Dumbbell Curl","Hammer Curl","Cable Curl",
        "Triceps Rope Pushdown","Skullcrusher","Overhead Triceps Extension",
        // Legs
        "Back Squat","Front Squat","Romanian Deadlift","Deadlift","Leg Press",
        "Bulgarian Split Squat","Lunge","Leg Extension","Leg Curl (Seated)",
        "Leg Curl (Lying)","Hip Thrust","Glute Bridge","Standing Calf Raise","Seated Calf Raise",
        // Core
        "Plank","Hanging Leg Raise","Cable Crunch","Ab Wheel Rollout"
    ]
}
// MARK: - Autocomplete text field for adding exercises
struct ExerciseAutocompleteField: View {
    var placeholder: String = "Add exercise"
    var onCommit: (String) -> Void

    @State private var text = ""
    @State private var isOpen = false
    @FocusState private var focused: Bool

    private var suggestions: [String] {
        let q = text.trimmingCharacters(in: .whitespaces).lowercased()
        guard !q.isEmpty else { return [] }

        // prefix matches first, then contains; stable sort
        let scored = ExerciseCatalog.all.compactMap { name -> (String, Int, Int)? in
            let lower = name.lowercased()
            if lower.hasPrefix(q) { return (name, 0, 0) }
            if let r = lower.range(of: q) {
                let pos = lower.distance(from: lower.startIndex, to: r.lowerBound)
                return (name, 1, pos)
            }
            return nil
        }

        return scored
            .sorted { a, b in
                if a.1 != b.1 { return a.1 < b.1 }     // score: prefix(0) before contains(1)
                if a.2 != b.2 { return a.2 < b.2 }     // earlier position first
                return a.0 < b.0                       // alphabetical fallback
            }
            .prefix(8)
            .map { $0.0 }
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 6) {
            HStack(spacing: 8) {
                TextField(placeholder, text: $text)
                    .textFieldStyle(.roundedBorder)
                    .focused($focused)
                    .onChange(of: text) { _, _ in isOpen = true }

                Button("Add") { commit(with: text.isEmpty ? (suggestions.first ?? "") : text) }
                    .buttonStyle(.borderedProminent)
                    .disabled(text.trimmingCharacters(in: .whitespaces).isEmpty && suggestions.first == nil)
            }

            if isOpen && !suggestions.isEmpty && focused {
                VStack(spacing: 0) {
                    ForEach(suggestions, id: \.self) { name in
                        Button {
                            commit(with: name)
                        } label: {
                            HStack {
                                Text(name)
                                Spacer()
                            }
                            .padding(.horizontal, 12)
                            .padding(.vertical, 10)
                        }
                        .buttonStyle(.plain)

                        if name != suggestions.last {
                            Divider().padding(.leading, 12)
                        }
                    }
                }
                .background(.ultraThinMaterial)
                .clipShape(RoundedRectangle(cornerRadius: 12, style: .continuous))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .stroke(.black.opacity(0.08), lineWidth: 1)
                )
                .shadow(color: .black.opacity(0.08), radius: 8, x: 0, y: 4)
            }
        }
        .animation(.easeInOut(duration: 0.15), value: suggestions)
        .onTapGesture { isOpen = true }
    }

    private func commit(with name: String) {
        let trimmed = name.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }
        onCommit(trimmed)
        text = ""
        isOpen = false
        focused = false
    }
}


// MARK: WorkoutView (shows 4 sections in one row)
// MARK: WorkoutView (full-width vertical, scrollable)
struct WorkoutView: View {
    @EnvironmentObject var workoutHistory: WorkoutHistoryStore
    
    var body: some View {
        NavigationStack {
            ScrollView {
                LazyVStack(spacing: 14, pinnedViews: []) {
                    sectionCard(kind: .push,   template: pushTemplate())
                    sectionCard(kind: .pull,   template: pullTemplate())
                    sectionCard(kind: .legs,   template: legsTemplate())
                    sectionCard(kind: .custom, template: []) // blank canvas
                    
                    // NEW: Workout History Card
                    WorkoutHistoryCard()
                        .environmentObject(workoutHistory)
                }
                .padding(.horizontal, 16)
                .padding(.vertical, 16)
            }
            .scrollIndicators(.hidden) // optional
            .navigationTitle("Workout")
        }
    }

    // FULL-WIDTH card row
    @ViewBuilder
    private func sectionCard(kind: WPWorkoutKind, template: [WPExercisePlan]) -> some View {
        NavigationLink {
            WorkoutPlanEditor(kind: kind, initial: template)
        } label: {
            VStack(alignment: .leading, spacing: 12) {
                HStack(spacing: 12) {
                    ZStack {
                        Circle()
                            .fill(Color(.systemGray5))
                            .frame(width: 46, height: 46)
                        Image(systemName: icon(for: kind))
                            .font(.system(size: 20, weight: .semibold))
                            .foregroundColor(cardAccent(for: kind))
                    }

                    VStack(alignment: .leading, spacing: 4) {
                        Text(kind.rawValue)
                            .font(.headline)
                            .foregroundColor(.primary)
                        Text(kind == .custom ? "Blank canvas" : "Preset plan")
                            .font(.subheadline)
                            .foregroundColor(.secondary)
                    }

                    Spacer()

                    Image(systemName: "chevron.right")
                        .font(.headline)
                        .foregroundColor(.secondary)
                }

                HStack(spacing: 8) {
                    pill(label: "Plan", systemImage: "list.bullet", tint: cardAccent(for: kind))
                    pill(label: "Form", systemImage: "figure.strengthtraining.functional", tint: cardAccent(for: kind))
                }
            }
            .padding(18)
            .frame(maxWidth: .infinity, minHeight: 118, alignment: .leading)
            .background(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .fill(Color(.systemBackground).opacity(0.9))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 22, style: .continuous)
                    .stroke(cardAccent(for: kind).opacity(0.25), lineWidth: 1)
            )
            .shadow(color: .black.opacity(0.04), radius: 10, x: 0, y: 6)
        }
        .buttonStyle(.plain)
    }

    private func pill(label: String, systemImage: String, tint: Color) -> some View {
        Label(label, systemImage: systemImage)
            .font(.caption.weight(.semibold))
            .padding(.horizontal, 12)
            .padding(.vertical, 7)
            .background(tint.opacity(0.12))
            .clipShape(Capsule())
            .foregroundColor(tint)
    }

    private func cardAccent(for kind: WPWorkoutKind) -> Color {
        switch kind {
        case .push:
            return Color(red: 0.82, green: 0.24, blue: 0.30)
        case .pull:
            return Color(red: 0.24, green: 0.45, blue: 0.92)
        case .legs:
            return Color(red: 0.20, green: 0.62, blue: 0.46)
        case .custom:
            return Color(red: 0.54, green: 0.45, blue: 0.85)
        }
    }



    private func icon(for kind: WPWorkoutKind) -> String {
        switch kind {
        case .push:   return "figure.strengthtraining.traditional"
        case .pull:   return "figure.run"
        case .legs:   return "figure.walk"
        case .custom: return "slider.horizontal.3"
        }
    }
}

// MARK: - Workout History Card (NEW)
struct WorkoutHistoryCard: View {
    @EnvironmentObject var workoutHistory: WorkoutHistoryStore
    
    private var past10DaysSessions: [WorkoutSession] {
        let tenDaysAgo = Calendar.current.date(byAdding: .day, value: -10, to: Date()) ?? Date()
        return workoutHistory.sessions
            .filter { $0.date >= tenDaysAgo }
            .sorted { $0.date > $1.date }
    }
    
    private var groupedByDay: [(day: String, sessions: [WorkoutSession])] {
        var grouped: [String: [WorkoutSession]] = [:]
        let formatter = DateFormatter()
        formatter.dateFormat = "MMM d"
        
        for session in past10DaysSessions {
            let dayKey = formatter.string(from: session.date)
            if grouped[dayKey] == nil {
                grouped[dayKey] = []
            }
            grouped[dayKey]?.append(session)
        }
        
        return grouped
            .sorted { date1, date2 in
                guard let d1 = formatter.date(from: date1.key),
                      let d2 = formatter.date(from: date2.key) else { return false }
                return d1 > d2
            }
            .map { (key, value) in
                let sorted = value.sorted { $0.date > $1.date }
                return (key, sorted)
            }
    }
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: "clock.fill")
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(.primary)
                
                Text("Workout History")
                    .font(.headline)
                    .foregroundColor(.primary)
                
                Spacer()
                
                Text("Last 10 days")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
            
            if past10DaysSessions.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "dumbbell.fill")
                        .font(.system(size: 28))
                        .foregroundColor(.secondary)
                    
                    Text("No workouts yet")
                        .font(.subheadline.weight(.semibold))
                        .foregroundColor(.secondary)
                    
                    Text("Start logging to see your history")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .frame(maxWidth: .infinity)
                .padding(.vertical, 24)
            } else {
                ScrollView(.vertical, showsIndicators: false) {
                    VStack(alignment: .leading, spacing: 10) {
                        ForEach(groupedByDay, id: \.day) { day, sessions in
                            VStack(alignment: .leading, spacing: 8) {
                                // Day header
                                Text(day)
                                    .font(.caption.weight(.semibold))
                                    .foregroundColor(.secondary)
                                    .padding(.horizontal, 0)
                                
                                // Sessions for that day
                                VStack(alignment: .leading, spacing: 6) {
                                    ForEach(sessions) { session in
                                        HStack(spacing: 10) {
                                            // Exercise icon
                                            Image(systemName: "bolt.fill")
                                                .font(.system(size: 10, weight: .bold))
                                                .foregroundColor(.white)
                                                .frame(width: 24, height: 24)
                                                .background(
                                                    Circle()
                                                        .fill(Color(red: 0.86, green: 0.18, blue: 0.18))
                                                )
                                            
                                            // Exercise name and weight
                                            VStack(alignment: .leading, spacing: 2) {
                                                Text(session.exerciseName)
                                                    .font(.subheadline.weight(.semibold))
                                                    .foregroundColor(.primary)
                                                    .lineLimit(1)
                                                
                                                HStack(spacing: 4) {
                                                    Image(systemName: "chart.line.uptrend.xyaxis")
                                                        .font(.system(size: 8))
                                                    
                                                    Text("\(session.topWeight, specifier: "%.1f") lbs")
                                                        .font(.caption)
                                                        .foregroundStyle(.secondary)
                                                }
                                            }
                                            
                                            Spacer()
                                            
                                            // Time
                                            Text(timeString(for: session.date))
                                                .font(.caption)
                                                .foregroundStyle(.secondary)
                                        }
                                        .padding(.horizontal, 10)
                                        .padding(.vertical, 8)
                                        .background(
                                            RoundedRectangle(cornerRadius: 10)
                                                .fill(Color(.systemGray6))
                                        )
                                    }
                                }
                            }
                        }
                    }
                }
                .frame(maxHeight: 240)
            }
        }
        .padding(16)
        .frame(maxWidth: .infinity)
        .background(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .overlay(
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .stroke(Color(red: 0.86, green: 0.18, blue: 0.18).opacity(0.15), lineWidth: 1)
        )
        .shadow(color: .black.opacity(0.06), radius: 8, x: 0, y: 4)
    }
    
    private func timeString(for date: Date) -> String {
        let formatter = DateFormatter()
        formatter.timeStyle = .short
        return formatter.string(from: date)
    }
}

// MARK: - Workout Templates

    // Push: chest/shoulders/triceps — heavy compounds 5–8 reps, accessories 10–15
    private func pushTemplate() -> [WPExercisePlan] {
        [
            WPExercisePlan(name: "Barbell Bench Press",      sets: [8,8,6,6].map { WPSetEntry(reps: $0) }),
            WPExercisePlan(name: "Incline Dumbbell Press",   sets: [10,10,8].map { WPSetEntry(reps: $0) }),
            WPExercisePlan(name: "Overhead Press (Barbell)", sets: [8,8,6].map { WPSetEntry(reps: $0) }),
            WPExercisePlan(name: "Dips (Weighted if able)",  sets: [8,8,8].map { WPSetEntry(reps: $0) }),
            WPExercisePlan(name: "Lateral Raise",            sets: [15,15,15].map { WPSetEntry(reps: $0) }),
            WPExercisePlan(name: "Triceps Rope Pushdown",    sets: [12,12,12].map { WPSetEntry(reps: $0) })
        ]
    }

    // Pull: back/biceps — vertical + horizontal pulls, rear delts; compounds 6–10, accessories 12–15
    private func pullTemplate() -> [WPExercisePlan] {
        [
            WPExercisePlan(name: "Pull-ups / Lat Pulldown",  sets: [6,6,6,6].map { WPSetEntry(reps: $0) }),
            WPExercisePlan(name: "Barbell Row",              sets: [8,8,8,8].map { WPSetEntry(reps: $0) }),
            WPExercisePlan(name: "Chest-Supported Row",      sets: [10,10,10].map { WPSetEntry(reps: $0) }),
            WPExercisePlan(name: "Face Pull",                sets: [15,15,15].map { WPSetEntry(reps: $0) }),
            WPExercisePlan(name: "Rear Delt Fly",            sets: [15,15,15].map { WPSetEntry(reps: $0) }),
            WPExercisePlan(name: "Hammer Curl",              sets: [12,12,12].map { WPSetEntry(reps: $0) }),
            WPExercisePlan(name: "EZ-Bar Curl",              sets: [10,10,10].map { WPSetEntry(reps: $0) })
        ]
    }

    // Legs: quads/hamstrings/glutes/calves — squat pattern + hinge + single-leg; compounds 5–8, accessories 10–15+
    private func legsTemplate() -> [WPExercisePlan] {
        [
            WPExercisePlan(name: "Back Squat",               sets: [5,5,5,5].map { WPSetEntry(reps: $0) }),
            WPExercisePlan(name: "Romanian Deadlift",        sets: [8,8,8].map { WPSetEntry(reps: $0) }),
            WPExercisePlan(name: "Leg Press",                sets: [12,12,10].map { WPSetEntry(reps: $0) }),
            WPExercisePlan(name: "Bulgarian Split Squat",    sets: [10,10,10].map { WPSetEntry(reps: $0) }),
            WPExercisePlan(name: "Leg Curl (Seated/Lying)",  sets: [12,12,12].map { WPSetEntry(reps: $0) }),
            WPExercisePlan(name: "Standing Calf Raise",      sets: [15,15,15].map { WPSetEntry(reps: $0) })
        ]
    }

    // Simple presets (you can change these anytime)
    // MARK: - Evidence-based PPL templates (editable defaults)
struct WorkoutPlanEditor: View {
    let kind: WPWorkoutKind
    @State var plan: [WPExercisePlan]
    @EnvironmentObject var workoutHistory: WorkoutHistoryStore
    @Environment(\.dismiss) private var dismiss

    init(kind: WPWorkoutKind, initial: [WPExercisePlan]) {
        self.kind = kind
        self._plan = State(initialValue: initial)
    }

    @State private var newExercise = ""

    var body: some View {
        if kind == .custom {
            CustomPlanEditor()
                .navigationTitle("Custom")
        } else {
            List {
                Section("Exercises") {
                    ForEach($plan) { $exercise in
                        ExerciseEditor(exercise: $exercise)
                    }
                    .onDelete { plan.remove(atOffsets: $0) }

                    ExerciseAutocompleteField(placeholder: "Add exercise") { name in
                        plan.append(WPExercisePlan(name: name, sets: [WPSetEntry(reps: 10)]))
                    }
                }
            }
            .listStyle(.insetGrouped)
            .navigationTitle(kind.rawValue)
            .toolbar {
                // ✅ SAVE SESSION BUTTON
                Button("Save Session") {
                    let now = Date()
                    for exercise in plan {
                        workoutHistory.logSession(for: exercise, at: now)
                    }
                    dismiss()
                }
            }
        }
    }
}



// MARK: - Custom split: list of days
struct CustomPlanEditor: View {
    @State private var days: [WPDayPlan] = []
    @State private var newDayName = ""

    var body: some View {
        List {
            Section("Days") {
                ForEach($days) { $day in
                    NavigationLink {
                        DayExerciseEditor(day: $day)
                    } label: {
                        HStack(spacing: 12) {
                            TextField("Day name (e.g., Upper, Day 1)", text: $day.name)
                                .textFieldStyle(.roundedBorder)
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .padding(.vertical, 4)
                    }
                }
                .onDelete { days.remove(atOffsets: $0) }
                .onMove { from, to in days.move(fromOffsets: from, toOffset: to) }

                HStack {
                    TextField("Add day", text: $newDayName)
                        .textFieldStyle(.roundedBorder)
                    Button("Add") {
                        let name = newDayName.trimmingCharacters(in: .whitespacesAndNewlines)
                        guard !name.isEmpty else { return }
                        days.append(WPDayPlan(name: name))
                        newDayName = ""
                    }
                    .buttonStyle(.borderedProminent)
                }
            }
        }
        .listStyle(.insetGrouped)
        .toolbar { EditButton() }
    }
}

// MARK: - Exercises inside a specific day (reuses ExerciseEditor)
struct DayExerciseEditor: View {
    @Binding var day: WPDayPlan
    @State private var newExercise = ""

    var body: some View {
        List {
            Section("Exercises") {
                ForEach($day.exercises) { $exercise in
                    ExerciseEditor(exercise: $exercise)
                }
                .onDelete { day.exercises.remove(atOffsets: $0) }
                .onMove { from, to in day.exercises.move(fromOffsets: from, toOffset: to) }

               
                ExerciseAutocompleteField(placeholder: "Add exercise") { name in
                    day.exercises.append(WPExercisePlan(name: name, sets: [WPSetEntry(reps: 10)]))
                }
            }
        }
        .listStyle(.insetGrouped)
        .navigationTitle(day.name)
        .toolbar { EditButton() }
    }
}

// Single-exercise editor: change number of sets and reps per set
struct ExerciseEditor: View {
    @Binding var exercise: WPExercisePlan
    @EnvironmentObject var workoutHistory: WorkoutHistoryStore
    
    private var previousTopWeights: [Double] {
        workoutHistory.lastSessionTopWeights(for: exercise.name, count: 3)
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 10) {
            HStack(alignment: .center, spacing: 10) {
                VStack(alignment: .leading, spacing: 4) {
                    Text(exercise.name)
                        .font(.headline)
                    HStack(spacing: 8) {
                        Text("Sets: \(exercise.sets.count)")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                        if let last = previousTopWeights.first {
                            Text("Prev: \(last, specifier: "%.1f")")
                                .font(.caption.weight(.semibold))
                                .padding(.horizontal, 8)
                                .padding(.vertical, 4)
                                .background(Capsule().fill(Color(.systemGray6)))
                        }
                    }
                }

                Spacer()

                Stepper(value: Binding(
                    get: { exercise.sets.count },
                    set: { newCount in
                        let diff = newCount - exercise.sets.count
                        if diff > 0 {
                            let newOnes = (0..<diff).map { _ in WPSetEntry(reps: 10) }
                            exercise.sets.append(contentsOf: newOnes)
                        } else if diff < 0 {
                            exercise.sets.removeLast(-diff)
                        }
                    }
                ), in: 0...10) {
                    Text("")
                }
                .labelsHidden()
            }

            if let link = youtubeFormLink(for: exercise.name) {
                Link("Form video", destination: link)
                    .font(.caption.weight(.semibold))
                    .foregroundColor(.blue)
            }

            if exercise.sets.isEmpty {
                Text("No sets yet. Increase Sets to add.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            } else {
                VStack(alignment: .leading, spacing: 8) {
                    ForEach($exercise.sets) { $set in
                        HStack(alignment: .center, spacing: 6) {
                            Button { set.done.toggle() } label: {
                                Image(systemName: set.done ? "checkmark.circle.fill" : "circle")
                                    .foregroundColor(set.done ? .green : .secondary)
                                    .font(.system(size: 20, weight: .semibold))
                            }

                            Text("Set \((exercise.sets.firstIndex(where: { $0.id == set.id }) ?? 0) + 1)")
                                .font(.subheadline)
                                .frame(width: 50, alignment: .leading)

                            HStack(spacing: 6) {
                                Text("\(set.reps) reps")
                                    .monospacedDigit()
                                    .font(.subheadline)
                                    .frame(width: 58, alignment: .trailing)
                                    .padding(.trailing, 4)
                                    .lineLimit(1)

                                Stepper("", value: $set.reps, in: 0...100)
                                    .labelsHidden()
                                    .frame(width: 64)
                            }
                            .frame(width: 124, alignment: .leading)

                            HStack(spacing: 6) {
                                TextField("0", value: $set.weight, format: .number)
                                    .keyboardType(.decimalPad)
                                    .frame(width: 70)
                                    .textFieldStyle(.roundedBorder)
                                Text("lbs")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }

                            Spacer()
                        }
                        .padding(.vertical, 6)
                    }
                }
            }
        }
        .padding(.vertical, 8)
    }
}

private func youtubeFormLink(for name: String) -> URL? {
    let query = name.replacingOccurrences(of: " ", with: "+") + "+exercise+form"
    return URL(string: "https://www.youtube.com/results?search_query=\(query)")
}


#Preview {
    ContentView()
        .environmentObject(CalorieStore())  // <- inject for previews
        .environmentObject(WorkoutHistoryStore())
}
// MARK: - Custom Food Form
struct CustomFoodFormView: View {
    @Binding var isPresented: Bool
    var store: CalorieStore
    
    @State private var foodName: String = ""
    @State private var calories: String = ""
    @State private var protein: String = ""
    @State private var carbs: String = ""
    @State private var fats: String = ""
    
    var body: some View {
        NavigationStack {
            Form {
                Section("Food Details") {
                    TextField("Food Name", text: $foodName)
                    TextField("Calories (per 100g)", text: $calories)
                        .keyboardType(.decimalPad)
                    TextField("Protein (g per 100g)", text: $protein)
                        .keyboardType(.decimalPad)
                    TextField("Carbs (g per 100g)", text: $carbs)
                        .keyboardType(.decimalPad)
                    TextField("Fats (g per 100g)", text: $fats)
                        .keyboardType(.decimalPad)
                }
                
                Section {
                    Button(action: addCustomFood) {
                        HStack {
                            Image(systemName: "plus.circle.fill")
                            Text("Add to Daily Log")
                        }
                        .frame(maxWidth: .infinity)
                        .foregroundColor(.white)
                        .padding(.vertical, 8)
                        .background(
                            LinearGradient(
                                gradient: Gradient(colors: [Color(red: 0.86, green: 0.18, blue: 0.18), Color(red: 1, green: 0.34, blue: 0.36)]),
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                        .cornerRadius(8)
                    }
                    .buttonStyle(.plain)
                }
            }
            .navigationTitle("Add Custom Food")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .navigationBarLeading) {
                    Button("Cancel") {
                        isPresented = false
                    }
                }
            }
        }
    }
    
    private func addCustomFood() {
        guard !foodName.isEmpty,
              let caloriesVal = Double(calories), caloriesVal > 0,
              let proteinVal = Double(protein),
              let carbsVal = Double(carbs),
              let fatsVal = Double(fats) else {
            return
        }
        
        // Add entry with 100g default
        let entry = CalorieEntry(
            date: Date(),
            calories: Int(caloriesVal),
            protein: proteinVal,
            carbs: carbsVal,
            fats: fatsVal
        )
        
        store.entries.append(entry)
        isPresented = false
    }
}

// MARK: - Helper Extensions
extension Collection {
    subscript(safe index: Index) -> Element? {
        return indices.contains(index) ? self[index] : nil
    }
}
