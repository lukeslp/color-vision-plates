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
        // Arms the shell's screenshot hook: the control plate answers
        // itself in-page (ContentViewController gates the injection on
        // this variable; it cannot be set on a production device).
        app.launchEnvironment["CVT_UITEST_AUTOANSWER"] = "1"
        app.launch()
        let webView = app.webViews.firstMatch

        // 1. Hero
        let start = webView.buttons["Start Screening"]
        XCTAssertTrue(start.waitForExistence(timeout: 15))
        Thread.sleep(forTimeInterval: 1.0) // let the hero plate finish rendering
        snap("01-hero")
        start.tap()

        // 2. Calibration probe
        // The screenshot hook fixes the brighter patch at index 3.
        let patch = webView.buttons["Gray patch 4 of 4"]
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

        // Demo plate (practice, unscored) — skip through. The control
        // plate then answers itself through the CVT_AUTOANSWER hook
        // (armed via launch environment above): XCUITest cannot type
        // into this WKWebView, so the test never touches the text
        // field or the keyboard. The control plate must score correct
        // or the run ends Inconclusive — the results assertion below
        // catches that.
        cantSee.tap()
        Thread.sleep(forTimeInterval: 0.6)

        // Wait for the autoanswer (fires 2.5s after plate 1 shows)
        // BEFORE the can't-see loop — otherwise the loop answers the
        // control plate first and the hook's currentPlate guard makes
        // it a no-op. Then can't-see through the rest. Number plates
        // autofocus and raise the keyboard, so 03-plate is captured on
        // the first shape plate instead — keyboard-free, and it shows
        // the HRR shape buttons.
        // Case-insensitive: .plate-label has text-transform:uppercase
        // and the iOS 26.5 runtime reflects the transform into the
        // accessibility label ('PLATE 2 OF 14'); 26.4 did not.
        let plate2 = webView.staticTexts.matching(
            NSPredicate(format: "label ==[c] %@", "Plate 2 of 14")
        ).firstMatch
        XCTAssertTrue(plate2.waitForExistence(timeout: 10), "autoanswer hook never advanced the control plate")
        let circle = webView.buttons["Circle"]
        var plateSnapped = false
        for _ in 1...25 {
            guard cantSee.exists else { break }
            if !plateSnapped && circle.exists {
                Thread.sleep(forTimeInterval: 0.5)
                snap("03-plate")
                plateSnapped = true
            }
            cantSee.tap()
            Thread.sleep(forTimeInterval: 0.4)
        }

        // 4. Results (with the what-this-means card populated)
        let resultBadge = webView.staticTexts["Answer pattern"]
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
