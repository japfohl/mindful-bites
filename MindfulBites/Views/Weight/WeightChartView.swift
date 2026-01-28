import SwiftUI
import Charts

struct WeightChartView: View {
    let entries: [WeightEntry]
    let weightUnit: WeightUnit

    private var chartData: [(date: Date, weight: Double)] {
        entries
            .sorted { $0.date < $1.date }
            .map { (date: $0.date, weight: weightUnit.convert(fromKg: $0.weight)) }
    }

    private var yAxisRange: ClosedRange<Double> {
        guard !chartData.isEmpty else { return 0...100 }

        let weights = chartData.map { $0.weight }
        let minWeight = weights.min() ?? 0
        let maxWeight = weights.max() ?? 100

        // Add some padding
        let padding = (maxWeight - minWeight) * 0.1
        let adjustedMin = max(0, minWeight - padding - 5)
        let adjustedMax = maxWeight + padding + 5

        return adjustedMin...adjustedMax
    }

    var body: some View {
        if chartData.isEmpty {
            ContentUnavailableView(
                "No Data",
                systemImage: "chart.line.downtrend.xyaxis",
                description: Text("Log weight to see your trend")
            )
            .frame(height: 200)
        } else if chartData.count == 1 {
            singlePointView
        } else {
            chartView
        }
    }

    private var singlePointView: some View {
        VStack(spacing: 8) {
            Text(String(format: "%.1f", chartData.first?.weight ?? 0))
                .font(.system(size: 48, weight: .bold, design: .rounded))

            Text(weightUnit.abbreviation)
                .font(.title3)
                .foregroundColor(.secondary)

            Text(chartData.first?.date ?? Date(), style: .date)
                .font(.subheadline)
                .foregroundColor(.secondary)
        }
        .frame(height: 200)
        .frame(maxWidth: .infinity)
    }

    private var chartView: some View {
        Chart(chartData, id: \.date) { item in
            LineMark(
                x: .value("Date", item.date),
                y: .value("Weight", item.weight)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(Color.accentColor)

            AreaMark(
                x: .value("Date", item.date),
                y: .value("Weight", item.weight)
            )
            .interpolationMethod(.catmullRom)
            .foregroundStyle(
                LinearGradient(
                    colors: [Color.accentColor.opacity(0.3), Color.accentColor.opacity(0.0)],
                    startPoint: .top,
                    endPoint: .bottom
                )
            )

            PointMark(
                x: .value("Date", item.date),
                y: .value("Weight", item.weight)
            )
            .foregroundStyle(Color.accentColor)
            .symbolSize(30)
        }
        .chartYScale(domain: yAxisRange)
        .chartYAxis {
            AxisMarks(position: .leading) { value in
                AxisGridLine()
                AxisValueLabel {
                    if let weight = value.as(Double.self) {
                        Text(String(format: "%.0f", weight))
                    }
                }
            }
        }
        .chartXAxis {
            AxisMarks(values: .automatic) { value in
                AxisGridLine()
                AxisValueLabel(format: .dateTime.month(.abbreviated).day())
            }
        }
        .frame(height: 200)
    }
}

#Preview {
    let entries = [
        WeightEntry(date: Calendar.current.date(byAdding: .day, value: -6, to: Date())!, weight: 70.0),
        WeightEntry(date: Calendar.current.date(byAdding: .day, value: -5, to: Date())!, weight: 69.8),
        WeightEntry(date: Calendar.current.date(byAdding: .day, value: -3, to: Date())!, weight: 69.5),
        WeightEntry(date: Calendar.current.date(byAdding: .day, value: -1, to: Date())!, weight: 69.7),
        WeightEntry(date: Date(), weight: 69.3)
    ]

    return WeightChartView(entries: entries, weightUnit: .kg)
        .padding()
}
