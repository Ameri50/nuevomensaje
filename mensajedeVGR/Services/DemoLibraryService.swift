import Foundation
import SwiftData

@MainActor
final class DemoLibraryService {
    static let shared = DemoLibraryService()

    func seedIfNeeded(context: ModelContext, onComplete: (@MainActor () -> Void)? = nil) {
        let fetch: FetchDescriptor<SermonRecord> = FetchDescriptor<SermonRecord>()
        guard let existing = try? context.fetch(fetch), existing.isEmpty else {
            Task { @MainActor in onComplete?() }
            return
        }

        Task.detached(priority: .userInitiated) {
            // Cargar y decodificar el JSON fuera del hilo principal
            let catalog: [BroSermonCatalogEntry]
            let isSpanish: Bool

            if let spanishCatalog = await self.loadSpanishCatalogAsync() {
                catalog = spanishCatalog
                isSpanish = true
            } else {
                catalog = BroSermonCatalogLoader.shared.loadCatalog()
                isSpanish = false
            }

            // Insertar en lotes de 50 en el MainActor
            let batchSize = 50
            for batchStart in stride(from: 0, to: catalog.count, by: batchSize) {
                let batchEnd = min(batchStart + batchSize, catalog.count)
                let batch = Array(catalog[batchStart..<batchEnd])

                await MainActor.run {
                    for sermon in batch {
                        let sermonRecord = SermonRecord(
                            code: sermon.id,
                            title: sermon.title,
                            date: self.parseDate(from: sermon.meta?.date ?? sermon.date ?? ""),
                            location: sermon.meta?.location ?? sermon.location ?? "Desconocida",
                            language: isSpanish ? "Español" : "Inglés",
                            durationMinutes: self.estimateDuration(from: sermon.paragraphs.count),
                            audioURL: nil,
                            source: isSpanish ? "importado-es" : "bro-william-branham-sermon-library",
                            body: sermon.paragraphs.map { $0.text }.joined(separator: "\n\n"),
                            isFeatured: false
                        )
                        context.insert(sermonRecord)

                        for paragraph in sermon.paragraphs {
                            context.insert(ParagraphRecord(
                                sermonID: sermonRecord.id,
                                number: paragraph.number,
                                text: paragraph.text
                            ))
                        }
                    }
                    try? context.save()
                }
            }

            await MainActor.run {
                onComplete?()
            }
        }
    }

    /// Carga el JSON de sermones en español desde el bundle, si existe. Async para no bloquear.
    private func loadSpanishCatalogAsync() async -> [BroSermonCatalogEntry]? {
        guard let url = Bundle.main.url(forResource: "bro_branham_sermons_es", withExtension: "json") else {
            return nil
        }
        guard let data = try? Data(contentsOf: url),
              !BroSermonCatalogLoader.isGitLFSPointer(data) else {
            return nil
        }
        let envelope = try? JSONDecoder().decode(BroSermonCatalogEnvelope.self, from: data)
        return envelope?.sermons
    }
    private func loadSpanishCatalogAsync() async -> [BroSermonCatalogEntry]? {
        guard let url = Bundle.main.url(forResource: "bro_branham_sermons_es", withExtension: "json") else {
            return nil
        }
        guard let data = try? Data(contentsOf: url),
              !BroSermonCatalogLoader.isGitLFSPointer(data) else {
            return nil
        }
        let envelope = try? JSONDecoder().decode(BroSermonCatalogEnvelope.self, from: data)
        return envelope?.sermons
    }

    /// Inserta o actualiza sermones en SwiftData a partir de un catálogo
    /// (por ejemplo, el resultado de importar traducciones en español).
    /// A diferencia de seedIfNeeded, esto SIEMPRE aplica los cambios,
    /// sin importar si la base de datos ya tenía datos — por eso es el
    /// método correcto para agregar/actualizar contenido después del
    /// primer arranque de la app.
    ///
    /// - Returns: (insertados, actualizados)
    @discardableResult
    func upsert(catalog: [BroSermonCatalogEntry], context: ModelContext) -> (inserted: Int, updated: Int) {
        var insertados = 0
        var actualizados = 0

        for sermon in catalog {
            let code = sermon.id
            let fetch = FetchDescriptor<SermonRecord>(
                predicate: #Predicate { $0.code == code }
            )
            let existentes = (try? context.fetch(fetch)) ?? []

            let nuevoBody = sermon.paragraphs.map { $0.text }.joined(separator: "\n\n")
            let nuevaFecha = parseDate(from: sermon.meta?.date ?? sermon.date ?? "")
            let nuevaUbicacion = sermon.meta?.location ?? sermon.location ?? "Desconocida"
            let nuevaDuracion = estimateDuration(from: sermon.paragraphs.count)

            if let existente = existentes.first {
                // Actualiza el registro existente en vez de duplicarlo
                existente.title = sermon.title
                existente.date = nuevaFecha
                existente.location = nuevaUbicacion
                existente.language = "Español"
                existente.durationMinutes = nuevaDuracion
                existente.body = nuevoBody
                existente.updatedAt = .now

                // Reemplaza los párrafos asociados
                let sermonID = existente.id
                let paragraphFetch = FetchDescriptor<ParagraphRecord>(
                    predicate: #Predicate { $0.sermonID == sermonID }
                )
                if let paragrafosViejos = try? context.fetch(paragraphFetch) {
                    for p in paragrafosViejos { context.delete(p) }
                }
                for paragraph in sermon.paragraphs {
                    context.insert(ParagraphRecord(
                        sermonID: sermonID,
                        number: paragraph.number,
                        text: paragraph.text
                    ))
                }
                actualizados += 1
            } else {
                // Sermón nuevo, no existía por code
                let sermonRecord = SermonRecord(
                    code: code,
                    title: sermon.title,
                    date: nuevaFecha,
                    location: nuevaUbicacion,
                    language: "Español",
                    durationMinutes: nuevaDuracion,
                    audioURL: nil,
                    source: "importado-es",
                    body: nuevoBody,
                    isFeatured: false
                )
                context.insert(sermonRecord)

                for paragraph in sermon.paragraphs {
                    context.insert(ParagraphRecord(
                        sermonID: sermonRecord.id,
                        number: paragraph.number,
                        text: paragraph.text
                    ))
                }
                insertados += 1
            }
        }

        try? context.save()
        return (insertados, actualizados)
    }

    func allMessages(context: ModelContext) -> [SermonRecord] {
        let fetch: FetchDescriptor<SermonRecord> = FetchDescriptor<SermonRecord>(sortBy: [SortDescriptor(\.title)])
        return (try? context.fetch(fetch)) ?? []
    }

    func search(context: ModelContext, query: String) -> [SermonRecord] {
        let trimmed = query.trimmingCharacters(in: .whitespacesAndNewlines)
        guard !trimmed.isEmpty else { return allMessages(context: context) }

        return allMessages(context: context).filter {
            $0.title.localizedCaseInsensitiveContains(trimmed) ||
            $0.code.localizedCaseInsensitiveContains(trimmed) ||
            $0.location.localizedCaseInsensitiveContains(trimmed) ||
            $0.body.localizedCaseInsensitiveContains(trimmed)
        }
    }

    private func parseDate(from value: String) -> Date {
        if value.isEmpty { return Date() }

        let patterns = [
            "MMMM d, yyyy",
            "MMMM d 'of' yyyy",
            "MMMM dth, yyyy",
            "MMMM dth, yyyy",
            "MMMM d, yyyy",
            "MMMM d, yyyy",
            "MMMM d, yyyy",
            "MMMM dth of yyyy",
            "MMMM d'nd', yyyy",
            "MMMM d'st', yyyy",
            "MMMM d'rd', yyyy"
        ]

        let formatter = DateFormatter()
        formatter.locale = Locale(identifier: "en_US_POSIX")
        formatter.timeZone = TimeZone(secondsFromGMT: 0)

        for pattern in patterns {
            formatter.dateFormat = pattern
            if let date = formatter.date(from: value) { return date }
        }

        formatter.dateFormat = "yyyy-MM-dd"
        if let date = formatter.date(from: value) { return date }

        return Date()
    }

    private func estimateDuration(from paragraphCount: Int) -> Int {
        let minutes = max(30, paragraphCount / 5)
        return min(120, minutes)
    }
}
