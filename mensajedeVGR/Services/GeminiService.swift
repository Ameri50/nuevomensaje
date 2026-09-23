import Foundation

enum GeminiServiceError: Error {
    case invalidAPIKey
    case invalidResponse
    case requestFailed(String)
}

/// Respuesta estructurada y "fundamentada" (grounding): Gemini solo puede
/// citar texto que ya le mandamos como contexto, nunca inventar.
struct GeminiGroundedResponse: Decodable {
    struct Cita: Decodable {
        let parrafo: Int
        let texto: String
    }

    let respuesta: String
    let citas: [Cita]
    let noEncontrado: Bool
}

final class GeminiService {
    private let apiKey: String
    private let baseURL = URL(string: "https://generativelanguage.googleapis.com/v1beta/models")!

    init(apiKey: String) {
        self.apiKey = apiKey
    }

    /// - Parameters:
    ///   - prompt: pregunta del usuario.
    ///   - context: párrafos reales, YA numerados, ej:
    ///     "[Párrafo 12] texto...\n\n[Párrafo 13] texto..."
    func ask(prompt: String, context: String) async throws -> GeminiGroundedResponse {
        guard !apiKey.isEmpty else {
            throw GeminiServiceError.invalidAPIKey
        }

        guard !context.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty else {
            return GeminiGroundedResponse(
                respuesta: "No encontré esa información en los mensajes disponibles en la aplicación.",
                citas: [],
                noEncontrado: true
            )
        }

        let model = "gemini-2.0-flash"
        let endpoint = baseURL.appendingPathComponent(model).appendingPathComponent(":generateContent")
        var urlRequest = URLRequest(url: endpoint)
        urlRequest.httpMethod = "POST"
        urlRequest.setValue("application/json", forHTTPHeaderField: "Content-Type")

        let instrucciones = """
        Eres un asistente que solo puede responder citando texto EXACTO del contexto provisto.

        Reglas obligatorias:
        1. No parafrasees, no resumas, no completes con conocimiento propio.
        2. Cada cita en "citas" debe ser copiada literalmente del contexto (sin cambiar palabras).
        3. "parrafo" debe ser el número real que aparece entre corchetes en el contexto, ej: [Párrafo 12].
        4. Si el contexto no contiene la respuesta, responde con noEncontrado=true, citas=[] y
           respuesta="No encontré esa información en los mensajes disponibles en la aplicación."
        5. No inventes números de párrafo ni texto que no esté en el contexto.
        6. Responde ÚNICAMENTE con JSON válido, sin texto adicional, sin backticks, con este formato exacto:
        {"respuesta": string, "noEncontrado": boolean, "citas": [{"parrafo": number, "texto": string}]}

        Pregunta: \(prompt)

        Contexto (párrafos reales de la biblioteca):
        \(context)
        """

        let payload: [String: Any] = [
            "contents": [[
                "parts": [
                    ["text": instrucciones]
                ]
            ]],
            "generationConfig": [
                "temperature": 0,
                "maxOutputTokens": 800,
                "responseMimeType": "application/json"
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

        let textoBruto = parts.compactMap { $0["text"] as? String }.joined()
        let textoLimpio = limpiarJSON(textoBruto)

        guard let jsonData = textoLimpio.data(using: .utf8),
              let estructurado = try? JSONDecoder().decode(GeminiGroundedResponse.self, from: jsonData) else {
            // Si Gemini no devolvió JSON válido, no inventamos nada: lo tratamos como "no encontrado".
            return GeminiGroundedResponse(
                respuesta: "No encontré esa información en los mensajes disponibles en la aplicación.",
                citas: [],
                noEncontrado: true
            )
        }

        return estructurado
    }

    /// Por si el modelo igual envuelve el JSON en ```json ... ``` a pesar de la instrucción.
    private func limpiarJSON(_ texto: String) -> String {
        var limpio = texto.trimmingCharacters(in: .whitespacesAndNewlines)
        if limpio.hasPrefix("```") {
            limpio = limpio.replacingOccurrences(of: "```json", with: "")
            limpio = limpio.replacingOccurrences(of: "```", with: "")
        }
        return limpio.trimmingCharacters(in: .whitespacesAndNewlines)
    }
}
