import SwiftUI

struct AuthorizedImportView: View {
    @State private var title = ""
    @State private var urlText = ""
    @State private var selectedKind: AuthorizedMediaSource.SourceKind = .audio
    @State private var hasAuthorization = true
    @State private var statusMessage = "Verifica la URL antes de agregarla."
    @State private var approvedSources: [AuthorizedMediaSource] = []

    var body: some View {
        Form {
            Section("Política de uso") {
                Text("No se descargan ni se copian libros, audios o PDFs completos sin permiso explícito del usuario o de la organización responsable.")
                    .font(.subheadline)
                    .foregroundStyle(.secondary)
                Text("Solo se aceptan URLs provenientes de fuentes ya autorizadas y verificadas.")
                    .font(.caption)
                    .foregroundStyle(.secondary)
            }

            Section("Validar importación") {
                TextField("Título", text: $title)
                TextField("URL autorizada", text: $urlText)
                    .textInputAutocapitalization(.never)
                    .autocorrectionDisabled()
                    .keyboardType(.URL)

                Picker("Tipo", selection: $selectedKind) {
                    Text("Audio").tag(AuthorizedMediaSource.SourceKind.audio)
                    Text("PDF").tag(AuthorizedMediaSource.SourceKind.pdf)
                    Text("Transcripción").tag(AuthorizedMediaSource.SourceKind.transcript)
                    Text("Metadatos").tag(AuthorizedMediaSource.SourceKind.metadata)
                }
                .pickerStyle(.segmented)

                Toggle("Tengo autorización explícita", isOn: $hasAuthorization)

                Button("Validar y guardar") {
                    validateAndStore()
                }
                .buttonStyle(.borderedProminent)

                Text(statusMessage)
                    .font(.subheadline)
                    .foregroundStyle(statusColor)
            }

            Section("Fuentes aceptadas") {
                if approvedSources.isEmpty {
                    Text("Aún no tienes ninguna fuente autorizada agregada.")
                        .foregroundStyle(.secondary)
                } else {
                    ForEach(approvedSources) { source in
                        VStack(alignment: .leading, spacing: 6) {
                            Text(source.title)
                                .font(.headline)
                            Text(source.kind.rawValue.capitalized)
                                .font(.caption)
                                .foregroundStyle(.secondary)
                            Text(source.sourceURL.absoluteString)
                                .font(.caption2)
                                .foregroundStyle(.blue)
                        }
                        .padding(.vertical, 4)
                    }
                }
            }
        }
        .navigationTitle("Importación autorizada")
    }

    private var statusColor: Color {
        statusMessage.contains("No se puede") ? .red : .green
    }

    private func validateAndStore() {
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        let trimmedURL = urlText.trimmingCharacters(in: .whitespacesAndNewlines)

        guard !trimmedTitle.isEmpty else {
            statusMessage = "Escribe un título antes de continuar."
            return
        }

        guard !trimmedURL.isEmpty, let url = URL(string: trimmedURL) else {
            statusMessage = "La URL no es válida. Usa una dirección completa incluida el protocolo https://"
            return
        }

        guard hasAuthorization else {
            statusMessage = "No se puede importar sin autorización explícita."
            return
        }

        guard AuthorizedLibraryImportService.shared.validateSourceURL(url) else {
            statusMessage = "No se puede importar esta URL. Solo se permiten hosts autorizados y verificados."
            return
        }

        do {
            let source = try AuthorizedLibraryImportService.shared.makeAuthorizedSource(
                title: trimmedTitle,
                url: url,
                kind: selectedKind
            )
            approvedSources.insert(source, at: 0)
            title = ""
            urlText = ""
            statusMessage = "Fuente autorizada añadida correctamente."
        } catch {
            statusMessage = "No se puede importar esta fuente. Comprueba la URL y la autorización."
        }
    }
}

#Preview {
    NavigationStack {
        AuthorizedImportView()
    }
}
