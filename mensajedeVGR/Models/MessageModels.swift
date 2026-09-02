import Foundation
import SwiftData

@Model
final class SermonRecord {
    @Attribute(.unique) var id: UUID
    var code: String
    var title: String
    var date: Date?
    var location: String
    var language: String
    var durationMinutes: Int
    var audioURL: String?
    var source: String
    var body: String
    var isFeatured: Bool
    var createdAt: Date
    var updatedAt: Date

    init(
        id: UUID = UUID(),
        code: String,
        title: String,
        date: Date? = nil,
        location: String = "",
        language: String = "Inglés",
        durationMinutes: Int = 30,
        audioURL: String? = nil,
        source: String = "Fuente local",
        body: String = "",
        isFeatured: Bool = false,
        createdAt: Date = .now,
        updatedAt: Date = .now
    ) {
        self.id = id
        self.code = code
        self.title = title
        self.date = date
        self.location = location
        self.language = language
        self.durationMinutes = durationMinutes
        self.audioURL = audioURL
        self.source = source
        self.body = body
        self.isFeatured = isFeatured
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

@Model
final class ParagraphRecord {
    @Attribute(.unique) var id: UUID
    var sermonID: UUID
    var number: Int
    var text: String
    var embedding: String?

    init(id: UUID = UUID(), sermonID: UUID, number: Int, text: String, embedding: String? = nil) {
        self.id = id
        self.sermonID = sermonID
        self.number = number
        self.text = text
        self.embedding = embedding
    }
}

@Model
final class FavoriteRecord {
    @Attribute(.unique) var id: UUID
    var type: String
    var sermonID: UUID?
    var paragraphID: UUID?
    var createdAt: Date

    init(id: UUID = UUID(), type: String, sermonID: UUID? = nil, paragraphID: UUID? = nil, createdAt: Date = .now) {
        self.id = id
        self.type = type
        self.sermonID = sermonID
        self.paragraphID = paragraphID
        self.createdAt = createdAt
    }
}

@Model
final class NoteRecord {
    @Attribute(.unique) var id: UUID
    var sermonID: UUID?
    var paragraphID: UUID?
    var text: String
    var createdAt: Date
    var updatedAt: Date

    init(id: UUID = UUID(), sermonID: UUID? = nil, paragraphID: UUID? = nil, text: String, createdAt: Date = .now, updatedAt: Date = .now) {
        self.id = id
        self.sermonID = sermonID
        self.paragraphID = paragraphID
        self.text = text
        self.createdAt = createdAt
        self.updatedAt = updatedAt
    }
}

@Model
final class AIChatMessage {
    @Attribute(.unique) var id: UUID
    var role: String
    var text: String
    var timestamp: Date
    var sourceSummary: String

    init(id: UUID = UUID(), role: String, text: String, timestamp: Date = .now, sourceSummary: String = "") {
        self.id = id
        self.role = role
        self.text = text
        self.timestamp = timestamp
        self.sourceSummary = sourceSummary
    }
}

struct SermonReference: Identifiable, Hashable {
    let id: UUID
    let code: String
    let title: String
    let paragraphNumber: Int?
    let snippet: String

    var displayName: String {
        "\(code) — \(title)"
    }
}
