import SwiftUI

struct TrendCard: View {
    let trend: WeightTrend
    let changeAmount: Double?
    let unit: WeightUnit

    private var changeText: String? {
        guard let change = changeAmount, trend != .notEnoughData else { return nil }
        let formatted = String(format: "%.1f", abs(change))
        return "\(formatted) \(unit.abbreviation)"
    }

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                Image(systemName: trend.icon)
                    .font(.title2)
                    .foregroundColor(trend.color)
                    .frame(width: 40, height: 40)
                    .background(trend.color.opacity(0.15))
                    .clipShape(Circle())

                Spacer()
            }

            VStack(alignment: .leading, spacing: 4) {
                Text(trend.message)
                    .font(.headline)

                if let changeText = changeText {
                    Text(changeText)
                        .font(.subheadline)
                        .foregroundColor(.secondary)
                }

                Text("Last 7 days")
                    .font(.caption)
                    .foregroundColor(.secondary)
            }
        }
        .padding()
        .frame(maxWidth: .infinity, alignment: .leading)
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
}

#Preview {
    VStack(spacing: 12) {
        TrendCard(trend: .up, changeAmount: 1.2, unit: .lbs)
        TrendCard(trend: .down, changeAmount: 0.8, unit: .kg)
        TrendCard(trend: .stable, changeAmount: 0.1, unit: .lbs)
        TrendCard(trend: .notEnoughData, changeAmount: nil, unit: .lbs)
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
