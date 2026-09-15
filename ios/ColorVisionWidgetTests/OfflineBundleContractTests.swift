import XCTest

final class OfflineBundleContractTests: XCTestCase {
    func testNativeHTMLHasNoRemoteSubresources() throws {
        let bundle = Bundle(for: OfflineBundleContractTests.self)
        let url = try XCTUnwrap(bundle.url(forResource: "index", withExtension: "html"))
        let html = try String(contentsOf: url, encoding: .utf8)

        XCTAssertFalse(html.contains("src=\"https://"))
        XCTAssertFalse(html.contains("<script src=\"https://"))
        XCTAssertFalse(html.contains("href=\"https://whatcoloristhis.one/favicon.ico\""))
        XCTAssertFalse(html.contains("href=\"https://whatcoloristhis.one/apple-touch-icon.png\""))
        XCTAssertTrue(html.contains("src=\"icon-512.png\""))
    }
}
