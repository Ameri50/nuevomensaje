import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var appState: AppState
    @EnvironmentObject private var localization: LocalizationManager  // ← CAMBIADO a EnvironmentObject

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            HomeView()
                .tabItem {
                    Label(localization.getString("tabHome"), systemImage: "house.fill")
                }
                .tag(0)

            SermonsListView()
                .tabItem {
                    Label(localization.getString("tabMessages"), systemImage: "book.fill")
                }
                .tag(1)

            FavoritesView()
                .tabItem {
                    Label(localization.getString("tabFavorites"), systemImage: "star.fill")
                }
                .tag(2)

            AIChatView()
                .tabItem {
                    Label(localization.getString("tabAI"), systemImage: "sparkles")
                }
                .tag(3)

            SettingsView()
                .tabItem {
                    Label(localization.getString("tabSettings"), systemImage: "gear")
                }
                .tag(4)
        }
        .tint(.blue)
        .preferredColorScheme(localization.isDarkMode ? .dark : .light)
    }
}
