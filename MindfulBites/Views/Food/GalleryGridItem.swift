import SwiftUI

struct GalleryGridItem: View {
    let entry: FoodEntry
    let size: CGFloat

    @State private var thumbnail: UIImage?

    var body: some View {
        ZStack(alignment: .bottomLeading) {
            Group {
                if let thumbnail = thumbnail {
                    Image(uiImage: thumbnail)
                        .resizable()
                        .scaledToFill()
                } else {
                    Color(.systemGray5)
                }
            }
            .frame(width: size, height: size)
            .clipped()

            // Meal type overlay
            if let mealType = entry.mealType {
                Image(systemName: mealType.icon)
                    .font(.caption)
                    .padding(6)
                    .background(.ultraThinMaterial)
                    .clipShape(Circle())
                    .padding(6)
            }
        }
        .clipShape(RoundedRectangle(cornerRadius: 8))
        .task(id: entry.photoFileName) {
            await loadThumbnail()
        }
    }

    private func loadThumbnail() async {
        guard let filename = entry.photoFileName else { return }

        let targetSize = CGSize(width: size * 2, height: size * 2) // 2x for retina
        let image = await ThumbnailCache.shared.thumbnail(for: filename, size: targetSize)

        await MainActor.run {
            self.thumbnail = image
        }
    }
}

#Preview {
    GalleryGridItem(
        entry: FoodEntry(text: "Test", photoFileName: nil, mealType: .lunch),
        size: 120
    )
}
