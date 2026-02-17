import HealthKit

struct HealthDataTypes {
    static var allReadTypes: Set<HKObjectType> {
        Set(HealthMetric.allCases.map { $0.hkSampleType as HKObjectType })
    }
}
