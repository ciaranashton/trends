import SwiftUI

struct StatsSummaryView: View {
    let metric: HealthMetric
    let average: Double?
    let minimum: Double?
    let maximum: Double?

    var body: some View {
        HStack(spacing: 0) {
            StatItem(
                title: "Average",
                value: average.map { metric.formatValue($0) } ?? "--",
                unit: metric.unitLabel
            )
            Divider().frame(height: 36)
            StatItem(
                title: "Min",
                value: minimum.map { metric.formatValue($0) } ?? "--",
                unit: metric.unitLabel
            )
            Divider().frame(height: 36)
            StatItem(
                title: "Max",
                value: maximum.map { metric.formatValue($0) } ?? "--",
                unit: metric.unitLabel
            )
        }
        .padding(.vertical, 12)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
    }
}

private struct StatItem: View {
    let title: String
    let value: String
    let unit: String

    var body: some View {
        VStack(spacing: 4) {
            Text(title)
                .font(.caption)
                .foregroundStyle(.secondary)

            HStack(alignment: .firstTextBaseline, spacing: 2) {
                Text(value)
                    .font(.subheadline.weight(.semibold).monospacedDigit())

                if !unit.isEmpty && value != "--" {
                    Text(unit)
                        .font(.caption2)
                        .foregroundStyle(.secondary)
                }
            }
        }
        .frame(maxWidth: .infinity)
    }
}
