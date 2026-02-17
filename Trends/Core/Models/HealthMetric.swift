import Foundation
import HealthKit
import SwiftUI

enum HealthMetricCategory: String, CaseIterable {
    case activityAndFitness = "Activity & Fitness"
    case bodyMeasurements = "Body Measurements"
    case vitalsAndSleep = "Vitals & Sleep"
}

enum HealthMetric: String, CaseIterable, Identifiable, Hashable {
    // Activity & Fitness
    case steps
    case activeEnergy
    case exerciseTime
    case walkingRunningDistance

    // Body Measurements
    case weight
    case bmi
    case bodyFatPercentage

    // Vitals & Sleep
    case heartRate
    case restingHeartRate
    case heartRateVariability
    case sleepAnalysis
    case respiratoryRate

    var id: String { rawValue }

    var category: HealthMetricCategory {
        switch self {
        case .steps, .activeEnergy, .exerciseTime, .walkingRunningDistance:
            return .activityAndFitness
        case .weight, .bmi, .bodyFatPercentage:
            return .bodyMeasurements
        case .heartRate, .restingHeartRate, .heartRateVariability, .sleepAnalysis, .respiratoryRate:
            return .vitalsAndSleep
        }
    }

    var displayName: String {
        switch self {
        case .steps: return "Steps"
        case .activeEnergy: return "Active Energy"
        case .exerciseTime: return "Exercise Time"
        case .walkingRunningDistance: return "Distance"
        case .weight: return "Weight"
        case .bmi: return "BMI"
        case .bodyFatPercentage: return "Body Fat"
        case .heartRate: return "Heart Rate"
        case .restingHeartRate: return "Resting HR"
        case .heartRateVariability: return "HRV"
        case .sleepAnalysis: return "Sleep"
        case .respiratoryRate: return "Respiratory Rate"
        }
    }

    var systemImage: String {
        switch self {
        case .steps: return "figure.walk"
        case .activeEnergy: return "flame.fill"
        case .exerciseTime: return "timer"
        case .walkingRunningDistance: return "figure.run"
        case .weight: return "scalemass.fill"
        case .bmi: return "person.fill"
        case .bodyFatPercentage: return "percent"
        case .heartRate: return "heart.fill"
        case .restingHeartRate: return "heart.text.square.fill"
        case .heartRateVariability: return "waveform.path.ecg"
        case .sleepAnalysis: return "bed.double.fill"
        case .respiratoryRate: return "lungs.fill"
        }
    }

    var accentColor: Color {
        switch self {
        case .steps: return .green
        case .activeEnergy: return .red
        case .exerciseTime: return .yellow
        case .walkingRunningDistance: return .blue
        case .weight: return .purple
        case .bmi: return .indigo
        case .bodyFatPercentage: return .orange
        case .heartRate: return .red
        case .restingHeartRate: return .pink
        case .heartRateVariability: return .purple
        case .sleepAnalysis: return .cyan
        case .respiratoryRate: return .teal
        }
    }

    var unitLabel: String {
        switch self {
        case .steps: return "steps"
        case .activeEnergy: return "kcal"
        case .exerciseTime: return "min"
        case .walkingRunningDistance: return "km"
        case .weight: return "kg"
        case .bmi: return ""
        case .bodyFatPercentage: return "%"
        case .heartRate, .restingHeartRate: return "bpm"
        case .heartRateVariability: return "ms"
        case .sleepAnalysis: return "hrs"
        case .respiratoryRate: return "br/min"
        }
    }

    var hkSampleType: HKSampleType {
        switch self {
        case .sleepAnalysis:
            return HKCategoryType(.sleepAnalysis)
        default:
            return hkQuantityType
        }
    }

    var hkQuantityType: HKQuantityType {
        switch self {
        case .steps: return HKQuantityType(.stepCount)
        case .activeEnergy: return HKQuantityType(.activeEnergyBurned)
        case .exerciseTime: return HKQuantityType(.appleExerciseTime)
        case .walkingRunningDistance: return HKQuantityType(.distanceWalkingRunning)
        case .weight: return HKQuantityType(.bodyMass)
        case .bmi: return HKQuantityType(.bodyMassIndex)
        case .bodyFatPercentage: return HKQuantityType(.bodyFatPercentage)
        case .heartRate: return HKQuantityType(.heartRate)
        case .restingHeartRate: return HKQuantityType(.restingHeartRate)
        case .heartRateVariability: return HKQuantityType(.heartRateVariabilitySDNN)
        case .sleepAnalysis: return HKQuantityType(.heartRate) // unused for sleep
        case .respiratoryRate: return HKQuantityType(.respiratoryRate)
        }
    }

    var hkUnit: HKUnit {
        switch self {
        case .steps: return .count()
        case .activeEnergy: return .kilocalorie()
        case .exerciseTime: return .minute()
        case .walkingRunningDistance: return .meterUnit(with: .kilo)
        case .weight: return .gramUnit(with: .kilo)
        case .bmi: return .count()
        case .bodyFatPercentage: return .percent()
        case .heartRate, .restingHeartRate: return HKUnit.count().unitDivided(by: .minute())
        case .heartRateVariability: return .secondUnit(with: .milli)
        case .sleepAnalysis: return .hour()
        case .respiratoryRate: return HKUnit.count().unitDivided(by: .minute())
        }
    }

    var statisticsOption: HKStatisticsOptions {
        switch self {
        case .steps, .activeEnergy, .exerciseTime, .walkingRunningDistance:
            return .cumulativeSum
        case .weight, .bmi, .bodyFatPercentage, .heartRate, .restingHeartRate,
             .heartRateVariability, .respiratoryRate, .sleepAnalysis:
            return .discreteAverage
        }
    }

    var isCumulative: Bool {
        statisticsOption == .cumulativeSum
    }

    var isQuantityType: Bool {
        self != .sleepAnalysis
    }

    static func metrics(for category: HealthMetricCategory) -> [HealthMetric] {
        allCases.filter { $0.category == category }
    }

    func formatValue(_ value: Double) -> String {
        switch self {
        case .steps:
            return value >= 1000
                ? String(format: "%.1fk", value / 1000)
                : String(format: "%.0f", value)
        case .activeEnergy:
            return String(format: "%.0f", value)
        case .exerciseTime:
            return String(format: "%.0f", value)
        case .walkingRunningDistance:
            return String(format: "%.1f", value)
        case .weight:
            return String(format: "%.1f", value)
        case .bmi:
            return String(format: "%.1f", value)
        case .bodyFatPercentage:
            return String(format: "%.1f", value * 100)
        case .heartRate, .restingHeartRate:
            return String(format: "%.0f", value)
        case .heartRateVariability:
            return String(format: "%.0f", value)
        case .sleepAnalysis:
            let hours = Int(value)
            let minutes = Int((value - Double(hours)) * 60)
            return "\(hours)h \(minutes)m"
        case .respiratoryRate:
            return String(format: "%.1f", value)
        }
    }
}
