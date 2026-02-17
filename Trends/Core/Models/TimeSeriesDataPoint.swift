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

    var formattedValue: String {
        guard let value else { return "--" }
        return metric.formatValue(value)
    }

    var hasData: Bool {
        value != nil
    }
}
