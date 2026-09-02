import SwiftUI
import SwiftData

struct SermonsListView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var searchText = ""

    private var filteredMessages: [SermonRecord] {
        let service = DemoLibraryService.shared
        return service.search(context: modelContext, query: searchText)
    }

    var body: some View {
        NavigationStack {
            List(filteredMessages) { message in
                NavigationLink(destination: SermonDetailView(sermon: message)) {
                    VStack(alignment: .leading, spacing: 6) {
                        HStack {
                            Text(message.code)
                                .font(.headline)
                            Spacer()
                            if message.audioURL != nil {
                                Image(systemName: "play.circle.fill")
                                    .foregroundStyle(.blue)
                            }
                        }
                        Text(message.title)
                            .font(.subheadline)
                            .fontWeight(.semibold)
                            .fixedSize(horizontal: false, vertical: true)
                        Text(message.location)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                        Text(message.date?.formatted(date: .abbreviated, time: .omitted) ?? "Sin fecha")
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }
            }
            .listStyle(.plain)
            .searchable(text: $searchText, prompt: "Buscar por título, código o tema")
            .navigationTitle("Mensajes")
            .toolbar {
                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        searchText = ""
                    } label: {
                        Label("Limpiar", systemImage: "xmark.circle")
                    }
                }
            }
        }
    }
}

#Preview {
    SermonsListView()
        .modelContainer(for: [SermonRecord.self, ParagraphRecord.self, FavoriteRecord.self, NoteRecord.self], inMemory: true)
}
