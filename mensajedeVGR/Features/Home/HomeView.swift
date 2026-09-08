import SwiftUI
import SwiftData

struct HomeView: View {
    @Environment(\.modelContext) private var modelContext
    @State private var searchText = ""
    @EnvironmentObject private var localization: LocalizationManager  // ← CAMBIADO a EnvironmentObject

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(alignment: .leading, spacing: 20) {
                    VStack(alignment: .leading, spacing: 4) {
                        Text(localization.getString("homeTitle"))
                            .font(.largeTitle.bold())
                        Text(localization.getString("homeSubtitle"))
                    }
                    .padding(.horizontal)

                    SearchBar(text: $searchText, placeholder: localization.getString("homeSearch"))

                    if let featuredMessage = defaultMessage() {
                        HomeSection(title: localization.getString("homeContinueReading")) {
                            NavigationLink(destination: SermonDetailView(sermon: featuredMessage)) {
                                HStack(spacing: 12) {
                                    RoundedRectangle(cornerRadius: 12)
                                        .fill(Color.blue.opacity(0.12))
                                        .frame(width: 52, height: 52)
                                        .overlay(Image(systemName: "book.fill"))
                                    VStack(alignment: .leading) {
                                        Text(featuredMessage.code)
                                            .font(.headline)
                                        Text(featuredMessage.title)
                                            .foregroundStyle(.secondary)
                                    }
                                    Spacer()
                                    Image(systemName: "chevron.right")
                                        .foregroundStyle(.secondary)
                                }
                                .padding(.horizontal)
                                .padding(.vertical, 6)
                            }
                            .buttonStyle(.plain)
                        }
                    }

                    HomeSection(title: localization.getString("homeRecentMessages")) {
                        MessageCardRow(messages: demoMessages())
                    }

                    HomeSection(title: localization.getString("homeAuthorizedSources")) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(localization.getString("homeAuthorizationNote"))
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                            Text(localization.getString("homeReferenceSource"))
                                .font(.caption)
                                .foregroundStyle(.blue)
                            Text(localization.getString("homeUnauthorizedWarning"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .frame(maxWidth: .infinity, alignment: .leading)
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                        .padding(.horizontal)
                    }

                    HomeSection(title: localization.getString("homeAskMessages")) {
                        VStack(alignment: .leading, spacing: 10) {
                            ForEach(exampleQuestions, id: \ .self) { question in
                                Button(action: {}) {
                                    Text(question)
                                        .frame(maxWidth: .infinity, alignment: .leading)
                                        .padding(10)
                                        .background(Color(.secondarySystemBackground))
                                        .clipShape(RoundedRectangle(cornerRadius: 10))
                                }
                                .buttonStyle(.plain)
                            }
                        }
                    }
                }
                .padding(.bottom, 30)
            }
            .navigationTitle(localization.getString("homeTitle"))
        }
    }

    private func demoMessages() -> [SermonRecord] {
        let service = DemoLibraryService.shared
        return service.allMessages(context: modelContext)
    }

    private func defaultMessage() -> SermonRecord? {
        let messages = demoMessages()
        return messages.first
    }
}

private struct HomeSection<Content: View>: View {
    let title: String
    @ViewBuilder let content: () -> Content

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text(title)
                .font(.title3.bold())
                .padding(.horizontal)
            content()
        }
    }
}

private struct MessageCardRow: View {
    let messages: [SermonRecord]

    var body: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 12) {
                ForEach(messages) { message in
                    NavigationLink(destination: SermonDetailView(sermon: message)) {
                        VStack(alignment: .leading, spacing: 8) {
                            Text(message.code)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(message.title)
                                .font(.headline)
                                .fixedSize(horizontal: false, vertical: true)
                            Text(message.location)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Spacer()
                        }
                        .frame(width: 180, height: 150)
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 16))
                    }
                    .buttonStyle(.plain)
                }
            }
            .padding(.horizontal)
        }
    }
}

private let exampleQuestions = [
    "¿Qué enseñó Branham sobre la mujer y el hombre?",
    "¿Qué dijo sobre la serpiente?",
    "¿Dónde habló sobre Daniel?",
    "Busca todos los mensajes donde menciona Génesis 3."
]

#Preview {
    HomeView()
        .environmentObject(LocalizationManager.shared)
}
