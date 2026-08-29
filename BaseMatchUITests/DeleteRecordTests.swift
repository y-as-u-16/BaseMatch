import XCTest

/// 削除導線を画面操作で確認する。
/// カスケード削除そのものは RepositoryTests が担保しているので、
/// ここでは「確認ダイアログを経て実際に消えるか」だけを見る。
final class DeleteRecordTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-seedDemoData"]
        app.launch()
        Thread.sleep(forTimeInterval: 4)
    }

    func testDeleteGameFromDetail() throws {
        openTodaysGame()

        let deleteButton = app.buttons["deleteGame"].firstMatch
        XCTAssertTrue(deleteButton.waitForExistence(timeout: 10), "削除ボタンが見つからない")
        deleteButton.tap()
        Thread.sleep(forTimeInterval: 1)

        // 確認ダイアログの破棄ボタン。一覧に戻ることまで確認する。
        let confirm = app.buttons.matching(
            NSPredicate(format: "label == %@", "削除")
        ).firstMatch
        XCTAssertTrue(confirm.waitForExistence(timeout: 5), "確認ダイアログが出ていない")
        confirm.tap()
        Thread.sleep(forTimeInterval: 2)

        // 記録画面へ戻り、その日の試合が消えている。
        let emptyLabel = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS %@", "この日の試合はありません")
        ).firstMatch
        XCTAssertTrue(emptyLabel.waitForExistence(timeout: 10), "試合が消えていない")
    }

    func testCancelKeepsGame() throws {
        openTodaysGame()

        app.buttons["deleteGame"].firstMatch.tap()
        Thread.sleep(forTimeInterval: 1)

        // ポップオーバー表示ではキャンセルボタンが描画されない（枠外タップで閉じる仕様）。
        // ボタンを探すのではなく、実際の操作と同じく枠外をタップする。
        let dialog = app.sheets.firstMatch
        XCTAssertTrue(dialog.waitForExistence(timeout: 5), "確認ダイアログが出ていない")

        app.coordinate(withNormalizedOffset: CGVector(dx: 0.5, dy: 0.95)).tap()
        Thread.sleep(forTimeInterval: 1.5)

        // 詳細画面に留まっている。
        XCTAssertTrue(app.buttons["deleteGame"].firstMatch.exists, "画面が閉じてしまった")
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
