import Foundation
import Observation

@Observable
final class ScoreDetailViewModel {
    let scoreType: ScoreType

    var trendData: [ScoreTimeSeriesPoint] = []
    var selectedRange: TimeRange = .week
    var isLoading = false

    var average: Double? {
        guard !trendData.isEmpty else { return nil }
        return trendData.map(\.value).reduce(0, +) / Double(trendData.count)
    }

    var minimum: Double? {
        trendData.map(\.value).min()
    }

    var maximum: Double? {
        trendData.map(\.value).max()
    }

    private let scoreEngine: ScoreEngine

    init(scoreType: ScoreType, scoreEngine: ScoreEngine) {
        self.scoreType = scoreType
        self.scoreEngine = scoreEngine
    }

    func loadTrend() async {
        isLoading = true
        trendData = await scoreEngine.scoreTimeSeries(for: scoreType, range: selectedRange)
        isLoading = false
    }
}
