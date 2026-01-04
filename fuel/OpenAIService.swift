import Foundation

// MARK: - OpenAI Models
struct OpenAIMessage: Codable {
    let role: String // "user" or "assistant"
    let content: String
}

struct OpenAIRequest: Codable {
    let model: String = "gpt-3.5-turbo"
    let messages: [OpenAIMessage]
    let temperature: Double = 0.7
    let max_tokens: Int = 500
}

struct OpenAIResponse: Codable {
    let choices: [Choice]
    
    struct Choice: Codable {
        let message: OpenAIMessage
    }
}

// MARK: - OpenAI Service
class OpenAIService {
    static let shared = OpenAIService()
    
    private let apiKey = "your-api-key-here" // User will add their key here
    private let apiEndpoint = "https://api.openai.com/v1/chat/completions"
    
    func setAPIKey(_ key: String) {
        // In production, store this securely in Keychain
        UserDefaults.standard.set(key, forKey: "openai_api_key")
    }
    
    private func getAPIKey() -> String? {
        // Retrieve from secure storage
        return UserDefaults.standard.string(forKey: "openai_api_key") ?? apiKey
    }
    
    func sendMessage(_ userMessage: String, conversationHistory: [OpenAIMessage]) async throws -> String {
        guard let apiKey = getAPIKey(), !apiKey.isEmpty else {
            throw NSError(domain: "OpenAI", code: -1, userInfo: [NSLocalizedDescriptionKey: "API key not set"])
        }
        
        // Build conversation with system prompt
        var messages = conversationHistory
        messages.append(OpenAIMessage(role: "user", content: userMessage))
        
        let request = OpenAIRequest(messages: messages)
        
        var urlRequest = URLRequest(url: URL(string: apiEndpoint)!)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")
        urlRequest.setValue("Bearer \(apiKey)", forHTTPHeaderField: "Authorization")
        urlRequest.httpBody = try JSONEncoder().encode(request)
        
        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        
        guard let httpResponse = response as? HTTPURLResponse, httpResponse.statusCode == 200 else {
            throw NSError(domain: "OpenAI", code: -2, userInfo: [NSLocalizedDescriptionKey: "API request failed"])
        }
        
        let decodedResponse = try JSONDecoder().decode(OpenAIResponse.self, from: data)
        
        guard let assistantMessage = decodedResponse.choices.first?.message.content else {
            throw NSError(domain: "OpenAI", code: -3, userInfo: [NSLocalizedDescriptionKey: "No response from AI"])
        }
        
        return assistantMessage
    }
}
