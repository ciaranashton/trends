import SwiftUI

struct ScoreDetailView: View {
    let scoreType: ScoreType
    let currentResult: ScoreResult?
    let scoreEngine: ScoreEngine

    @State private var viewModel: ScoreDetailViewModel?
    @State private var animateGauge = false

    var body: some View {
        ScrollView {
            VStack(spacing: 28) {
                // Hero gauge
                scoreHeader
                    .padding(.top, 8)

                // Insight card
                if let insight = currentResult?.insight {
                    insightCard(insight)
                }

                // Component breakdown
                if let components = currentResult?.components, !components.isEmpty {
                    componentBreakdown(components)
                }

                // Trend chart
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
                // Soft glow behind gauge
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

    // MARK: - Component Breakdown

    private func componentBreakdown(_ components: [ScoreComponent]) -> some View {
        VStack(alignment: .leading, spacing: 14) {
            Text("Breakdown")
                .font(.title3.weight(.semibold))
                .padding(.horizontal)

            VStack(spacing: 10) {
                ForEach(components) { component in
                    componentRow(component)
                }
            }
            .padding(.horizontal)
        }
    }

    private func componentRow(_ component: ScoreComponent) -> some View {
        VStack(spacing: 8) {
            HStack(alignment: .center) {
                // Score indicator dot
                Circle()
                    .fill(barColor(for: component.score))
                    .frame(width: 8, height: 8)

                Text(component.name)
                    .font(.subheadline.weight(.medium))

                Spacer()

                // Raw value
                Text(component.formattedRaw)
                    .font(.subheadline.monospacedDigit())
                    .foregroundStyle(.secondary)

                // Score badge
                Text(String(format: "%.0f", component.score))
                    .font(.caption.weight(.bold).monospacedDigit())
                    .foregroundStyle(barColor(for: component.score))
                    .padding(.horizontal, 8)
                    .padding(.vertical, 3)
                    .background(barColor(for: component.score).opacity(0.12), in: Capsule())
            }

            // Progress bar
            GeometryReader { geo in
                ZStack(alignment: .leading) {
                    RoundedRectangle(cornerRadius: 3)
                        .fill(.secondary.opacity(0.1))

                    RoundedRectangle(cornerRadius: 3)
                        .fill(
                            LinearGradient(
                                colors: [barColor(for: component.score).opacity(0.7), barColor(for: component.score)],
                                startPoint: .leading,
                                endPoint: .trailing
                            )
                        )
                        .frame(width: animateGauge ? max(0, geo.size.width * component.score / 100) : 0)
                        .animation(.easeOut(duration: 0.6).delay(0.1), value: animateGauge)
                }
            }
            .frame(height: 5)

            // Weight label
            HStack {
                Text("\(String(format: "%.0f%%", component.weight * 100)) weight")
                    .font(.system(size: 10))
                    .foregroundStyle(.tertiary)
                Spacer()
            }
        }
        .padding(12)
        .background {
            RoundedRectangle(cornerRadius: 12, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                        .strokeBorder(.secondary.opacity(0.08), lineWidth: 0.5)
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

                    // Stats row
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
