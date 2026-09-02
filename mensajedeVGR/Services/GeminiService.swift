import Foundation

enum GeminiServiceError: Error {
    case invalidAPIKey
    case invalidResponse
    case requestFailed(String)
}

final class GeminiService {
    private let apiKey: String
    private let baseURL = URL(string: "https://generativelanguage.googleapis.com/v1beta/models")!

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    func ask(prompt: String, context: String) async throws -> String {
        guard !apiKey.isEmpty else {
            throw GeminiServiceError.invalidAPIKey
        }

        let model = "gemini-2.0-flash"
        let endpoint = baseURL.appendingPathComponent(model).appendingPathComponent(":generateContent")
        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let payload: [String: Any] = [
            "contents": [[
                "parts": [
                    ["text": "Responde usando solo el contexto provisto. Si no hay suficiente información, responde: \"No encontré esa información en los mensajes disponibles en la aplicación.\"\n\nPregunta: \(prompt)\n\nContexto:\n\(context)"]
                ]
            ]],
            "generationConfig": [
                "temperature": 0.2,
                "maxOutputTokens": 800
            ]
        ]

        urlRequest.httpBody = try JSONSerialization.data(withJSONObject: payload)

        let queryItems = [URLQueryItem(name: "key", value: apiKey)]
        var components = URLComponents(url: endpoint, resolvingAgainstBaseURL: false)
        components?.queryItems = queryItems
        urlRequest.url = components?.url

        let (data, response) = try await URLSession.shared.data(for: urlRequest)
        guard let httpResponse = response as? HTTPURLResponse, 200...299 ~= httpResponse.statusCode else {
            let body = String(data: data, encoding: .utf8) ?? ""
            throw GeminiServiceError.requestFailed(body)
        }

        guard let json = try JSONSerialization.jsonObject(with: data) as? [String: Any],
              let candidates = json["candidates"] as? [[String: Any]],
              let firstCandidate = candidates.first,
              let content = firstCandidate["content"] as? [String: Any],
              let parts = content["parts"] as? [[String: Any]] else {
            throw GeminiServiceError.invalidResponse
        }

        let text = parts.compactMap { $0["text"] as? String }.joined(separator: "\n")
        return text.isEmpty ? "No encontré suficiente información en los mensajes disponibles." : text
    }
}
