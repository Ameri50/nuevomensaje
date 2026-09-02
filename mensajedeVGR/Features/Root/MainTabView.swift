import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var appState: AppState

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            HomeView()
                .tabItem {
                    Label("Inicio", systemImage: "house.fill")
                }
                .tag(0)

            SermonsListView()
                .tabItem {
                    Label("Mensajes", systemImage: "book.fill")
                }
                .tag(1)

            FavoritesView()
                .tabItem {
                    Label("Favoritos", systemImage: "star.fill")
                }
                .tag(2)

            AuthorizedImportView()
                .tabItem {
                    Label("Importar", systemImage: "arrow.down.doc.fill")
                }
                .tag(3)

            AIChatView()
                .tabItem {
                    Label("IA", systemImage: "sparkles")
                }
                .tag(4)
        }
        .tint(.blue)
    }
}
