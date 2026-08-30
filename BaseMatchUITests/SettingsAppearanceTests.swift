import XCTest

/// 言語とテーマの切り替えを画面操作で確認する。
/// L10n は Environment を見ないため、実際に文言が変わるかは
/// 画面を動かさないと分からない。
final class SettingsAppearanceTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        // 言語・テーマの選択は UserDefaults に残る。前のテストの結果を
        // 引き継がないよう毎回初期化してから起動する。
        app.launchArguments = ["-seedDemoData", "-resetAppSettings"]
        app.launch()
        Thread.sleep(forTimeInterval: 4)
    }

    func testSwitchingLanguageChangesUIText() throws {
        openSettings()

        // 日本語で表示されている。
        XCTAssertTrue(
            app.staticTexts["言語"].waitForExistence(timeout: 5),
            "設定画面が日本語で出ていない"
        )

        selectPickerOption(picker: "言語", option: "English")
        Thread.sleep(forTimeInterval: 2)

        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = "after-language-switch"
        shot.lifetime = .keepAlways
        add(shot)

        // 英語に切り替わっている。
        XCTAssertTrue(
            app.staticTexts["Language"].waitForExistence(timeout: 10),
            "英語に切り替わっていない"
        )
        XCTAssertFalse(app.staticTexts["言語"].exists, "日本語表記が残っている")
    }

    func testSwitchingThemePersistsSelection() throws {
        openSettings()

        selectPickerOption(picker: "外観", option: "ダーク")
        Thread.sleep(forTimeInterval: 1.5)

        // 選択が反映されている（Picker の現在値として表示される）。
        let picker = app.buttons.containing(
            NSPredicate(format: "label CONTAINS %@", "外観")
        ).firstMatch
        XCTAssertTrue(picker.waitForExistence(timeout: 5), "外観の行が無い")
        XCTAssertTrue(picker.label.contains("ダーク"), "選択が反映されていない: \(picker.label)")
    }

    func testLanguageAppliesToOtherScreens() throws {
        openSettings()
        selectPickerOption(picker: "言語", option: "English")
        Thread.sleep(forTimeInterval: 2)

        app.buttons["Done"].firstMatch.tap()
        Thread.sleep(forTimeInterval: 1.5)

        // ホームのタブと見出しが英語になっている。
        XCTAssertTrue(
            app.staticTexts["Record your games"].waitForExistence(timeout: 10),
            "ホーム画面が英語になっていない"
        )

        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = "home-in-english"
        shot.lifetime = .keepAlways
        add(shot)
    }

    // MARK: - 部品

    private func openSettings() {
        let gear = app.buttons["設定を開く"].firstMatch
        XCTAssertTrue(gear.waitForExistence(timeout: 10), "設定ボタンが見つからない")
        gear.tap()
        Thread.sleep(forTimeInterval: 1.5)
    }

    private func selectPickerOption(picker: String, option: String) {
        let row = app.buttons.containing(
            NSPredicate(format: "label CONTAINS %@", picker)
        ).firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 5), "\(picker) の行が無い")
        row.tap()
        Thread.sleep(forTimeInterval: 1)

        let choice = app.buttons.matching(
            NSPredicate(format: "label == %@", option)
        ).firstMatch
        XCTAssertTrue(choice.waitForExistence(timeout: 5), "\(option) の選択肢が無い")
        choice.tap()
    }
}
