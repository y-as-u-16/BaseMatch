import XCTest

/// ホーム画面から試合詳細へ入る導線を確認する。
final class HomeTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-seedDemoData", "-resetAppSettings"]
        app.launch()
        Thread.sleep(forTimeInterval: 4)
    }

    func testRecentGameCardOpensTheGame() throws {
        let card = app.descendants(matching: .any)
            .matching(identifier: "recentGameCard").firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 10), "直近の試合カードが出ていない")

        card.tap()
        Thread.sleep(forTimeInterval: 2)

        XCTAssertTrue(
            app.buttons["deleteGame"].firstMatch.waitForExistence(timeout: 10),
            "試合詳細へ遷移していない"
        )
    }
}
