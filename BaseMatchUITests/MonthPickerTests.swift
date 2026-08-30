import XCTest

/// 年月ヘッダーから離れた月へ飛べることを確認する。
final class MonthPickerTests: XCTestCase {
    private var app: XCUIApplication!

    override func setUpWithError() throws {
        continueAfterFailure = false
        app = XCUIApplication()
        app.launchArguments = ["-seedDemoData", "-resetAppSettings"]
        app.launch()
        Thread.sleep(forTimeInterval: 4)
    }

    func testJumpToAnotherMonth() throws {
        app.tabBars.buttons.element(boundBy: 1).tap()
        Thread.sleep(forTimeInterval: 1.5)

        let header = app.buttons["monthHeader"].firstMatch
        XCTAssertTrue(header.waitForExistence(timeout: 10), "年月ヘッダーが押せない")
        let before = app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "\\d{4}/\\d{1,2}")).firstMatch.label
        header.tap()
        Thread.sleep(forTimeInterval: 1.5)

        // ホイールを回して別の年へ。
        let yearWheel = app.pickerWheels.element(boundBy: 0)
        XCTAssertTrue(yearWheel.waitForExistence(timeout: 5), "年のホイールが無い")
        yearWheel.adjust(toPickerWheelValue: "2025")
        Thread.sleep(forTimeInterval: 1)

        let shot = XCTAttachment(screenshot: XCUIScreen.main.screenshot())
        shot.name = "month-picker"
        shot.lifetime = .keepAlways
        add(shot)

        app.buttons["confirmMonth"].firstMatch.tap()
        Thread.sleep(forTimeInterval: 2)

        // ヘッダーの表示が変わっている。
        let after = app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "\\d{4}/\\d{1,2}")).firstMatch.label
        XCTAssertNotEqual(before, after, "月が移動していない")
        XCTAssertTrue(after.contains("2025"), "選んだ年になっていない: \(after)")
    }

    func testTodayButtonReturnsToCurrentMonth() throws {
        app.tabBars.buttons.element(boundBy: 1).tap()
        Thread.sleep(forTimeInterval: 1.5)

        let header = app.buttons["monthHeader"].firstMatch
        XCTAssertTrue(header.waitForExistence(timeout: 10))
        let thisMonth = app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "\\d{4}/\\d{1,2}")).firstMatch.label
        header.tap()
        Thread.sleep(forTimeInterval: 1.5)

        app.pickerWheels.element(boundBy: 0).adjust(toPickerWheelValue: "2025")
        Thread.sleep(forTimeInterval: 1)

        let today = app.buttons.containing(
            NSPredicate(format: "label CONTAINS %@", "今日")
        ).firstMatch
        XCTAssertTrue(today.waitForExistence(timeout: 5), "今日ボタンが無い")
        today.tap()
        Thread.sleep(forTimeInterval: 1)

        app.buttons["confirmMonth"].firstMatch.tap()
        Thread.sleep(forTimeInterval: 2)

        XCTAssertEqual(
            app.staticTexts.matching(NSPredicate(format: "label MATCHES %@", "\\d{4}/\\d{1,2}")).firstMatch.label, thisMonth,
            "今日ボタンで今月に戻らない"
        )
    }
}
