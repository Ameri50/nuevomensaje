//
//  mensajedeVGRApp.swift
//  mensajedeVGR
//
//  Created by Moises rojas on 2/09/26.
//

import SwiftUI
import SwiftData

@main
struct mensajedeVGRApp: App {
    @StateObject private var appState = AppState()

    var sharedModelContainer: ModelContainer = {
        let schema = Schema([
            SermonRecord.self,
            ParagraphRecord.self,
            FavoriteRecord.self,
            NoteRecord.self,
            AIChatMessage.self
        ])
        let modelConfiguration = ModelConfiguration(schema: schema, isStoredInMemoryOnly: false)

        do {
            return try ModelContainer(for: schema, configurations: [modelConfiguration])
        } catch {
            print("No se pudo crear ModelContainer: \(error)")
            let fallback = ModelConfiguration(schema: schema, isStoredInMemoryOnly: true)
            do {
                return try ModelContainer(for: schema, configurations: [fallback])
            } catch {
                fatalError("No se pudo crear el contenedor de datos: \(error)")
            }
        }
    }()

    var body: some Scene {
        WindowGroup {
            MainTabView()
                .environmentObject(appState)
                .modelContainer(sharedModelContainer)
                .onAppear {
                    DemoLibraryService.shared.seedIfNeeded(context: sharedModelContainer.mainContext)
                }
        }
    }
}
