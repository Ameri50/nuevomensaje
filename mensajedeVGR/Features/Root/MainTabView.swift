import SwiftUI

struct MainTabView: View {
    @EnvironmentObject private var appState: AppState
    @ObservedObject private var localization = LocalizationManager.shared

    var body: some View {
        TabView(selection: $appState.selectedTab) {
            HomeView()
                .tabItem {
                    Label(Strings.get("tabHome", language: localization.currentLanguage), systemImage: "house.fill")
                }
                .tag(0)

            SermonsListView()
                .tabItem {
                    Label(Strings.get("tabMessages", language: localization.currentLanguage), systemImage: "book.fill")
                }
                .tag(1)

            FavoritesView()
                .tabItem {
                    Label(Strings.get("tabFavorites", language: localization.currentLanguage), systemImage: "star.fill")
                }
                .tag(2)

            AuthorizedImportView()
                .tabItem {
                    Label(Strings.get("tabImport", language: localization.currentLanguage), systemImage: "arrow.down.doc.fill")
                }
                .tag(3)

            AIChatView()
                .tabItem {
                    Label(Strings.get("tabAI", language: localization.currentLanguage), systemImage: "sparkles")
                }
                .tag(4)
            
            SettingsView()
                .tabItem {
                    Label(Strings.get("tabSettings", language: localization.currentLanguage), systemImage: "gear")
                }
                .tag(5)
        }
        .tint(.blue)
        .preferredColorScheme(localization.isDarkMode ? .dark : .light)
    }
}
