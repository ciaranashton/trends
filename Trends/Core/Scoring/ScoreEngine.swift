import Foundation
import Observation

@Observable
final class ScoreEngine {
    var sleepScore: ScoreResult?
    var recoveryScore: ScoreResult?
    var effortScore: ScoreResult?
    var isLoading = false

    private let healthManager: HealthManager
    private let baselineStore = BaselineStore()

    init(healthManager: HealthManager) {
        self.healthManager = healthManager
    }

    @MainActor
    func computeScores() async {
        isLoading = true

        // Fetch all data concurrently
        async let sleepData = healthManager.detailedSleepData()
        async let hrvValue = healthManager.todayValue(for: .heartRateVariability)
        async let restingHRValue = healthManager.todayValue(for: .restingHeartRate)
        async let respiratoryRateValue = healthManager.todayValue(for: .respiratoryRate)
        async let activeEnergyValue = healthManager.todayValue(for: .activeEnergy)
        async let exerciseTimeValue = healthManager.todayValue(for: .exerciseTime)
        async let stepsValue = healthManager.todayValue(for: .steps)
        async let avgHRValue = healthManager.todayValue(for: .heartRate)

        let sleep = await sleepData
        let hrv = await hrvValue
        let restingHR = await restingHRValue
        let rr = await respiratoryRateValue
        let energy = await activeEnergyValue
        let exercise = await exerciseTimeValue
        let steps = await stepsValue
        let avgHR = await avgHRValue

        // Record baselines for sleep
        if sleep.totalHours > 0 {
            baselineStore.record(metric: "sleepHours", value: sleep.totalHours)
        }

        // 1. Sleep Score
        let sleepCalc = SleepScoreCalculator()
        let sleepResult = sleepCalc.calculate(data: sleep)
        self.sleepScore = sleepResult

        // 2. Recovery Score (depends on sleep)
        let recoveryCalc = RecoveryScoreCalculator(baselineStore: baselineStore)
        self.recoveryScore = recoveryCalc.calculate(
            hrv: hrv,
            restingHR: restingHR,
            respiratoryRate: rr,
            sleepScore: sleepResult.value
        )

        // 3. Effort Score
        let effortCalc = EffortScoreCalculator(baselineStore: baselineStore)
        self.effortScore = effortCalc.calculate(
            activeEnergy: energy,
            exerciseMinutes: exercise,
            steps: steps,
            averageHR: avgHR,
            restingHR: restingHR
        )

        isLoading = false
    }

    // MARK: - Historical Scores

    func scoreTimeSeries(for type: ScoreType, range: TimeRange) async -> [ScoreTimeSeriesPoint] {
        let start = range.startDate
        let end = Date()
        let calendar = Calendar.current

        var points: [ScoreTimeSeriesPoint] = []
        var current = start

        while current <= end {
            let dayEnd = calendar.date(byAdding: .day, value: 1, to: current)!

            let value: Double? = await computeHistoricalScore(type: type, dayStart: current, dayEnd: dayEnd)

            if let value {
                points.append(ScoreTimeSeriesPoint(date: current, value: value))
            }

            current = dayEnd
        }

        return points
    }

    private func computeHistoricalScore(type: ScoreType, dayStart: Date, dayEnd: Date) async -> Double? {
        switch type {
        case .sleep:
            let data = await healthManager.detailedSleepData(for: dayStart)
            guard data.totalHours > 0 else { return nil }
            return SleepScoreCalculator().calculate(data: data).value

        case .recovery:
            let data = await healthManager.detailedSleepData(for: dayStart)
            guard data.totalHours > 0 else { return nil }
            let sleepVal = SleepScoreCalculator().calculate(data: data).value
            let hrv = await healthManager.dayValue(for: .heartRateVariability, date: dayStart)
            let rhr = await healthManager.dayValue(for: .restingHeartRate, date: dayStart)
            let rr = await healthManager.dayValue(for: .respiratoryRate, date: dayStart)
            let calc = RecoveryScoreCalculator(baselineStore: baselineStore)
            return calc.calculate(hrv: hrv, restingHR: rhr, respiratoryRate: rr, sleepScore: sleepVal).value

        case .effort:
            let energy = await healthManager.dayValue(for: .activeEnergy, date: dayStart)
            let exercise = await healthManager.dayValue(for: .exerciseTime, date: dayStart)
            let steps = await healthManager.dayValue(for: .steps, date: dayStart)
            let avgHR = await healthManager.dayValue(for: .heartRate, date: dayStart)
            let rhr = await healthManager.dayValue(for: .restingHeartRate, date: dayStart)
            guard energy != nil || exercise != nil || steps != nil else { return nil }
            let calc = EffortScoreCalculator(baselineStore: baselineStore)
            return calc.calculate(
                activeEnergy: energy,
                exerciseMinutes: exercise,
                steps: steps,
                averageHR: avgHR,
                restingHR: rhr
            ).value
        }
    }
}
