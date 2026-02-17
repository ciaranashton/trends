import SwiftUI

struct ScoreCardView: View {
    let scoreType: ScoreType
    let result: ScoreResult?

    private var displayValue: String {
        result?.formattedValue ?? "--"
    }

    private var color: Color {
        result?.color ?? .secondary
    }

    private var gaugeValue: Double {
        result?.value ?? 0
    }

    var body: some View {
        VStack(spacing: 8) {
            // Icon
            Image(systemName: scoreType.systemImage)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(color.opacity(0.8))

            // Gauge with value
            ZStack {
                ScoreGaugeView(
                    value: gaugeValue,
                    maxValue: scoreType.maxValue,
                    color: color,
                    lineWidth: 6
                )

                Text(displayValue)
                    .font(.system(size: 20, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(result != nil ? .primary : .secondary)
                    .offset(y: -2)
            }
            .frame(width: 58, height: 58)

            // Label + status
            VStack(spacing: 2) {
                Text(scoreType.displayName)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(.primary)

                if let label = result?.label {
                    Text(label)
                        .font(.system(size: 9, weight: .medium))
                        .foregroundStyle(color)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(color.opacity(0.12), in: Capsule())
                }
            }
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .padding(.horizontal, 4)
        .background {
            RoundedRectangle(cornerRadius: 16, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.06), color.opacity(0.02), .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .strokeBorder(color.opacity(0.1), lineWidth: 0.5)
                )
        }
    }
}
