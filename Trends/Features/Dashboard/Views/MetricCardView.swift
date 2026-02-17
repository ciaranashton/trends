import SwiftUI

struct MetricCardView: View {
    let summary: MetricSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 0) {
            // Top: icon + trend
            HStack(alignment: .center) {
                Image(systemName: summary.metric.systemImage)
                    .font(.subheadline.weight(.semibold))
                    .foregroundStyle(summary.metric.accentColor)
                    .frame(width: 28, height: 28)
                    .background(summary.metric.accentColor.opacity(0.12), in: RoundedRectangle(cornerRadius: 8, style: .continuous))

                Spacer()

                // Trend badge
                if let trendText = summary.formattedTrend {
                    let isPositive = (summary.trend ?? 0) > 0
                    let trendColor = trendColorForMetric(isPositive: isPositive)

                    HStack(spacing: 2) {
                        Image(systemName: summary.trendDirection.icon)
                            .font(.system(size: 8, weight: .bold))
                        Text(trendText)
                            .font(.system(size: 10, weight: .semibold).monospacedDigit())
                    }
                    .foregroundStyle(trendColor)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 3)
                    .background(trendColor.opacity(0.12), in: Capsule())
                }
            }

            Spacer(minLength: 4)

            // Sparkline
            if summary.sparkline.count >= 2 {
                SparklineView(
                    data: summary.sparkline,
                    color: summary.metric.accentColor,
                    lineWidth: 1.5
                )
                .frame(height: 32)
                .padding(.trailing, 4)
            } else {
                Spacer()
                    .frame(height: 32)
            }

            Spacer(minLength: 6)

            // Bottom: value + label
            HStack(alignment: .firstTextBaseline, spacing: 4) {
                Text(summary.formattedValue)
                    .font(.title3.weight(.bold).monospacedDigit())
                    .foregroundStyle(.primary)

                if summary.hasData && !summary.metric.unitLabel.isEmpty {
                    Text(summary.metric.unitLabel)
                        .font(.caption2)
                        .foregroundStyle(.tertiary)
                }
            }

            Text(summary.metric.displayName)
                .font(.caption2.weight(.medium))
                .foregroundStyle(.secondary)
                .lineLimit(1)
        }
        .padding(12)
        .frame(maxWidth: .infinity, minHeight: 130, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [summary.metric.accentColor.opacity(0.04), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(summary.metric.accentColor.opacity(0.08), lineWidth: 0.5)
                )
        }
    }

    /// For most metrics "up" is good (steps, energy), but for some "down" is good (resting HR, body fat)
    private func trendColorForMetric(isPositive: Bool) -> Color {
        let lowerIsBetter: Set<HealthMetric> = [.restingHeartRate, .bmi, .bodyFatPercentage, .weight, .respiratoryRate]
        let inverted = lowerIsBetter.contains(summary.metric)
        let isGood = inverted ? !isPositive : isPositive
        return isGood ? .green : .orange
    }
}
