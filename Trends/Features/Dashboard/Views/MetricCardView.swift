import SwiftUI

/// Compact label row on top, full-width sparkline underneath — all charts align.
struct MetricCardView: View {
    let summary: MetricSummary

    var body: some View {
        VStack(spacing: 6) {
            // Top row: dot + name | value + trend
            HStack(spacing: 0) {
                HStack(spacing: 6) {
                    Circle()
                        .fill(summary.metric.accentColor)
                        .frame(width: 6, height: 6)

                    Text(summary.metric.displayName)
                        .font(.caption.weight(.medium))
                        .foregroundStyle(.secondary)
                        .lineLimit(1)
                }

                Spacer(minLength: 8)

                HStack(spacing: 6) {
                    HStack(alignment: .firstTextBaseline, spacing: 2) {
                        Text(summary.formattedValue)
                            .font(.system(size: 15, weight: .semibold, design: .rounded).monospacedDigit())
                            .foregroundStyle(.primary)

                        if summary.hasData && !summary.metric.unitLabel.isEmpty {
                            Text(summary.metric.unitLabel)
                                .font(.system(size: 9))
                                .foregroundStyle(.tertiary)
                        }
                    }

                    if let trendText = summary.formattedTrend {
                        let isPositive = (summary.trend ?? 0) > 0
                        let trendColor = trendColorForMetric(isPositive: isPositive)

                        HStack(spacing: 2) {
                            Image(systemName: summary.trendDirection.icon)
                                .font(.system(size: 6, weight: .bold))
                            Text(trendText)
                                .font(.system(size: 9, weight: .semibold).monospacedDigit())
                        }
                        .foregroundStyle(trendColor)
                        .padding(.horizontal, 5)
                        .padding(.vertical, 3)
                        .background(trendColor.opacity(0.12), in: Capsule())
                    }
                }
            }

            // Full-width sparkline underneath
            if summary.sparkline.count >= 2 {
                SparklineView(
                    data: summary.sparkline,
                    color: summary.metric.accentColor,
                    lineWidth: 1.5
                )
                .frame(height: 30)
            } else {
                RoundedRectangle(cornerRadius: 4, style: .continuous)
                    .fill(.secondary.opacity(0.04))
                    .frame(height: 30)
                    .overlay {
                        Text("No data yet")
                            .font(.system(size: 9))
                            .foregroundStyle(.quaternary)
                    }
            }
        }
        .padding(.vertical, 10)
        .padding(.horizontal, 14)
        .contentShape(Rectangle())
    }

    private func trendColorForMetric(isPositive: Bool) -> Color {
        let lowerIsBetter: Set<HealthMetric> = [.restingHeartRate, .bmi, .bodyFatPercentage, .weight, .respiratoryRate]
        let inverted = lowerIsBetter.contains(summary.metric)
        let isGood = inverted ? !isPositive : isPositive
        return isGood ? .green : .orange
    }
}
