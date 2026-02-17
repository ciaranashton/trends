import SwiftUI
import Charts

struct TrendChartView: View {
    let dataPoints: [TimeSeriesDataPoint]
    let metric: HealthMetric

    @State private var selectedDate: Date?

    private var selectedDataPoint: TimeSeriesDataPoint? {
        guard let selectedDate else { return nil }
        return dataPoints.min(by: {
            abs($0.date.timeIntervalSince(selectedDate)) < abs($1.date.timeIntervalSince(selectedDate))
        })
    }

    var body: some View {
        Chart(dataPoints) { point in
            if metric.isCumulative {
                BarMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value(metric.displayName, point.value)
                )
                .foregroundStyle(metric.accentColor.gradient)
                .cornerRadius(4)
            } else {
                LineMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value(metric.displayName, point.value)
                )
                .foregroundStyle(metric.accentColor)
                .interpolationMethod(.catmullRom)
                .lineStyle(StrokeStyle(lineWidth: 2))

                AreaMark(
                    x: .value("Date", point.date, unit: .day),
                    y: .value(metric.displayName, point.value)
                )
                .foregroundStyle(metric.accentColor.opacity(0.1).gradient)
                .interpolationMethod(.catmullRom)
            }
        }
        .chartXSelection(value: $selectedDate)
        .chartOverlay { proxy in
            GeometryReader { geometry in
                if let selectedDataPoint, let selectedDate {
                    let xPosition = proxy.position(forX: selectedDate) ?? 0
                    let yPosition = proxy.position(forY: selectedDataPoint.value) ?? 0

                    VStack(spacing: 4) {
                        Text(metric.formatValue(selectedDataPoint.value))
                            .font(.caption.weight(.semibold).monospacedDigit())
                        Text(selectedDataPoint.date.shortFormatted)
                            .font(.caption2)
                            .foregroundStyle(.secondary)
                    }
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 8))
                    .position(
                        x: clamp(xPosition, min: 40, max: geometry.size.width - 40),
                        y: max(yPosition - 40, 20)
                    )
                }
            }
        }
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(.secondary.opacity(0.3))
                AxisValueLabel()
                    .font(.caption2)
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { value in
                AxisGridLine(stroke: StrokeStyle(lineWidth: 0.5))
                    .foregroundStyle(.secondary.opacity(0.3))
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
                    .font(.caption2)
            }
        }
    }

    private func clamp(_ value: CGFloat, min minVal: CGFloat, max maxVal: CGFloat) -> CGFloat {
        Swift.min(Swift.max(value, minVal), maxVal)
    }
}
