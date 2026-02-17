import SwiftUI

struct ScoresSectionView: View {
    let scoreEngine: ScoreEngine

    private var readinessValue: Double {
        // Weighted blend: 40% recovery, 35% sleep, 25% inverse effort
        let sleep = scoreEngine.sleepScore?.value ?? 0
        let recovery = scoreEngine.recoveryScore?.value ?? 0
        let effort = scoreEngine.effortScore?.value ?? 0
        let effortInverse = max(0, 100 - (effort / 21.0 * 100))
        return sleep * 0.35 + recovery * 0.40 + effortInverse * 0.25
    }

    private var readinessColor: Color {
        switch readinessValue {
        case 70...100: return .green
        case 40..<70: return .yellow
        default: return .red
        }
    }

    private var hasAnyScore: Bool {
        scoreEngine.sleepScore != nil || scoreEngine.recoveryScore != nil || scoreEngine.effortScore != nil
    }

    var body: some View {
        VStack(spacing: 16) {
            // Top: readiness ring with three score columns
            HStack(spacing: 0) {
                // Sleep column
                NavigationLink(value: ScoreType.sleep) {
                    scoreColumn(
                        type: .sleep,
                        result: scoreEngine.sleepScore
                    )
                }
                .buttonStyle(.plain)

                // Center: readiness ring
                readinessRing
                    .frame(width: 100)

                // Recovery column
                NavigationLink(value: ScoreType.recovery) {
                    scoreColumn(
                        type: .recovery,
                        result: scoreEngine.recoveryScore
                    )
                }
                .buttonStyle(.plain)
            }

            // Bottom: effort bar (full width)
            NavigationLink(value: ScoreType.effort) {
                effortBar
            }
            .buttonStyle(.plain)
        }
        .padding(16)
        .background {
            RoundedRectangle(cornerRadius: 20, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [readinessColor.opacity(0.05), .clear, .clear],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 20, style: .continuous)
                        .strokeBorder(readinessColor.opacity(0.1), lineWidth: 0.5)
                )
        }
    }

    // MARK: - Readiness Ring

    private var readinessRing: some View {
        ZStack {
            // Glow
            Circle()
                .fill(
                    RadialGradient(
                        colors: [readinessColor.opacity(hasAnyScore ? 0.12 : 0.04), .clear],
                        center: .center,
                        startRadius: 20,
                        endRadius: 56
                    )
                )
                .frame(width: 110, height: 110)

            // Three concentric rings
            // Outer: sleep
            ringArc(value: scoreEngine.sleepScore?.value ?? 0, max: 100, color: scoreEngine.sleepScore?.color ?? .secondary.opacity(0.3), width: 5, size: 80)
            // Middle: recovery
            ringArc(value: scoreEngine.recoveryScore?.value ?? 0, max: 100, color: scoreEngine.recoveryScore?.color ?? .secondary.opacity(0.3), width: 5, size: 62)
            // Inner: effort
            ringArc(value: scoreEngine.effortScore?.value ?? 0, max: 21, color: scoreEngine.effortScore?.color ?? .secondary.opacity(0.3), width: 5, size: 44)

            // Center label
            VStack(spacing: 1) {
                if hasAnyScore {
                    Text(String(format: "%.0f", readinessValue))
                        .font(.system(size: 18, weight: .bold, design: .rounded).monospacedDigit())
                } else {
                    Text("--")
                        .font(.system(size: 18, weight: .bold, design: .rounded))
                        .foregroundStyle(.secondary)
                }
                Text("READY")
                    .font(.system(size: 7, weight: .bold, design: .rounded))
                    .tracking(0.8)
                    .foregroundStyle(.secondary)
            }
        }
    }

    private func ringArc(value: Double, max: Double, color: Color, width: CGFloat, size: CGFloat) -> some View {
        let progress = max > 0 ? Swift.min(value / max, 1.0) : 0

        return ZStack {
            Circle()
                .trim(from: 0, to: 0.75)
                .stroke(color.opacity(0.12), style: StrokeStyle(lineWidth: width, lineCap: .round))
                .rotationEffect(.degrees(135))

            Circle()
                .trim(from: 0, to: 0.75 * progress)
                .stroke(
                    AngularGradient(
                        colors: [color.opacity(0.5), color],
                        center: .center,
                        startAngle: .degrees(135),
                        endAngle: .degrees(135 + 270 * progress)
                    ),
                    style: StrokeStyle(lineWidth: width, lineCap: .round)
                )
                .rotationEffect(.degrees(135))
                .shadow(color: color.opacity(0.3), radius: 3)
        }
        .frame(width: size, height: size)
    }

    // MARK: - Score Column

    private func scoreColumn(type: ScoreType, result: ScoreResult?) -> some View {
        VStack(spacing: 6) {
            Image(systemName: type.systemImage)
                .font(.caption2.weight(.semibold))
                .foregroundStyle(result?.color ?? .secondary)

            Text(result?.formattedValue ?? "--")
                .font(.system(size: 22, weight: .bold, design: .rounded).monospacedDigit())
                .foregroundStyle(result != nil ? .primary : .secondary)

            Text(type.displayName)
                .font(.system(size: 10, weight: .medium))
                .foregroundStyle(.secondary)

            if let label = result?.label {
                Text(label)
                    .font(.system(size: 9, weight: .semibold))
                    .foregroundStyle(result?.color ?? .secondary)
                    .padding(.horizontal, 6)
                    .padding(.vertical, 2)
                    .background((result?.color ?? .secondary).opacity(0.1), in: Capsule())
            }
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Effort Bar

    private var effortBar: some View {
        let effort = scoreEngine.effortScore
        let value = effort?.value ?? 0
        let color = effort?.color ?? .secondary
        let progress = min(value / 21.0, 1.0)

        return VStack(spacing: 8) {
            HStack {
                Image(systemName: ScoreType.effort.systemImage)
                    .font(.caption2.weight(.semibold))
                    .foregroundStyle(color)
                Text("Effort")
                    .font(.caption.weight(.semibold))
                Spacer()
                Text(effort?.formattedValue ?? "--")
                    .font(.subheadline.weight(.bold).monospacedDigit())
                    .foregroundStyle(color)
                Text("/ 21")
                    .font(.caption2)
                    .foregroundStyle(.tertiary)
                if let label = effort?.label {
                    Text(label)
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundStyle(color)
                        .padding(.horizontal, 6)
                        .padding(.vertical, 2)
                        .background(color.opacity(0.1), in: Capsule())
                }
            }

            // Segmented strain bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    // Background segments
                    HStack(spacing: 2) {
                        ForEach(ScoreType.effort.zoneBands, id: \.label) { band in
                            let bandWidth = (band.range.upperBound - band.range.lowerBound) / 21.0
                            RoundedRectangle(cornerRadius: 3)
                                .fill(band.color.opacity(0.12))
                                .frame(width: geo.size.width * bandWidth)
                        }
                    }

                    // Fill
                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.6), color],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: max(0, geo.size.width * progress))
                        .shadow(color: color.opacity(0.3), radius: 2, x: 1)
                }
            }
            .frame(height: 8)
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(color.opacity(0.04))
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(color.opacity(0.08), lineWidth: 0.5)
                )
        }
    }
}
