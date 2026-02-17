import SwiftUI

struct ScoresSectionView: View {
    let scoreEngine: ScoreEngine

    var body: some View {
        HStack(spacing: 10) {
            NavigationLink(value: ScoreType.sleep) {
                ScoreCardView(scoreType: .sleep, result: scoreEngine.sleepScore)
            }
            .buttonStyle(.plain)

            NavigationLink(value: ScoreType.recovery) {
                ScoreCardView(scoreType: .recovery, result: scoreEngine.recoveryScore)
            }
            .buttonStyle(.plain)

            NavigationLink(value: ScoreType.effort) {
                ScoreCardView(scoreType: .effort, result: scoreEngine.effortScore)
            }
            .buttonStyle(.plain)
        }
    }
}
