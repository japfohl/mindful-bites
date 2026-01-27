import SwiftUI

struct FoodEntryRow: View {
    let entry: FoodEntry

    @State private var thumbnail: UIImage?

    private let thumbnailSize = CGSize(width: 120, height: 120)

    var body: some View {
        HStack(spacing: 12) {
            if entry.hasPhoto {
                Group {
                    if let thumbnail = thumbnail {
                        Image(uiImage: thumbnail)
                            .resizable()
                            .scaledToFill()
                    } else {
                        Color(.systemGray5)
                    }
                }
                .frame(width: 60, height: 60)
                .clipShape(RoundedRectangle(cornerRadius: 8))
            }

            VStack(alignment: .leading, spacing: 4) {
                // Title as primary text
                Text(entry.title)
                    .font(.headline)
                    .lineLimit(1)

                // Meal type and time
                HStack(spacing: 6) {
                    if let mealType = entry.mealType {
                        Image(systemName: mealType.icon)
                            .foregroundColor(.accentColor)
                    }

                    Text(entry.createdAt.formatted(date: .omitted, time: .shortened))
                        .foregroundColor(.secondary)
                }
                .font(.caption)

                // Description as secondary text
                if let text = entry.text, !text.isEmpty {
                    Text(text)
                        .font(.subheadline)
                        .lineLimit(1)
                        .foregroundColor(.secondary)
                }
            }

            Spacer()
        }
        .padding(.vertical, 4)
        .task {
            await loadThumbnail()
        }
    }

    private func loadThumbnail() async {
        guard let filename = entry.photoFileName else { return }

        let image = await ThumbnailCache.shared.thumbnail(for: filename, size: thumbnailSize)

        await MainActor.run {
            self.thumbnail = image
        }
    }
}

#Preview {
    List {
        FoodEntryRow(entry: FoodEntry(
            title: "Breakfast at Home",
            text: "Oatmeal with berries and honey",
            mealType: .breakfast
        ))

        FoodEntryRow(entry: FoodEntry(
            title: "Quick Lunch",
            text: "Grilled chicken salad",
            mealType: .lunch
        ))

        FoodEntryRow(entry: FoodEntry(
            title: "Afternoon Snack",
            text: nil,
            mealType: .snack
        ))
    }
}
