import Foundation

/// One completed screening, as posted by index.html's showResults()
/// through the `screeningResult` message handler. Fields mirror the
/// web result object; the date is stamped natively on save.
struct ScreeningResult: Codable {
    let date: Date
    let type: String      // scoring-cascade vision_type, e.g. "normal", "deutan", "inconclusive"
    let label: String     // human label, e.g. "Likely Green-Type Color Difference"
    let rgFailed: Int
    let rgTotal: Int
    let byFailed: Int
    let byTotal: Int
}

final class ResultStore {
    static let shared = ResultStore()
    static let changedNotification = Notification.Name("ColorVisionTestHistoryChanged")

    private let key = "screeningHistory"
    private let maxEntries = 100

    /// Newest first.
    private(set) var results: [ScreeningResult] = []

    private init() {
        if let data = UserDefaults.standard.data(forKey: key),
           let decoded = try? JSONDecoder().decode([ScreeningResult].self, from: data) {
            results = decoded
        }
    }

    func save(from body: [String: Any]) {
        guard let type = body["type"] as? String,
              let label = body["label"] as? String else { return }
        let result = ScreeningResult(
            date: Date(),
            type: type,
            label: label,
            rgFailed: body["rgFailed"] as? Int ?? 0,
            rgTotal: body["rgTotal"] as? Int ?? 0,
            byFailed: body["byFailed"] as? Int ?? 0,
            byTotal: body["byTotal"] as? Int ?? 0
        )
        results.insert(result, at: 0)
        if results.count > maxEntries {
            results.removeLast(results.count - maxEntries)
        }
        persist()
    }

    func clear() {
        results = []
        persist()
    }

    private func persist() {
        if let data = try? JSONEncoder().encode(results) {
            UserDefaults.standard.set(data, forKey: key)
        }
        NotificationCenter.default.post(name: Self.changedNotification, object: nil)
    }
}
