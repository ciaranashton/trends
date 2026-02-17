import SwiftUI

struct ContentView: View {
    let healthManager: HealthManager
    @State private var scoreEngine: ScoreEngine?

    var body: some View {
        Group {
            if let scoreEngine {
                TabView {
                    DashboardView(healthManager: healthManager, scoreEngine: scoreEngine)
                        .tabItem {
                            Label("Dashboard", systemImage: "square.grid.2x2.fill")
                        }

                    TrendsTabView(scoreEngine: scoreEngine)
                        .tabItem {
                            Label("Trends", systemImage: "chart.line.uptrend.xyaxis")
                        }
                }
            } else {
                ProgressView()
                    .task {
                        scoreEngine = ScoreEngine(healthManager: healthManager)
                    }
            }
        }
    }
}
