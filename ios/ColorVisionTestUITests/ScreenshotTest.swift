import XCTest

/// App Store screenshot capture. Not part of the regression suite —
/// run explicitly with:
///   xcodebuild test -only-testing:ColorVisionTestUITests/ScreenshotTest ...
/// then export the attachments from the .xcresult with xcresulttool
/// (ios/scripts/capture_screenshots.sh does the whole dance, including
/// the simctl status-bar override for the clean 9:41 look).
///
/// Drives: hero → calibration → control plate (answered correctly, so
/// the screening is valid) → can't-see through the rest → results with
/// the day-to-day meaning card → native Settings → Screening History.
final class ScreenshotTest: XCTestCase {
    private func snap(_ name: String) {
        let shot = XCUIScreen.main.screenshot()
        let att = XCTAttachment(screenshot: shot)
        att.name = name
        att.lifetime = .keepAlways
        add(att)
    }

    func testCaptureScreenshots() {
        let app = XCUIApplication()
        app.launch()
        let webView = app.webViews.firstMatch

        // 1. Hero
        let start = webView.buttons["Start Screening"]
        XCTAssertTrue(start.waitForExistence(timeout: 15))
        Thread.sleep(forTimeInterval: 1.0) // let the hero plate finish rendering
        snap("01-hero")
        start.tap()

        // 2. Calibration probe
        let patch = webView.buttons["Gray patch 1 of 4"]
        XCTAssertTrue(patch.waitForExistence(timeout: 10))
        Thread.sleep(forTimeInterval: 0.5)
        snap("02-calibration")
        patch.tap()

        let cantSee = webView.buttons["I can't see anything"]
        let skip = webView.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Skip'")).firstMatch
        for _ in 1...10 {
            if cantSee.exists { break }
            if skip.exists { skip.tap() }
            Thread.sleep(forTimeInterval: 0.5)
        }
        XCTAssertTrue(cantSee.waitForExistence(timeout: 10))

        // Demo plate (practice, unscored) — skip through.
        cantSee.tap()
        Thread.sleep(forTimeInterval: 0.6)

        // 3. Plate 1 — always the control plate ("12"). Capture it,
        // then answer correctly so the screening isn't inconclusive.
        snap("03-plate")
        let input = webView.textFields.firstMatch
        if input.waitForExistence(timeout: 5) {
            input.tap()
            input.typeText("12")
            webView.buttons["Next"].tap()
        }
        Thread.sleep(forTimeInterval: 0.6)

        // Remaining plates: can't-see through to results.
        for _ in 1...20 {
            guard cantSee.exists else { break }
            cantSee.tap()
            Thread.sleep(forTimeInterval: 0.4)
        }

        // 4. Results (with the what-this-means card populated)
        let resultBadge = webView.staticTexts["Color vision difference"]
        XCTAssertTrue(resultBadge.waitForExistence(timeout: 10))
        Thread.sleep(forTimeInterval: 1.0)
        snap("04-results")

        // 5. Native Settings
        let gear = webView.buttons["Settings"]
        XCTAssertTrue(gear.waitForExistence(timeout: 5))
        gear.tap()
        let historyCell = app.tables.staticTexts["Screening History"]
        XCTAssertTrue(historyCell.waitForExistence(timeout: 10))
        Thread.sleep(forTimeInterval: 0.5)
        snap("05-settings")

        // 6. Screening History with the saved result
        historyCell.tap()
        XCTAssertTrue(app.tables.cells.firstMatch.waitForExistence(timeout: 10))
        Thread.sleep(forTimeInterval: 0.5)
        snap("06-history")
    }
}
