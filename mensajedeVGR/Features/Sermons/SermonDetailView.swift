import SwiftUI
import SwiftData

struct SermonDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @EnvironmentObject private var localization: LocalizationManager
    @State private var isFavorited = false
    @State private var note: String = ""
    
    let sermon: SermonRecord
    
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
                        
                        // Información del Sermón
                        HStack(spacing: 16) {
                            Label {
                                Text("\(sermon.durationMinutes) min")
                                    .font(.caption)
                            } icon: {
                                Image(systemName: "clock")
                            }
                            .foregroundStyle(.secondary)
                            
                            Divider()
                                .frame(height: 16)
                            
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
                    
                    // MARK: - Audio Player (Si existe)
                    if let audioURL = sermon.audioURL, !audioURL.isEmpty {
                        VStack(spacing: 12) {
                            HStack(spacing: 12) {
                                Image(systemName: "play.circle.fill")
                                    .font(.system(size: 32))
                                    .foregroundStyle(.blue)
                                
                                VStack(alignment: .leading, spacing: 2) {
                                    Text(localization.getString("sermonAudioPlayback"))
                                        .font(.subheadline)
                                    Text(sermon.code)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                Spacer()
                            }
                            .padding()
                            .background(Color(.secondarySystemBackground))
                            .clipShape(RoundedRectangle(cornerRadius: 12))
                            
                            HStack(spacing: 0) {
                                Text("0:00")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                                
                                Slider(value: .constant(0.3))
                                    .disabled(true)
                                
                                Text("1:23:45")
                                    .font(.caption2)
                                    .foregroundStyle(.secondary)
                            }
                        }
                        .padding()
                    }
                    
                    // MARK: - Contenido del Mensaje
                    if !sermon.body.isEmpty {
                        VStack(alignment: .leading, spacing: 12) {
                            Text(localization.getString("sermonContent"))
                                .font(.headline)
                            
                            Text(sermon.body)
                                .font(.body)
                                .lineSpacing(4)
                                .foregroundStyle(.primary)
                        }
                        .padding()
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
            .onAppear {
                checkIfFavorited()
            }
        }
    }
    
    private func toggleFavorite() {
        withAnimation {
            isFavorited.toggle()
            
            if isFavorited {
                let favorite = FavoriteRecord(
                    type: "sermon",
                    sermonID: sermon.id,
                    createdAt: .now
                )
                modelContext.insert(favorite)
            } else {
                // Eliminar de favoritos
                if let favoriteToRemove = findFavorite() {
                    modelContext.delete(favoriteToRemove)
                }
            }
        }
    }
    
    private func findFavorite() -> FavoriteRecord? {
        let sermonID = sermon.id
        let predicate = #Predicate<FavoriteRecord> {
            $0.sermonID == sermonID && $0.type == "sermon"
        }
        let descriptor = FetchDescriptor<FavoriteRecord>(predicate: predicate)
        return try? modelContext.fetch(descriptor).first
    }
    
    private func checkIfFavorited() {
        isFavorited = findFavorite() != nil
    }
    
    private func saveNote() {
        // Guardar nota (implementar lógica real)
        print("Nota guardada: \(note)")
    }
}

#Preview {
    let sermon = SermonRecord(
        code: "52-0713",
        title: "El Séptimo Sello",
        location: "Los Ángeles, CA",
        body: "Este es el contenido del mensaje..."
    )
    
    return SermonDetailView(sermon: sermon)
        .environmentObject(LocalizationManager.shared)
}
