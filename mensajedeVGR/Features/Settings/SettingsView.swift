import SwiftUI

struct SettingsView: View {
    @EnvironmentObject private var localization: LocalizationManager  // ← CAMBIADO a EnvironmentObject
    @EnvironmentObject private var appState: AppState
    
    var body: some View {
        NavigationStack {
            Form {
                // MARK: - Apariencia
                Section(header: Text(localization.getString("settingsAppearance"))
                    .font(.headline)) {
                        
                        Toggle(isOn: $localization.isDarkMode) {
                            HStack(spacing: 12) {
                                Image(systemName: localization.isDarkMode ? "moon.fill" : "sun.max.fill")
                                    .foregroundStyle(.orange)
                                Text(localization.getString("settingsDarkMode"))
                            }
                        }
                        .tint(.blue)
                    }
                // MARK: - Idioma
                Section(header: Text(localization.getString("settingsLanguage"))
                    .font(.headline)) {
                        
                        Picker(localization.getString("settingsLanguage"),
                               selection: $localization.currentLanguage) {
                            Text(localization.getString("settingsSpanish"))
                                .tag("es")
                            
                            Text(localization.getString("settingsEnglish"))
                                .tag("en")
                        }
                               .pickerStyle(.segmented)
                    }
                
                // MARK: - Tamaño de Texto
                Section(header: Text(localization.getString("settingsTextSize"))
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
                Section(header: Text(localization.getString("settingsAbout"))
                    .font(.headline)) {
                        
                        VStack(alignment: .center, spacing: 12) {
                            Image(systemName: "book.circle.fill")
                                .font(.system(size: 48))
                                .foregroundStyle(.blue)
                            
                            Text(localization.getString("homeTitle"))
                                .font(.headline)
                            
                            Text(localization.getString("settingsAboutText"))
                                .font(.caption)
                                .foregroundStyle(.secondary)
                                .multilineTextAlignment(.center)
                        }
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 20)
                    }
            }
            .navigationTitle(localization.getString("settingsTitle"))
            .navigationBarTitleDisplayMode(.inline)
            .preferredColorScheme(localization.isDarkMode ? .dark : .light)
        }
    }
    
    
}
