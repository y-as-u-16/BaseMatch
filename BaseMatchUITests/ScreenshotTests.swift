import XCTest

/// App Store 掲載用スクリーンショットを撮る。
/// デモデータは `-seedDemoData` でアプリ側が投入する。
/// UI テストはクローンされたシミュレータ上で動くため外部の simctl からは撮れない。
/// XCUIScreen で撮って xcresult の添付として持ち帰る。
final class ScreenshotTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-seedDemoData"]
        app.launch()
        // スプラッシュ 1.5 秒 + 遷移アニメーション
        Thread.sleep(forTimeInterval: 4)
    }

    func testCaptureAll() throws {
        capture(named: "01-home")

        tapTab(index: 1)
        Thread.sleep(forTimeInterval: 1.5)
        capture(named: "02-record")

        tapTab(index: 2)
        Thread.sleep(forTimeInterval: 1.5)
        capture(named: "03-stats")

        try capturePlateInput()
    }

    // MARK: - 打席入力

    /// 言語に依存しないよう accessibilityIdentifier で辿る。
    private func capturePlateInput() throws {
        tapTab(index: 1)
        Thread.sleep(forTimeInterval: 1.5)

        let card = app.descendants(matching: .any)
            .matching(identifier: "gameCard").firstMatch
        XCTAssertTrue(card.waitForExistence(timeout: 10), "試合カードが見つからない")
        card.tap()
        Thread.sleep(forTimeInterval: 1.5)

        let addPA = app.descendants(matching: .any)
            .matching(identifier: "addPlateAppearance").firstMatch
        XCTAssertTrue(addPA.waitForExistence(timeout: 10), "打席ボタンが見つからない")
        addPA.tap()
        Thread.sleep(forTimeInterval: 1.5)

        let chip = app.descendants(matching: .any)
            .matching(identifier: "chip-double").firstMatch
        XCTAssertTrue(chip.waitForExistence(timeout: 10), "二塁打チップが見つからない")
        chip.tap()
        Thread.sleep(forTimeInterval: 1.2)

        capture(named: "04-plate-input")
    }

    // MARK: - 部品

    private func tapTab(index: Int) {
        let tabs = app.tabBars.buttons
        guard tabs.count > index else { return }
        tabs.element(boundBy: index).tap()
    }

    private func capture(named name: String) {
        let shot = XCUIScreen.main.screenshot()
        let attachment = XCTAttachment(screenshot: shot)
        attachment.name = name
        attachment.lifetime = .keepAlways
        add(attachment)
    }
}
