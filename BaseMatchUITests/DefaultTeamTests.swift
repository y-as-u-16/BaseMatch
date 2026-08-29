import XCTest

/// デフォルトチームの切り替えを画面操作で確認する。
/// リポジトリ層は RepositoryTests が担保しているので、ここでは
/// 「行をタップするとバッジが移動し、再起動しても残る」ことだけを見る。
final class DefaultTeamTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-seedDemoData"]
        app.launch()
        Thread.sleep(forTimeInterval: 4)
    }

    func testTappingTeamMovesDefaultBadge() throws {
        openSettings()

        // デモデータのチームは1件なので、切り替え先をその場で作る。
        addTeam(named: "ウエストサイド")

        let seeded = app.buttons.containing(
            NSPredicate(format: "label CONTAINS %@", "イーストサイド")
        ).firstMatch
        let added = app.buttons.containing(
            NSPredicate(format: "label CONTAINS %@", "ウエストサイド")
        ).firstMatch

        XCTAssertTrue(seeded.waitForExistence(timeout: 5), "既存チームの行が無い")
        XCTAssertTrue(added.waitForExistence(timeout: 5), "追加したチームの行が無い")

        // 作成直後は既存チームがデフォルトのまま。
        XCTAssertTrue(seeded.label.contains("デフォルト"), "初期のデフォルトが違う: \(seeded.label)")
        XCTAssertFalse(added.label.contains("デフォルト"))

        added.tap()
        Thread.sleep(forTimeInterval: 1)

        capture(named: "settings-after-switch")
        XCTAssertTrue(added.label.contains("デフォルト"), "タップしてもバッジが移らない: \(added.label)")
        XCTAssertFalse(seeded.label.contains("デフォルト"), "元のバッジが外れていない: \(seeded.label)")
    }

    private func capture(named name: String) {
        let a = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        a.name = name
        a.lifetime = .keepAlways
        add(a)
    }

    // MARK: - 部品

    private func openSettings() {
        let gear = app.buttons["設定を開く"].firstMatch
        XCTAssertTrue(gear.waitForExistence(timeout: 10), "設定ボタンが見つからない")
        gear.tap()
        Thread.sleep(forTimeInterval: 1.5)
    }

    private func addTeam(named name: String) {
        let addButton = app.buttons.containing(
            NSPredicate(format: "label CONTAINS %@", "チームを追加")
        ).firstMatch
        XCTAssertTrue(addButton.waitForExistence(timeout: 5), "追加ボタンが見つからない")
        addButton.tap()
        Thread.sleep(forTimeInterval: 1)

        let field = app.textFields.firstMatch
        XCTAssertTrue(field.waitForExistence(timeout: 5), "チーム名の入力欄が無い")
        field.tap()
        field.typeText(name)

        // シートの確定ボタンは label がちょうど「追加」。一覧の「チームを追加」と
        // 取り違えないよう完全一致で引く。
        let confirm = app.buttons.matching(
            NSPredicate(format: "label == %@", "追加")
        ).firstMatch
        XCTAssertTrue(confirm.waitForExistence(timeout: 5), "確定ボタンが見つからない")
        confirm.tap()
        Thread.sleep(forTimeInterval: 1.5)
    }
}
