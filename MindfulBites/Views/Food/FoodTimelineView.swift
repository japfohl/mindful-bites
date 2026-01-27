import SwiftUI
import SwiftData

struct FoodTimelineView: View {
    let entries: [FoodEntry]
    let onEntryTap: (FoodEntry) -> Void

    private var groupedEntries: [(date: Date, entries: [FoodEntry])] {
        let grouped = Dictionary(grouping: entries) { entry in
            entry.createdAt.startOfDay
        }

        return grouped
            .map { (date: $0.key, entries: $0.value.sorted { $0.createdAt > $1.createdAt }) }
            .sorted { $0.date > $1.date }
    }

    var body: some View {
        if entries.isEmpty {
            emptyState
        } else {
            List {
                ForEach(groupedEntries, id: \.date) { group in
                    Section {
                        ForEach(group.entries) { entry in
                            Button {
                                onEntryTap(entry)
                            } label: {
                                FoodEntryRow(entry: entry)
                            }
                            .buttonStyle(.plain)
                        }
                    } header: {
                        Text(group.date.timelineSectionHeader)
                            .font(.headline)
                            .foregroundColor(.primary)
                            .textCase(nil)
                    }
                }
            }
            .listStyle(.plain)
        }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "No entries yet",
            systemImage: "fork.knife",
            description: Text("Tap the + button to log your first meal")
        )
    }
}

#Preview {
    let entries = [
        FoodEntry(text: "Oatmeal with berries", photoFileName: nil, mealType: .breakfast),
        FoodEntry(text: "Grilled chicken salad", photoFileName: nil, mealType: .lunch),
        FoodEntry(text: "Apple and peanut butter", photoFileName: nil, mealType: .snack),
    ]

    return FoodTimelineView(entries: entries) { entry in
        print("Tapped: \(entry.text ?? "no text")")
    }
}
