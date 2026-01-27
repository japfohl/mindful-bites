import SwiftUI

struct MealTypePicker: View {
    @Binding var selection: MealType

    var body: some View {
        HStack(spacing: 12) {
            ForEach(MealType.allCases) { mealType in
                Button {
                    selection = mealType
                } label: {
                    VStack(spacing: 4) {
                        Image(systemName: mealType.icon)
                            .font(.title2)
                        Text(mealType.displayName)
                            .font(.caption)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
                    .background(
                        RoundedRectangle(cornerRadius: 12)
                            .fill(selection == mealType ? Color.accentColor.opacity(0.2) : Color(.systemGray6))
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 12)
                            .stroke(selection == mealType ? Color.accentColor : Color.clear, lineWidth: 2)
                    )
                }
                .buttonStyle(.plain)
                .foregroundColor(selection == mealType ? .accentColor : .primary)
            }
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var selection: MealType = .breakfast

        var body: some View {
            MealTypePicker(selection: $selection)
                .padding()
        }
    }

    return PreviewWrapper()
}
