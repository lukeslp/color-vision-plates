import UIKit

/// Native results history — each completed screening is saved locally
/// and listed newest-first, so retests over time can be compared
/// (display conditions change results far more often than vision does;
/// the footer says so).
final class HistoryViewController: UITableViewController {
    private var results = ResultStore.shared.results

    private lazy var dateFormatter: DateFormatter = {
        let f = DateFormatter()
        f.dateStyle = .medium
        f.timeStyle = .short
        return f
    }()

    override func viewDidLoad() {
        super.viewDidLoad()
        title = "History"
        NotificationCenter.default.addObserver(
            self, selector: #selector(reload),
            name: ResultStore.changedNotification, object: nil
        )
        updateEmptyState()
    }

    @objc private func reload() {
        results = ResultStore.shared.results
        tableView.reloadData()
        updateEmptyState()
    }

    private func updateEmptyState() {
        if results.isEmpty {
            let label = UILabel()
            label.text = "No screenings yet.\nFinish a test and it will show up here."
            label.numberOfLines = 0
            label.textAlignment = .center
            label.textColor = .secondaryLabel
            label.font = .preferredFont(forTextStyle: .body)
            tableView.backgroundView = label
        } else {
            tableView.backgroundView = nil
        }
    }

    override func numberOfSections(in tableView: UITableView) -> Int { 1 }

    override func tableView(_ tableView: UITableView, numberOfRowsInSection section: Int) -> Int {
        results.count
    }

    override func tableView(_ tableView: UITableView, cellForRowAt indexPath: IndexPath) -> UITableViewCell {
        let cell = UITableViewCell(style: .subtitle, reuseIdentifier: nil)
        let r = results[indexPath.row]

        cell.textLabel?.text = r.label
        cell.textLabel?.numberOfLines = 0

        var detail = dateFormatter.string(from: r.date)
        if r.rgTotal > 0 || r.byTotal > 0 {
            detail += "  ·  red-green \(r.rgTotal - r.rgFailed)/\(r.rgTotal), blue-yellow \(r.byTotal - r.byFailed)/\(r.byTotal)"
        }
        // Compare against the chronologically previous screening (the
        // next row down, since the list is newest-first).
        if indexPath.row + 1 < results.count {
            let previous = results[indexPath.row + 1]
            if previous.type != r.type {
                detail += "\nChanged from “\(previous.label)”"
            }
        }
        cell.detailTextLabel?.text = detail
        cell.detailTextLabel?.numberOfLines = 0
        cell.detailTextLabel?.textColor = .secondaryLabel
        cell.selectionStyle = .none
        return cell
    }

    override func tableView(_ tableView: UITableView, titleForFooterInSection section: Int) -> String? {
        guard !results.isEmpty else { return nil }
        return "Results vary with screen brightness, Night Shift / True Tone, and ambient light. A changed result usually reflects viewing conditions, not a change in your vision. This is a screening, not a medical diagnosis."
    }
}
