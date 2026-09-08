import SwiftUI

struct SettingsView: View {
    @ObservedObject private var localization = LocalizationManager.shared
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Apariencia
                Section(header: Text(Strings.get("settingsAppearance", language: localization.currentLanguage))
                    .font(.headline)) {
                    
                    Toggle(isOn: $localization.isDarkMode) {
                        HStack(spacing: 12) {
                            Image(systemName: localization.isDarkMode ? "moon.fill" : "sun.max.fill")
                                .foregroundStyle(.orange)
                            Text(Strings.get("settingsDarkMode", language: localization.currentLanguage))
                        }
                    }
                    .tint(.blue)
                }
                
                // MARK: - Idioma
                Section(header: Text(Strings.get("settingsLanguage", language: localization.currentLanguage))
                    .font(.headline)) {
                    
                    Picker(Strings.get("settingsLanguage", language: localization.currentLanguage), 
                           selection: $localization.currentLanguage) {
                        HStack {
                            Image(systemName: "es")
                                .hidden()
                            Text(Strings.get("settingsSpanish", language: localization.currentLanguage))
                        }
                        .tag("es")
                        
                        HStack {
                            Image(systemName: "us")
                                .hidden()
                            Text(Strings.get("settingsEnglish", language: localization.currentLanguage))
                        }
                        .tag("en")
                    }
                    .pickerStyle(.segmented)
                }
                
                // MARK: - Tamaño de Texto
                Section(header: Text(Strings.get("settingsTextSize", language: localization.currentLanguage))
                    .font(.headline)) {
                    
                    HStack {
                        Text("A")
                            .font(.caption)
                        Slider(value: $appState.readingFontSize, in: 12...24, step: 1)
                            .frame(maxWidth: .infinity)
                        Text("A")
                            .font(.title3.bold())
                    }
                    
                    Text(String(format: "%.0f pt", appState.readingFontSize))
                        .foregroundStyle(.secondary)
                        .font(.caption)
                }
                
                // MARK: - Acerca de
                Section(header: Text(Strings.get("settingsAbout", language: localization.currentLanguage))
                    .font(.headline)) {
                    
                    VStack(alignment: .center, spacing: 12) {
                        Image(systemName: "book.circle.fill")
                            .font(.system(size: 48))
                            .foregroundStyle(.blue)
                        
                        Text("Mensajes de William Branham")
                            .font(.headline)
                        
                        Text(Strings.get("settingsAboutText", language: localization.currentLanguage))
                            .font(.caption)
                            .foregroundStyle(.secondary)
                            .multilineTextAlignment(.center)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 20)
                }
            }
            .navigationTitle(Strings.get("settingsTitle", language: localization.currentLanguage))
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(localization.isDarkMode ? .dark : .light)
        }
    }
}

#Preview {
    SettingsView()
        .environmentObject(AppState())
}
