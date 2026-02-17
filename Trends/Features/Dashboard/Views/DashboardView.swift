import SwiftUI

struct DashboardView: View {
    let healthManager: HealthManager
    let scoreEngine: ScoreEngine
    @State private var viewModel: DashboardViewModel?

    private let columns = [
        GridItem(.flexible(), spacing: 12),
        GridItem(.flexible(), spacing: 12)
    ]

    var body: some View {
        NavigationStack {
            ScrollView {
                if let viewModel, !viewModel.isLoading {
                    LazyVStack(alignment: .leading, spacing: 24) {
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

                        ForEach(HealthMetricCategory.allCases, id: \.self) { category in
                            let categorySummaries = viewModel.summaries(for: category)
                            if !categorySummaries.isEmpty {
                                Section {
                                    LazyVGrid(columns: columns, spacing: 12) {
                                        ForEach(categorySummaries) { summary in
                                            NavigationLink(value: summary.metric) {
                                                MetricCardView(summary: summary)
                                            }
                                            .buttonStyle(.plain)
                                        }
                                    }
                                } header: {
                                    Text(category.rawValue)
                                        .font(.title3.weight(.semibold))
                                        .foregroundStyle(.primary)
                                }
                            }
                        }
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
            .navigationTitle("Dashboard")
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

    private func currentResult(for type: ScoreType) -> ScoreResult? {
        switch type {
        case .sleep: return scoreEngine.sleepScore
        case .recovery: return scoreEngine.recoveryScore
        case .effort: return scoreEngine.effortScore
        }
    }
}
