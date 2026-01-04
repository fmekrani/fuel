//
//  FoodDatabase.swift
//  fuel
//
//  Created by faheem mekrani
//

import SwiftUI

struct CommonFood: Identifiable {
    let id = UUID()
    let name: String
    let calories: Int
    let protein: Double
    let carbs: Double
    let fats: Double
    let category: FoodCategory
}

enum FoodCategory: String, CaseIterable {
    case fruit = "Fruit"
    case vegetable = "Vegetable"
    case protein = "Protein"
    case carbs = "Carbs"
    case dairy = "Dairy"
    case snacks = "Snacks"
}

struct FoodDatabase {
    static let foods: [CommonFood] = [
        // Fruits
        CommonFood(name: "Banana", calories: 105, protein: 1.3, carbs: 27, fats: 0.4, category: .fruit),
        CommonFood(name: "Apple", calories: 95, protein: 0.5, carbs: 25, fats: 0.3, category: .fruit),
        CommonFood(name: "Orange", calories: 62, protein: 1.2, carbs: 15, fats: 0.2, category: .fruit),
        CommonFood(name: "Strawberries (1 cup)", calories: 49, protein: 1, carbs: 12, fats: 0.5, category: .fruit),
        CommonFood(name: "Blueberries (1 cup)", calories: 84, protein: 1.1, carbs: 21, fats: 0.5, category: .fruit),
        
        // Vegetables
        CommonFood(name: "Broccoli (1 cup)", calories: 31, protein: 2.5, carbs: 6, fats: 0.3, category: .vegetable),
        CommonFood(name: "Spinach (1 cup)", calories: 7, protein: 0.9, carbs: 1.1, fats: 0.1, category: .vegetable),
        CommonFood(name: "Carrots (1 cup)", calories: 52, protein: 1.2, carbs: 12, fats: 0.3, category: .vegetable),
        CommonFood(name: "Sweet Potato", calories: 112, protein: 2, carbs: 26, fats: 0.1, category: .vegetable),
        
        // Protein
        CommonFood(name: "Chicken Breast (100g)", calories: 165, protein: 31, carbs: 0, fats: 3.6, category: .protein),
        CommonFood(name: "Salmon (100g)", calories: 208, protein: 20, carbs: 0, fats: 13, category: .protein),
        CommonFood(name: "Ground Beef (100g)", calories: 250, protein: 26, carbs: 0, fats: 15, category: .protein),
        CommonFood(name: "Egg (1 large)", calories: 72, protein: 6, carbs: 0.4, fats: 5, category: .protein),
        CommonFood(name: "Tofu (100g)", calories: 76, protein: 8, carbs: 1.9, fats: 4.8, category: .protein),
        CommonFood(name: "Greek Yogurt (1 cup)", calories: 100, protein: 17, carbs: 6, fats: 0.7, category: .dairy),
        
        // Carbs
        CommonFood(name: "White Rice (1 cup)", calories: 206, protein: 4.3, carbs: 45, fats: 0.4, category: .carbs),
        CommonFood(name: "Brown Rice (1 cup)", calories: 216, protein: 5, carbs: 45, fats: 1.8, category: .carbs),
        CommonFood(name: "Pasta (1 cup)", calories: 221, protein: 8, carbs: 43, fats: 1.3, category: .carbs),
        CommonFood(name: "Oatmeal (1 cup)", calories: 166, protein: 5.9, carbs: 28, fats: 3.6, category: .carbs),
        CommonFood(name: "Whole Wheat Bread (1 slice)", calories: 82, protein: 4, carbs: 14, fats: 1.1, category: .carbs),
        CommonFood(name: "Quinoa (1 cup)", calories: 222, protein: 8.1, carbs: 39, fats: 3.6, category: .carbs),
        
        // Dairy
        CommonFood(name: "Milk (1 cup)", calories: 149, protein: 8, carbs: 12, fats: 8, category: .dairy),
        CommonFood(name: "Cheddar Cheese (1 oz)", calories: 114, protein: 7, carbs: 0.4, fats: 9, category: .dairy),
        
        // Snacks
        CommonFood(name: "Almonds (1 oz)", calories: 164, protein: 6, carbs: 6, fats: 14, category: .snacks),
        CommonFood(name: "Peanut Butter (2 tbsp)", calories: 188, protein: 8, carbs: 7, fats: 16, category: .snacks),
        CommonFood(name: "Protein Bar", calories: 200, protein: 20, carbs: 24, fats: 8, category: .snacks),
        CommonFood(name: "Protein Shake", calories: 120, protein: 24, carbs: 3, fats: 1.5, category: .snacks),
    ]
    
    static func search(_ query: String) -> [CommonFood] {
        guard !query.isEmpty else { return foods }
        return foods.filter { $0.name.lowercased().contains(query.lowercased()) }
    }
}
