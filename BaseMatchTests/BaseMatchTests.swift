//
//  BaseMatchTests.swift
//  BaseMatchTests
//

import Foundation
import Testing
@testable import BaseMatch

struct BaseMatchTests {

    @Test func example() async throws {
        // Write your test here and use APIs like `#expect(...)` to check expected conditions.
        // Swift Testing Documentation
        // https://developer.apple.com/documentation/testing
    }

}

@Suite("L10n の言語切り替え")
@MainActor
struct L10nLocaleTests {
    @Test("locale を渡すと訳が切り替わる")
    func overrideLocaleSwitchesTranslation() {
        let original = l10nOverrideLocale
        defer { l10nOverrideLocale = original }

        l10nOverrideLocale = Locale(identifier: "ja_JP")
        let ja = String(localized: L10n.settingsLanguage)

        l10nOverrideLocale = Locale(identifier: "en_US")
        let en = String(localized: L10n.settingsLanguage)

        #expect(ja == "言語")
        #expect(en == "Language")
    }
}

@Suite("AppSettings")
@MainActor
struct AppSettingsTests {
    @Test("言語を変えると L10n に反映される")
    func changingLanguageUpdatesL10n() {
        let defaults = UserDefaults(suiteName: "test-\(UUID().uuidString)")!
        let settings = AppSettings(defaults: defaults)

        settings.language = .english
        #expect(String(localized: L10n.settingsLanguage) == "Language")

        settings.language = .japanese
        #expect(String(localized: L10n.settingsLanguage) == "言語")
    }
}
