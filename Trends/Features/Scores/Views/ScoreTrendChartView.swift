import SwiftUI
import Charts

struct ScoreTrendChartView: View {
    let dataPoints: [ScoreTimeSeriesPoint]
    let scoreType: ScoreType

    @State private var selectedDate: Date?

    private var selectedPoint: ScoreTimeSeriesPoint? {
        guard let selectedDate else { return nil }
        return dataPoints.min(by: {
            abs($0.date.timeIntervalSince(selectedDate)) < abs($1.date.timeIntervalSince(selectedDate))
        })
    }

    private var yRange: ClosedRange<Double> {
        switch scoreType {
        case .sleep, .recovery: return 0...100
        case .effort: return 0...21
        }
    }

    private var averageColor: Color {
        guard !dataPoints.isEmpty else { return .secondary }
        let avg = dataPoints.map(\.value).reduce(0, +) / Double(dataPoints.count)
        return scoreType.color(for: avg)
    }

    var body: some View {
        Chart {
            // Zone bands
            ForEach(scoreType.zoneBands, id: \.label) { band in
                RectangleMark(
                    xStart: nil,
                    xEnd: nil,
                    yStart: .value("", band.range.lowerBound),
                    yEnd: .value("", band.range.upperBound)
                )
                .foregroundStyle(band.color.opacity(0.06))
            }

            // Data line + area
            ForEach(dataPoints) { point in
                LineMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value(scoreType.displayName, point.value)
                )
                .foregroundStyle(averageColor.gradient)
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 2.5))

                AreaMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value(scoreType.displayName, point.value)
                )
                .foregroundStyle(
                    .linearGradient(
                        colors: [averageColor.opacity(0.15), averageColor.opacity(0.03), .clear],
                        startPoint: .top,
                        endPoint: .bottom
                    )
                )
                .interpolationMethod(.catmullRom)
            }

            // Selection indicator
            if let selectedPoint, let selectedDate {
                RuleMark(x: .value("Selected", selectedDate, unit: .day))
                    .foregroundStyle(averageColor.opacity(0.3))
                    .lineStyle(StrokeStyle(lineWidth: 1, dash: [4, 3]))

                PointMark(
                    x: .value("Date", selectedPoint.date, unit: .day),
                    y: .value(scoreType.displayName, selectedPoint.value)
                )
                .foregroundStyle(averageColor)
                .symbolSize(40)

                PointMark(
                    x: .value("Date", selectedPoint.date, unit: .day),
                    y: .value(scoreType.displayName, selectedPoint.value)
                )
                .foregroundStyle(.white)
                .symbolSize(16)
            }
        }
        .chartYScale(domain: yRange)
        .chartXSelection(value: $selectedDate)
        .chartOverlay { proxy in
            GeometryReader { geometry in
                if let selectedPoint, let selectedDate {
                    let xPosition = proxy.position(forX: selectedDate) ?? 0
                    let color = scoreType.color(for: selectedPoint.value)

                    VStack(spacing: 2) {
                        Text(scoreType.formatValue(selectedPoint.value))
                            .font(.caption.weight(.bold).monospacedDigit())
                            .foregroundStyle(color)
                        Text(selectedPoint.date.shortFormatted)
                            .font(.system(size: 10))
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 10)
                    .padding(.vertical, 6)
                    .background {
                        RoundedRectangle(cornerRadius: 8, style: .continuous)
                            .fill(.ultraThinMaterial)
                            .overlay(
                                RoundedRectangle(cornerRadius: 8, style: .continuous)
                                    .strokeBorder(color.opacity(0.2), lineWidth: 0.5)
                            )
                            .shadow(color: .black.opacity(0.08), radius: 4, y: 2)
                    }
                    .position(
                        x: min(max(xPosition, 40), geometry.size.width - 40),
                        y: 14
                    )
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading, values: .automatic(desiredCount: 4)) { _ in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(.secondary.opacity(0.15))
                AxisValueLabel()
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic(desiredCount: 5)) { _ in
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    .font(.system(size: 10))
                    .foregroundStyle(.secondary)
            }
        }
    }
}
