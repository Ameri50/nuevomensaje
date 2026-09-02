import SwiftUI
import SwiftData

struct AIChatView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var query = ""
    @State private var messages: [String] = [
        "¿Qué enseñó Branham sobre la mujer y el hombre?"
    ]
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            VStack {
                ScrollView {
                    VStack(alignment: .leading, spacing: 12) {
                        ForEach(messages.indices, id: \ .self) { index in
                            HStack {
                                if index % 2 == 0 {
                                    Spacer()
                                }
                                Text(messages[index])
                                    .padding(12)
                                    .background(index % 2 == 0 ? Color.blue.opacity(0.12) : Color(.secondarySystemBackground))
                                    .clipShape(RoundedRectangle(cornerRadius: 12))
                                if index % 2 != 0 {
                                    Spacer()
                                }
                            }
                        }

                        if isLoading {
                            ProgressView()
                                .padding()
                        }
                    }
                    .padding()
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Usa solo contenido local del catálogo disponible en la app, sin descargar audios ni libros completos.")
                        .font(.caption)
                        .foregroundStyle(.secondary)

                    HStack {
                        TextField("Haz una pregunta sobre los mensajes", text: $query)
                            .textFieldStyle(.roundedBorder)
                        Button("Enviar") {
                            submitQuestion()
                        }
                        .buttonStyle(.borderedProminent)
                    }
                }
                .padding()
            }
            .navigationTitle("Pregúntale a los Mensajes")
        }
    }

    private func submitQuestion() {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return }

        messages.append(trimmed)
        query = ""
        isLoading = true

        let sources = DemoLibraryService.shared.search(context: modelContext, query: trimmed)
        let context = sources.map { "\($0.code) — \($0.title): \($0.body)" }.joined(separator: "\n\n")

        Task {
            do {
                let service = GeminiService(apiKey: Secrets.geminiAPIKey)
                let reply = try await service.ask(prompt: trimmed, context: context.isEmpty ? "No se encontraron mensajes relevantes en el catálogo local." : context)
                messages.append(reply)
            } catch {
                messages.append("No encontré esa información en los mensajes disponibles en la aplicación.")
            }
            isLoading = false
        }
    }
}

#Preview {
    AIChatView()
        .modelContainer(for: [SermonRecord.self, ParagraphRecord.self, FavoriteRecord.self, NoteRecord.self], inMemory: true)
}
