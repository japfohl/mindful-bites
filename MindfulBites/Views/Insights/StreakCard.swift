import SwiftUI

struct StreakCard: View {
    let title: String
    let days: Int
    let icon: String
    var iconColor: Color = .orange

    private var daysText: String {
        days == 1 ? "1 day" : "\(days) days"
    }

    var body: some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.title)
                .foregroundColor(iconColor)
                .frame(width: 44, height: 44)
                .background(iconColor.opacity(0.15))
                .clipShape(Circle())

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(.subheadline)
                    .foregroundColor(.secondary)

                Text(daysText)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .monospacedDigit()
            }

            Spacer()
        }
        .padding()
        .background(Color(.systemBackground))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }
}

#Preview {
    VStack(spacing: 12) {
        StreakCard(title: "Current Streak", days: 7, icon: "flame.fill", iconColor: .orange)
        StreakCard(title: "Longest Streak", days: 14, icon: "trophy.fill", iconColor: .yellow)
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
