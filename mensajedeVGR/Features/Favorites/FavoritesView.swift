import SwiftUI
import SwiftData

struct FavoritesView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var favoriteSermons: [SermonRecord] = []

    var body: some View {
        NavigationStack {
            Group {
                if favoriteSermons.isEmpty {
                    ContentUnavailableView(
                        "Sin favoritos",
                        systemImage: "star.fill",
                        description: Text("Guarda mensajes para volver aquí rápidamente y revisarlos más tarde.")
                    )
                } else {
                    List {
                        ForEach(favoriteSermons) { sermon in
                            NavigationLink(destination: SermonDetailView(sermon: sermon)) {
                                VStack(alignment: .leading, spacing: 8) {
                                    Text(sermon.code)
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                    Text(sermon.title)
                                        .font(.headline)
                                    Text(sermon.location)
                                        .font(.subheadline)
                                        .foregroundStyle(.secondary)
                                    Text(sermon.date?.formatted(date: .abbreviated, time: .omitted) ?? "Sin fecha")
                                        .font(.caption)
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.vertical, 4)
                            }
                        }
                    }
                    .listStyle(.plain)
                }
            }
            .navigationTitle("Favoritos")
            .onAppear {
                loadFavorites()
            }
        }
    }

    private func loadFavorites() {
        let favoriteDescriptor = FetchDescriptor<FavoriteRecord>()
        let favorites = (try? modelContext.fetch(favoriteDescriptor)) ?? []
        let sermonIDs = favorites.compactMap { $0.sermonID }

        guard !sermonIDs.isEmpty else {
            favoriteSermons = []
            return
        }

        let sermonDescriptor = FetchDescriptor<SermonRecord>()
        let allSermons = (try? modelContext.fetch(sermonDescriptor)) ?? []
        favoriteSermons = allSermons.filter { sermonIDs.contains($0.id) }
    }
}

#Preview {
    FavoritesView()
        .modelContainer(for: [SermonRecord.self, FavoriteRecord.self], inMemory: true)
}
