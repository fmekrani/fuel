//
//  WeightTracker.swift
//  fuel
//
//  Created by faheem mekrani
//

import SwiftUI

// MARK: - Weight Entry Model
struct WeightEntry: Identifiable, Codable {
    let id: UUID
    let date: Date
    let weight: Double
    
    init(id: UUID = UUID(), date: Date, weight: Double) {
        self.id = id
        self.date = date
        self.weight = weight
    }
}

// MARK: - Weight Store
@MainActor
class WeightStore: ObservableObject {
    @Published var entries: [WeightEntry] = [] {
        didSet { saveEntries() }
    }
    
    @AppStorage("weightUnit") var weightUnit: String = "lbs"
    
    init() {
        self.entries = loadEntries()
    }
    
    private func saveEntries() {
        if let encoded = try? JSONEncoder().encode(entries) {
            UserDefaults.standard.set(encoded, forKey: "weightEntries")
        }
    }
    
    private func loadEntries() -> [WeightEntry] {
        guard let data = UserDefaults.standard.data(forKey: "weightEntries"),
              let decoded = try? JSONDecoder().decode([WeightEntry].self, from: data) else {
            return []
        }
        return decoded
    }
    
    var latestWeight: Double? {
        entries.sorted { $0.date > $1.date }.first?.weight
    }
    
    var averageWeight: Double? {
        guard !entries.isEmpty else { return nil }
        let sum = entries.map(\.weight).reduce(0, +)
        return sum / Double(entries.count)
    }
    
    var weightChange: Double? {
        guard entries.count >= 2 else { return nil }
        let sorted = entries.sorted { $0.date < $1.date }
        guard let first = sorted.first?.weight,
              let last = sorted.last?.weight else { return nil }
        return last - first
    }
}

// MARK: - Weight Tracker View
struct WeightTrackerView: View {
    @StateObject private var store = WeightStore()
    @State private var weightInput = ""
    @State private var showingUnitPicker = false
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                
                // MARK: - Current Weight Card
                VStack(alignment: .leading, spacing: 12) {
                    HStack {
                        Text("Current Weight")
                            .font(.headline)
                        Spacer()
                        Button {
                            showingUnitPicker.toggle()
                        } label: {
                            HStack(spacing: 4) {
                                Text(store.weightUnit)
                                    .font(.caption)
                                Image(systemName: "chevron.down")
                                    .font(.caption2)
                            }
                            .padding(.horizontal, 8)
                            .padding(.vertical, 4)
                            .background(
                                Capsule()
                                    .fill(.white.opacity(0.2))
                            )
                        }
                    }
                    
                    if let latest = store.latestWeight {
                        HStack(alignment: .firstTextBaseline, spacing: 8) {
                            Text("\(latest, specifier: "%.1f")")
                                .font(.system(size: 42, weight: .bold, design: .rounded))
                            Text(store.weightUnit)
                                .font(.title3.weight(.semibold))
                        }
                        
                        if let change = store.weightChange {
                            HStack(spacing: 4) {
                                Image(systemName: change >= 0 ? "arrow.up.right" : "arrow.down.right")
                                    .font(.caption)
                                Text("\(abs(change), specifier: "%.1f") \(store.weightUnit)")
                                    .font(.subheadline)
                                Text("since start")
                                    .font(.caption)
                                    .foregroundColor(.white.opacity(0.8))
                            }
                            .foregroundColor(change >= 0 ? .orange : .green)
                        }
                    } else {
                        Text("No weight logged yet")
                            .foregroundStyle(.white.opacity(0.8))
                            .font(.subheadline)
                    }
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(Theme.gradient)
                )
                .foregroundColor(.white)
                .shadow(color: Theme.accent.opacity(0.3), radius: 12, x: 0, y: 8)
                
                // MARK: - Stats Row
                if !store.entries.isEmpty {
                    HStack(spacing: 16) {
                        statCard(
                            title: "Average",
                            value: store.averageWeight.map { String(format: "%.1f", $0) } ?? "—",
                            unit: store.weightUnit
                        )
                        
                        statCard(
                            title: "Entries",
                            value: "\(store.entries.count)",
                            unit: "total"
                        )
                    }
                }
                
                // MARK: - Log Weight Card
                VStack(alignment: .leading, spacing: 12) {
                    Text("Log Weight")
                        .font(.headline)
                    
                    HStack {
                        TextField("Weight", text: $weightInput)
                            .textFieldStyle(.roundedBorder)
                            .keyboardType(.decimalPad)
                        
                        Text(store.weightUnit)
                            .foregroundStyle(.secondary)
                            .font(.subheadline)
                        
                        Button("Add") {
                            if let weight = Double(weightInput), weight > 0 {
                                store.entries.append(WeightEntry(date: Date(), weight: weight))
                                weightInput = ""
                            }
                        }
                        .buttonStyle(.borderedProminent)
                        .disabled(weightInput.isEmpty)
                    }
                    
                    Text("Tip: Weigh yourself at the same time each day for consistency.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding(20)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(.ultraThinMaterial)
                )
                .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
                
                // MARK: - History List (FIXED VERSION)
                if !store.entries.isEmpty {
                    VStack(alignment: .leading, spacing: 12) {
                        Text("History")
                            .font(.headline)
                            .padding(.horizontal, 4)
                        
                        List {
                            ForEach(store.entries.sorted { $0.date > $1.date }) { entry in
                                HStack {
                                    VStack(alignment: .leading, spacing: 4) {
                                        Text(entry.date, style: .date)
                                            .font(.subheadline)
                                        Text(entry.date, style: .time)
                                            .font(.caption)
                                            .foregroundStyle(.secondary)
                                    }
                                    
                                    Spacer()
                                    
                                    Text("\(entry.weight, specifier: "%.1f") \(store.weightUnit)")
                                        .font(.headline)
                                        .foregroundColor(Theme.accent)
                                }
                            }
                            .onDelete { indexSet in
                                let sorted = store.entries.sorted { $0.date > $1.date }
                                for index in indexSet {
                                    if let entryToDelete = sorted[safe: index],
                                       let globalIndex = store.entries.firstIndex(where: { $0.id == entryToDelete.id }) {
                                        store.entries.remove(at: globalIndex)
                                    }
                                }
                            }
                        }
                        .listStyle(.plain)
                        .frame(height: CGFloat(min(store.entries.count * 70, 350)))
                        .clipShape(RoundedRectangle(cornerRadius: 20, style: .continuous))
                        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
                    }
                } else {
                    VStack(spacing: 12) {
                        Image(systemName: "scalemass")
                            .font(.system(size: 48))
                            .foregroundStyle(.secondary)
                        Text("No weight entries yet")
                            .font(.headline)
                            .foregroundStyle(.secondary)
                        Text("Log your first weight to start tracking!")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(40)
                    .background(
                        RoundedRectangle(cornerRadius: 20, style: .continuous)
                            .fill(.ultraThinMaterial)
                    )
                }
                
                Text("Progress is progress, no matter how small.")
                    .font(.custom("Lato-Regular", size: 16))
                    .italic()
                    .foregroundStyle(.secondary)
                    .multilineTextAlignment(.center)
                    .padding(.top, 8)
            }
            .padding(16)
        }
        .navigationTitle("Weight Tracker")
        .navigationBarTitleDisplayMode(.large)
        .confirmationDialog("Weight Unit", isPresented: $showingUnitPicker) {
            Button("Pounds (lbs)") {
                store.weightUnit = "lbs"
            }
            Button("Kilograms (kg)") {
                store.weightUnit = "kg"
            }
            Button("Cancel", role: .cancel) { }
        }
    }
    
    // MARK: - Stat Card Helper
    private func statCard(title: String, value: String, unit: String) -> some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(.subheadline)
                .foregroundStyle(.secondary)
            
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(value)
                    .font(.title2.weight(.bold))
                Text(unit)
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
        )
        .shadow(color: .black.opacity(0.05), radius: 6, x: 0, y: 3)
    }
}

#Preview {
    NavigationStack {
        WeightTrackerView()
    }
}
