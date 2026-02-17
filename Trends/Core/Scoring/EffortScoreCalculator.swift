import Foundation

struct EffortScoreCalculator {
    let baselineStore: BaselineStore

    func calculate(
        activeEnergy: Double?,
        exerciseMinutes: Double?,
        steps: Double?,
        averageHR: Double?,
        restingHR: Double?
    ) -> ScoreResult {
        var components: [ScoreComponent] = []

        // 1. Active Energy (35%)
        let energyWeight = 0.35
        let energyScore: Double
        if let activeEnergy, activeEnergy > 0 {
            baselineStore.record(metric: "activeEnergy", value: activeEnergy)
            let b = baselineStore.baseline(for: "activeEnergy")
            let ratio = activeEnergy / max(b.average, 1)
            energyScore = min(100, ratio * 50)
        } else {
            energyScore = 0
        }
        components.append(ScoreComponent(
            name: "Active Energy",
            rawValue: activeEnergy,
            rawUnit: "kcal",
            score: energyScore,
            weight: energyWeight,
            weightedScore: energyScore * energyWeight
        ))

        // 2. Exercise Time (30%)
        let exerciseWeight = 0.30
        let exerciseScore: Double
        if let exerciseMinutes, exerciseMinutes > 0 {
            baselineStore.record(metric: "exerciseMinutes", value: exerciseMinutes)
            let b = baselineStore.baseline(for: "exerciseMinutes")
            let ratio = exerciseMinutes / max(b.average, 1)
            exerciseScore = min(100, ratio * 50)
        } else {
            exerciseScore = 0
        }
        components.append(ScoreComponent(
            name: "Exercise Time",
            rawValue: exerciseMinutes,
            rawUnit: "min",
            score: exerciseScore,
            weight: exerciseWeight,
            weightedScore: exerciseScore * exerciseWeight
        ))

        // 3. HR Intensity (25%)
        let hrWeight = 0.25
        let hrScore: Double
        if let averageHR, let restingHR, averageHR > restingHR {
            let gap = averageHR - restingHR
            // 50bpm gap = 80pts
            hrScore = min(100, gap / 50.0 * 80)
        } else {
            hrScore = 0
        }
        components.append(ScoreComponent(
            name: "HR Intensity",
            rawValue: averageHR.flatMap { restingHR != nil ? $0 - restingHR! : nil },
            rawUnit: "bpm gap",
            score: hrScore,
            weight: hrWeight,
            weightedScore: hrScore * hrWeight
        ))

        // 4. Steps (10%)
        let stepsWeight = 0.10
        let stepsScore: Double
        if let steps, steps > 0 {
            baselineStore.record(metric: "steps", value: steps)
            let b = baselineStore.baseline(for: "steps")
            let ratio = steps / max(b.average, 1)
            stepsScore = min(100, ratio * 50)
        } else {
            stepsScore = 0
        }
        components.append(ScoreComponent(
            name: "Steps",
            rawValue: steps,
            rawUnit: "steps",
            score: stepsScore,
            weight: stepsWeight,
            weightedScore: stepsScore * stepsWeight
        ))

        // Linear effort (0-100+) → logarithmic 0-21
        let linearPoints = components.reduce(0) { $0 + $1.weightedScore }
        let strain = 7.0 * log(1 + linearPoints / 12.0)
        let clampedStrain = min(21, max(0, strain))

        let insight = effortInsight(strain: clampedStrain)

        return ScoreResult(
            type: .effort,
            value: clampedStrain,
            components: components,
            date: Date(),
            insight: insight
        )
    }

    private func effortInsight(strain: Double) -> String {
        if strain >= 18 {
            return "All-out effort today. Make sure to prioritize recovery tomorrow."
        } else if strain >= 14 {
            return "High strain day. Great work pushing your limits."
        } else if strain >= 7 {
            return "Moderate activity. Solid day of movement and exercise."
        } else {
            return "Light activity so far. A good opportunity to get moving or rest up."
        }
    }
}
