import SwiftUI
import PhotosUI

struct FoodIdentifierView: View {
    @EnvironmentObject var store: CalorieStore
    @State private var selectedPhoto: PhotosPickerItem?
    @State private var selectedImage: UIImage?
    @State private var isLoading = false
    @State private var identifiedFood: IdentifiedFood?
    @State private var showingCamera = false
    @State private var showAddAlert = false
    @State private var selectedWeight: String = "100"
    @State private var errorMessage = ""
    @State private var showError = false
    
    var body: some View {
        ZStack {
            Color(.systemBackground).ignoresSafeArea()
            
            VStack(spacing: 20) {
                // Header
                HStack {
                    Text("Food Scanner")
                        .font(.system(size: 32, weight: .bold))
                    Spacer()
                }
                .padding(.horizontal)
                .padding(.top, 10)
                
                ScrollView {
                    VStack(spacing: 20) {
                        // Image Section
                        if let selectedImage = selectedImage {
                            VStack(spacing: 12) {
                                Image(uiImage: selectedImage)
                                    .resizable()
                                    .scaledToFill()
                                    .frame(height: 250)
                                    .clipShape(RoundedRectangle(cornerRadius: 16))
                                    .overlay(
                                        RoundedRectangle(cornerRadius: 16)
                                            .stroke(Color.red.opacity(0.3), lineWidth: 2)
                                    )
                                
                                // Action Buttons
                                HStack(spacing: 12) {
                                    Button(action: resetImage) {
                                        Label("New Photo", systemImage: "xmark.circle.fill")
                                            .foregroundColor(.white)
                                            .frame(maxWidth: .infinity)
                                            .padding(12)
                                            .background(Color.gray)
                                            .cornerRadius(12)
                                    }
                                    
                                    if !isLoading {
                                        Button(action: identifyFood) {
                                            Label("Identify Food", systemImage: "sparkles")
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
                                                .cornerRadius(12)
                                        }
                                    } else {
                                        HStack(spacing: 8) {
                                            ProgressView()
                                                .tint(.white)
                                            Text("Analyzing...")
                                                .foregroundColor(.white)
                                        }
                                        .frame(maxWidth: .infinity)
                                        .padding(12)
                                        .background(Color.gray)
                                        .cornerRadius(12)
                                    }
                                }
                            }
                        } else {
                            // Upload Options
                            VStack(spacing: 12) {
                                VStack(spacing: 20) {
                                    Image(systemName: "camera.fill")
                                        .font(.system(size: 48))
                                        .foregroundColor(.red)
                                    
                                    Text("Take a Photo or Upload")
                                        .font(.headline)
                                        .foregroundColor(.primary)
                                    
                                    Text("Scan your food to instantly identify it and get nutritional info")
                                        .font(.caption)
                                        .foregroundColor(.secondary)
                                        .multilineTextAlignment(.center)
                                }
                                .frame(maxWidth: .infinity)
                                .padding(30)
                                .background(Color(.systemGray6))
                                .cornerRadius(16)
                                
                                // Camera Button
                                Button(action: { showingCamera = true }) {
                                    Label("Take Photo", systemImage: "camera.fill")
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(14)
                                        .background(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color(red: 0.86, green: 0.18, blue: 0.18), Color(red: 1, green: 0.34, blue: 0.36)]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .cornerRadius(12)
                                }
                                
                                // Photo Library Button
                                PhotosPicker(selection: $selectedPhoto, matching: .images) {
                                    Label("Choose from Library", systemImage: "photo.fill")
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(14)
                                        .background(Color.gray)
                                        .cornerRadius(12)
                                }
                            }
                            .padding()
                        }
                        
                        // Results Section
                        if let food = identifiedFood {
                            VStack(spacing: 16) {
                                VStack(alignment: .leading, spacing: 12) {
                                    HStack {
                                        VStack(alignment: .leading, spacing: 4) {
                                            Text(food.name)
                                                .font(.headline)
                                                .foregroundColor(.primary)
                                            Text("Per 100g")
                                                .font(.caption)
                                                .foregroundColor(.secondary)
                                        }
                                        Spacer()
                                        Image(systemName: "checkmark.circle.fill")
                                            .foregroundColor(.green)
                                            .font(.system(size: 24))
                                    }
                                    
                                    Divider()
                                    
                                    // Nutrition Grid
                                    VStack(spacing: 12) {
                                        HStack(spacing: 12) {
                                            NutritionPill(label: "Calories", value: "\(Int(food.caloriesPer100g))", color: .red)
                                            NutritionPill(label: "Protein", value: "\(Int(food.proteinPer100g))g", color: .blue)
                                        }
                                        
                                        HStack(spacing: 12) {
                                            NutritionPill(label: "Carbs", value: "\(Int(food.carbsPer100g))g", color: .orange)
                                            NutritionPill(label: "Fats", value: "\(Int(food.fatsPer100g))g", color: .red)
                                        }
                                    }
                                    
                                    Divider()
                                    
                                    // Weight Input
                                    VStack(alignment: .leading, spacing: 8) {
                                        Text("Amount (grams)")
                                            .font(.caption)
                                            .foregroundColor(.secondary)
                                        
                                        HStack {
                                            TextField("100", text: $selectedWeight)
                                                .keyboardType(.numberPad)
                                                .font(.system(size: 16, weight: .semibold))
                                                .padding(12)
                                                .background(Color(.systemGray6))
                                                .cornerRadius(8)
                                                .frame(maxWidth: 100)
                                            
                                            Text("g")
                                                .foregroundColor(.secondary)
                                            
                                            Spacer()
                                            
                                            if let weight = Double(selectedWeight), weight > 0 {
                                                VStack(alignment: .trailing, spacing: 2) {
                                                    Text("\(Int(food.caloriesPer100g * weight / 100)) cal")
                                                        .font(.headline)
                                                        .foregroundColor(.red)
                                                    Text("for \(Int(weight))g")
                                                        .font(.caption)
                                                        .foregroundColor(.secondary)
                                                }
                                            }
                                        }
                                    }
                                }
                                .padding(16)
                                .background(Color(.systemGray6))
                                .cornerRadius(12)
                                
                                // Add to Daily Log Button
                                Button(action: addFoodToLog) {
                                    Label("Add to Today", systemImage: "plus.circle.fill")
                                        .foregroundColor(.white)
                                        .frame(maxWidth: .infinity)
                                        .padding(14)
                                        .background(
                                            LinearGradient(
                                                gradient: Gradient(colors: [Color(red: 0.86, green: 0.18, blue: 0.18), Color(red: 1, green: 0.34, blue: 0.36)]),
                                                startPoint: .topLeading,
                                                endPoint: .bottomTrailing
                                            )
                                        )
                                        .cornerRadius(12)
                                }
                            }
                            .transition(.opacity)
                        }
                        
                        Spacer(minLength: 20)
                    }
                    .padding()
                }
            }
        }
        .sheet(isPresented: $showingCamera) {
            CameraPicker(image: $selectedImage)
        }
        .onChange(of: selectedPhoto) { newValue in
            Task {
                if let data = try? await newValue?.loadTransferable(type: Data.self),
                   let uiImage = UIImage(data: data) {
                    selectedImage = uiImage
                }
            }
        }
        .alert("Error", isPresented: $showError) {
            Button("OK", role: .cancel) { }
        } message: {
            Text(errorMessage)
        }
    }
    
    private func resetImage() {
        selectedImage = nil
        identifiedFood = nil
        selectedWeight = "100"
    }
    
    private func identifyFood() {
        // This will be implemented when API key is added
        isLoading = true
        
        // Placeholder: simulate API call
        DispatchQueue.main.asyncAfter(deadline: .now() + 1.5) {
            identifiedFood = IdentifiedFood(
                name: "Chicken Breast",
                caloriesPer100g: 165,
                proteinPer100g: 31,
                carbsPer100g: 0,
                fatsPer100g: 3.6
            )
            isLoading = false
        }
    }
    
    private func addFoodToLog() {
        guard let food = identifiedFood,
              let weight = Double(selectedWeight), weight > 0 else {
            errorMessage = "Please enter a valid weight"
            showError = true
            return
        }
        
        let calories = Int(food.caloriesPer100g * weight / 100)
        let protein = food.proteinPer100g * weight / 100
        let carbs = food.carbsPer100g * weight / 100
        let fats = food.fatsPer100g * weight / 100
        
        let entry = CalorieEntry(
            date: Date(),
            calories: calories,
            protein: protein,
            carbs: carbs,
            fats: fats
        )
        
        store.entries.append(entry)
        resetImage()
    }
}

struct NutritionPill: View {
    let label: String
    let value: String
    let color: Color
    
    var body: some View {
        VStack(spacing: 6) {
            Text(label)
                .font(.caption)
                .foregroundColor(.secondary)
            
            Text(value)
                .font(.headline)
                .foregroundColor(color)
        }
        .frame(maxWidth: .infinity)
        .padding(12)
        .background(color.opacity(0.1))
        .cornerRadius(8)
    }
}

struct IdentifiedFood {
    let name: String
    let caloriesPer100g: Double
    let proteinPer100g: Double
    let carbsPer100g: Double
    let fatsPer100g: Double
}

struct CameraPicker: UIViewControllerRepresentable {
    @Binding var image: UIImage?
    @Environment(\.dismiss) var dismiss
    
    func makeUIViewController(context: Context) -> UIImagePickerController {
        let picker = UIImagePickerController()
        picker.sourceType = .camera
        picker.delegate = context.coordinator
        return picker
    }
    
    func updateUIViewController(_ uiViewController: UIImagePickerController, context: Context) {}
    
    func makeCoordinator() -> Coordinator {
        Coordinator(self)
    }
    
    class Coordinator: NSObject, UIImagePickerControllerDelegate, UINavigationControllerDelegate {
        let parent: CameraPicker
        
        init(_ parent: CameraPicker) {
            self.parent = parent
        }
        
        func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
            if let uiImage = info[.originalImage] as? UIImage {
                parent.image = uiImage
            }
            parent.dismiss()
        }
    }
}

#Preview {
    FoodIdentifierView()
        .environmentObject(CalorieStore())
}
