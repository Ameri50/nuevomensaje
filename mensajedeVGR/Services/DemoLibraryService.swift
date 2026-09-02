import Foundation
import SwiftData

@MainActor
final class DemoLibraryService {
    static let shared = DemoLibraryService()

    func seedIfNeeded(context: ModelContext) {
        let fetch: FetchDescriptor<SermonRecord> = FetchDescriptor<SermonRecord>()
        guard let existing = try? context.fetch(fetch), existing.isEmpty else { return }

        let catalog = BroSermonCatalogLoader.shared.loadCatalog()

        for sermon in catalog {
            let sermonRecord = SermonRecord(
                code: sermon.id,
                title: sermon.title,
                date: parseDate(from: sermon.meta?.date ?? sermon.date ?? ""),
                location: sermon.meta?.location ?? sermon.location ?? "Desconocida",
                language: "Inglés",
                durationMinutes: estimateDuration(from: sermon.paragraphs.count),
                audioURL: nil,
                source: "bro-william-branham-sermon-library",
                body: sermon.paragraphs.map { $0.text }.joined(separator: "\n\n"),
                isFeatured: false
            )

            context.insert(sermonRecord)

            for paragraph in sermon.paragraphs {
                let paragraphRecord = ParagraphRecord(
                    sermonID: sermonRecord.id,
                    number: paragraph.number,
                    text: paragraph.text
                )
                context.insert(paragraphRecord)
            }
        }

        try? context.save()
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
