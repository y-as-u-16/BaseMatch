import XCTest

/// ホーム画面の「記録中の試合」導線を確認する。
final class HomeTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-seedDemoData", "-resetAppSettings"]
        app.launch()
        Thread.sleep(forTimeInterval: 4)
    }

    func testDraftGameCardOpensTheGame() throws {
        let card = app.descendants(matching: .any)
            .matching(identifier: "draftGameCard").firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 10), "記録中のカードが出ていない")

        card.tap()
        Thread.sleep(forTimeInterval: 2)

        // 試合詳細へ遷移している。
        XCTAssertTrue(
            app.buttons["deleteGame"].firstMatch.waitForExistence(timeout: 10),
            "試合詳細へ遷移していない"
        )
    }

    /// 記録途中の試合に勝敗を出すと確定済みに見えてしまう。
    func testDraftGameShowsRecordingInsteadOfResult() throws {
        let badge = app.staticTexts.matching(
            NSPredicate(format: "label == %@", "記録中")
        ).firstMatch
        XCTAssertTrue(badge.waitForExistence(timeout: 10), "記録中バッジが無い")
    }
}
