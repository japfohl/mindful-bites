import SwiftUI
import SwiftData

struct WeightView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WeightEntry.date, order: .reverse) private var entries: [WeightEntry]

    var body: some View {
        NavigationStack {
            Group {
                if entries.isEmpty {
                    ContentUnavailableView(
                        "No Weight Logged Yet",
                        systemImage: "scalemass",
                        description: Text("Tap the + button to log your weight")
                    )
                } else {
                    List {
                        ForEach(entries) { entry in
                            HStack {
                                Text(entry.date, style: .date)
                                Spacer()
                                Text(String(format: "%.1f kg", entry.weight))
                            }
                        }
                    }
                }
            }
            .navigationTitle("Weight")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: {}) {
                        Image(systemName: "plus")
                    }
                }
            }
        }
    }
}

#Preview {
    WeightView()
        .modelContainer(for: WeightEntry.self, inMemory: true)
}
