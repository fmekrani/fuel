import SwiftUI

struct HungryCardView: View {
    @EnvironmentObject var store: CalorieStore
    @State private var ingredients: String = ""
    @State private var isLoading = false
    @State private var suggestedRecipe: RecipeSuggestion?
    @State private var errorMessage = ""
    @State private var showError = false
    
    var remainingMacros: (protein: Int, carbs: Int, fats: Int) {
        let macros = store.macrosToday
        let dailyGoal = store.dailyGoal ?? 2000
        
        let remainingProtein = max(0, 150 - Int(macros.protein))
        let remainingCarbs = max(0, 250 - Int(macros.carbs))
        let remainingFats = max(0, 65 - Int(macros.fats))
        
        return (remainingProtein, remainingCarbs, remainingFats)
    }
    
    var body: some View {
        VStack(spacing: 16) {
            // Header
            HStack(spacing: 12) {
                VStack(alignment: .leading, spacing: 4) {
                    Text("Hungry?")
                        .font(.system(size: 20, weight: .bold))
                        .foregroundColor(.primary)
                    
                    Text("Get AI recipe suggestions")
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
                
                Spacer()
                
                Image(systemName: "fork.knife")
                    .font(.system(size: 24))
                    .foregroundColor(Color(red: 0.86, green: 0.18, blue: 0.18))
            }
            
            Divider()
            
            // Remaining Macros Badge
            VStack(alignment: .leading, spacing: 8) {
                Text("Macros Left Today")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                HStack(spacing: 12) {
                    MacroBadge(label: "P", value: remainingMacros.protein, unit: "g", color: .blue)
                    MacroBadge(label: "C", value: remainingMacros.carbs, unit: "g", color: .orange)
                    MacroBadge(label: "F", value: remainingMacros.fats, unit: "g", color: .red)
                }
            }
            
            Divider()
            
            // Ingredients Input
            VStack(alignment: .leading, spacing: 8) {
                Text("What ingredients do you have?")
                    .font(.caption)
                    .foregroundColor(.secondary)
                
                TextEditor(text: $ingredients)
                    .frame(height: 80)
                    .padding(10)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                    .overlay(
                        RoundedRectangle(cornerRadius: 10)
                            .stroke(Color.gray.opacity(0.3), lineWidth: 1)
                    )
            }
            
            // Generate Button
            if !isLoading {
                Button(action: generateRecipe) {
                    HStack(spacing: 8) {
                        Image(systemName: "sparkles")
                        Text("Generate Recipe")
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
            } else {
                HStack(spacing: 8) {
                    ProgressView()
                        .tint(.white)
                    Text("Creating recipe...")
                        .foregroundColor(.white)
                }
                .frame(maxWidth: .infinity)
                .padding(12)
                .background(Color.gray)
                .cornerRadius(10)
            }
            
            // Recipe Result
            if let recipe = suggestedRecipe {
                VStack(alignment: .leading, spacing: 12) {
                    Divider()
                    
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            Text(recipe.name)
                                .font(.headline)
                            
                            Spacer()
                            
                            Button(action: { suggestedRecipe = nil }) {
                                Image(systemName: "xmark.circle.fill")
                                    .foregroundColor(.gray)
                            }
                        }
                        
                        // Nutrition Info
                        HStack(spacing: 12) {
                            NutritionBadgeSmall(label: "P", value: recipe.protein, color: .blue)
                            NutritionBadgeSmall(label: "C", value: recipe.carbs, color: .orange)
                            NutritionBadgeSmall(label: "F", value: recipe.fats, color: .red)
                            NutritionBadgeSmall(label: "Cal", value: recipe.calories, color: .red)
                        }
                        
                        // Ingredients
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Ingredients")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            VStack(alignment: .leading, spacing: 6) {
                                ForEach(recipe.ingredients, id: \.self) { ingredient in
                                    HStack(spacing: 8) {
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                            .font(.caption)
                                        
                                        Text(ingredient)
                                            .font(.caption)
                                            .foregroundColor(.primary)
                                    }
                                }
                            }
                        }
                        
                        // Instructions
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Instructions")
                                .font(.caption)
                                .foregroundColor(.secondary)
                            
                            Text(recipe.instructions)
                                .font(.caption)
                                .lineLimit(5)
                                .foregroundColor(.primary)
                        }
                    }
                    .padding(12)
                    .background(Color(.systemGray6))
                    .cornerRadius(10)
                }
            }
        }
        .padding(16)
        .background(
            RoundedRectangle(cornerRadius: 16)
                .fill(Color(.systemBackground))
                .shadow(color: Color.black.opacity(0.05), radius: 8, x: 0, y: 2)
        )
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func generateRecipe() {
        guard !ingredients.isEmpty else {
            errorMessage = "Please enter at least one ingredient"
            showError = true
            return
        }
        
        isLoading = true
        
        let remaining = remainingMacros
        let prompt = """
        Create a simple recipe that uses these ingredients: \(ingredients)
        
        The recipe should fit within these remaining macros:
        - Protein: \(remaining.protein)g
        - Carbs: \(remaining.carbs)g
        - Fats: \(remaining.fats)g
        
        Please respond in this exact format:
        RECIPE: [Recipe Name]
        CALORIES: [number]
        PROTEIN: [number]
        CARBS: [number]
        FATS: [number]
        INGREDIENTS:
        - [ingredient 1]
        - [ingredient 2]
        (list all ingredients)
        INSTRUCTIONS:
        [Step-by-step cooking instructions]
        """
        
        Task {
            do {
                let response = try await OpenAIService.shared.sendMessage(prompt, conversationHistory: [])
                
                let recipe = parseRecipe(from: response)
                DispatchQueue.main.async {
                    self.suggestedRecipe = recipe
                    self.isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    self.errorMessage = "Failed to generate recipe. Make sure API key is set."
                    self.showError = true
                    self.isLoading = false
                }
            }
        }
    }
    
    private func parseRecipe(from text: String) -> RecipeSuggestion {
        let lines = text.split(separator: "\n", omittingEmptySubsequences: true).map(String.init)
        
        var name = "Recipe"
        var calories = 0
        var protein = 0
        var carbs = 0
        var fats = 0
        var ingredients: [String] = []
        var instructions = ""
        var parsingIngredients = false
        var parsingInstructions = false
        
        for line in lines {
            if line.starts(with: "RECIPE:") {
                name = line.replacingOccurrences(of: "RECIPE:", with: "").trimmingCharacters(in: .whitespaces)
            } else if line.starts(with: "CALORIES:") {
                calories = Int(line.replacingOccurrences(of: "CALORIES:", with: "").trimmingCharacters(in: .whitespaces)) ?? 0
            } else if line.starts(with: "PROTEIN:") {
                protein = Int(line.replacingOccurrences(of: "PROTEIN:", with: "").trimmingCharacters(in: .whitespaces)) ?? 0
            } else if line.starts(with: "CARBS:") {
                carbs = Int(line.replacingOccurrences(of: "CARBS:", with: "").trimmingCharacters(in: .whitespaces)) ?? 0
            } else if line.starts(with: "FATS:") {
                fats = Int(line.replacingOccurrences(of: "FATS:", with: "").trimmingCharacters(in: .whitespaces)) ?? 0
            } else if line.starts(with: "INGREDIENTS:") {
                parsingIngredients = true
                parsingInstructions = false
            } else if line.starts(with: "INSTRUCTIONS:") {
                parsingIngredients = false
                parsingInstructions = true
            } else if parsingIngredients && line.starts(with: "-") {
                let ingredient = line.replacingOccurrences(of: "-", with: "").trimmingCharacters(in: .whitespaces)
                if !ingredient.isEmpty {
                    ingredients.append(ingredient)
                }
            } else if parsingInstructions {
                instructions += line + " "
            }
        }
        
        return RecipeSuggestion(
            name: name,
            calories: calories,
            protein: protein,
            carbs: carbs,
            fats: fats,
            ingredients: ingredients,
            instructions: instructions.trimmingCharacters(in: .whitespaces)
        )
    }
}

struct RecipeSuggestion {
    let name: String
    let calories: Int
    let protein: Int
    let carbs: Int
    let fats: Int
    let ingredients: [String]
    let instructions: String
}

struct MacroBadge: View {
    let label: String
    let value: Int
    let unit: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 4) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text("\(value)\(unit)")
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(8)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct NutritionBadgeSmall: View {
    let label: String
    let value: Int
    let color: Color
    
    var body: some View {
        VStack(spacing: 2) {
            Text(label)
                .font(.caption2)
                .foregroundColor(.secondary)
            
            Text("\(value)")
                .font(.caption)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(6)
        .background(color.opacity(0.1))
        .cornerRadius(6)
    }
}

#Preview {
    HungryCardView()
        .environmentObject(CalorieStore())
}
