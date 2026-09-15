import UIKit

final class SettingsViewController: UITableViewController {
    private enum Row {
        case history, about, privacy, licenses, version, clearHistory
    }

    private let rows: [Row] = [.history, .about, .privacy, .licenses, .version, .clearHistory]

    static func makeWrapped() -> UINavigationController {
        let vc = SettingsViewController(style: .insetGrouped)
        return UINavigationController(rootViewController: vc)
    }

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "Settings"
        navigationItem.rightBarButtonItem = UIBarButtonItem(
            barButtonSystemItem: .done,
            target: self,
            action: #selector(dismissSelf)
        )
    }

    @objc private func dismissSelf() {
        dismiss(animated: true)
    }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        rows.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .value1, reuseIdentifier: nil)
        switch rows[indexPath.row] {
        case .history:
            cell.textLabel?.text = "Screening History"
            cell.accessoryType = .disclosureIndicator
        case .about:
            cell.textLabel?.text = "About"
            cell.accessoryType = .disclosureIndicator
        case .privacy:
            cell.textLabel?.text = "Privacy"
            cell.accessoryType = .disclosureIndicator
        case .licenses:
            cell.textLabel?.text = "Sources & Licenses"
            cell.accessoryType = .disclosureIndicator
        case .version:
            cell.textLabel?.text = "Version"
            let v = Bundle.main.infoDictionary?["CFBundleShortVersionString"] as? String ?? "?"
            let b = Bundle.main.infoDictionary?["CFBundleVersion"] as? String ?? "?"
            cell.detailTextLabel?.text = "\(v) (\(b))"
            cell.selectionStyle = .none
        case .clearHistory:
            cell.textLabel?.text = "Clear Screening History"
            cell.textLabel?.textColor = .systemRed
        }
        return cell
    }

    override func tableView(_ tableView: UITableView, didSelectRowAt indexPath: IndexPath) {
        tableView.deselectRow(at: indexPath, animated: true)
        switch rows[indexPath.row] {
        case .history:
            navigationController?.pushViewController(HistoryViewController(style: .insetGrouped), animated: true)
        case .about:
            push(textController(title: "About", text: Self.aboutText))
        case .privacy:
            push(textController(title: "Privacy", text: Self.privacyText))
        case .licenses:
            push(textController(title: "Sources & Licenses", text: Self.licensesText))
        case .version:
            break
        case .clearHistory:
            confirmClearHistory()
        }
    }

    private func push(_ vc: UIViewController) {
        navigationController?.pushViewController(vc, animated: true)
    }

    private func textController(title: String, text: String) -> UIViewController {
        let vc = UIViewController()
        vc.view.backgroundColor = .systemBackground
        vc.title = title
        let textView = UITextView()
        textView.translatesAutoresizingMaskIntoConstraints = false
        textView.isEditable = false
        textView.alwaysBounceVertical = true
        textView.font = .preferredFont(forTextStyle: .body)
        textView.adjustsFontForContentSizeCategory = true
        textView.textContainerInset = UIEdgeInsets(top: 24, left: 16, bottom: 24, right: 16)
        textView.text = text
        vc.view.addSubview(textView)
        NSLayoutConstraint.activate([
            textView.leadingAnchor.constraint(equalTo: vc.view.leadingAnchor),
            textView.trailingAnchor.constraint(equalTo: vc.view.trailingAnchor),
            textView.topAnchor.constraint(equalTo: vc.view.topAnchor),
            textView.bottomAnchor.constraint(equalTo: vc.view.bottomAnchor)
        ])
        return vc
    }

    private func confirmClearHistory() {
        let alert = UIAlertController(
            title: "Clear Screening History?",
            message: "This erases all saved screening results from this device. It cannot be undone.",
            preferredStyle: .alert
        )
        alert.addAction(UIAlertAction(title: "Cancel", style: .cancel))
        alert.addAction(UIAlertAction(title: "Clear", style: .destructive) { _ in
            ResultStore.shared.clear()
        })
        present(alert, animated: true)
    }

    // MARK: - Static copy

    private static let aboutText = """
    Color Vision Plates

    A 14-plate color vision screening that tests for red-green and \
    blue-yellow color vision deficiency and attempts to classify \
    red-green deficiency as protan-type (red-weak) or deutan-type \
    (green-weak).

    It combines Ishihara-style number plates and HRR-style shape \
    plates with confusion-line geometry from Brettel, Viénot & Mollon \
    (1997), scored with the CIEDE2000 color-difference formula. Plate \
    1 is a luminance-contrast control: if it is missed, the result is \
    flagged as inconclusive rather than guessed.

    This is a screening, not a medical diagnosis. Display calibration, \
    Night Shift / True Tone, screen brightness, and ambient lighting \
    all affect screen-based color tests. See an eye care professional \
    for a clinical evaluation.

    Made by Luke Steuber, published by Bridge City Lab LLC. Free. No \
    accounts, no ads, no tracking. Companion app: What Color Is This? \
    (whatcoloristhis.one).
    """

    private static let privacyText = """
    Everything stays on your device.

    The test runs entirely offline from files bundled with the app. \
    Your answers and screening results are stored only on this device \
    (you can erase them with “Clear Screening History”). Nothing is \
    uploaded, no account exists, there are no analytics and no \
    tracking of any kind.

    Links to external sites (the companion app, methodology sources) \
    open in your browser; those sites have their own policies.
    """

    private static let licensesText = """
    Color Vision Plates: MIT License, © Luke Steuber

    METHODOLOGY SOURCES

    Ishihara, S. (1917). Tests for Colour-Blindness. Handaya, Tokyo.

    Hardy, L.H., Rand, G., & Rittler, M.C. (1954). HRR \
    Pseudoisochromatic Plates for Detecting and Classifying Color \
    Vision Deficiency. American Optical Company.

    Brettel, H., Viénot, F., & Mollon, J.D. (1997). Computerized \
    simulation of color appearance for dichromats. Journal of the \
    Optical Society of America A, 14(10), 2647–2655.

    Sharma, G., Wu, W., & Dalal, E.N. (2005). The CIEDE2000 \
    color-difference formula: implementation notes, supplementary \
    test data, and mathematical observations. Color Research & \
    Application, 30(1), 21–30.

    Birch, J. (2012). Worldwide prevalence of red-green color \
    deficiency. Journal of the Optical Society of America A, 29(3), \
    313–320.

    Cole, B.L. (2007). Assessment of inherited colour vision defects \
    in clinical practice. Clinical and Experimental Optometry, 90(3), \
    157–175.

    The CIEDE2000 and Brettel dichromacy algorithms are public \
    algorithms; this app uses original implementations shared with \
    the What Color Is This? project.
    """
}
