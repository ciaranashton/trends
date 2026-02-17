import SwiftUI

struct TrendsTabView: View {
    let scoreEngine: ScoreEngine

    @State private var selectedRange: TimeRange = .week
    @State private var sleepTrend: [ScoreTimeSeriesPoint] = []
    @State private var recoveryTrend: [ScoreTimeSeriesPoint] = []
    @State private var effortTrend: [ScoreTimeSeriesPoint] = []
    @State private var isLoading = false

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 20) {
                    // Time range picker
                    Picker("Time Range", selection: $selectedRange) {
                        ForEach([TimeRange.week, .month, .threeMonths], id: \.self) { range in
                            Text(range.displayName).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    if isLoading {
                        VStack(spacing: 16) {
                            ProgressView()
                            Text("Loading trends...")
                                .font(.subheadline)
                                .foregroundStyle(.secondary)
                        }
                        .frame(maxWidth: .infinity, minHeight: 400)
                    } else {
                        trendCard(scoreType: .sleep, data: sleepTrend, currentScore: scoreEngine.sleepScore)
                        trendCard(scoreType: .recovery, data: recoveryTrend, currentScore: scoreEngine.recoveryScore)
                        trendCard(scoreType: .effort, data: effortTrend, currentScore: scoreEngine.effortScore)
                    }

                    Spacer(minLength: 16)
                }
                .padding(.top, 8)
            }
            .navigationTitle("Trends")
            .task { await loadTrends() }
            .onChange(of: selectedRange) { _, _ in
                Task { await loadTrends() }
            }
        }
    }

    // MARK: - Trend Card

    private func trendCard(
        scoreType: ScoreType,
        data: [ScoreTimeSeriesPoint],
        currentScore: ScoreResult?
    ) -> some View {
        let color = currentScore?.color ?? (data.isEmpty ? .secondary : scoreType.color(for: average(of: data)))

        return VStack(alignment: .leading, spacing: 14) {
            // Header with icon, title, current score badge
            HStack(spacing: 10) {
                // Icon circle
                Image(systemName: scoreType.systemImage)
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(color)
                    .frame(width: 28, height: 28)
                    .background(color.opacity(0.12), in: Circle())

                Text(scoreType.displayName)
                    .font(.headline)

                Spacer()

                // Current score badge
                if let currentScore {
                    HStack(spacing: 4) {
                        Text(currentScore.formattedValue)
                            .font(.subheadline.weight(.bold).monospacedDigit())
                            .foregroundStyle(currentScore.color)
                        Text(currentScore.label)
                            .font(.caption2.weight(.medium))
                            .foregroundStyle(currentScore.color.opacity(0.8))
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 5)
                    .background(currentScore.color.opacity(0.1), in: Capsule())
                }
            }
            .padding(.horizontal, 16)

            if data.isEmpty {
                VStack(spacing: 8) {
                    Image(systemName: "chart.line.flattrend.xyaxis")
                        .font(.title2)
                        .foregroundStyle(.secondary.opacity(0.3))
                    Text("No data for this period")
                        .font(.caption)
                        .foregroundStyle(.tertiary)
                }
                .frame(maxWidth: .infinity, minHeight: 140)
            } else {
                ScoreTrendChartView(dataPoints: data, scoreType: scoreType)
                    .frame(height: 150)
                    .padding(.horizontal, 12)

                // Stats row
                HStack(spacing: 0) {
                    miniStat("Avg", value: average(of: data), scoreType: scoreType)
                    miniSeparator
                    miniStat("Low", value: data.map(\.value).min(), scoreType: scoreType)
                    miniSeparator
                    miniStat("High", value: data.map(\.value).max(), scoreType: scoreType)
                }
                .padding(.vertical, 10)
                .background(.secondary.opacity(0.05), in: RoundedRectangle(cornerRadius: 10, style: .continuous))
                .padding(.horizontal, 12)
            }
        }
        .padding(.vertical, 14)
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.04), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(color.opacity(0.08), lineWidth: 0.5)
                )
        }
        .padding(.horizontal)
    }

    private var miniSeparator: some View {
        Rectangle()
            .fill(.secondary.opacity(0.12))
            .frame(width: 0.5, height: 26)
    }

    private func miniStat(_ title: String, value: Double?, scoreType: ScoreType) -> some View {
        VStack(spacing: 2) {
            Text(title)
                .font(.system(size: 10))
                .foregroundStyle(.tertiary)
            Text(value.map { scoreType.formatValue($0) } ?? "--")
                .font(.caption.weight(.semibold).monospacedDigit())
                .foregroundStyle(value.map { scoreType.color(for: $0) } ?? .secondary)
        }
        .frame(maxWidth: .infinity)
    }

    // MARK: - Helpers

    private func average(of data: [ScoreTimeSeriesPoint]) -> Double {
        guard !data.isEmpty else { return 0 }
        return data.map(\.value).reduce(0, +) / Double(data.count)
    }

    private func loadTrends() async {
        isLoading = true
        async let s = scoreEngine.scoreTimeSeries(for: .sleep, range: selectedRange)
        async let r = scoreEngine.scoreTimeSeries(for: .recovery, range: selectedRange)
        async let e = scoreEngine.scoreTimeSeries(for: .effort, range: selectedRange)
        sleepTrend = await s
        recoveryTrend = await r
        effortTrend = await e
        isLoading = false
    }
}
