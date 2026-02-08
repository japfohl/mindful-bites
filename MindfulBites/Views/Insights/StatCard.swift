import SwiftUI

struct StatCard: View {
    let title: String
    let value: String
    let icon: String
    var iconColor: Color = .accentColor

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            HStack {
                Image(systemName: icon)
                    .font(.title3)
                    .foregroundColor(iconColor)
                Spacer()
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(value)
                    .font(.title2)
                    .fontWeight(.semibold)
                    .monospacedDigit()

                Text(title)
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
    HStack {
        StatCard(title: "Days Logged", value: "42", icon: "calendar", iconColor: .blue)
        StatCard(title: "Avg Meals/Day", value: "3.2", icon: "fork.knife", iconColor: .green)
    }
    .padding()
    .background(Color(.systemGroupedBackground))
}
