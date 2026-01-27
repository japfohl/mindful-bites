import SwiftUI
import SwiftData

struct FoodGalleryView: View {
    let entries: [FoodEntry]
    let onEntryTap: (FoodEntry) -> Void

    @State private var filter = GalleryFilter()
    @State private var showingFilter = false

    private let columns = [
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4)
    ]

    private var photoEntries: [FoodEntry] {
        entries.filter { $0.hasPhoto }
    }

    private var filteredEntries: [FoodEntry] {
        var result = photoEntries

        // Filter by date range
        if let startDate = filter.startDate {
            result = result.filter { $0.createdAt >= startDate }
        }
        if let endDate = filter.endDate {
            result = result.filter { $0.createdAt < endDate }
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
        Group {
            if photoEntries.isEmpty {
                emptyState
            } else if filteredEntries.isEmpty {
                noResultsState
            } else {
                galleryGrid
            }
        }
        .toolbar {
            ToolbarItem(placement: .primaryAction) {
                Button {
                    showingFilter = true
                } label: {
                    Image(systemName: filter.isActive ? "line.3.horizontal.decrease.circle.fill" : "line.3.horizontal.decrease.circle")
                }
            }
        }
        .sheet(isPresented: $showingFilter) {
            GalleryFilterSheet(filter: $filter)
        }
    }

    private var galleryGrid: some View {
        GeometryReader { geometry in
            let itemSize = (geometry.size.width - 8) / 3

            ScrollView {
                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(filteredEntries) { entry in
                        Button {
                            onEntryTap(entry)
                        } label: {
                            GalleryGridItem(entry: entry, size: itemSize)
                        }
                        .buttonStyle(.plain)
                    }
                }
                .padding(.horizontal, 2)
            }
        }
    }

    private var emptyState: some View {
        ContentUnavailableView(
            "No Photos Yet",
            systemImage: "photo.on.rectangle",
            description: Text("Add photos to your food entries to see them here")
        )
    }

    private var noResultsState: some View {
        ContentUnavailableView {
            Label("No Matching Photos", systemImage: "magnifyingglass")
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

#Preview {
    NavigationStack {
        FoodGalleryView(entries: []) { _ in }
    }
    .modelContainer(for: [FoodEntry.self, Tag.self], inMemory: true)
}
