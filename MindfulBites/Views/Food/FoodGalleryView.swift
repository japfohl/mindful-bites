import SwiftUI
import SwiftData

struct FoodGalleryView: View {
    let entries: [FoodEntry]
    let onEntryTap: (FoodEntry) -> Void

    private let columns = [
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4),
        GridItem(.flexible(), spacing: 4)
    ]

    /// Only show entries that have photos in the gallery
    private var photoEntries: [FoodEntry] {
        entries.filter { $0.hasPhoto }
    }

    var body: some View {
        if photoEntries.isEmpty {
            emptyState
        } else {
            galleryGrid
        }
    }

    private var galleryGrid: some View {
        GeometryReader { geometry in
            let itemSize = (geometry.size.width - 8) / 3

            ScrollView {
                LazyVGrid(columns: columns, spacing: 4) {
                    ForEach(photoEntries) { entry in
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
            "No Photos",
            systemImage: "photo.on.rectangle",
            description: Text("Entries with photos will appear here")
        )
    }
}

#Preview {
    NavigationStack {
        FoodGalleryView(entries: []) { _ in }
    }
    .modelContainer(for: [FoodEntry.self, Tag.self], inMemory: true)
}
