import Foundation
import Combine
import SwiftUI

@MainActor
final class AppState: ObservableObject {
    @Published var selectedTab: Int = 0
    @Published var searchText: String = ""
    @Published var preferredLanguage: String = "Español"
    @Published var isAIEnabled: Bool = true
    @Published var readingFontSize: Double = 18
    @Published var appearanceMode: String = "Automático"
    @Published var offlineMode: Bool = true

    func setTab(_ tab: Int) {
        selectedTab = tab
    }
}
