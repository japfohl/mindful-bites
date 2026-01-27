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
                HStack(spacing: 6) {
                    if let mealType = entry.mealType {
                        Label(mealType.displayName, systemImage: mealType.icon)
                            .font(.caption)
                            .foregroundColor(.accentColor)
                    }

                    Text(entry.createdAt.formatted(date: .omitted, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }

                if let text = entry.text, !text.isEmpty {
                    Text(text)
                        .font(.body)
                        .lineLimit(2)
                        .foregroundColor(.primary)
                } else if !entry.hasPhoto {
                    Text("No description")
                        .font(.body)
                        .foregroundColor(.secondary)
                        .italic()
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

        let image = await Task.detached(priority: .utility) {
            PhotoStorageService.shared.loadThumbnail(filename: filename, size: thumbnailSize)
        }.value

        await MainActor.run {
            self.thumbnail = image
        }
    }
}

#Preview {
    List {
        FoodEntryRow(entry: FoodEntry(
            text: "Oatmeal with berries and honey",
            photoFileName: nil,
            mealType: .breakfast
        ))

        FoodEntryRow(entry: FoodEntry(
            text: "Grilled chicken salad",
            photoFileName: nil,
            mealType: .lunch
        ))

        FoodEntryRow(entry: FoodEntry(
            text: nil,
            photoFileName: nil,
            mealType: .snack
        ))
    }
}
