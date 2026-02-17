import Foundation
import HealthKit
import Observation

@Observable
final class HealthManager {
    private let healthStore = HKHealthStore()

    var isAuthorized = false

    func requestAuthorization() async throws {
        guard HKHealthStore.isHealthDataAvailable() else { return }

        try await healthStore.requestAuthorization(
            toShare: [],
            read: HealthDataTypes.allReadTypes
        )
        isAuthorized = true
    }

    // MARK: - Today's Summary

    func todaySummary(for metric: HealthMetric) async -> MetricSummary {
        if metric == .sleepAnalysis {
            return await sleepSummaryForToday(metric: metric)
        }

        do {
            let value = try await queryTodayStatistics(for: metric)
            return MetricSummary(metric: metric, value: value, date: .now)
        } catch {
            return MetricSummary(metric: metric, value: nil, date: .now)
        }
    }

    // MARK: - Time Series

    func timeSeries(for metric: HealthMetric, range: TimeRange) async -> [TimeSeriesDataPoint] {
        if metric == .sleepAnalysis {
            return await sleepTimeSeries(range: range)
        }

        do {
            return try await queryStatisticsCollection(for: metric, range: range)
        } catch {
            return []
        }
    }

    // MARK: - Private: Quantity Statistics

    private func queryTodayStatistics(for metric: HealthMetric) async throws -> Double? {
        let start = Date().startOfDay
        let end = Date()
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        let quantityType = metric.hkQuantityType

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsQuery(
                quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: metric.statisticsOption
            ) { _, statistics, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let statistics else {
                    continuation.resume(returning: nil)
                    return
                }

                let value: Double?
                if metric.isCumulative {
                    value = statistics.sumQuantity()?.doubleValue(for: metric.hkUnit)
                } else {
                    value = statistics.averageQuantity()?.doubleValue(for: metric.hkUnit)
                }

                continuation.resume(returning: value)
            }
            healthStore.execute(query)
        }
    }

    private func queryStatisticsCollection(
        for metric: HealthMetric,
        range: TimeRange
    ) async throws -> [TimeSeriesDataPoint] {
        let start = range.startDate
        let end = Date()
        let interval = DateComponents(day: 1)
        let anchorDate = Calendar.current.startOfDay(for: start)
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        let quantityType = metric.hkQuantityType

        return try await withCheckedThrowingContinuation { continuation in
            let query = HKStatisticsCollectionQuery(
                quantityType: quantityType,
                quantitySamplePredicate: predicate,
                options: metric.statisticsOption,
                anchorDate: anchorDate,
                intervalComponents: interval
            )

            query.initialResultsHandler = { _, results, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                guard let results else {
                    continuation.resume(returning: [])
                    return
                }

                var dataPoints: [TimeSeriesDataPoint] = []
                results.enumerateStatistics(from: start, to: end) { statistics, _ in
                    let value: Double?
                    if metric.isCumulative {
                        value = statistics.sumQuantity()?.doubleValue(for: metric.hkUnit)
                    } else {
                        value = statistics.averageQuantity()?.doubleValue(for: metric.hkUnit)
                    }

                    if let value {
                        dataPoints.append(TimeSeriesDataPoint(date: statistics.startDate, value: value))
                    }
                }

                continuation.resume(returning: dataPoints)
            }

            healthStore.execute(query)
        }
    }

    // MARK: - Private: Sleep

    private func sleepSummaryForToday(metric: HealthMetric) async -> MetricSummary {
        let sleepType = HKCategoryType(.sleepAnalysis)
        let start = Calendar.current.date(byAdding: .day, value: -1, to: Date().startOfDay)!
        let end = Date()
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)

        do {
            let samples = try await queryCategorySamples(type: sleepType, predicate: predicate)
            let totalHours = aggregateSleepHours(from: samples)
            let value = totalHours > 0 ? totalHours : nil
            return MetricSummary(metric: metric, value: value, date: .now)
        } catch {
            return MetricSummary(metric: metric, value: nil, date: .now)
        }
    }

    private func sleepTimeSeries(range: TimeRange) async -> [TimeSeriesDataPoint] {
        let sleepType = HKCategoryType(.sleepAnalysis)
        let start = range.startDate
        let end = Date()
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)

        do {
            let samples = try await queryCategorySamples(type: sleepType, predicate: predicate)
            return aggregateSleepByNight(from: samples, start: start, end: end)
        } catch {
            return []
        }
    }

    private func queryCategorySamples(
        type: HKCategoryType,
        predicate: NSPredicate
    ) async throws -> [HKCategorySample] {
        try await withCheckedThrowingContinuation { continuation in
            let query = HKSampleQuery(
                sampleType: type,
                predicate: predicate,
                limit: HKObjectQueryNoLimit,
                sortDescriptors: [NSSortDescriptor(key: HKSampleSortIdentifierStartDate, ascending: true)]
            ) { _, samples, error in
                if let error {
                    continuation.resume(throwing: error)
                    return
                }

                let categorySamples = (samples as? [HKCategorySample]) ?? []
                continuation.resume(returning: categorySamples)
            }
            healthStore.execute(query)
        }
    }

    private func aggregateSleepHours(from samples: [HKCategorySample]) -> Double {
        let asleepValues: Set<Int> = [
            HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
            HKCategoryValueSleepAnalysis.asleepCore.rawValue,
            HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
            HKCategoryValueSleepAnalysis.asleepREM.rawValue
        ]

        let totalSeconds = samples
            .filter { asleepValues.contains($0.value) }
            .reduce(0.0) { $0 + $1.endDate.timeIntervalSince($1.startDate) }

        return totalSeconds / 3600.0
    }

    private func aggregateSleepByNight(
        from samples: [HKCategorySample],
        start: Date,
        end: Date
    ) -> [TimeSeriesDataPoint] {
        let asleepValues: Set<Int> = [
            HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue,
            HKCategoryValueSleepAnalysis.asleepCore.rawValue,
            HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
            HKCategoryValueSleepAnalysis.asleepREM.rawValue
        ]

        let asleepSamples = samples.filter { asleepValues.contains($0.value) }

        var nightlyHours: [Date: Double] = [:]
        for sample in asleepSamples {
            // Attribute sleep to the night it started (use noon as the cutoff)
            let calendar = Calendar.current
            let sampleDate = sample.startDate
            let hour = calendar.component(.hour, from: sampleDate)
            let nightDate: Date
            if hour < 12 {
                nightDate = calendar.date(byAdding: .day, value: -1, to: sampleDate.startOfDay)!
            } else {
                nightDate = sampleDate.startOfDay
            }

            let duration = sample.endDate.timeIntervalSince(sample.startDate) / 3600.0
            nightlyHours[nightDate, default: 0] += duration
        }

        return nightlyHours
            .map { TimeSeriesDataPoint(date: $0.key, value: $0.value) }
            .filter { $0.date >= start && $0.date <= end }
            .sorted { $0.date < $1.date }
    }

    private func nightDate(for sampleDate: Date) -> Date {
        let calendar = Calendar.current
        let hour = calendar.component(.hour, from: sampleDate)
        if hour < 12 {
            return calendar.date(byAdding: .day, value: -1, to: sampleDate.startOfDay)!
        } else {
            return sampleDate.startOfDay
        }
    }

    // MARK: - Score Support: Single Value Queries

    func todayValue(for metric: HealthMetric) async -> Double? {
        guard metric.isQuantityType else { return nil }
        do {
            return try await queryTodayStatistics(for: metric)
        } catch {
            return nil
        }
    }

    func dayValue(for metric: HealthMetric, date: Date) async -> Double? {
        guard metric.isQuantityType else { return nil }
        let start = Calendar.current.startOfDay(for: date)
        let end = Calendar.current.date(byAdding: .day, value: 1, to: start)!
        let predicate = HKQuery.predicateForSamples(withStart: start, end: end)
        let quantityType = metric.hkQuantityType

        do {
            return try await withCheckedThrowingContinuation { continuation in
                let query = HKStatisticsQuery(
                    quantityType: quantityType,
                    quantitySamplePredicate: predicate,
                    options: metric.statisticsOption
                ) { _, statistics, error in
                    if let error {
                        continuation.resume(throwing: error)
                        return
                    }
                    guard let statistics else {
                        continuation.resume(returning: nil)
                        return
                    }
                    let value: Double?
                    if metric.isCumulative {
                        value = statistics.sumQuantity()?.doubleValue(for: metric.hkUnit)
                    } else {
                        value = statistics.averageQuantity()?.doubleValue(for: metric.hkUnit)
                    }
                    continuation.resume(returning: value)
                }
                healthStore.execute(query)
            }
        } catch {
            return nil
        }
    }

    // MARK: - Detailed Sleep Data

    func detailedSleepData(for date: Date? = nil) async -> DetailedSleepData {
        let calendar = Calendar.current
        let targetDay = date ?? calendar.date(byAdding: .day, value: -1, to: Date().startOfDay)!
        // Look from the evening before through the next morning
        let queryStart = calendar.date(bySettingHour: 18, minute: 0, second: 0, of: targetDay)!
        let queryEnd = calendar.date(byAdding: .hour, value: 18, to: queryStart)! // noon next day

        let sleepType = HKCategoryType(.sleepAnalysis)
        let predicate = HKQuery.predicateForSamples(withStart: queryStart, end: queryEnd)

        do {
            let samples = try await queryCategorySamples(type: sleepType, predicate: predicate)
            return buildDetailedSleepData(from: samples, targetNight: targetDay)
        } catch {
            return DetailedSleepData.empty
        }
    }

    private func buildDetailedSleepData(
        from samples: [HKCategorySample],
        targetNight: Date
    ) -> DetailedSleepData {
        var coreSeconds = 0.0
        var deepSeconds = 0.0
        var remSeconds = 0.0
        var unspecifiedSeconds = 0.0
        var inBedSeconds = 0.0
        var bedtime: Date?
        var wakeTime: Date?

        for sample in samples {
            let duration = sample.endDate.timeIntervalSince(sample.startDate)

            switch sample.value {
            case HKCategoryValueSleepAnalysis.inBed.rawValue:
                inBedSeconds += duration
                if bedtime == nil || sample.startDate < bedtime! {
                    bedtime = sample.startDate
                }
                if wakeTime == nil || sample.endDate > wakeTime! {
                    wakeTime = sample.endDate
                }
            case HKCategoryValueSleepAnalysis.asleepCore.rawValue:
                coreSeconds += duration
            case HKCategoryValueSleepAnalysis.asleepDeep.rawValue:
                deepSeconds += duration
            case HKCategoryValueSleepAnalysis.asleepREM.rawValue:
                remSeconds += duration
            case HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue:
                unspecifiedSeconds += duration
            default:
                break
            }
        }

        // If no explicit inBed samples, estimate from asleep range
        if inBedSeconds == 0 {
            let asleepSamples = samples.filter {
                [HKCategoryValueSleepAnalysis.asleepCore.rawValue,
                 HKCategoryValueSleepAnalysis.asleepDeep.rawValue,
                 HKCategoryValueSleepAnalysis.asleepREM.rawValue,
                 HKCategoryValueSleepAnalysis.asleepUnspecified.rawValue].contains($0.value)
            }
            if let first = asleepSamples.first, let last = asleepSamples.last {
                bedtime = first.startDate
                wakeTime = last.endDate
            }
        }

        let totalAsleepSeconds = coreSeconds + deepSeconds + remSeconds + unspecifiedSeconds
        let hasStageData = deepSeconds > 0 || remSeconds > 0

        return DetailedSleepData(
            totalHours: totalAsleepSeconds / 3600,
            coreHours: coreSeconds / 3600,
            deepHours: deepSeconds / 3600,
            remHours: remSeconds / 3600,
            inBedHours: inBedSeconds / 3600,
            hasStageData: hasStageData,
            bedtime: bedtime,
            wakeTime: wakeTime,
            recentBedtimes: [],  // Populated by extended query below
            recentWakeTimes: []
        )
    }
}

// MARK: - Detailed Sleep Data Model

struct DetailedSleepData {
    let totalHours: Double
    let coreHours: Double
    let deepHours: Double
    let remHours: Double
    let inBedHours: Double
    let hasStageData: Bool
    let bedtime: Date?
    let wakeTime: Date?
    let recentBedtimes: [Date]
    let recentWakeTimes: [Date]

    static let empty = DetailedSleepData(
        totalHours: 0, coreHours: 0, deepHours: 0, remHours: 0,
        inBedHours: 0, hasStageData: false, bedtime: nil, wakeTime: nil,
        recentBedtimes: [], recentWakeTimes: []
    )
}
