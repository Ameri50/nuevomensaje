import SwiftUI

struct AuthorizedImportView: View {
    @EnvironmentObject private var localization: LocalizationManager
    @State private var showingFilePicker = false
    @State private var importStatus: String = ""
    
    var body: some View {
        NavigationStack {
            VStack(spacing: 20) {
                // MARK: - Encabezado
                VStack(alignment: .leading, spacing: 8) {
                    Text(localization.getString("homeTitle"))
                        .font(.headline)
                    Text(localization.getString("homeAuthorizationNote"))
                        .font(.caption)
                        .foregroundStyle(.secondary)
                }
                .padding()
                
                // MARK: - Botones de Importación
                VStack(spacing: 12) {
                    Button(action: { showingFilePicker = true }) {
                        HStack(spacing: 12) {
                            Image(systemName: "doc.badge.plus")
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Importar PDF")
                                    .font(.subheadline)
                                Text("Documentos autorizados")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .foregroundStyle(.primary)
                    
                    Button(action: {}) {
                        HStack(spacing: 12) {
                            Image(systemName: "waveform.circle")
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Importar Audio")
                                    .font(.subheadline)
                                Text("Archivos MP3/M4A")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .foregroundStyle(.primary)
                    
                    Button(action: importarSermonesEspanol) {
                        HStack(spacing: 12) {
                            Image(systemName: "text.book.closed")
                            VStack(alignment: .leading, spacing: 2) {
                                Text("Importar sermones en español")
                                    .font(.subheadline)
                                Text("Desde bro_branham_sermons_es.json")
                                    .font(.caption)
                                    .foregroundStyle(.secondary)
                            }
                            Spacer()
                            Image(systemName: "chevron.right")
                                .foregroundStyle(.secondary)
                        }
                        .padding()
                        .background(Color(.secondarySystemBackground))
                        .clipShape(RoundedRectangle(cornerRadius: 12))
                    }
                    .foregroundStyle(.primary)
                }
                .padding()
                
                // MARK: - Información de Fuentes
                VStack(alignment: .leading, spacing: 12) {
                    Text(localization.getString("homeAuthorizedSources"))
                        .font(.headline)
                        .padding(.horizontal)
                    
                    VStack(alignment: .leading, spacing: 8) {
                        Text(localization.getString("homeReferenceSource"))
                            .font(.caption)
                            .foregroundStyle(.blue)
                        Text(localization.getString("homeUnauthorizedWarning"))
                            .font(.caption)
                            .foregroundStyle(.red)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding(.horizontal)
                }
                
                // MARK: - Estado de Importación
                if !importStatus.isEmpty {
                    VStack(alignment: .leading, spacing: 8) {
                        Text("Estado de Importación")
                            .font(.headline)
                        Text(importStatus)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                    .padding()
                    .background(Color(.secondarySystemBackground))
                    .clipShape(RoundedRectangle(cornerRadius: 12))
                    .padding()
                }
                
                Spacer()
            }
            .navigationTitle(localization.getString("tabImport"))
            .navigationBarTitleDisplayMode(.inline)
        }
    }
    
    private func importarSermonesEspanol() {
        guard let url = Bundle.main.url(forResource: "bro_branham_sermons_es", withExtension: "json") else {
            importStatus = "❌ No se encontró bro_branham_sermons_es.json en el bundle."
            return
        }
        do {
            let agregados = try BroSermonCatalogLoader.shared.importAndMerge(from: url)
            importStatus = agregados > 0
                ? "✅ Se agregaron \(agregados) sermón(es) en español."
                : "ℹ️ No había sermones nuevos que agregar (ya existían)."
        } catch {
            importStatus = "❌ Error al importar: \(error.localizedDescription)"
        }
    }
}

#Preview {
    AuthorizedImportView()
        .environmentObject(LocalizationManager.shared)
}
