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
                    await self.healthManager.todaySummary(for: metric)
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

    func summaries(for category: HealthMetricCategory) -> [MetricSummary] {
        summaries.filter { $0.metric.category == category }
    }
}
