import Foundation

struct SleepScoreCalculator {
    func calculate(data: DetailedSleepData) -> ScoreResult {
        var components: [ScoreComponent] = []

        let hasStages = data.hasStageData
        let hasInBed = data.inBedHours > 0

        // Determine effective weights
        var durationWeight = 0.40
        var stageWeight = 0.25
        var efficiencyWeight = 0.15
        let consistencyWeight = 0.20

        if !hasStages {
            // Redistribute stage weight to duration
            durationWeight += stageWeight
            stageWeight = 0
        }
        if !hasInBed {
            // Redistribute efficiency weight to duration
            durationWeight += efficiencyWeight
            efficiencyWeight = 0
        }

        // 1. Duration (target: 7-9 hours)
        let durationScore: Double
        let totalHours = data.totalHours
        if totalHours >= 7 && totalHours <= 9 {
            durationScore = 100
        } else if totalHours < 7 {
            durationScore = max(0, 100 - (7 - totalHours) * 33)
        } else {
            durationScore = max(0, 100 - (totalHours - 9) * 20)
        }
        components.append(ScoreComponent(
            name: "Duration",
            rawValue: totalHours,
            rawUnit: "hrs",
            score: durationScore,
            weight: durationWeight,
            weightedScore: durationScore * durationWeight
        ))

        // 2. Stage Quality (deep% toward 17.5%, REM% toward 22.5%)
        if hasStages {
            let totalSleep = max(data.totalHours, 0.01)
            let deepPct = data.deepHours / totalSleep
            let remPct = data.remHours / totalSleep

            let deepTarget = 0.175
            let remTarget = 0.225

            // Score each stage: 100 at target, decreasing away from it
            let deepScore = max(0, 100 - abs(deepPct - deepTarget) / deepTarget * 100)
            let remScore = max(0, 100 - abs(remPct - remTarget) / remTarget * 100)
            let stageScore = (deepScore + remScore) / 2

            components.append(ScoreComponent(
                name: "Stage Quality",
                rawValue: deepPct + remPct,
                rawUnit: "%",
                score: stageScore,
                weight: stageWeight,
                weightedScore: stageScore * stageWeight
            ))
        }

        // 3. Efficiency (asleep / inBed, 70% = 0, 95% = 100)
        if hasInBed {
            let efficiency = data.totalHours / max(data.inBedHours, 0.01)
            let effScore = min(100, max(0, (efficiency - 0.70) / (0.95 - 0.70) * 100))

            components.append(ScoreComponent(
                name: "Efficiency",
                rawValue: efficiency,
                rawUnit: "%",
                score: effScore,
                weight: efficiencyWeight,
                weightedScore: effScore * efficiencyWeight
            ))
        }

        // 4. Consistency (stddev of bedtimes/waketimes over 7 nights)
        let consistencyScore: Double
        if data.recentBedtimes.count >= 2 && data.recentWakeTimes.count >= 2 {
            let bedtimeStddevHours = stddevOfTimeOfDay(data.recentBedtimes) / 3600.0
            let wakeStddevHours = stddevOfTimeOfDay(data.recentWakeTimes) / 3600.0
            let avgStddev = (bedtimeStddevHours + wakeStddevHours) / 2.0
            // 0 stddev = 100, 1.5h stddev = 0
            consistencyScore = max(0, min(100, (1 - avgStddev / 1.5) * 100))
        } else {
            consistencyScore = 50 // Neutral if insufficient data
        }
        components.append(ScoreComponent(
            name: "Consistency",
            rawValue: nil,
            rawUnit: "",
            score: consistencyScore,
            weight: consistencyWeight,
            weightedScore: consistencyScore * consistencyWeight
        ))

        let totalScore = min(100, max(0, components.reduce(0) { $0 + $1.weightedScore }))

        let insight = sleepInsight(score: totalScore, data: data)

        return ScoreResult(
            type: .sleep,
            value: totalScore,
            components: components,
            date: Date(),
            insight: insight
        )
    }

    // MARK: - Helpers

    private func stddevOfTimeOfDay(_ dates: [Date]) -> Double {
        let calendar = Calendar.current
        let seconds = dates.map { date -> Double in
            let comps = calendar.dateComponents([.hour, .minute, .second], from: date)
            var secs = Double(comps.hour ?? 0) * 3600 + Double(comps.minute ?? 0) * 60 + Double(comps.second ?? 0)
            // Wrap late night times (before 6am) to be > 24h for consistent math
            if secs < 6 * 3600 {
                secs += 24 * 3600
            }
            return secs
        }

        guard seconds.count >= 2 else { return 0 }
        let mean = seconds.reduce(0, +) / Double(seconds.count)
        let variance = seconds.map { ($0 - mean) * ($0 - mean) }.reduce(0, +) / Double(seconds.count)
        return sqrt(variance)
    }

    private func sleepInsight(score: Double, data: DetailedSleepData) -> String {
        if data.totalHours < 0.1 {
            return "No sleep data recorded for last night."
        }
        if score >= 85 {
            return "Excellent sleep. You're well rested and ready for a demanding day."
        } else if score >= 70 {
            return "Good sleep overall. You should feel ready for moderate to high intensity."
        } else if score >= 50 {
            if data.totalHours < 7 {
                return "Your sleep was shorter than ideal. Try to prioritize rest tonight."
            }
            return "Fair sleep quality. Consider adjusting your sleep environment."
        } else {
            if data.totalHours < 5 {
                return "Significantly under-slept. Take it easy today and prioritize recovery."
            }
            return "Poor sleep quality. Avoid high intensity and focus on recovery."
        }
    }
}
