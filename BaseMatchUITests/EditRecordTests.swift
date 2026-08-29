import XCTest

/// 打席記録の編集を画面操作で確認する。
/// 更新そのものは RepositoryTests が担保しているので、ここでは
/// 「既存の値が復元され、変更が一覧に反映されるか」を見る。
final class EditRecordTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-seedDemoData"]
        app.launch()
        Thread.sleep(forTimeInterval: 4)
    }

    func testEditPlateAppearanceRestoresAndSaves() throws {
        openTodaysGame()

        // デモデータの先頭打席は「田中 / 二塁打」。長押しで編集へ。
        let row = app.staticTexts["田中"].firstMatch
        XCTAssertTrue(row.waitForExistence(timeout: 10), "打席の行が見つからない")
        row.press(forDuration: 1.2)
        Thread.sleep(forTimeInterval: 1.5)

        let editItem = app.buttons.matching(
            NSPredicate(format: "label == %@", "編集")
        ).firstMatch
        XCTAssertTrue(editItem.waitForExistence(timeout: 5), "編集メニューが出ない")
        editItem.tap()
        Thread.sleep(forTimeInterval: 2)

        // 既存の値が復元されている。二塁打が選択済みで、打者名も入っている。
        let nameField = app.textFields.firstMatch
        XCTAssertTrue(nameField.waitForExistence(timeout: 5), "打者名の欄が無い")
        XCTAssertEqual(nameField.value as? String, "田中", "打者名が復元されていない")

        // 結果を本塁打に変えて保存する。
        let hrChip = app.descendants(matching: .any)
            .matching(identifier: "chip-hr").firstMatch
        XCTAssertTrue(hrChip.waitForExistence(timeout: 5), "本塁打チップが無い")
        hrChip.tap()
        Thread.sleep(forTimeInterval: 0.8)

        let save = app.buttons.containing(
            NSPredicate(format: "label CONTAINS %@", "登録する")
        ).firstMatch
        XCTAssertTrue(save.waitForExistence(timeout: 5), "保存ボタンが無い")
        save.tap()
        Thread.sleep(forTimeInterval: 2)

        // 詳細画面に戻り、変更が反映されている。
        let updated = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS %@", "本塁打")
        ).firstMatch
        XCTAssertTrue(updated.waitForExistence(timeout: 10), "変更が反映されていない")
    }

    // MARK: - 部品

    private func openTodaysGame() {
        app.tabBars.buttons.element(boundBy: 1).tap()
        Thread.sleep(forTimeInterval: 1.5)

        let card = app.descendants(matching: .any)
            .matching(identifier: "gameCard").firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 10), "試合カードが見つからない")
        card.tap()
        Thread.sleep(forTimeInterval: 1.5)
    }
}
