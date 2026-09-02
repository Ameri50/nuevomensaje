import XCTest
@testable import mensajedeVGR

final class BroSermonCatalogLoaderTests: XCTestCase {
    func testCatalogJSONExistsAndHasSermons() throws {
        let catalog = BroSermonCatalogLoader.shared.loadCatalog()
        XCTAssertFalse(catalog.isEmpty, "El catálogo de sermones no se cargó")
        let first = try XCTUnwrap(catalog.first)
        XCTAssertFalse(first.title.isEmpty)
        XCTAssertFalse(first.paragraphs.isEmpty)
    }
}
