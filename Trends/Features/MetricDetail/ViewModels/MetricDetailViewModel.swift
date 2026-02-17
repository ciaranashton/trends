import Foundation
import Observation

@Observable
final class MetricDetailViewModel {
    let metric: HealthMetric

    var dataPoints: [TimeSeriesDataPoint] = []
    var selectedRange: TimeRange = .week
    var isLoading = false

    var average: Double? {
        guard !dataPoints.isEmpty else { return nil }
        return dataPoints.map(\.value).reduce(0, +) / Double(dataPoints.count)
    }

    var minimum: Double? {
        dataPoints.map(\.value).min()
    }

    var maximum: Double? {
        dataPoints.map(\.value).max()
    }

    private let healthManager: HealthManager

    init(metric: HealthMetric, healthManager: HealthManager) {
        self.metric = metric
        self.healthManager = healthManager
    }

    func loadData() async {
        isLoading = true
        dataPoints = await healthManager.timeSeries(for: metric, range: selectedRange)
        isLoading = false
    }
}
