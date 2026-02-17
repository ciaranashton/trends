import SwiftUI
import Charts

struct ScoreDetailView: View {
    let scoreType: ScoreType
    let currentResult: ScoreResult?
    let scoreEngine: ScoreEngine

    @State private var viewModel: ScoreDetailViewModel?
    @State private var animateGauge = false

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                scoreHeader
                    .padding(.top, 8)

                if let insight = currentResult?.insight {
                    insightCard(insight)
                }

                // Visual breakdown specific to score type
                if scoreType == .sleep, let result = currentResult {
                    sleepStagesChart(result: result)
                }

                if let components = currentResult?.components, !components.isEmpty {
                    componentGrid(components)
                }

                trendSection

                Spacer(minLength: 20)
            }
        }
        .navigationTitle(scoreType.displayName)
        .navigationBarTitleDisplayMode(.large)
        .task {
            if viewModel == nil {
                let vm = ScoreDetailViewModel(scoreType: scoreType, scoreEngine: scoreEngine)
                viewModel = vm
                await vm.loadTrend()
            }
            withAnimation(.easeOut(duration: 0.8).delay(0.2)) {
                animateGauge = true
            }
        }
        .onChange(of: viewModel?.selectedRange) { _, _ in
            guard let viewModel else { return }
            Task { await viewModel.loadTrend() }
        }
    }

    // MARK: - Score Header

    private var scoreHeader: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(
                        RadialGradient(
                            colors: [
                                (currentResult?.color ?? .secondary).opacity(0.15),
                                .clear
                            ],
                            center: .center,
                            startRadius: 40,
                            endRadius: 100
                        )
                    )
                    .frame(width: 200, height: 200)

                ScoreGaugeView(
                    value: animateGauge ? (currentResult?.value ?? 0) : 0,
                    maxValue: scoreType.maxValue,
                    color: currentResult?.color ?? .secondary,
                    lineWidth: 14,
                    showTicks: true
                )

                VStack(spacing: 4) {
                    Text(currentResult?.formattedValue ?? "--")
                        .font(.system(size: 44, weight: .bold, design: .rounded).monospacedDigit())
                        .contentTransition(.numericText())

                    if let label = currentResult?.label {
                        Text(label.uppercased())
                            .font(.system(size: 11, weight: .bold, design: .rounded))
                            .tracking(1.2)
                            .foregroundStyle(currentResult?.color ?? .secondary)
                    }
                }
                .offset(y: -6)
            }
            .frame(width: 160, height: 160)
        }
    }

    // MARK: - Insight Card

    private func insightCard(_ insight: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: "brain.head.profile")
                .font(.title3)
                .foregroundStyle(currentResult?.color ?? .secondary)
                .frame(width: 32)

            Text(insight)
                .font(.subheadline)
                .foregroundStyle(.secondary)
                .fixedSize(horizontal: false, vertical: true)
        }
        .padding(16)
        .frame(maxWidth: .infinity, alignment: .leading)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder((currentResult?.color ?? .secondary).opacity(0.1), lineWidth: 0.5)
                )
        }
        .padding(.horizontal)
    }

    // MARK: - Sleep Stages Donut

    private func sleepStagesChart(result: ScoreResult) -> some View {
        let components = result.components
        // Extract stage data from components
        let durationComp = components.first(where: { $0.name == "Duration" })
        let stageComp = components.first(where: { $0.name == "Stage Quality" })

        let totalHrs = durationComp?.rawValue ?? 0
        let hasStages = stageComp != nil

        return VStack(alignment: .leading, spacing: 14) {
            Text("Sleep Stages")
                .font(.title3.weight(.semibold))
                .padding(.horizontal)

            HStack(spacing: 20) {
                // Donut chart
                ZStack {
                    if hasStages, let stageRatio = stageComp?.rawValue {
                        let deep = stageRatio * 0.4375  // approximate split
                        let rem = stageRatio * 0.5625
                        let core = max(0, 1.0 - deep - rem)

                        donutChart(slices: [
                            (label: "Core", value: core, color: Color.cyan),
                            (label: "Deep", value: deep, color: Color.indigo),
                            (label: "REM", value: rem, color: Color.purple),
                        ])
                    } else {
                        donutChart(slices: [
                            (label: "Sleep", value: 1.0, color: Color.cyan),
                        ])
                    }

                    VStack(spacing: 2) {
                        Text(formatHours(totalHrs))
                            .font(.system(size: 18, weight: .bold, design: .rounded).monospacedDigit())
                        Text("total")
                            .font(.system(size: 9, weight: .medium))
                            .foregroundStyle(.secondary)
                    }
                }
                .frame(width: 100, height: 100)

                // Legend
                VStack(alignment: .leading, spacing: 10) {
                    if hasStages {
                        stageLegend(color: .cyan, label: "Core", value: totalHrs * 0.55)
                        stageLegend(color: .indigo, label: "Deep", value: totalHrs * 0.175)
                        stageLegend(color: .purple, label: "REM", value: totalHrs * 0.225)
                        stageLegend(color: .secondary, label: "Awake", value: totalHrs * 0.05)
                    } else {
                        stageLegend(color: .cyan, label: "Asleep", value: totalHrs)
                        Text("No stage data available")
                            .font(.caption2)
                            .foregroundStyle(.tertiary)
                    }
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            }
            .padding(16)
            .background {
                RoundedRectangle(cornerRadius: 16, style: .continuous)
                    .fill(.ultraThinMaterial)
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .strokeBorder(.secondary.opacity(0.08), lineWidth: 0.5)
                    )
            }
            .padding(.horizontal)
        }
    }

    private func donutChart(slices: [(label: String, value: Double, color: Color)]) -> some View {
        let total = slices.map(\.value).reduce(0, +)

        return Canvas { context, size in
            let center = CGPoint(x: size.width / 2, y: size.height / 2)
            let radius = min(size.width, size.height) / 2
            let innerRadius = radius * 0.6
            let lineWidth = radius - innerRadius

            var startAngle = Angle.degrees(-90)

            for slice in slices {
                let fraction = total > 0 ? slice.value / total : 0
                let sweepAngle = Angle.degrees(360 * fraction)
                let endAngle = startAngle + sweepAngle

                let path = Path { p in
                    p.addArc(center: center, radius: radius - lineWidth / 2,
                             startAngle: startAngle, endAngle: endAngle, clockwise: false)
                }

                context.stroke(path, with: .color(slice.color),
                               style: StrokeStyle(lineWidth: lineWidth, lineCap: .butt))

                startAngle = endAngle
            }
        }
    }

    private func stageLegend(color: Color, label: String, value: Double) -> some View {
        HStack(spacing: 8) {
            RoundedRectangle(cornerRadius: 2)
                .fill(color)
                .frame(width: 12, height: 12)

            Text(label)
                .font(.caption.weight(.medium))

            Spacer()

            Text(formatHours(value))
                .font(.caption.weight(.semibold).monospacedDigit())
                .foregroundStyle(.secondary)
        }
    }

    private func formatHours(_ hours: Double) -> String {
        let h = Int(hours)
        let m = Int((hours - Double(h)) * 60)
        return "\(h)h \(m)m"
    }

    // MARK: - Component Grid

    private func componentGrid(_ components: [ScoreComponent]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Breakdown")
                .font(.title3.weight(.semibold))
                .padding(.horizontal)

            LazyVGrid(columns: [GridItem(.flexible(), spacing: 10), GridItem(.flexible(), spacing: 10)], spacing: 10) {
                ForEach(components) { component in
                    componentCard(component)
                }
            }
            .padding(.horizontal)
        }
    }

    private func componentCard(_ component: ScoreComponent) -> some View {
        VStack(spacing: 10) {
            // Mini ring gauge
            ZStack {
                ScoreGaugeView(
                    value: animateGauge ? component.score : 0,
                    maxValue: 100,
                    color: barColor(for: component.score),
                    lineWidth: 5
                )

                Text(String(format: "%.0f", component.score))
                    .font(.system(size: 16, weight: .bold, design: .rounded).monospacedDigit())
                    .foregroundStyle(barColor(for: component.score))
                    .offset(y: -2)
            }
            .frame(width: 48, height: 48)

            VStack(spacing: 3) {
                Text(component.name)
                    .font(.caption.weight(.semibold))
                    .multilineTextAlignment(.center)
                    .lineLimit(1)

                Text(component.formattedRaw)
                    .font(.caption2.monospacedDigit())
                    .foregroundStyle(.secondary)

                // Weight indicator
                GeometryReader { geo in
                    ZStack(alignment: .leading) {
                        Capsule()
                            .fill(.secondary.opacity(0.08))
                        Capsule()
                            .fill(barColor(for: component.score).opacity(0.3))
                            .frame(width: geo.size.width * component.weight)
                    }
                }
                .frame(height: 3)
                .padding(.horizontal, 8)

                Text("\(String(format: "%.0f%%", component.weight * 100)) weight")
                    .font(.system(size: 9))
                    .foregroundStyle(.tertiary)
            }
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 8)
        .frame(maxWidth: .infinity)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .fill(barColor(for: component.score).opacity(0.03))
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(barColor(for: component.score).opacity(0.1), lineWidth: 0.5)
                )
        }
    }

    private func barColor(for score: Double) -> Color {
        switch score {
        case 80...100: return .green
        case 60..<80: return .teal
        case 40..<60: return .yellow
        case 20..<40: return .orange
        default: return .red
        }
    }

    // MARK: - Trend Section

    private var trendSection: some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Trend")
                .font(.title3.weight(.semibold))
                .padding(.horizontal)

            if let viewModel {
                Picker("Time Range", selection: Binding(
                    get: { viewModel.selectedRange },
                    set: { viewModel.selectedRange = $0 }
                )) {
                    ForEach([TimeRange.week, .month, .threeMonths], id: \.self) { range in
                        Text(range.displayName).tag(range)
                    }
                }
                .pickerStyle(.segmented)
                .padding(.horizontal)

                if viewModel.isLoading {
                    ProgressView()
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                } else if viewModel.trendData.isEmpty {
                    emptyTrendState
                } else {
                    ScoreTrendChartView(
                        dataPoints: viewModel.trendData,
                        scoreType: scoreType
                    )
                    .frame(height: 200)
                    .padding(.horizontal)

                    statsRow(viewModel: viewModel)
                        .padding(.horizontal)
                }
            }
        }
    }

    private var emptyTrendState: some View {
        VStack(spacing: 12) {
            Image(systemName: scoreType.systemImage)
                .font(.largeTitle)
                .foregroundStyle(.secondary.opacity(0.4))
            Text("No History Yet")
                .font(.subheadline.weight(.medium))
                .foregroundStyle(.secondary)
            Text("Score history will build over time.")
                .font(.caption)
                .foregroundStyle(.tertiary)
        }
        .frame(maxWidth: .infinity, minHeight: 180)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
        }
        .padding(.horizontal)
    }

    private func statsRow(viewModel: ScoreDetailViewModel) -> some View {
        HStack(spacing: 0) {
            trendStat("Average", value: viewModel.average, icon: "chart.bar.fill")
            separatorLine
            trendStat("Low", value: viewModel.minimum, icon: "arrow.down")
            separatorLine
            trendStat("High", value: viewModel.maximum, icon: "arrow.up")
        }
        .padding(.vertical, 14)
        .background {
            RoundedRectangle(cornerRadius: 14, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 14, style: .continuous)
                        .strokeBorder(.secondary.opacity(0.08), lineWidth: 0.5)
                )
        }
    }

    private var separatorLine: some View {
        Rectangle()
            .fill(.secondary.opacity(0.15))
            .frame(width: 0.5, height: 32)
    }

    private func trendStat(_ title: String, value: Double?, icon: String) -> some View {
        VStack(spacing: 4) {
            HStack(spacing: 3) {
                Image(systemName: icon)
                    .font(.system(size: 8))
                    .foregroundStyle(.tertiary)
                Text(title)
                    .font(.caption2)
                    .foregroundStyle(.secondary)
            }
            Text(value.map { scoreType.formatValue($0) } ?? "--")
                .font(.subheadline.weight(.semibold).monospacedDigit())
                .foregroundStyle(value.map { scoreType.color(for: $0) } ?? .secondary)
        }
        .frame(maxWidth: .infinity)
    }
}
