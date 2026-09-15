import UIKit
import WebKit

final class ContentViewController: UIViewController, WKUIDelegate, WKNavigationDelegate, WKScriptMessageHandler {
    private var webView: WKWebView!

    override func loadView() {
        let config = WKWebViewConfiguration()
        config.limitsNavigationsToAppBoundDomains = true
        config.websiteDataStore = .default()
        config.applicationNameForUserAgent = "ColorVisionTestIOS/1.0"

        let userController = WKUserContentController()
        // The flag index.html checks to switch into native-shell mode:
        // hides the web-only CTA paths, posts screening results to the
        // `screeningResult` handler, shows the settings gear.
        userController.addUserScript(WKUserScript(
            source: "window.CVT_NATIVE = true;",
            injectionTime: .atDocumentStart,
            forMainFrameOnly: true
        ))
        userController.add(self, name: "settings")
        userController.add(self, name: "screeningResult")
        userController.add(self, name: "share")

        // Screenshot-pipeline hook (ScreenshotTest sets this launch
        // environment; nothing else can on a real device). XCUITest
        // cannot reliably type into a WKWebView text field — the
        // post-keyboard relayout breaks tap delivery — so index.html's
        // showPlate answers the control plate itself when this flag is
        // present (same injection mechanism as CVT_NATIVE).
        if ProcessInfo.processInfo.environment["CVT_UITEST_AUTOANSWER"] != nil {
            userController.addUserScript(WKUserScript(
                source: "window.CVT_AUTOANSWER = true;",
                injectionTime: .atDocumentStart,
                forMainFrameOnly: true
            ))
        }

        let allowedUITestProfiles = ["calibration-inconclusive", "tritan-mild", "tritan-likely"]
        if let profile = ProcessInfo.processInfo.environment["CVT_UITEST_PROFILE"],
           allowedUITestProfiles.contains(profile) {
            userController.addUserScript(WKUserScript(
                source: "window.CVT_UITEST_PROFILE = '\(profile)';",
                injectionTime: .atDocumentStart,
                forMainFrameOnly: true
            ))
        }
        config.userContentController = userController

        webView = WKWebView(frame: .zero, configuration: config)
        webView.uiDelegate = self
        webView.navigationDelegate = self
        webView.allowsBackForwardNavigationGestures = false
        // Match the page background (#0d0d0d) so the safe-area regions
        // and load-in don't flash white around the dark page.
        let pageBackground = UIColor(red: 13/255, green: 13/255, blue: 13/255, alpha: 1)
        webView.isOpaque = false
        webView.backgroundColor = pageBackground
        webView.scrollView.backgroundColor = pageBackground

        view = webView
    }

    override var preferredStatusBarStyle: UIStatusBarStyle { .lightContent }

    override func viewDidLoad() {
        super.viewDidLoad()
        loadIndex()
    }

    // navigator.wakeLock is unavailable in WKWebView on some iOS
    // versions; the screening depends on the screen staying lit at a
    // stable brightness mid-test, so pin the idle timer for the whole
    // foreground lifetime instead of bridging acquire/release.
    override func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        UIApplication.shared.isIdleTimerDisabled = true
        ReviewPromptPolicy().recordSession()
    }

    override func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        UIApplication.shared.isIdleTimerDisabled = false
    }

    private func loadIndex() {
        guard let indexURL = Bundle.main.url(forResource: "index", withExtension: "html") else {
            assertionFailure("index.html missing from bundle")
            return
        }
        webView.loadFileURL(indexURL, allowingReadAccessTo: indexURL.deletingLastPathComponent())
    }

    // MARK: - WKNavigationDelegate

    // Memory pressure can evict the WebKit content process; without
    // this the app stays a blank rectangle until force-quit.
    func webViewWebContentProcessDidTerminate(_ webView: WKWebView) {
        loadIndex()
    }

    func webView(_ webView: WKWebView, decidePolicyFor navigationAction: WKNavigationAction, decisionHandler: @escaping (WKNavigationActionPolicy) -> Void) {
        guard let url = navigationAction.request.url else {
            decisionHandler(.allow)
            return
        }
        if url.isFileURL || url.scheme == "about" {
            decisionHandler(.allow)
            return
        }
        if url.scheme == "http" || url.scheme == "https" {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
            decisionHandler(.cancel)
            return
        }
        decisionHandler(.allow)
    }

    // MARK: - WKUIDelegate

    // WKWebView silently drops target="_blank" clicks (no second window
    // context exists). Forward them to Safari.
    func webView(_ webView: WKWebView,
                 createWebViewWith configuration: WKWebViewConfiguration,
                 for navigationAction: WKNavigationAction,
                 windowFeatures: WKWindowFeatures) -> WKWebView? {
        if let url = navigationAction.request.url,
           url.scheme == "http" || url.scheme == "https" {
            UIApplication.shared.open(url, options: [:], completionHandler: nil)
        }
        return nil
    }

    // MARK: - WKScriptMessageHandler (JS bridge)

    func userContentController(_ userContentController: WKUserContentController, didReceive message: WKScriptMessage) {
        switch message.name {
        case "settings":
            present(SettingsViewController.makeWrapped(), animated: true)
        case "screeningResult":
            guard let body = message.body as? [String: Any] else { return }
            ResultStore.shared.save(from: body)
            // Finished screening + saved history is a calm completion moment.
            ReviewPromptPolicy().noteSuccessAndRequestIfAppropriate()
        case "share":
            // navigator.share / navigator.clipboard don't exist in a
            // file:// WKWebView (not a secure context) — the page posts
            // here instead and gets the native share sheet.
            guard let body = message.body as? [String: Any] else { return }
            var items: [Any] = []
            if let text = body["text"] as? String { items.append(text) }
            if let urlString = body["url"] as? String, let url = URL(string: urlString) { items.append(url) }
            guard !items.isEmpty else { return }
            let sheet = UIActivityViewController(activityItems: items, applicationActivities: nil)
            sheet.popoverPresentationController?.sourceView = view
            sheet.popoverPresentationController?.sourceRect = CGRect(
                x: view.bounds.midX, y: view.bounds.midY, width: 1, height: 1
            )
            present(sheet, animated: true)
        default:
            break
        }
    }
}
