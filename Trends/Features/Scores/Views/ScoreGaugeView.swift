import SwiftUI

struct ScoreGaugeView: View {
    let value: Double
    let maxValue: Double
    let color: Color
    let lineWidth: CGFloat
    var showTicks: Bool = false

    init(value: Double, maxValue: Double, color: Color, lineWidth: CGFloat = 8, showTicks: Bool = false) {
        self.value = value
        self.maxValue = maxValue
        self.color = color
        self.lineWidth = lineWidth
        self.showTicks = showTicks
    }

    private var progress: Double {
        guard maxValue > 0 else { return 0 }
        return min(value / maxValue, 1.0)
    }

    private let startAngle: Double = 135
    private let arcSpan: Double = 270 // 0.75 of 360

    var body: some View {
        ZStack {
            // Background track
            Circle()
                .trim(from: 0, to: 0.75)
                .stroke(
                    color.opacity(0.1),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(startAngle))

            // Progress arc with angular gradient
            Circle()
                .trim(from: 0, to: 0.75 * progress)
                .stroke(
                    AngularGradient(
                        colors: [color.opacity(0.5), color],
                        center: .center,
                        startAngle: .degrees(startAngle),
                        endAngle: .degrees(startAngle + arcSpan * progress)
                    ),
                    style: StrokeStyle(lineWidth: lineWidth, lineCap: .round)
                )
                .rotationEffect(.degrees(startAngle))
                .shadow(color: color.opacity(0.4), radius: lineWidth * 0.6, x: 0, y: 0)

            // Tick marks
            if showTicks {
                ForEach(0..<25, id: \.self) { i in
                    let fraction = Double(i) / 24.0
                    let angle = startAngle + arcSpan * fraction
                    let isMajor = i % 6 == 0
                    tickMark(angle: angle, isMajor: isMajor)
                }
            }
        }
    }

    private func tickMark(angle: Double, isMajor: Bool) -> some View {
        GeometryReader { geo in
            let center = CGPoint(x: geo.size.width / 2, y: geo.size.height / 2)
            let radius = min(geo.size.width, geo.size.height) / 2
            let tickLength: CGFloat = isMajor ? lineWidth * 0.8 : lineWidth * 0.4
            let innerRadius = radius - lineWidth / 2 - 2 - tickLength
            let outerRadius = radius - lineWidth / 2 - 2
            let rad = Angle(degrees: angle).radians

            Path { path in
                path.move(to: CGPoint(
                    x: center.x + innerRadius * cos(rad),
                    y: center.y + innerRadius * sin(rad)
                ))
                path.addLine(to: CGPoint(
                    x: center.x + outerRadius * cos(rad),
                    y: center.y + outerRadius * sin(rad)
                ))
            }
            .stroke(
                color.opacity(isMajor ? 0.3 : 0.15),
                style: StrokeStyle(lineWidth: isMajor ? 1.5 : 0.8, lineCap: .round)
            )
        }
    }
}
