import Foundation

struct RecoveryScoreCalculator {
    let baselineStore: BaselineStore

    func calculate(
        hrv: Double?,
        restingHR: Double?,
        respiratoryRate: Double?,
        sleepScore: Double
    ) -> ScoreResult {
        var components: [ScoreComponent] = []

        let hasHRV = hrv != nil
        let hasRR = respiratoryRate != nil

        // Determine effective weights with fallback redistribution
        var hrvWeight = 0.50
        var rhrWeight = 0.20
        var sleepWeight = 0.20
        var rrWeight = 0.10

        if !hasHRV {
            // Missing HRV → redistribute to RHR (35%) + Sleep (45%) + RR (20%)
            rhrWeight = 0.35
            sleepWeight = 0.45
            rrWeight = hasRR ? 0.20 : 0
            hrvWeight = 0
        }
        if !hasRR {
            // Missing RR → redistribute to HRV (55%) + Sleep (25%) + RHR remains
            if hasHRV {
                hrvWeight = 0.55
                sleepWeight = 0.25
                rrWeight = 0
            } else {
                // No HRV and no RR
                rhrWeight = 0.45
                sleepWeight = 0.55
                rrWeight = 0
                hrvWeight = 0
            }
        }

        // 1. HRV (higher is better)
        if let hrv {
            baselineStore.record(metric: "hrv", value: hrv)
            let z = baselineStore.zScore(for: "hrv", value: hrv)
            // At baseline (z=0) = 60pts, each stddev above = +20pts
            let score = min(100, max(0, 60 + z * 20))
            components.append(ScoreComponent(
                name: "HRV",
                rawValue: hrv,
                rawUnit: "ms",
                score: score,
                weight: hrvWeight,
                weightedScore: score * hrvWeight
            ))
        }

        // 2. Resting HR (lower is better → inverted z-score)
        if let restingHR {
            baselineStore.record(metric: "restingHR", value: restingHR)
            let z = baselineStore.zScore(for: "restingHR", value: restingHR)
            // Inverted: at baseline = 60pts, each stddev BELOW = +20pts
            let score = min(100, max(0, 60 - z * 20))
            components.append(ScoreComponent(
                name: "Resting HR",
                rawValue: restingHR,
                rawUnit: "bpm",
                score: score,
                weight: rhrWeight,
                weightedScore: score * rhrWeight
            ))
        } else {
            // If no RHR, redistribute its weight to sleep
            sleepWeight += rhrWeight
            rhrWeight = 0
        }

        // 3. Sleep Score (direct feed-in)
        components.append(ScoreComponent(
            name: "Sleep",
            rawValue: sleepScore,
            rawUnit: "",
            score: sleepScore,
            weight: sleepWeight,
            weightedScore: sleepScore * sleepWeight
        ))

        // 4. Respiratory Rate (lower is better → inverted z-score)
        if let respiratoryRate {
            baselineStore.record(metric: "respiratoryRate", value: respiratoryRate)
            let z = baselineStore.zScore(for: "respiratoryRate", value: respiratoryRate)
            // At baseline = 70pts, elevated = lower
            let score = min(100, max(0, 70 - z * 20))
            components.append(ScoreComponent(
                name: "Respiratory Rate",
                rawValue: respiratoryRate,
                rawUnit: "br/min",
                score: score,
                weight: rrWeight,
                weightedScore: score * rrWeight
            ))
        }

        let totalScore = min(100, max(0, components.reduce(0) { $0 + $1.weightedScore }))
        let insight = recoveryInsight(score: totalScore, hrv: hrv, restingHR: restingHR)

        return ScoreResult(
            type: .recovery,
            value: totalScore,
            components: components,
            date: Date(),
            insight: insight
        )
    }

    private func recoveryInsight(score: Double, hrv: Double?, restingHR: Double?) -> String {
        if score >= 67 {
            return "Your body is well recovered. Good day for intensity."
        } else if score >= 34 {
            if let hrv, baselineStore.zScore(for: "hrv", value: hrv) < -1 {
                return "HRV is below baseline. Consider moderate activity and focus on recovery."
            }
            return "Moderate recovery. Listen to your body and avoid overtraining."
        } else {
            return "Low recovery detected. Prioritize rest, hydration, and easy movement."
        }
    }
}
