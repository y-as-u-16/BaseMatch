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
        if let language = ProcessInfo.processInfo.environment["SCREENSHOT_LANGUAGE"] {
            app.launchArguments += ["-AppleLanguages", "(\(language))", "-AppleLocale", language]
        }
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

        capturePlateInput()
    }

    // MARK: - 打席入力

    private func capturePlateInput() {
        tapTab(index: 1)
        Thread.sleep(forTimeInterval: 1)

        // 選択日の試合カードを開く
        let card = app.buttons.containing(NSPredicate(format: "label CONTAINS %@", "vs")).firstMatch
        guard card.waitForExistence(timeout: 5) else { return }
        card.tap()
        Thread.sleep(forTimeInterval: 1.5)

        // 「打席」ボタン
        let addPA = app.buttons.matching(
            NSPredicate(format: "label == %@ OR label == %@", "打席", "At Bat")
        ).firstMatch
        guard addPA.waitForExistence(timeout: 5) else { return }
        addPA.tap()
        Thread.sleep(forTimeInterval: 1.5)

        // 結果チップを1つ選ぶ（二塁打 / Double）
        let chip = app.buttons.matching(
            NSPredicate(format: "label CONTAINS %@ OR label CONTAINS %@", "二塁打", "Double")
        ).firstMatch
        if chip.waitForExistence(timeout: 4) {
            chip.tap()
            Thread.sleep(forTimeInterval: 1)
        }

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
