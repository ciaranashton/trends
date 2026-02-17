import SwiftUI

struct MetricDetailView: View {
    let metric: HealthMetric
    let healthManager: HealthManager
    @State private var viewModel: MetricDetailViewModel?

    var body: some View {
        ScrollView {
            if let viewModel {
                VStack(spacing: 20) {
                    Picker("Time Range", selection: Binding(
                        get: { viewModel.selectedRange },
                        set: { viewModel.selectedRange = $0 }
                    )) {
                        ForEach(TimeRange.allCases) { range in
                            Text(range.displayName).tag(range)
                        }
                    }
                    .pickerStyle(.segmented)
                    .padding(.horizontal)

                    if viewModel.isLoading {
                        ProgressView()
                            .frame(height: 240)
                    } else if viewModel.dataPoints.isEmpty {
                        ContentUnavailableView(
                            "No Data",
                            systemImage: metric.systemImage,
                            description: Text("No \(metric.displayName.lowercased()) data available for this period.")
                        )
                        .frame(height: 240)
                    } else {
                        TrendChartView(
                            dataPoints: viewModel.dataPoints,
                            metric: metric
                        )
                        .frame(height: 240)
                        .padding(.horizontal)

                        StatsSummaryView(
                            metric: metric,
                            average: viewModel.average,
                            minimum: viewModel.minimum,
                            maximum: viewModel.maximum
                        )
                        .padding(.horizontal)
                    }
                }
                .padding(.top)
            }
        }
        .navigationTitle(metric.displayName)
        .navigationBarTitleDisplayMode(.large)
        .task {
            if viewModel == nil {
                let vm = MetricDetailViewModel(metric: metric, healthManager: healthManager)
                viewModel = vm
                await vm.loadData()
            }
        }
        .onChange(of: viewModel?.selectedRange) { _, _ in
            guard let viewModel else { return }
            Task {
                await viewModel.loadData()
            }
        }
    }
}
