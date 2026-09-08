import SwiftUI
import SwiftData

struct SermonDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var localization: LocalizationManager
    @StateObject private var speech = SpeechManager.shared
    @State private var isFavorited = false
    @State private var note: String = ""

    let sermon: SermonRecord

    /// Párrafos separados del body para el lector TTS
    private var paragraphs: [String] {
        sermon.body
            .components(separatedBy: "\n\n")
            .map { $0.trimmingCharacters(in: .whitespacesAndNewlines) }
            .filter { !$0.isEmpty }
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 16) {

                    // MARK: - Header
                    VStack(alignment: .leading, spacing: 12) {
                        HStack {
                            VStack(alignment: .leading, spacing: 4) {
                                Text(sermon.code)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                                Text(sermon.title)
                                    .font(.headline)
                                Text(sermon.location)
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Button(action: toggleFavorite) {
                                Image(systemName: isFavorited ? "star.fill" : "star")
                                    .font(.system(size: 20))
                                    .foregroundStyle(isFavorited ? .yellow : .gray)
                            }
                        }

                        HStack(spacing: 16) {
                            Label {
                                Text("\(sermon.durationMinutes) min")
                                    .font(.caption)
                            } icon: {
                                Image(systemName: "clock")
                            }
                            .foregroundStyle(.secondary)

                            Divider().frame(height: 16)

                            Label {
                                Text(sermon.language)
                                    .font(.caption)
                            } icon: {
                                Image(systemName: "globe")
                            }
                            .foregroundStyle(.secondary)

                            Spacer()
                        }
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding()

                    // MARK: - TTS Player
                    if !paragraphs.isEmpty {
                        TTSPlayerView(
                            paragraphs: paragraphs,
                            sermonLanguage: sermon.language,
                            speech: speech,
                            localization: localization
                        )
                        .padding(.horizontal)
                    }

                    // MARK: - Contenido del Mensaje
                    if !sermon.body.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(localization.getString("sermonContent"))
                                .font(.headline)
                                .padding(.horizontal)

                            // Párrafos individuales con resaltado
                            VStack(alignment: .leading, spacing: 8) {
                                ForEach(Array(paragraphs.enumerated()), id: \.offset) { index, text in
                                    ParagraphView(
                                        text: text,
                                        index: index,
                                        isActive: speech.currentParagraphIndex == index,
                                        onTap: {
                                            speech.speak(
                                                paragraphs: paragraphs,
                                                language: sermon.language,
                                                startingAt: index
                                            )
                                        }
                                    )
                                }
                            }
                            .padding(.horizontal)
                        }
                        .padding(.bottom, 8)
                    }

                    // MARK: - Notas
                    VStack(alignment: .leading, spacing: 12) {
                        Text(localization.getString("sermonMyNotes"))
                            .font(.headline)

                        TextEditor(text: $note)
                            .frame(height: 120)
                            .border(Color(.secondarySystemBackground), width: 1)
                            .clipShape(RoundedRectangle(cornerRadius: 8))

                        Button(action: saveNote) {
                            HStack {
                                Image(systemName: "checkmark.circle.fill")
                                Text(localization.getString("sermonSaveNote"))
                            }
                            .frame(maxWidth: .infinity)
                            .padding()
                            .background(Color.blue)
                            .foregroundStyle(.white)
                            .clipShape(RoundedRectangle(cornerRadius: 8))
                        }
                    }
                    .padding()
                }
                .padding(.bottom, 20)
            }
            .navigationTitle(sermon.code)
            .navigationBarTitleDisplayMode(.inline)
            .onAppear { checkIfFavorited() }
            .onDisappear { speech.stop() }
        }
    }

    // MARK: - Helpers

    private func toggleFavorite() {
        withAnimation {
            isFavorited.toggle()
            if isFavorited {
                modelContext.insert(FavoriteRecord(
                    type: "sermon",
                    sermonID: sermon.id,
                    createdAt: .now
                ))
            } else {
                if let fav = findFavorite() { modelContext.delete(fav) }
            }
        }
    }

    private func findFavorite() -> FavoriteRecord? {
        let sermonID = sermon.id
        let predicate = #Predicate<FavoriteRecord> {
            $0.sermonID == sermonID && $0.type == "sermon"
        }
        return try? modelContext.fetch(FetchDescriptor<FavoriteRecord>(predicate: predicate)).first
    }

    private func checkIfFavorited() {
        isFavorited = findFavorite() != nil
    }

    private func saveNote() {
        print("Nota guardada: \(note)")
    }
}

// MARK: - TTS Player View

private struct TTSPlayerView: View {
    let paragraphs: [String]
    let sermonLanguage: String
    @ObservedObject var speech: SpeechManager
    let localization: LocalizationManager

    var body: some View {
        VStack(spacing: 12) {
            // Controls row
            HStack(spacing: 20) {
                // Previous paragraph
                Button(action: { speech.skipToPrevious() }) {
                    Image(systemName: "backward.fill")
                        .font(.system(size: 20))
                }
                .disabled(!speech.isPlaying && !speech.isPaused)

                // Play / Pause / Resume
                Button(action: togglePlayback) {
                    Image(systemName: playIcon)
                        .font(.system(size: 36))
                        .foregroundStyle(.blue)
                }

                // Next paragraph
                Button(action: { speech.skipToNext() }) {
                    Image(systemName: "forward.fill")
                        .font(.system(size: 20))
                }
                .disabled(!speech.isPlaying && !speech.isPaused)

                // Stop
                if speech.isPlaying || speech.isPaused {
                    Button(action: { speech.stop() }) {
                        Image(systemName: "stop.fill")
                            .font(.system(size: 20))
                            .foregroundStyle(.red)
                    }
                }

                Spacer()

                // Speed picker
                Menu {
                    ForEach([0.4, 0.5, 0.6, 0.75, 1.0], id: \.self) { s in
                        Button(action: { speech.rate = Float(s) }) {
                            Label(speedLabel(s), systemImage: speech.rate == Float(s) ? "checkmark" : "")
                        }
                    }
                } label: {
                    HStack(spacing: 4) {
                        Image(systemName: "gauge.with.dots.needle.50percent")
                        Text(localization.getString("ttsSpeed"))
                            .font(.caption)
                    }
                    .foregroundStyle(.secondary)
                }
            }
            .padding()
            .background(Color(.secondarySystemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))

            // Status
            if speech.isPlaying || speech.isPaused {
                HStack {
                    Image(systemName: "waveform")
                        .foregroundStyle(.blue)
                        .symbolEffect(.variableColor, isActive: speech.isPlaying)
                    Text("\(localization.getString("ttsListening")) \(speech.currentParagraphIndex + 1) / \(paragraphs.count)")
                        .font(.caption)
                        .foregroundStyle(.secondary)
                    Spacer()
                }
                .padding(.horizontal, 4)
            }
        }
    }

    private var playIcon: String {
        if speech.isPaused { return "play.fill" }
        if speech.isPlaying { return "pause.fill" }
        return "play.fill"
    }

    private func togglePlayback() {
        if speech.isPaused {
            speech.resume()
        } else if speech.isPlaying {
            speech.pause()
        } else {
            speech.speak(paragraphs: paragraphs, language: sermonLanguage)
        }
    }

    private func speedLabel(_ s: Double) -> String {
        s == 1.0 ? "1× Normal" : "\(s)×"
    }
}

// MARK: - Paragraph View with highlight + tap-to-read

private struct ParagraphView: View {
    let text: String
    let index: Int
    let isActive: Bool
    let onTap: () -> Void

    var body: some View {
        Text(text)
            .font(.body)
            .lineSpacing(4)
            .foregroundStyle(isActive ? .primary : .primary)
            .padding(isActive ? 10 : 0)
            .frame(maxWidth: .infinity, alignment: .leading)
            .background(
                isActive
                    ? Color.blue.opacity(0.12)
                    : Color.clear
            )
            .clipShape(RoundedRectangle(cornerRadius: 8))
            .overlay(
                isActive
                    ? RoundedRectangle(cornerRadius: 8).stroke(Color.blue.opacity(0.4), lineWidth: 1)
                    : nil
            )
            .onTapGesture(perform: onTap)
            .animation(.easeInOut(duration: 0.2), value: isActive)
    }
}

#Preview {
    let sermon = SermonRecord(
        code: "52-0713",
        title: "El Séptimo Sello",
        location: "Los Ángeles, CA",
        body: "Este es el primer párrafo del mensaje.\n\nEste es el segundo párrafo con más contenido para probar la lectura en voz alta.\n\nTercer párrafo de ejemplo."
    )
    return SermonDetailView(sermon: sermon)
        .environmentObject(LocalizationManager.shared)
}
