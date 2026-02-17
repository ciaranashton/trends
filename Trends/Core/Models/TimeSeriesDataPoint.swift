import Foundation

struct TimeSeriesDataPoint: Identifiable {
    let id = UUID()
    let date: Date
    let value: Double
}

struct MetricSummary: Identifiable {
    let id = UUID()
    let metric: HealthMetric
    let value: Double?
    let date: Date
    let sparkline: [Double]
    let trend: Double? // percentage change vs 7-day avg

    init(metric: HealthMetric, value: Double?, date: Date, sparkline: [Double] = [], trend: Double? = nil) {
        self.metric = metric
        self.value = value
        self.date = date
        self.sparkline = sparkline
        self.trend = trend
    }

    var formattedValue: String {
        guard let value else { return "--" }
        return metric.formatValue(value)
    }

    var hasData: Bool {
        value != nil
    }

    var trendDirection: TrendDirection {
        guard let trend else { return .flat }
        if trend > 3 { return .up }
        if trend < -3 { return .down }
        return .flat
    }

    var formattedTrend: String? {
        guard let trend, abs(trend) > 1 else { return nil }
        let sign = trend > 0 ? "+" : ""
        return "\(sign)\(String(format: "%.0f", trend))%"
    }
}

enum TrendDirection {
    case up, down, flat

    var icon: String {
        switch self {
        case .up: return "arrow.up.right"
        case .down: return "arrow.down.right"
        case .flat: return "arrow.right"
        }
    }
}
