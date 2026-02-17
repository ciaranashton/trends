import Foundation

final class BaselineStore {
    private let defaults = UserDefaults.standard
    private let keyPrefix = "baseline_"
    private let windowDays = 14

    // Population defaults for cold start
    static let populationDefaults: [String: Double] = [
        "hrv": 40,
        "restingHR": 65,
        "respiratoryRate": 15,
        "sleepHours": 7,
        "activeEnergy": 500,
        "exerciseMinutes": 30,
        "steps": 8000,
    ]

    // MARK: - Data Point Storage

    private struct BaselineEntry: Codable {
        let date: Date
        let value: Double
    }

    private func storageKey(_ metric: String) -> String {
        "\(keyPrefix)\(metric)"
    }

    private func loadEntries(for metric: String) -> [BaselineEntry] {
        guard let data = defaults.data(forKey: storageKey(metric)),
              let entries = try? JSONDecoder().decode([BaselineEntry].self, from: data)
        else { return [] }
        return entries
    }

    private func saveEntries(_ entries: [BaselineEntry], for metric: String) {
        let cutoff = Calendar.current.date(byAdding: .day, value: -windowDays, to: Date())!
        let trimmed = entries.filter { $0.date >= cutoff }
        if let data = try? JSONEncoder().encode(trimmed) {
            defaults.set(data, forKey: storageKey(metric))
        }
    }

    // MARK: - Public API

    func record(metric: String, value: Double, date: Date = Date()) {
        var entries = loadEntries(for: metric)
        // Replace if same day exists
        let dayStart = Calendar.current.startOfDay(for: date)
        entries.removeAll { Calendar.current.isDate($0.date, inSameDayAs: dayStart) }
        entries.append(BaselineEntry(date: dayStart, value: value))
        saveEntries(entries, for: metric)
    }

    func baseline(for metric: String) -> (average: Double, stddev: Double, count: Int) {
        let entries = loadEntries(for: metric)
        let count = entries.count

        if count == 0 {
            let pop = Self.populationDefaults[metric] ?? 0
            return (pop, pop * 0.15, 0) // 15% estimated stddev
        }

        let values = entries.map(\.value)
        let avg = values.reduce(0, +) / Double(count)
        let variance = values.map { ($0 - avg) * ($0 - avg) }.reduce(0, +) / Double(count)
        let stddev = sqrt(variance)

        // Cold start blending: <7 days → blend with population defaults
        if count < 7, let pop = Self.populationDefaults[metric] {
            let personalWeight = Double(count) / 7.0
            let blendedAvg = personalWeight * avg + (1 - personalWeight) * pop
            let popStddev = pop * 0.15
            let blendedStddev = personalWeight * max(stddev, 0.01) + (1 - personalWeight) * popStddev
            return (blendedAvg, blendedStddev, count)
        }

        return (avg, max(stddev, 0.01), count)
    }

    /// Returns a clamped z-score in [-3, +3]
    func zScore(for metric: String, value: Double) -> Double {
        let b = baseline(for: metric)
        guard b.stddev > 0 else { return 0 }
        let z = (value - b.average) / b.stddev
        return min(max(z, -3), 3)
    }
}
