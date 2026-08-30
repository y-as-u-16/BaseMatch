import XCTest

final class CreateGameLocalizationTests: XCTestCase {
    func testMyTeamPickerShowsTranslatedBadge() throws {
        let app = XCUIApplication()
        app.launchArguments = ["-seedDemoData", "-resetAppSettings"]
        app.launch()
        Thread.sleep(forTimeInterval: 4)

        app.tabBars.buttons.element(boundBy: 1).tap()
        Thread.sleep(forTimeInterval: 1.5)
        app.buttons.matching(NSPredicate(format: "label CONTAINS %@", "試合を追加")).firstMatch.tap()
        Thread.sleep(forTimeInterval: 2)

        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = "create-game"
        shot.lifetime = .keepAlways
        add(shot)

        // デバッグ表記が漏れていないこと。
        let leaked = app.staticTexts.containing(
            NSPredicate(format: "label CONTAINS %@ OR label CONTAINS %@", "LocalizationValue", "key:")
        ).firstMatch
        XCTAssertFalse(leaked.exists, "デバッグ表記が出ている: \(leaked.label)")
    }
}
