import SwiftUI

struct SparklineView: View {
    let data: [Double]
    let color: Color
    var lineWidth: CGFloat = 1.5
    var filled: Bool = true

    var body: some View {
        GeometryReader { geo in
            if data.count >= 2 {
                let minVal = data.min() ?? 0
                let maxVal = data.max() ?? 1
                let range = max(maxVal - minVal, 0.001)
                let stepX = geo.size.width / CGFloat(data.count - 1)

                let points: [CGPoint] = data.enumerated().map { i, val in
                    CGPoint(
                        x: CGFloat(i) * stepX,
                        y: geo.size.height - (CGFloat(val - minVal) / CGFloat(range)) * geo.size.height
                    )
                }

                ZStack {
                    // Filled area
                    if filled {
                        Path { path in
                            path.move(to: CGPoint(x: points[0].x, y: geo.size.height))
                            path.addLine(to: points[0])
                            for i in 1..<points.count {
                                let prev = points[i - 1]
                                let curr = points[i]
                                let midX = (prev.x + curr.x) / 2
                                path.addCurve(
                                    to: curr,
                                    control1: CGPoint(x: midX, y: prev.y),
                                    control2: CGPoint(x: midX, y: curr.y)
                                )
                            }
                            path.addLine(to: CGPoint(x: points.last!.x, y: geo.size.height))
                            path.closeSubpath()
                        }
                        .fill(
                            LinearGradient(
                                colors: [color.opacity(0.2), color.opacity(0.02)],
                                startPoint: .top,
                                endPoint: .bottom
                            )
                        )
                    }

                    // Line
                    Path { path in
                        path.move(to: points[0])
                        for i in 1..<points.count {
                            let prev = points[i - 1]
                            let curr = points[i]
                            let midX = (prev.x + curr.x) / 2
                            path.addCurve(
                                to: curr,
                                control1: CGPoint(x: midX, y: prev.y),
                                control2: CGPoint(x: midX, y: curr.y)
                            )
                        }
                    }
                    .stroke(color, style: StrokeStyle(lineWidth: lineWidth, lineCap: .round, lineJoin: .round))

                    // End dot
                    if let last = points.last {
                        Circle()
                            .fill(color)
                            .frame(width: lineWidth * 2.5, height: lineWidth * 2.5)
                            .position(last)
                    }
                }
            }
        }
    }
}
