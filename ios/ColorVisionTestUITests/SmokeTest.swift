import XCTest

/// End-to-end smoke test of the native shell and JS bridge.
///
/// Drives a full screening by answering "I can't see anything" on
/// every plate — failing the control plate is the deterministic path
/// to a completed (inconclusive) result — then verifies:
///   1. the bundled web app loads and the test runs,
///   2. the native CTA swap happened (single companion-app link),
///   3. the screeningResult bridge fired (the result shows up in the
///      native Screening History behind the settings gear).
final class SmokeTest: XCTestCase {
    func testFullScreeningReachesNativeHistory() {
        let app = XCUIApplication()
        app.launch()

        let webView = app.webViews.firstMatch
        let start = webView.buttons["Start Screening"]
        XCTAssertTrue(start.waitForExistence(timeout: 15), "bundled index.html did not load")
        start.tap()

        // Calibration probe: 4 gray patches, the odd-brighter one is
        // randomized. Tap patch 1; if that guess was wrong the Skip
        // button appears — take it. Either path lands on the test.
        let patch = webView.buttons["Gray patch 1 of 4"]
        XCTAssertTrue(patch.waitForExistence(timeout: 10), "calibration probe never appeared")
        patch.tap()

        let cantSee = webView.buttons["I can't see anything"]
        let skip = webView.buttons.matching(NSPredicate(format: "label BEGINSWITH 'Skip'")).firstMatch
        for _ in 1...20 {
            if cantSee.exists { break }
            if skip.exists { skip.tap() }
            Thread.sleep(forTimeInterval: 0.5)
        }
        XCTAssertTrue(cantSee.waitForExistence(timeout: 10), "test screen never appeared")

        // One tap dismisses the unscored demo plate, then 14 scored
        // plates follow. Loop until the test section leaves the
        // accessibility tree (results page sets display:none on it),
        // with headroom over the expected 15 taps.
        for _ in 1...20 {
            guard cantSee.exists else { break }
            cantSee.tap()
            Thread.sleep(forTimeInterval: 0.4)
        }

        // Results page: control-plate failure scores as Inconclusive.
        let resultLabel = webView.staticTexts["Inconclusive"]
        XCTAssertTrue(resultLabel.waitForExistence(timeout: 10), "results page never appeared")

        // Native CTA swap: exactly one companion-app link, no TestFlight/APK.
        XCTAssertTrue(webView.links["Get What Color Is This?"].waitForExistence(timeout: 5),
                      "native companion-app CTA missing — CVT_NATIVE block didn't run")
        XCTAssertFalse(webView.links["iOS beta (TestFlight)"].exists,
                       "TestFlight link leaked into the native build")

        // Settings gear → native Settings sheet → Screening History
        // shows the screening we just completed (bridge round-trip).
        let gear = webView.buttons["Settings"]
        XCTAssertTrue(gear.waitForExistence(timeout: 5), "settings gear missing")
        gear.tap()

        let historyCell = app.tables.staticTexts["Screening History"]
        XCTAssertTrue(historyCell.waitForExistence(timeout: 10), "native Settings sheet did not open")
        historyCell.tap()

        let savedResult = app.tables.staticTexts["Inconclusive"]
        XCTAssertTrue(savedResult.waitForExistence(timeout: 10),
                      "screeningResult message never reached the native ResultStore")
    }
}
