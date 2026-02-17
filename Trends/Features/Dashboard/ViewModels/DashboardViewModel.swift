import Foundation
import Observation

@Observable
final class DashboardViewModel {
    var summaries: [MetricSummary] = []
    var isLoading = false

    private let healthManager: HealthManager

    init(healthManager: HealthManager) {
        self.healthManager = healthManager
    }

    func loadSummaries() async {
        isLoading = true

        let metrics = HealthMetric.allCases
        summaries = await withTaskGroup(of: MetricSummary.self) { group in
            for metric in metrics {
                group.addTask {
                    await self.loadSummaryWithSparkline(for: metric)
                }
            }

            var results: [MetricSummary] = []
            for await summary in group {
                results.append(summary)
            }
            return results
        }

        // Sort by the enum's declaration order
        let metricOrder = HealthMetric.allCases
        summaries.sort { a, b in
            let indexA = metricOrder.firstIndex(of: a.metric) ?? 0
            let indexB = metricOrder.firstIndex(of: b.metric) ?? 0
            return indexA < indexB
        }

        isLoading = false
    }

    private func loadSummaryWithSparkline(for metric: HealthMetric) async -> MetricSummary {
        // Fetch today's value and 7-day history concurrently
        async let todayResult = healthManager.todaySummary(for: metric)
        async let weekData = healthManager.timeSeries(for: metric, range: .week)

        let today = await todayResult
        let history = await weekData

        let sparklineValues = history.suffix(7).map(\.value)

        // Calculate trend: today vs 7-day average
        var trend: Double? = nil
        if let todayValue = today.value, !history.isEmpty {
            let avg = history.map(\.value).reduce(0, +) / Double(history.count)
            if avg > 0 {
                trend = ((todayValue - avg) / avg) * 100
            }
        }

        return MetricSummary(
            metric: metric,
            value: today.value,
            date: today.date,
            sparkline: sparklineValues,
            trend: trend
        )
    }

    func summaries(for category: HealthMetricCategory) -> [MetricSummary] {
        summaries.filter { $0.metric.category == category }
    }
}
