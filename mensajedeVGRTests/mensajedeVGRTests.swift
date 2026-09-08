//
//  mensajedeVGRTests.swift
//  mensajedeVGRTests
//
//  Created by Moises rojas on 2/09/26.
//

import Testing
import Foundation

struct mensajedeVGRTests {

    @Test func gitLfsPointerIsDetected() async throws {
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
