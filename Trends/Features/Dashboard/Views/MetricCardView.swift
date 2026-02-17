import SwiftUI

struct MetricCardView: View {
    let summary: MetricSummary

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: summary.metric.systemImage)
                    .font(.title3)
                    .foregroundStyle(summary.metric.accentColor)

                Spacer()
            }

            Spacer()

            VStack(alignment: .leading, spacing: 2) {
                HStack(alignment: .firstTextBaseline, spacing: 4) {
                    Text(summary.formattedValue)
                        .font(.title2.weight(.semibold).monospacedDigit())
                        .foregroundStyle(.primary)

                    if summary.hasData && !summary.metric.unitLabel.isEmpty {
                        Text(summary.metric.unitLabel)
                            .font(.caption)
                            .foregroundStyle(.secondary)
                    }
                }

                Text(summary.metric.displayName)
                    .font(.caption)
                    .foregroundStyle(.secondary)
                    .lineLimit(1)
            }
        }
        .padding(14)
        .frame(maxWidth: .infinity, minHeight: 110, alignment: .leading)
        .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 16))
    }
}
