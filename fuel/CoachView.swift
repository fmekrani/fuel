import SwiftUI
import UIKit

// MARK: - Chat Message Model
struct ChatMessage: Identifiable {
    let id = UUID()
    let role: String // "user" or "assistant"
    let content: String
    let timestamp: Date = Date()
}

// MARK: - Coach View (Personal Trainer Chat)
struct CoachView: View {
    @State private var messages: [ChatMessage] = [
        ChatMessage(role: "assistant", content: "Hey! 💪 I'm your personal fitness coach. Ask me anything about workouts, nutrition, form tips, or your fitness journey!")
    ]
    @State private var inputText: String = ""
    @State private var isLoading: Bool = false
    @State private var hasAPIKey: Bool = UserDefaults.standard.string(forKey: "openai_api_key") != nil
    @EnvironmentObject var store: CalorieStore
    @EnvironmentObject var workoutHistory: WorkoutHistoryStore
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // Messages List
                ScrollViewReader { proxy in
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(messages) { message in
                                ChatBubble(message: message)
                                    .id(message.id)
                            }
                            
                            if isLoading {
                                HStack(spacing: 8) {
                                    Circle()
                                        .fill(Theme.accent)
                                        .frame(width: 8)
                                        .opacity(0.6)
                                    Circle()
                                        .fill(Theme.accent)
                                        .frame(width: 8)
                                        .opacity(0.8)
                                    Circle()
                                        .fill(Theme.accent)
                                        .frame(width: 8)
                                    
                                    Spacer()
                                }
                                .padding(.horizontal, 16)
                                .padding(.vertical, 8)
                            }
                        }
                        .padding(16)
                    }
                    .onChange(of: messages.count) { _, _ in
                        withAnimation {
                            proxy.scrollTo(messages.last?.id, anchor: .bottom)
                        }
                    }
                }
                
                Divider()
                
                // Input Area
                VStack(spacing: 12) {
                    if !hasAPIKey {
                        VStack(spacing: 10) {
                            Image(systemName: "key.fill")
                                .font(.system(size: 24))
                                .foregroundColor(Theme.accent)
                            
                            Text("API Key Required")
                                .font(.headline)
                            
                            Text("Set your OpenAI API key to start chatting with your coach")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                            
                            NavigationLink(destination: APIKeySettingsView(hasAPIKey: $hasAPIKey)) {
                                Label("Add API Key", systemImage: "gear")
                                    .frame(maxWidth: .infinity)
                            }
                            .buttonStyle(.borderedProminent)
                        }
                        .padding(16)
                        .frame(maxWidth: .infinity)
                        .background(Color(.systemGray6))
                        .cornerRadius(12)
                        .padding(16)
                    } else {
                        HStack(spacing: 8) {
                            TextField("Ask your coach...", text: $inputText)
                                .textFieldStyle(.roundedBorder)
                                .disabled(isLoading)
                            
                            Button(action: sendMessage) {
                                Image(systemName: "paperplane.fill")
                                    .font(.system(size: 16))
                            }
                            .buttonStyle(.borderedProminent)
                            .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
                        }
                        .padding(16)
                        .background(Color(.systemBackground))
                    }
                }
            }
            .navigationTitle("Coach")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    NavigationLink(destination: APIKeySettingsView(hasAPIKey: $hasAPIKey)) {
                        Image(systemName: "gear")
                            .foregroundColor(.black)
                    }
                }
            }
        }
    }
    
    private func sendMessage() {
        let userMessage = inputText.trimmingCharacters(in: .whitespaces)
        guard !userMessage.isEmpty else { return }
        
        messages.append(ChatMessage(role: "user", content: userMessage))
        inputText = ""
        isLoading = true
        
        let context = buildContext()
        let systemPrompt = "You are an expert personal fitness coach. You provide personalized advice based on the user's fitness data: \(context). Be encouraging, knowledgeable, and practical. Keep responses concise (2-3 sentences)."
        
        Task {
            do {
                var conversationHistory = messages.dropLast().map {
                    OpenAIMessage(role: $0.role, content: $0.content)
                }
                
                if conversationHistory.isEmpty {
                    conversationHistory.append(OpenAIMessage(role: "system", content: systemPrompt))
                }
                
                let response = try await OpenAIService.shared.sendMessage(userMessage, conversationHistory: Array(conversationHistory))
                
                DispatchQueue.main.async {
                    messages.append(ChatMessage(role: "assistant", content: response))
                    isLoading = false
                }
            } catch {
                DispatchQueue.main.async {
                    messages.append(ChatMessage(role: "assistant", content: "Sorry, I couldn't process that. Please try again. Error: \(error.localizedDescription)"))
                    isLoading = false
                }
            }
        }
    }
    
    private func buildContext() -> String {
        let todayCalories = store.consumedToday
        let dailyGoal = store.dailyGoal ?? 2500
        let macros = store.macrosToday
        let weekAvg = store.dailyAverage
        let workoutCount = workoutHistory.sessions.filter {
            Calendar.current.isDate($0.date, inSameDayAs: Date())
        }.count
        
        return """
        Today: \(todayCalories)/\(dailyGoal) kcal, Protein: \(Int(macros.protein))g, Carbs: \(Int(macros.carbs))g, Fats: \(Int(macros.fats))g.
        7-day average: \(weekAvg) kcal/day.
        Workouts today: \(workoutCount).
        """
    }
}

// MARK: - Chat Bubble Component
struct ChatBubble: View {
    let message: ChatMessage
    
    var body: some View {
        HStack(alignment: .bottom, spacing: 8) {
            if message.role == "assistant" {
                VStack(alignment: .leading, spacing: 4) {
                    Text(message.content)
                        .font(.body)
                        .foregroundColor(.black)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Color(.systemGray5))
                        )
                }
                
                Spacer()
            } else {
                Spacer()
                
                VStack(alignment: .trailing, spacing: 4) {
                    Text(message.content)
                        .font(.body)
                        .foregroundColor(.white)
                        .padding(12)
                        .background(
                            RoundedRectangle(cornerRadius: 16)
                                .fill(Theme.gradient)
                        )
                }
            }
        }
        .padding(.horizontal, 4)
    }
}

// MARK: - API Key Settings View
struct APIKeySettingsView: View {
    @Binding var hasAPIKey: Bool
    @State private var apiKeyInput: String = UserDefaults.standard.string(forKey: "openai_api_key") ?? ""
    @State private var showSaveSuccess: Bool = false
    @State private var showError: Bool = false
    @Environment(\.dismiss) var dismiss
    
    var body: some View {
        Form {
            Section("OpenAI API Key") {
                VStack(alignment: .leading, spacing: 12) {
                    Text("Enter your OpenAI API key. You can type or paste it below.")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    
                    TextEditor(text: $apiKeyInput)
                        .frame(height: 80)
                        .border(Color.gray, width: 1)
                        .cornerRadius(6)
                        .font(.caption)
                    
                    HStack(spacing: 8) {
                        Button(action: pasteFromClipboard) {
                            Label("Paste", systemImage: "doc.on.clipboard")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                        
                        Button(action: clearInput) {
                            Label("Clear", systemImage: "xmark.circle")
                                .font(.caption)
                        }
                        .buttonStyle(.bordered)
                    }
                }
                .padding(.vertical, 8)
            }
            
            Section {
                Button(action: saveAPIKey) {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                        Text("Save API Key")
                    }
                }
                .buttonStyle(.borderedProminent)
                .frame(maxWidth: .infinity)
                .disabled(apiKeyInput.trimmingCharacters(in: .whitespaces).isEmpty)
            }
            
            Section("Instructions") {
                VStack(alignment: .leading, spacing: 8) {
                    Text("1. Open openai.com in Safari")
                        .font(.caption)
                    
                    Text("2. Sign in to your account")
                        .font(.caption)
                    
                    Text("3. Go to API Keys → Create new secret key")
                        .font(.caption)
                    
                    Text("4. Copy the key")
                        .font(.caption)
                    
                    Text("5. Return here and tap 'Paste' button")
                        .font(.caption)
                    
                    Text("6. Tap 'Save API Key'")
                        .font(.caption)
                }
                .foregroundStyle(.secondary)
            }
            
            if hasAPIKey {
                Section {
                    HStack {
                        Image(systemName: "checkmark.circle.fill")
                            .foregroundColor(.green)
                        Text("API Key is saved")
                            .font(.caption)
                        Spacer()
                    }
                    
                    Button(role: .destructive) {
                        removeAPIKey()
                    } label: {
                        HStack {
                            Image(systemName: "trash.fill")
                            Text("Remove API Key")
                        }
                        .frame(maxWidth: .infinity)
                    }
                }
            }
        }
        .navigationTitle("API Key Settings")
        .alert("Success!", isPresented: $showSaveSuccess) {
            Button("OK") {
                dismiss()
            }
        } message: {
            Text("API key saved successfully! You can now chat with your coach.")
        }
        .alert("Error", isPresented: $showError) {
            Button("OK") { }
        } message: {
            Text("Please enter a valid API key before saving.")
        }
    }
    
    private func pasteFromClipboard() {
        if let pasteboard = UIPasteboard.general.string {
            apiKeyInput = pasteboard
        }
    }
    
    private func clearInput() {
        apiKeyInput = ""
    }
    
    private func saveAPIKey() {
        let trimmed = apiKeyInput.trimmingCharacters(in: .whitespaces)
        guard !trimmed.isEmpty else {
            showError = true
            return
        }
        
        OpenAIService.shared.setAPIKey(trimmed)
        hasAPIKey = true
        showSaveSuccess = true
    }
    
    private func removeAPIKey() {
        UserDefaults.standard.removeObject(forKey: "openai_api_key")
        hasAPIKey = false
        apiKeyInput = ""
    }
}

#Preview {
    CoachView()
        .environmentObject(CalorieStore())
        .environmentObject(WorkoutHistoryStore())
}
