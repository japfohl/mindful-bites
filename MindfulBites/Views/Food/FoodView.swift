import SwiftUI
import SwiftData

enum FoodViewMode: String, CaseIterable {
    case timeline = "Timeline"
    case gallery = "Gallery"
}

struct FoodView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FoodEntry.createdAt, order: .reverse) private var entries: [FoodEntry]

    @State private var viewMode: FoodViewMode = .timeline
    @State private var showingAddEntry = false
    @State private var selectedEntry: FoodEntry?

    var body: some View {
        NavigationStack {
            VStack(spacing: 0) {
                Picker("View Mode", selection: $viewMode) {
                    ForEach(FoodViewMode.allCases, id: \.self) { mode in
                        Text(mode.rawValue).tag(mode)
                    }
                }
                .pickerStyle(.segmented)
                .padding()

                switch viewMode {
                case .timeline:
                    FoodTimelineView(entries: entries) { entry in
                        selectedEntry = entry
                    }
                case .gallery:
                    FoodGalleryView(entries: entries) { entry in
                        selectedEntry = entry
                    }
                }
            }
            .navigationTitle("Food")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button {
                        showingAddEntry = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddEntry) {
                AddFoodEntryView()
            }
            .navigationDestination(item: $selectedEntry) { entry in
                FoodEntryDetailView(entry: entry)
            }
        }
    }
}

#Preview {
    FoodView()
        .modelContainer(for: [FoodEntry.self, Tag.self], inMemory: true)
}
