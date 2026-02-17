import Foundation

enum TimeRange: String, CaseIterable, Identifiable {
    case week = "7D"
    case month = "30D"
    case threeMonths = "90D"
    case year = "1Y"

    var id: String { rawValue }

    var days: Int {
        switch self {
        case .week: return 7
        case .month: return 30
        case .threeMonths: return 90
        case .year: return 365
        }
    }

    var startDate: Date {
        Calendar.current.date(byAdding: .day, value: -days, to: Date().startOfDay)!
    }

    var displayName: String {
        rawValue
    }
}
