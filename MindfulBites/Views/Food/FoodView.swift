import SwiftUI
import SwiftData

enum FoodViewMode: String {
    case timeline
    case gallery
}

struct FoodView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \FoodEntry.createdAt, order: .reverse) private var entries: [FoodEntry]

    @State private var viewMode: FoodViewMode = .timeline
    @State private var showingAddEntry = false
    @State private var selectedEntry: FoodEntry?
    @State private var filter = GalleryFilter()
    @State private var showingFilter = false

    private var filteredEntries: [FoodEntry] {
        var result = entries

        // Filter by date range
        if let startDate = filter.startDate {
            result = result.filter { $0.createdAt >= startDate }
        }
        if let endDate = filter.endDate {
            result = result.filter { $0.createdAt < endDate }
        }

        // Filter by meal type
        if !filter.selectedMealTypes.isEmpty {
            result = result.filter { entry in
                guard let mealType = entry.mealType else { return false }
                return filter.selectedMealTypes.contains(mealType)
            }
        }

        // Filter by tags
        if !filter.selectedTagIDs.isEmpty {
            result = result.filter { entry in
                entry.tags.contains { filter.selectedTagIDs.contains($0.id) }
            }
        }

        return result
    }

    var body: some View {
        NavigationStack {
            contentView
                .toolbar {
                    ToolbarItem(placement: .topBarLeading) {
                        Button {
                            showingFilter = true
                        } label: {
                            Image(systemName: filter.isActive ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                        }
                    }

                    ToolbarItem(placement: .principal) {
                        viewModePicker
                    }

                    ToolbarItem(placement: .topBarTrailing) {
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
                .sheet(isPresented: $showingFilter) {
                    GalleryFilterSheet(filter: $filter)
                }
                .navigationDestination(item: $selectedEntry) { entry in
                    FoodEntryDetailView(entry: entry)
                }
        }
    }

    private var viewModePicker: some View {
        HStack(spacing: 0) {
            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewMode = .timeline
                }
            } label: {
                Image(systemName: "list.bullet")
                    .frame(width: 44, height: 32)
                    .background(viewMode == .timeline ? Color.accentColor.opacity(0.15) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .foregroundColor(viewMode == .timeline ? .accentColor : .secondary)

            Button {
                withAnimation(.easeInOut(duration: 0.2)) {
                    viewMode = .gallery
                }
            } label: {
                Image(systemName: "square.grid.2x2")
                    .frame(width: 44, height: 32)
                    .background(viewMode == .gallery ? Color.accentColor.opacity(0.15) : Color.clear)
                    .clipShape(RoundedRectangle(cornerRadius: 6))
            }
            .foregroundColor(viewMode == .gallery ? .accentColor : .secondary)
        }
        .padding(2)
        .background(.ultraThinMaterial)
        .clipShape(RoundedRectangle(cornerRadius: 10))
    }

    @ViewBuilder
    private var contentView: some View {
        if filteredEntries.isEmpty {
            emptyState
        } else {
            switch viewMode {
            case .timeline:
                FoodTimelineView(entries: filteredEntries) { entry in
                    selectedEntry = entry
                }
            case .gallery:
                FoodGalleryView(entries: filteredEntries) { entry in
                    selectedEntry = entry
                }
            }
        }
    }

    private var emptyState: some View {
        Group {
            if entries.isEmpty {
                ContentUnavailableView(
                    "No Entries Yet",
                    systemImage: "fork.knife",
                    description: Text("Tap + to log your first meal")
                )
            } else {
                ContentUnavailableView {
                    Label("No Matching Entries", systemImage: "magnifyingglass")
                } description: {
                    Text("Try adjusting your filters")
                } actions: {
                    Button("Clear Filters") {
                        filter.clear()
                    }
                    .buttonStyle(.bordered)
                }
            }
        }
    }
}

#Preview {
    FoodView()
        .modelContainer(for: [FoodEntry.self, Tag.self], inMemory: true)
}
