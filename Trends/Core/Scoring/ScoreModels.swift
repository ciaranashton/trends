import Foundation
import SwiftUI

// MARK: - Score Type

enum ScoreType: String, CaseIterable, Identifiable, Hashable {
    case sleep
    case recovery
    case effort

    var id: String { rawValue }

    var displayName: String {
        switch self {
        case .sleep: return "Sleep"
        case .recovery: return "Recovery"
        case .effort: return "Effort"
        }
    }

    var systemImage: String {
        switch self {
        case .sleep: return "bed.double.fill"
        case .recovery: return "arrow.counterclockwise.heart"
        case .effort: return "flame.fill"
        }
    }

    var maxValue: Double {
        switch self {
        case .sleep, .recovery: return 100
        case .effort: return 21
        }
    }

    func formatValue(_ value: Double) -> String {
        switch self {
        case .sleep, .recovery: return String(format: "%.0f", value)
        case .effort: return String(format: "%.1f", value)
        }
    }

    func color(for value: Double) -> Color {
        switch self {
        case .sleep:
            switch value {
            case 85...100: return .green
            case 70..<85: return .teal
            case 50..<70: return .yellow
            default: return .red
            }
        case .recovery:
            switch value {
            case 67...100: return .green
            case 34..<67: return .yellow
            default: return .red
            }
        case .effort:
            switch value {
            case 18...21: return .red
            case 14..<18: return .orange
            case 7..<14: return .green
            default: return .blue
            }
        }
    }

    func label(for value: Double) -> String {
        switch self {
        case .sleep:
            switch value {
            case 85...100: return "Excellent"
            case 70..<85: return "Good"
            case 50..<70: return "Fair"
            default: return "Poor"
            }
        case .recovery:
            switch value {
            case 67...100: return "Recovered"
            case 34..<67: return "Moderate"
            default: return "Low"
            }
        case .effort:
            switch value {
            case 18...21: return "All-Out"
            case 14..<18: return "High"
            case 7..<14: return "Moderate"
            default: return "Light"
            }
        }
    }

    var zoneBands: [(label: String, range: ClosedRange<Double>, color: Color)] {
        switch self {
        case .sleep:
            return [
                ("Poor", 0...49, .red),
                ("Fair", 50...69, .yellow),
                ("Good", 70...84, .teal),
                ("Excellent", 85...100, .green),
            ]
        case .recovery:
            return [
                ("Low", 0...33, .red),
                ("Moderate", 34...66, .yellow),
                ("Recovered", 67...100, .green),
            ]
        case .effort:
            return [
                ("Light", 0...6.9, .blue),
                ("Moderate", 7...13.9, .green),
                ("High", 14...17.9, .orange),
                ("All-Out", 18...21, .red),
            ]
        }
    }
}

// MARK: - Score Result

struct ScoreResult: Identifiable {
    let id = UUID()
    let type: ScoreType
    let value: Double
    let components: [ScoreComponent]
    let date: Date
    let insight: String?

    var color: Color { type.color(for: value) }
    var label: String { type.label(for: value) }
    var formattedValue: String { type.formatValue(value) }
}

// MARK: - Score Component

struct ScoreComponent: Identifiable {
    let id = UUID()
    let name: String
    let rawValue: Double?
    let rawUnit: String
    let score: Double       // 0-100 sub-score
    let weight: Double      // 0-1
    let weightedScore: Double

    var formattedRaw: String {
        guard let rawValue else { return "--" }
        if rawUnit == "hrs" {
            let hours = Int(rawValue)
            let minutes = Int((rawValue - Double(hours)) * 60)
            return "\(hours)h \(minutes)m"
        }
        if rawUnit == "%" {
            return String(format: "%.1f%%", rawValue * 100)
        }
        return String(format: "%.1f", rawValue) + (rawUnit.isEmpty ? "" : " \(rawUnit)")
    }
}

// MARK: - Score Time Series Point

struct ScoreTimeSeriesPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}
