//
//  mensajedeVGRTests.swift
//  mensajedeVGRTests
//
//  Created by Moises rojas on 2/09/26.
//

import Testing
import Foundation
@testable import mensajedeVGR

struct mensajedeVGRTests {

    @Test @MainActor func groundingSearchRejectsUnmatchedQueries() {
        let sermon = SermonRecord(code: "58-0928E", title: "The Serpent's Seed", body: "The seed was planted in the beginning.")
        let passages = SermonGroundingSearch.retrieve(query: "astronomy telescope", sermons: [sermon])
        #expect(passages.isEmpty)
    }

    @Test @MainActor func groundingSearchReturnsTheMatchingParagraph() {
        let sermon = SermonRecord(
            code: "58-0928E",
            title: "The Serpent's Seed",
            body: "First paragraph about faith.\n\nLa semilla fue plantada al principio."
        )
        let passages = SermonGroundingSearch.retrieve(query: "semilla", sermons: [sermon])
        #expect(passages.count == 1)
        #expect(passages.first?.paragraphNumber == 2)
        #expect(passages.first?.code == "58-0928E")
    }

    @Test @MainActor func officialAudioCatalogSearchFindsSpanishTitle() {
        let matches = BranhamAudioCatalog.shared.search(query: "Fe Es La Sustancia")
        #expect(matches.contains { $0.code == "47-0412" && $0.lang == "SPN" })

        let codeMatches = BranhamAudioCatalog.shared.search(query: "47-0412")
        #expect(codeMatches.first?.code == "47-0412")
    }

    @Test func tabernaculoSearchPreservesSourceTextAndParagraphReference() throws {
        let payload = Data(#"{"state":1,"resultado":[{"MessageId":"13","Title":"Fe es la Sustancia","Date":"47-0412","Number":"1","Content":"Texto literal, con puntuación…"}]}"#.utf8)
        let results = try TabernaculoZoeSearchService.decodeResults(from: payload)

        #expect(results.count == 1)
        #expect(results[0].text == "Texto literal, con puntuación…")
        #expect(results[0].code == "47-0412")
        #expect(results[0].paragraphNumber == 1)
    }

    @Test func zoeCatalogDecoderLoadsMessageMetadata() throws {
        let payload = Data(#"{"state":1,"resultado":[{"MessageId":"13","Title":"Fe es la Sustancia","Date":"47-0412","Lugar":"Oakland, California","Origen":"La Voz de Dios","urlAudio":""}]}"#.utf8)
        let catalog = try TabernaculoZoeSearchService.decodeCatalog(from: payload)

        #expect(catalog.count == 1)
        #expect(catalog[0].messageID == "13")
        #expect(catalog[0].code == "47-0412")
        #expect(catalog[0].location == "Oakland, California")
        #expect(catalog[0].audioURL == nil)
    }

    @Test func zoeMessageDecoderReturnsOrderedCompleteParagraphs() throws {
        let payload = Data(#"{"state":1,"resultado":[{"MessageId":"13","Number":"2","Content":"Segundo párrafo completo."},{"MessageId":"13","Number":"1","Content":"Primer párrafo completo."}]}"#.utf8)
        let paragraphs = try TabernaculoZoeSearchService.decodeMessageParagraphs(from: payload, messageID: "13")

        #expect(paragraphs.map(\.number) == [1, 2])
        #expect(paragraphs[0].text == "Primer párrafo completo.")
    }

    @Test func freeNoteStoresOptionalSermonParagraphReference() {
        let note = FreeNoteRecord(
            title: "Promesa para estudiar",
            text: "Revisar este pasaje junto con la nota de clase.",
            referenceMessageID: "13",
            referenceCode: "47-0412",
            referenceTitle: "Fe es la Sustancia",
            referenceParagraphNumber: 42
        )

        #expect(note.title == "Promesa para estudiar")
        #expect(note.referenceCode == "47-0412")
        #expect(note.referenceParagraphNumber == 42)
    }

    @Test func naturalQuestionProducesSearchableTerms() {
        let variants = TabernaculoZoeSearchService.queryVariants(for: "¿Qué dijo William Branham sobre la fe?")
        #expect(variants.first == "creencia")
        #expect(variants.contains("creer"))
        #expect(variants.contains("creencia"))
        #expect(!variants.contains("branham"))
        #expect(TabernaculoZoeSearchService.matchesQueryTerms(
            "¿Qué dijo William Branham sobre la fe?",
            in: "La fe es la sustancia de lo que se espera."
        ))
        #expect(!TabernaculoZoeSearchService.matchesQueryTerms(
            "¿Qué dijo William Branham sobre la fe?",
            in: "La creencia de una persona puede ser firme."
        ))
    }

    @Test func fullParagraphHydrationDoesNotTruncateSourceText() throws {
        let longText = String(repeating: "Texto literal completo. ", count: 20)
        let fullPayload = Data("""
        {"state":1,"resultado":[{"MessageId":"13","Title":"Fe es la Sustancia","Date":"47-0412","Number":"1","Content":"\(longText)"}]}
        """.utf8)

        let results = try TabernaculoZoeSearchService.decodeFullParagraphs(
            from: fullPayload,
            messageID: "13",
            titleFallback: "Título alternativo",
            codeFallback: "00-0000",
            containing: ["texto"]
        )

        #expect(results.first?.text == longText)
        #expect(results.first?.title == "Fe es la Sustancia")
        #expect(results.first?.code == "47-0412")
    }

    @Test func groundingSearchRejectsUnverifiedCitations() {
        let passage = GroundedSermonPassage(
            code: "58-0928E",
            title: "The Serpent's Seed",
            paragraphNumber: 2,
            text: "La semilla fue plantada al principio.",
            score: 1
        )

        #expect(SermonGroundingSearch.hasVerifiedCitations(
            in: "La semilla fue plantada [58-0928E, párrafo 2].",
            passages: [passage]
        ))
        #expect(!SermonGroundingSearch.hasVerifiedCitations(
            in: "La semilla fue plantada [58-0928E, párrafo 9].",
            passages: [passage]
        ))
        #expect(!SermonGroundingSearch.hasVerifiedCitations(
            in: "La semilla fue plantada sin referencia.",
            passages: [passage]
        ))
    }

    @Test @MainActor func gitLfsPointerIsDetected() async throws {
        let pointer = Data("version https://git-lfs.github.com/spec/v1\nsha256: abcdef\n".utf8)
        #expect(BroSermonCatalogLoader.isGitLFSPointer(pointer))

        let url = Bundle.main.url(forResource: "bro_branham_sermons", withExtension: "json")
        #expect(url != nil)

        if let url {
            let data = try Data(contentsOf: url)
            #expect(!BroSermonCatalogLoader.isGitLFSPointer(data))
        }
    }

}
