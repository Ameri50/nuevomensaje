import SwiftUI
import SwiftData

struct AIChatView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \AIChatMessage.timestamp, order: .forward) private var messages: [AIChatMessage]
    @EnvironmentObject private var localization: LocalizationManager
    @State private var inputText: String = ""
    @State private var isLoading = false
    @State private var errorMessage: String? = nil
    @State private var showDeleteConfirmation = false
    
    // ✅ Instancia del servicio Gemini - lee desde Secrets.swift via GeminiConfig
    private let geminiService = GeminiService(apiKey: GeminiConfig.apiKey)
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                // MARK: - Chat Messages
                if messages.isEmpty {
                    VStack(spacing: 16) {
                        Image(systemName: "bubble.right")
                            .font(.system(size: 48))
                            .foregroundStyle(.blue)
                        
                        Text(localization.getString("homeAskMessages"))
                            .font(.headline)
                        
                        Text("Haz preguntas sobre los mensajes de William Branham")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity, maxHeight: .infinity)
                    .background(Color(.systemBackground))
                } else {
                    ScrollViewReader { scrollProxy in
                        ScrollView {
                            VStack(alignment: .leading, spacing: 12) {
                                ForEach(messages) { message in
                                    ChatBubble(message: message)
                                        .id(message.id)
                                }
                            }
                            .padding()
                        }
                        .onChange(of: messages.count) { oldCount, newCount in
                            if newCount > oldCount, let lastMessage = messages.last {
                                withAnimation {
                                    scrollProxy.scrollTo(lastMessage.id, anchor: .bottom)
                                }
                            }
                        }
                    }
                }
                
                // MARK: - Error Alert
                if let error = errorMessage {
                    VStack(spacing: 8) {
                        HStack {
                            Image(systemName: "exclamationmark.circle.fill")
                                .foregroundStyle(.red)
                            Text(error)
                                .font(.caption)
                                .foregroundStyle(.red)
                            Spacer()
                            Button(action: { errorMessage = nil }) {
                                Image(systemName: "xmark")
                                    .font(.caption)
                                    .foregroundStyle(.red)
                            }
                        }
                        .padding(12)
                        .background(Color.red.opacity(0.1))
                        .cornerRadius(8)
                        .padding()
                    }
                }
                
                // MARK: - Input Area
                VStack(spacing: 0) {
                    Divider()
                    
                    HStack(spacing: 12) {
                        TextField("Pregunta...", text: $inputText)
                            .textFieldStyle(.roundedBorder)
                            .disabled(isLoading)
                        
                        Button(action: {
                            Task {
                                await sendMessage()
                            }
                        }) {
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
                        .disabled(inputText.isEmpty || isLoading)
                    }
                    .padding()
                }
            }
            .navigationTitle(localization.getString("tabAI"))
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItemGroup(placement: .topBarTrailing) {
                    ShareLink(item: conversationText) {
                        Image(systemName: "square.and.arrow.up")
                    }
                    .disabled(messages.isEmpty)
                    .accessibilityLabel("Compartir conversación")

                    Button {
                        showDeleteConfirmation = true
                    } label: {
                        Image(systemName: "trash")
                    }
                    .disabled(messages.isEmpty || isLoading)
                    .accessibilityLabel("Eliminar conversación")
                }
            }
            .confirmationDialog("¿Eliminar conversación?", isPresented: $showDeleteConfirmation, titleVisibility: .visible) {
                Button("Eliminar", role: .destructive, action: deleteConversation)
                Button("Cancelar", role: .cancel) { }
            } message: {
                Text("Se eliminarán todas las preguntas y respuestas guardadas.")
            }
        }
    }

    private var conversationText: String {
        messages.map { message in
            "\(message.role == "user" ? "Pregunta" : "Respuesta"):\n\(message.text)"
        }.joined(separator: "\n\n")
    }

    private func deleteConversation() {
        for message in messages {
            modelContext.delete(message)
        }
        try? modelContext.save()
        errorMessage = nil
    }
    
    // ✅ Función que llama a Gemini de verdad
    private func sendMessage() async {
        let userInput = inputText.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !userInput.isEmpty else { return }
        
        isLoading = true
        errorMessage = nil
        
        // Guardar mensaje del usuario
        let userMessage = AIChatMessage(
            role: "user",
            text: userInput,
            timestamp: .now,
            sourceSummary: ""
        )
        modelContext.insert(userMessage)
        inputText = ""
        
        // Obtener contexto de los sermones
        let context = getContextFromSermons(query: userInput)
        
        // ✅ LLAMADA REAL A GEMINI
        do {
            // GeminiService.ask() retorna GeminiResponse
            let geminiResponse = try await geminiService.ask(prompt: userInput, context: context)
            
            // ✅ Acceder al campo .respuesta de GeminiResponse
            let aiMessage = AIChatMessage(
                role: "assistant",
                text: geminiResponse.respuesta,
                timestamp: .now,
                sourceSummary: ""
            )
            modelContext.insert(aiMessage)
        } catch let error as GeminiServiceError {
            errorMessage = error.errorDescription ?? "No se pudo obtener una respuesta."
        } catch {
            errorMessage = "No se pudo obtener una respuesta. Comprueba la conexión e inténtalo de nuevo."
        }
        
        isLoading = false
    }
    
    // Obtener contexto de sermones para pasar a Gemini
    private func getContextFromSermons(query: String) -> String {
        let sermons = DemoLibraryService.shared.allMessages(context: modelContext)
        let terms = searchTerms(from: query)

        let rankedSermons: [(sermon: SermonRecord, score: Int)] = sermons
            .map { sermon in
                let searchableText = normalized("\(sermon.title) \(sermon.code) \(sermon.location) \(sermon.body)")
                let score = terms.reduce(into: 0) { result, term in
                    if searchableText.contains(term) { result += 1 }
                }
                return (sermon, score)
            }
            .sorted { first, second in
                if first.score == second.score {
                    return first.sermon.title < second.sermon.title
                }
                return first.score > second.score
            }

        let selectedSermons = rankedSermons.filter { $0.score > 0 }.prefix(8)
        let fallbackSermons = selectedSermons.isEmpty ? rankedSermons.prefix(6) : selectedSermons

        let context = fallbackSermons.map { item in
            let paragraphs = item.sermon.body.components(separatedBy: "\n\n")
            let relevantParagraphs = paragraphs.enumerated().filter { _, paragraph in
                terms.isEmpty || terms.contains { normalized(paragraph).contains($0) }
            }
            let paragraphsToInclude = relevantParagraphs.isEmpty
                ? Array(paragraphs.prefix(6).enumerated())
                : Array(relevantParagraphs.prefix(12))
            let formattedParagraphs = paragraphsToInclude
                .map { "[Sermón: \(item.sermon.code)] [Párrafo: \($0.offset + 1)] \($0.element)" }
                .joined(separator: "\n")
            return "[Sermón: \(item.sermon.code)] \(item.sermon.title)\n\(formattedParagraphs)"
        }.joined(separator: "\n\n")

        return String(context.prefix(24000))
    }

    private func searchTerms(from query: String) -> [String] {
        let stopWords: Set<String> = [
            "a", "al", "como", "con", "cual", "cuando", "de", "del", "donde",
            "el", "en", "es", "esta", "estas", "este", "esto", "hay", "la", "las",
            "lo", "los", "me", "para", "por", "que", "se", "sobre", "su", "un", "una",
            "y"
        ]

        return normalized(query)
            .split(whereSeparator: { $0.isWhitespace || $0.isPunctuation })
            .map(String.init)
            .filter { $0.count >= 3 && !stopWords.contains($0) }
    }

    private func normalized(_ value: String) -> String {
        value
            .folding(options: [.diacriticInsensitive, .caseInsensitive], locale: .current)
            .lowercased()
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
