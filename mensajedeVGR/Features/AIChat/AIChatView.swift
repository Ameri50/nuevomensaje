import SwiftUI
import SwiftData

/// Pon aquí tu API key de Gemini (o mejor, cárgala desde Info.plist /
/// tu Cloud Function proxy con App Check, como en tus otros proyectos).
enum GeminiConfig {
    static let apiKey: String = "TU_API_KEY_DE_GEMINI"
}

/// Palabras muy comunes en español que no aportan nada a la búsqueda
/// (si no las filtramos, "Donde" o "habla" dominan el ranking y ensucian
/// los resultados).
private let palabrasVacias: Set<String> = [
    "donde", "dónde", "que", "qué", "habla", "hablan", "cual", "cuál",
    "como", "cómo", "cuando", "cuándo", "para", "por", "con", "los",
    "las", "del", "una", "uno", "esta", "este", "sobre", "acerca"
]

struct AIChatView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \AIChatMessage.timestamp, order: .reverse) private var messages: [AIChatMessage]
    @EnvironmentObject private var localization: LocalizationManager
    @State private var inputText: String = ""
    @State private var isLoading = false
    @State private var errorMensaje: String?

    private let geminiService = GeminiService(apiKey: GeminiConfig.apiKey)

    /// Máximo de párrafos que se mandan como contexto (para no pasarse de tokens).
    private let maxParrafosContexto = 8
    /// Máximo de caracteres por párrafo dentro del contexto.
    private let maxCaracteresPorParrafo = 600

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                if messages.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bubble.right")
                            .font(.system(size: 48))
                            .foregroundStyle(.blue)

                        Text(localization.getString("homeAskMessages"))
                            .font(.headline)

                        Text(localization.getString("aiChatHint"))
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
                } else {
                    ScrollView {
                        VStack(alignment: .leading, spacing: 12) {
                            ForEach(messages.reversed()) { message in
                                ChatBubble(message: message)
                            }
                        }
                        .padding()
                    }
                }

                if let errorMensaje {
                    Text(errorMensaje)
                        .font(.caption)
                        .foregroundStyle(.red)
                        .padding(.horizontal)
                }

                VStack(spacing: 0) {
                    Divider()

                    HStack(spacing: 12) {
                        TextField(localization.getString("aiChatPlaceholder"), text: $inputText)
                            .textFieldStyle(.roundedBorder)
                            .disabled(isLoading)

                        Button(action: sendMessage) {
                            if isLoading {
                                ProgressView()
                                    .frame(width: 44, height: 44)
                            } else {
                                Image(systemName: "paperplane.fill")
                                    .font(.system(size: 16))
                                    .frame(width: 44, height: 44)
                                    .background(Color.blue)
                                    .foregroundStyle(.white)
                                    .clipShape(Circle())
                            }
                        }
                        .disabled(inputText.trimmingCharacters(in: .whitespaces).isEmpty || isLoading)
                    }
                    .padding()
                }
            }
            .navigationTitle(localization.getString("tabAI"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }

    private func sendMessage() {
        let pregunta = inputText.trimmingCharacters(in: .whitespaces)
        guard !pregunta.isEmpty else { return }

        errorMensaje = nil
        isLoading = true
        inputText = ""

        let userMessage = AIChatMessage(role: "user", text: pregunta, timestamp: .now, sourceSummary: "")
        modelContext.insert(userMessage)
        try? modelContext.save()

        Task {
            do {
                let (contexto, resumenFuentes) = buscarContextoReal(query: pregunta)
                let resultado = try await geminiService.ask(prompt: pregunta, context: contexto)

                await MainActor.run {
                    let aiResponse = AIChatMessage(
                        role: "assistant",
                        text: resultado.respuesta,
                        timestamp: .now,
                        sourceSummary: resultado.noEncontrado ? "" : resumenFuentes
                    )
                    modelContext.insert(aiResponse)
                    try? modelContext.save()
                    isLoading = false
                }
            } catch {
                await MainActor.run {
                    errorMensaje = "No se pudo consultar la IA: \(error.localizedDescription)"
                    isLoading = false
                }
            }
        }
    }

    /// Busca directamente por PALABRAS CLAVE dentro de los párrafos reales
    /// (no por la pregunta completa como frase literal, que casi nunca
    /// coincide) y arma el contexto que se le manda a Gemini.
    private func buscarContextoReal(query: String) -> (contexto: String, resumenFuentes: String) {
        let terminos = query
            .lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)
            .components(separatedBy: CharacterSet.alphanumerics.inverted)
            .filter { $0.count > 2 && !palabrasVacias.contains($0) }

        guard !terminos.isEmpty else { return ("", "") }

        let fetch = FetchDescriptor<ParagraphRecord>()
        let todosLosParrafos = (try? modelContext.fetch(fetch)) ?? []

        let parrafosCandidatos = todosLosParrafos
            .map { parrafo in (parrafo: parrafo, puntaje: puntaje(texto: parrafo.text, terminos: terminos)) }
            .filter { $0.puntaje > 0 }
            .sorted { $0.puntaje > $1.puntaje }
            .prefix(maxParrafosContexto)

        guard !parrafosCandidatos.isEmpty else { return ("", "") }

        var contexto = ""
        var idsSermonesUsados: Set<UUID> = []

        for candidato in parrafosCandidatos {
            let textoRecortado = String(candidato.parrafo.text.prefix(maxCaracteresPorParrafo))
            contexto += "[Párrafo \(candidato.parrafo.number)] \(textoRecortado)\n\n"
            idsSermonesUsados.insert(candidato.parrafo.sermonID)
        }

        let sermonFetch = FetchDescriptor<SermonRecord>()
        let todosLosSermones = (try? modelContext.fetch(sermonFetch)) ?? []
        let codigosUsados = todosLosSermones
            .filter { idsSermonesUsados.contains($0.id) }
            .map { $0.code }
            .sorted()

        let resumenFuentes = codigosUsados.isEmpty ? "" : "Fuentes: \(codigosUsados.joined(separator: ", "))"
        return (contexto, resumenFuentes)
    }

    private func puntaje(texto: String, terminos: [String]) -> Int {
        let textoLower = texto
            .lowercased()
            .folding(options: .diacriticInsensitive, locale: .current)
        return terminos.reduce(0) { total, termino in
            total + (textoLower.contains(termino) ? 1 : 0)
        }
    }
}

// MARK: - Chat Bubble Component

struct ChatBubble: View {
    let message: AIChatMessage

    var isUser: Bool {
        message.role == "user"
    }

    var body: some View {
        HStack(spacing: 0) {
            if isUser {
                Spacer()
            }

            VStack(alignment: isUser ? .trailing : .leading, spacing: 4) {
                Text(message.text)
                    .font(.body)
                    .padding(12)
                    .background(isUser ? Color.blue : Color(.secondarySystemBackground))
                    .foregroundStyle(isUser ? .white : .primary)
                    .clipShape(RoundedRectangle(cornerRadius: 12))

                if !message.sourceSummary.isEmpty {
                    Text(message.sourceSummary)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
            }

            if !isUser {
                Spacer()
            }
        }
        .padding(.vertical, 4)
    }
}

#Preview {
    AIChatView()
        .environmentObject(LocalizationManager.shared)
}
