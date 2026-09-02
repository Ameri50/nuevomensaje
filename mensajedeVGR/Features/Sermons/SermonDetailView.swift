import SwiftUI
import SwiftData

struct SermonDetailView: View {
    @Environment(\.modelContext) private var modelContext

    let sermon: SermonRecord

    @State private var isFavorite = false
    @State private var noteText = ""
    @State private var paragraphs: [ParagraphRecord] = []

    private var fullBodyText: String {
        let trimmed = sermon.body.trimmingCharacters(in: .whitespacesAndNewlines)
        if !trimmed.isEmpty {
            return trimmed
        }
        return paragraphs.sorted { $0.number < $1.number }.map(\.text).joined(separator: "\n\n")
    }

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                VStack(alignment: .leading, spacing: 5) {
                    Text(sermon.code)
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Text(sermon.title)
                        .font(.title2.bold())
                    Text("\(sermon.location) · \(sermon.language)")
                        .foregroundStyle(.secondary)
                }

                HStack(spacing: 12) {
                    Label(sermon.date?.formatted(date: .abbreviated, time: .omitted) ?? "Sin fecha", systemImage: "calendar")
                    Spacer()
                    Label("\(sermon.durationMinutes) min", systemImage: "clock")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)

                HStack {
                    Button(action: toggleFavorite) {
                        Label(isFavorite ? "Favorito" : "Guardar", systemImage: isFavorite ? "star.fill" : "star")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.borderedProminent)

                    Button(action: { /* futuro: reproducir audio local autorizado */ }) {
                        Label("Escuchar", systemImage: "play.fill")
                            .frame(maxWidth: .infinity)
                    }
                    .buttonStyle(.bordered)
                    .disabled(sermon.audioURL == nil)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Text("Mensaje completo")
                        .font(.headline)
                    Text(fullBodyText)
                        .font(.body)
                        .fixedSize(horizontal: false, vertical: true)
                        .lineSpacing(7)
                        .frame(maxWidth: .infinity, alignment: .leading)
                }

                VStack(alignment: .leading, spacing: 12) {
                    Text("Párrafos")
                        .font(.headline)

                    ForEach(paragraphs.sorted { $0.number < $1.number }) { paragraph in
                        VStack(alignment: .leading, spacing: 6) {
                            Text("Párrafo \(paragraph.number)")
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(paragraph.text)
                                .font(.body)
                                .fixedSize(horizontal: false, vertical: true)
                                .lineSpacing(5)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                }

                VStack(alignment: .leading, spacing: 10) {
                    Text("Mis notas")
                        .font(.headline)
                    TextEditor(text: $noteText)
                        .frame(minHeight: 140)
                        .padding(8)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    Button("Guardar nota") {
                        saveNote()
                    }
                    .buttonStyle(.borderedProminent)
                }

                VStack(alignment: .leading, spacing: 8) {
                    Label("Fuente: \(sermon.source)", systemImage: "link")
                    Label("Idioma: \(sermon.language)", systemImage: "globe")
                    Label("Audio disponible: \(sermon.audioURL == nil ? "No" : "Sí")", systemImage: sermon.audioURL == nil ? "xmark.circle" : "play.circle")
                    Label("Importación autorizada solo: no se descargan libros o audios completos sin permiso explícito.", systemImage: "shield.checkered")
                }
                .font(.subheadline)
                .foregroundStyle(.secondary)
            }
            .padding()
        }
        .navigationTitle("Detalle")
        .navigationBarTitleDisplayMode(.inline)
        .onAppear {
            loadState()
        }
    }

    private func loadState() {
        paragraphs = fetchParagraphs()
        isFavorite = hasFavorite()
        noteText = fetchNote() ?? ""
    }

    private func fetchParagraphs() -> [ParagraphRecord] {
        let descriptor = FetchDescriptor<ParagraphRecord>(sortBy: [SortDescriptor(\.number)])
        let paragraphs = (try? modelContext.fetch(descriptor)) ?? []
        return paragraphs.filter { $0.sermonID == sermon.id }
    }

    private func hasFavorite() -> Bool {
        let descriptor = FetchDescriptor<FavoriteRecord>()
        let favorites = (try? modelContext.fetch(descriptor)) ?? []
        return favorites.contains { $0.sermonID == sermon.id }
    }

    private func fetchNote() -> String? {
        let descriptor = FetchDescriptor<NoteRecord>()
        let notes = (try? modelContext.fetch(descriptor)) ?? []
        return notes.first { $0.sermonID == sermon.id }?.text
    }

    private func toggleFavorite() {
        let descriptor = FetchDescriptor<FavoriteRecord>()
        let favorites = (try? modelContext.fetch(descriptor)) ?? []

        if isFavorite {
            if let favorite = favorites.first(where: { $0.sermonID == sermon.id }) {
                modelContext.delete(favorite)
            }
            isFavorite = false
        } else {
            let favorite = FavoriteRecord(type: "sermon", sermonID: sermon.id)
            modelContext.insert(favorite)
            isFavorite = true
        }

        try? modelContext.save()
    }

    private func saveNote() {
        let trimmed = noteText.trimmingCharacters(in: .whitespacesAndNewlines)
        if trimmed.isEmpty {
            return
        }

        let descriptor = FetchDescriptor<NoteRecord>()
        let notes = (try? modelContext.fetch(descriptor)) ?? []

        if let existingNote = notes.first(where: { $0.sermonID == sermon.id }) {
            existingNote.text = trimmed
            existingNote.updatedAt = Date()
        } else {
            let note = NoteRecord(sermonID: sermon.id, text: trimmed)
            modelContext.insert(note)
        }

        try? modelContext.save()
    }
}

#Preview {
    SermonDetailView(sermon: SermonRecord(code: "58-0928E", title: "The Serpent's Seed", location: "Jeffersonville", language: "Inglés", durationMinutes: 68, source: "Voice of God Recordings", body: "Demo text"))
        .modelContainer(for: [SermonRecord.self, ParagraphRecord.self, FavoriteRecord.self, NoteRecord.self], inMemory: true)
}
