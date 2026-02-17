import SwiftUI

struct DashboardView: View {
    let healthManager: HealthManager
    let scoreEngine: ScoreEngine
    @State private var viewModel: DashboardViewModel?

    var body: some View {
        NavigationStack {
            ScrollView {
                if let viewModel, !viewModel.isLoading {
                    LazyVStack(alignment: .leading, spacing: 20) {
                        // Score cards section
                        VStack(alignment: .leading, spacing: 12) {
                            HStack(spacing: 6) {
                                Image(systemName: "waveform.path.ecg")
                                    .font(.caption.weight(.semibold))
                                    .foregroundStyle(.secondary)
                                Text("Today's Scores")
                                    .font(.subheadline.weight(.semibold))
                                    .foregroundStyle(.secondary)
                            }

                            ScoresSectionView(scoreEngine: scoreEngine)
                        }

                        // Metric categories as unified cards
                        ForEach(HealthMetricCategory.allCases, id: \.self) { category in
                            let categorySummaries = viewModel.summaries(for: category)
                            if !categorySummaries.isEmpty {
                                categoryCard(category: category, summaries: categorySummaries)
                            }
                        }

                        Spacer(minLength: 16)
                    }
                    .padding(.horizontal)
                    .padding(.top, 8)
                } else {
                    VStack(spacing: 16) {
                        ProgressView()
                        Text("Loading health data...")
                            .font(.subheadline)
                            .foregroundStyle(.secondary)
                    }
                    .frame(maxWidth: .infinity, minHeight: 300)
                }
            }
            .navigationTitle(dateTitle)
            .navigationDestination(for: HealthMetric.self) { metric in
                MetricDetailView(metric: metric, healthManager: healthManager)
            }
            .navigationDestination(for: ScoreType.self) { scoreType in
                ScoreDetailView(
                    scoreType: scoreType,
                    currentResult: currentResult(for: scoreType),
                    scoreEngine: scoreEngine
                )
            }
            .refreshable {
                async let _ = viewModel?.loadSummaries()
                async let _ = scoreEngine.computeScores()
            }
            .task {
                if viewModel == nil {
                    let vm = DashboardViewModel(healthManager: healthManager)
                    viewModel = vm
                    await vm.loadSummaries()
                }
                await scoreEngine.computeScores()
            }
        }
    }

    // MARK: - Date Title

    private var dateTitle: String {
        let formatter = DateFormatter()
        formatter.dateFormat = "EEEE, MMM d"
        return formatter.string(from: Date())
    }

    // MARK: - Category Card

    private func categoryCard(category: HealthMetricCategory, summaries: [MetricSummary]) -> some View {
        VStack(alignment: .leading, spacing: 0) {
            // Category header
            HStack(spacing: 8) {
                Image(systemName: categoryIcon(category))
                    .font(.caption.weight(.semibold))
                    .foregroundStyle(categoryColor(category))
                    .frame(width: 24, height: 24)
                    .background(categoryColor(category).opacity(0.12), in: RoundedRectangle(cornerRadius: 6, style: .continuous))

                Text(category.rawValue)
                    .font(.subheadline.weight(.semibold))

                Spacer()

                Image(systemName: "chevron.right")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundStyle(.quaternary)
            }
            .padding(.horizontal, 14)
            .padding(.top, 14)
            .padding(.bottom, 8)

            // Metric rows
            ForEach(Array(summaries.enumerated()), id: \.element.id) { index, summary in
                NavigationLink(value: summary.metric) {
                    MetricCardView(summary: summary)
                }
                .buttonStyle(.plain)

                if index < summaries.count - 1 {
                    Divider()
                        .padding(.leading, 36)
                        .padding(.trailing, 14)
                }
            }

            Spacer().frame(height: 6)
        }
        .background {
            RoundedRectangle(cornerRadius: 18, style: .continuous)
                .fill(.ultraThinMaterial)
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(
                            LinearGradient(
                                colors: [categoryColor(category).opacity(0.03), .clear],
                                startPoint: .topLeading,
                                endPoint: .bottomTrailing
                            )
                        )
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .strokeBorder(.secondary.opacity(0.08), lineWidth: 0.5)
                )
        }
    }

    // MARK: - Category Helpers

    private func categoryIcon(_ category: HealthMetricCategory) -> String {
        switch category {
        case .activityAndFitness: return "figure.run"
        case .bodyMeasurements: return "scalemass.fill"
        case .vitalsAndSleep: return "heart.fill"
        }
    }

    private func categoryColor(_ category: HealthMetricCategory) -> Color {
        switch category {
        case .activityAndFitness: return .green
        case .bodyMeasurements: return .purple
        case .vitalsAndSleep: return .red
        }
    }

    private func currentResult(for type: ScoreType) -> ScoreResult? {
        switch type {
        case .sleep: return scoreEngine.sleepScore
        case .recovery: return scoreEngine.recoveryScore
        case .effort: return scoreEngine.effortScore
        }
    }
}
