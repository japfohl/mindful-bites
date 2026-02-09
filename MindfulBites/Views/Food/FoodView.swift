import SwiftUI
import SwiftData

enum FoodViewMode: String {
    case timeline
    case gallery
}

struct FoodView: View {
    @Query(sort: \FoodEntry.createdAt, order: .reverse) private var allEntries: [FoodEntry]

    @State private var viewMode: FoodViewMode = .timeline
    @State private var showingAddEntry = false
    @State private var selectedEntry: FoodEntry?
    @State private var filter = GalleryFilter()
    @State private var showingFilter = false

    var body: some View {
        NavigationStack {
            FilteredFoodContent(
                startDate: filter.startDate,
                endDate: filter.endDate,
                selectedMealTypes: filter.selectedMealTypes,
                selectedTagIDs: filter.selectedTagIDs,
                viewMode: viewMode,
                hasAnyEntries: !allEntries.isEmpty,
                selectedEntry: $selectedEntry,
                onClearFilters: { filter.clear() }
            )
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
}

// MARK: - FilteredFoodContent

/// A subview that uses @Query with date predicates pushed to the SwiftData
/// query level, while keeping tag and meal-type filtering in-memory.
private struct FilteredFoodContent: View {
    @Query private var entries: [FoodEntry]

    let selectedMealTypes: Set<MealType>
    let selectedTagIDs: Set<UUID>
    let viewMode: FoodViewMode
    let hasAnyEntries: Bool
    @Binding var selectedEntry: FoodEntry?
    let onClearFilters: () -> Void

    init(
        startDate: Date?,
        endDate: Date?,
        selectedMealTypes: Set<MealType>,
        selectedTagIDs: Set<UUID>,
        viewMode: FoodViewMode,
        hasAnyEntries: Bool,
        selectedEntry: Binding<FoodEntry?>,
        onClearFilters: @escaping () -> Void
    ) {
        // Build a FetchDescriptor with date predicates at the database level
        var descriptor = FetchDescriptor<FoodEntry>(
            sortBy: [SortDescriptor(\.createdAt, order: .reverse)]
        )

        if let start = startDate, let end = endDate {
            descriptor.predicate = #Predicate<FoodEntry> { entry in
                entry.createdAt >= start && entry.createdAt < end
            }
        } else if let start = startDate {
            descriptor.predicate = #Predicate<FoodEntry> { entry in
                entry.createdAt >= start
            }
        } else if let end = endDate {
            descriptor.predicate = #Predicate<FoodEntry> { entry in
                entry.createdAt < end
            }
        }

        _entries = Query(descriptor)

        self.selectedMealTypes = selectedMealTypes
        self.selectedTagIDs = selectedTagIDs
        self.viewMode = viewMode
        self.hasAnyEntries = hasAnyEntries
        self._selectedEntry = selectedEntry
        self.onClearFilters = onClearFilters
    }

    /// Apply tag and meal-type filters in-memory (SwiftData #Predicate
    /// does not support relationship traversal or optional enum matching).
    private var filteredEntries: [FoodEntry] {
        var result = entries

        if !selectedMealTypes.isEmpty {
            result = result.filter { entry in
                guard let mealType = entry.mealType else { return false }
                return selectedMealTypes.contains(mealType)
            }
        }

        if !selectedTagIDs.isEmpty {
            result = result.filter { entry in
                entry.tags.contains { selectedTagIDs.contains($0.id) }
            }
        }

        return result
    }

    var body: some View {
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
            if !hasAnyEntries {
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
                        onClearFilters()
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
