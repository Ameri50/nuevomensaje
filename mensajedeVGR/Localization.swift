import Foundation

// MARK: - Localization Manager
class LocalizationManager: ObservableObject {
    static let shared = LocalizationManager()
    
    @Published var currentLanguage: String = UserDefaults.standard.string(forKey: "appLanguage") ?? "es" {
        didSet {
            UserDefaults.standard.set(currentLanguage, forKey: "appLanguage")
        }
    }
    
    @Published var isDarkMode: Bool = UserDefaults.standard.bool(forKey: "isDarkMode") {
        didSet {
            UserDefaults.standard.set(isDarkMode, forKey: "isDarkMode")
        }
    }
    
    func getString(_ key: String) -> String {
        return Strings.get(key, language: currentLanguage)
    }
}

// MARK: - All Strings
struct Strings {
    // MARK: - Tab Labels
    static let tabHome = [
        "es": "Inicio",
        "en": "Home"
    ]
    static let tabMessages = [
        "es": "Mensajes",
        "en": "Messages"
    ]
    static let tabFavorites = [
        "es": "Favoritos",
        "en": "Favorites"
    ]
    static let tabImport = [
        "es": "Importar",
        "en": "Import"
    ]
    static let tabAI = [
        "es": "IA",
        "en": "AI"
    ]
    static let tabSettings = [
        "es": "Ajustes",
        "en": "Settings"
    ]
    
    // MARK: - Home View
    static let homeTitle = [
        "es": "Mensajes de William Branham",
        "en": "Messages by William Branham"
    ]
    static let homeSubtitle = [
        "es": "Busca, estudia y escucha los mensajes.",
        "en": "Search, study and listen to messages."
    ]
    static let homeSearch = [
        "es": "Buscar mensajes, referencias o temas",
        "en": "Search messages, references or topics"
    ]
    static let homeContinueReading = [
        "es": "Continuar leyendo",
        "en": "Continue Reading"
    ]
    static let homeRecentMessages = [
        "es": "Mensajes recientes",
        "en": "Recent Messages"
    ]
    static let homeAuthorizedSources = [
        "es": "Fuentes autorizadas",
        "en": "Authorized Sources"
    ]
    static let homeAuthorizationNote = [
        "es": "La biblioteca solo debe incluir audios, PDFs y transcripciones que el usuario tenga autorización para usar.",
        "en": "The library should only include audio, PDFs and transcriptions that the user is authorized to use."
    ]
    static let homeReferenceSource = [
        "es": "Fuente referencial: branham.org/es/messageaudio",
        "en": "Reference source: branham.org/en/messageaudio"
    ]
    static let homeUnauthorizedWarning = [
        "es": "Importar contenido protegido sin autorización no está permitido.",
        "en": "Importing protected content without authorization is not allowed."
    ]
    static let homeAskMessages = [
        "es": "Pregúntale a los Mensajes",
        "en": "Ask the Messages"
    ]
    
    // MARK: - Settings View
    static let settingsTitle = [
        "es": "Ajustes",
        "en": "Settings"
    ]
    static let settingsAppearance = [
        "es": "Apariencia",
        "en": "Appearance"
    ]
    static let settingsDarkMode = [
        "es": "Modo Oscuro",
        "en": "Dark Mode"
    ]
    static let settingsLanguage = [
        "es": "Idioma",
        "en": "Language"
    ]
    static let settingsSpanish = [
        "es": "Español",
        "en": "Spanish"
    ]
    static let settingsEnglish = [
        "es": "Inglés",
        "en": "English"
    ]
    static let settingsTextSize = [
        "es": "Tamaño de Texto",
        "en": "Text Size"
    ]
    static let settingsAbout = [
        "es": "Acerca de",
        "en": "About"
    ]
    static let settingsAboutText = [
        "es": "Versión 1.0\n\nAplicación de estudio de los mensajes de William Branham.",
        "en": "Version 1.0\n\nApplication to study the messages of William Branham."
    ]
    
    // MARK: - Common
    static let ok = [
        "es": "OK",
        "en": "OK"
    ]
    static let cancel = [
        "es": "Cancelar",
        "en": "Cancel"
    ]
    static let save = [
        "es": "Guardar",
        "en": "Save"
    ]
    static let close = [
        "es": "Cerrar",
        "en": "Close"
    ]
    static let search = [
        "es": "Buscar",
        "en": "Search"
    ]
    
    // MARK: - Getter
    static func get(_ key: String, language: String) -> String {
        let dict = stringDictionary[key] ?? [:]
        return dict[language] ?? dict["es"] ?? key
    }
    
    private static let stringDictionary: [String: [String: String]] = [
        "tabHome": tabHome,
        "tabMessages": tabMessages,
        "tabFavorites": tabFavorites,
        "tabImport": tabImport,
        "tabAI": tabAI,
        "tabSettings": tabSettings,
        "homeTitle": homeTitle,
        "homeSubtitle": homeSubtitle,
        "homeSearch": homeSearch,
        "homeContinueReading": homeContinueReading,
        "homeRecentMessages": homeRecentMessages,
        "homeAuthorizedSources": homeAuthorizedSources,
        "homeAuthorizationNote": homeAuthorizationNote,
        "homeReferenceSource": homeReferenceSource,
        "homeUnauthorizedWarning": homeUnauthorizedWarning,
        "homeAskMessages": homeAskMessages,
        "settingsTitle": settingsTitle,
        "settingsAppearance": settingsAppearance,
        "settingsDarkMode": settingsDarkMode,
        "settingsLanguage": settingsLanguage,
        "settingsSpanish": settingsSpanish,
        "settingsEnglish": settingsEnglish,
        "settingsTextSize": settingsTextSize,
        "settingsAbout": settingsAbout,
        "settingsAboutText": settingsAboutText,
        "ok": ok,
        "cancel": cancel,
        "save": save,
        "close": close,
        "search": search
    ]
}

// MARK: - Extension para acceso rápido
extension String {
    static func localized(_ key: String, language: String? = nil) -> String {
        let lang = language ?? LocalizationManager.shared.currentLanguage
        return Strings.get(key, language: lang)
    }
}
