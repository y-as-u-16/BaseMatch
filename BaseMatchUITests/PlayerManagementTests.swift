import XCTest

/// 選手の改名とデフォルト切替を画面操作で確認する。
final class PlayerManagementTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-seedDemoData", "-resetAppSettings"]
        app.launch()
        Thread.sleep(forTimeInterval: 4)
        openSettings()
        addPlayer("田中")
        addPlayer("佐藤")
    }

    func testRenamingPlayerUpdatesTheList() throws {
        app.staticTexts["佐藤"].firstMatch.press(forDuration: 1.2)
        Thread.sleep(forTimeInterval: 1.5)

        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "名前を変更"))
            .firstMatch.tap()
        Thread.sleep(forTimeInterval: 1.5)

        let field = app.textFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 5), "入力欄が出ない")
        // 既存の名前が入っていること。
        XCTAssertEqual(field.value as? String, "佐藤", "現在の名前が入っていない")

        field.tap()
        field.typeText("次郎")
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "保存")).firstMatch.tap()
        Thread.sleep(forTimeInterval: 2)

        XCTAssertTrue(app.staticTexts["佐藤次郎"].waitForExistence(timeout: 5), "改名されていない")
    }

    func testSwitchingDefaultPlayer() throws {
        // 1人目が自動でデフォルトになっている。
        XCTAssertTrue(rowLabel(for: "田中").contains("デフォルト"), "1人目がデフォルトでない")

        app.staticTexts["佐藤"].firstMatch.press(forDuration: 1.2)
        Thread.sleep(forTimeInterval: 1.5)
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "デフォルトにする"))
            .firstMatch.tap()
        Thread.sleep(forTimeInterval: 2)

        XCTAssertTrue(rowLabel(for: "佐藤").contains("デフォルト"), "デフォルトが移っていない")
        XCTAssertFalse(rowLabel(for: "田中").contains("デフォルト"), "元のバッジが外れていない")
    }

    // MARK: - 部品

    private func openSettings() {
        app.buttons["設定を開く"].firstMatch.tap()
        Thread.sleep(forTimeInterval: 1.5)
    }

    private func addPlayer(_ name: String) {
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "選手を追加"))
            .firstMatch.tap()
        Thread.sleep(forTimeInterval: 1)
        let field = app.textFields.firstMatch
        field.tap()
        field.typeText(name)
        app.buttons.matching(NSPredicate(format: "label == %@", "追加")).firstMatch.tap()
        Thread.sleep(forTimeInterval: 1.5)
    }

    /// 行はバッジ込みで1要素にまとめられているため、行全体のラベルを見る。
    private func rowLabel(for name: String) -> String {
        app.descendants(matching: .any)
            .matching(NSPredicate(format: "label CONTAINS %@", name))
            .allElementsBoundByIndex
            .map(\.label)
            .first { $0.contains(name) } ?? ""
    }
}
