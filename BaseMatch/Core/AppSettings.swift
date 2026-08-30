import SwiftUI

enum AppLanguage: String, CaseIterable, Identifiable {
    case system
    case japanese = "ja"
    case english = "en"

    var id: String { rawValue }

    var label: LocalizedStringResource {
        switch self {
        case .system: L10n.followSystemLabel
        case .japanese: "日本語"
        case .english: "English"
        }
    }

    /// system のときは端末設定に任せるため nil を返す。
    var locale: Locale? {
        switch self {
        case .system: nil
        case .japanese: Locale(identifier: "ja_JP")
        case .english: Locale(identifier: "en_US")
        }
    }
}

enum AppThemeMode: String, CaseIterable, Identifiable {
    case system
    case light
    case dark

    var id: String { rawValue }

    var label: LocalizedStringResource {
        switch self {
        case .system: L10n.followSystemLabel
        case .light: L10n.lightThemeLabel
        case .dark: L10n.darkThemeLabel
        }
    }

    var colorScheme: ColorScheme? {
        switch self {
        case .system: nil
        case .light: .light
        case .dark: .dark
        }
    }
}

/// 言語とテーマの選択を保持する。UserDefaults に永続化される。
@Observable
final class AppSettings {
    /// @Observable は didSet を素通りさせることがあるため、永続化と
    /// L10n への反映は setter を明示的に書いて確実に走らせる。
    var language: AppLanguage {
        get { storedLanguage }
        set {
            storedLanguage = newValue
            defaults.set(newValue.rawValue, forKey: Keys.language)
            l10nOverrideLocale = newValue.locale
        }
    }

    var theme: AppThemeMode {
        get { storedTheme }
        set {
            storedTheme = newValue
            defaults.set(newValue.rawValue, forKey: Keys.theme)
        }
    }

    private var storedLanguage: AppLanguage
    private var storedTheme: AppThemeMode

    private let defaults: UserDefaults

    init(defaults: UserDefaults = .standard) {
        self.defaults = defaults

        // UI テストが前回の選択を引き継がないようにする。
        if CommandLine.arguments.contains("-resetAppSettings") {
            defaults.removeObject(forKey: Keys.language)
            defaults.removeObject(forKey: Keys.theme)
        }

        storedLanguage = defaults.string(forKey: Keys.language)
            .flatMap(AppLanguage.init(rawValue:)) ?? .system
        storedTheme = defaults.string(forKey: Keys.theme)
            .flatMap(AppThemeMode.init(rawValue:)) ?? .system

        // setter は init 中に呼べないため、起動時のぶんは直接反映する。
        l10nOverrideLocale = storedLanguage.locale
    }

    private enum Keys {
        static let language = "settings.language"
        static let theme = "settings.theme"
    }
}
