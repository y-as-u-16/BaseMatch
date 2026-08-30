import XCTest

/// 選手の登録から記録入力での選択、成績の絞り込みまでを通しで確認する。
final class PlayerTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-seedDemoData", "-resetAppSettings"]
        app.launch()
        Thread.sleep(forTimeInterval: 4)
    }

    func testAddPlayerThenPickItWhenRecording() throws {
        addPlayer(named: "山田")

        // 打席入力を開き、メニューから選べる。
        app.tabBars.buttons.element(boundBy: 1).tap()
        Thread.sleep(forTimeInterval: 1.5)
        app.descendants(matching: .any).matching(identifier: "gameCard").firstMatch.tap()
        Thread.sleep(forTimeInterval: 1.5)
        app.descendants(matching: .any).matching(identifier: "addPlateAppearance").firstMatch.tap()
        Thread.sleep(forTimeInterval: 1.5)

        let picker = app.descendants(matching: .any)
            .matching(identifier: "playerPicker").firstMatch
        XCTAssertTrue(picker.waitForExistence(timeout: 10), "選手メニューが出ない")
        picker.tap()
        Thread.sleep(forTimeInterval: 1)

        let option = app.buttons.matching(NSPredicate(format: "label == %@", "山田")).firstMatch
        XCTAssertTrue(option.waitForExistence(timeout: 5), "登録した選手が候補に無い")
        option.tap()
        Thread.sleep(forTimeInterval: 1)

        let field = app.textFields.firstMatch
        XCTAssertEqual(field.value as? String, "山田", "選んだ名前が入っていない")
    }

    func testStatsCanBeFilteredByPlayer() throws {
        app.tabBars.buttons.element(boundBy: 2).tap()
        Thread.sleep(forTimeInterval: 2)

        let filter = app.descendants(matching: .any)
            .matching(identifier: "playerFilter").firstMatch
        XCTAssertTrue(filter.waitForExistence(timeout: 10), "絞り込みが出ていない")

        // 絞り込む前は複数の選手が並んでいる。
        XCTAssertTrue(app.staticTexts["田中"].exists, "田中が居ない")
        XCTAssertTrue(app.staticTexts["佐藤"].exists, "佐藤が居ない")

        filter.tap()
        Thread.sleep(forTimeInterval: 1)
        app.buttons.matching(NSPredicate(format: "label == %@", "田中")).firstMatch.tap()
        Thread.sleep(forTimeInterval: 1.5)

        XCTAssertTrue(app.staticTexts["田中"].exists, "絞り込み後に田中が消えた")
        XCTAssertFalse(app.staticTexts["佐藤"].exists, "絞り込みが効いていない")
    }

    // MARK: - 部品

    private func addPlayer(named name: String) {
        app.buttons["設定を開く"].firstMatch.tap()
        Thread.sleep(forTimeInterval: 1.5)

        let addButton = app.buttons.containing(
            NSPredicate(format: "label CONTAINS %@", "選手を追加")
        ).firstMatch
        XCTAssertTrue(addButton.waitForExistence(timeout: 5), "選手追加ボタンが無い")
        addButton.tap()
        Thread.sleep(forTimeInterval: 1)

        let field = app.textFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 5), "選手名の入力欄が無い")
        field.tap()
        field.typeText(name)

        app.buttons.matching(NSPredicate(format: "label == %@", "追加")).firstMatch.tap()
        Thread.sleep(forTimeInterval: 1.5)

        XCTAssertTrue(app.staticTexts[name].waitForExistence(timeout: 5), "選手が追加されていない")

        app.buttons["完了"].firstMatch.tap()
        Thread.sleep(forTimeInterval: 1.5)
    }
}
