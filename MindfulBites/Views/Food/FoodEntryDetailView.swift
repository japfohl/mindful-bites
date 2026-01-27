import SwiftUI
import SwiftData

struct FoodEntryDetailView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let entry: FoodEntry

    @State private var fullImage: UIImage?
    @State private var showingDeleteConfirmation = false

    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                if entry.hasPhoto {
                    photoSection
                }

                detailsSection

                if !entry.tags.isEmpty {
                    tagsSection
                }
            }
            .padding()
        }
        .navigationTitle("Entry")
        .navigationBarTitleDisplayMode(.inline)
        .toolbar {
            ToolbarItem(placement: .destructiveAction) {
                Button(role: .destructive) {
                    showingDeleteConfirmation = true
                } label: {
                    Image(systemName: "trash")
                }
            }
        }
        .confirmationDialog("Delete Entry", isPresented: $showingDeleteConfirmation) {
            Button("Delete", role: .destructive) {
                deleteEntry()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("Are you sure you want to delete this entry? This cannot be undone.")
        }
        .task {
            await loadFullImage()
        }
    }

    // MARK: - Photo Section

    private var photoSection: some View {
        Group {
            if let image = fullImage {
                Image(uiImage: image)
                    .resizable()
                    .scaledToFit()
                    .clipShape(RoundedRectangle(cornerRadius: 12))
            } else {
                RoundedRectangle(cornerRadius: 12)
                    .fill(Color(.systemGray5))
                    .aspectRatio(4/3, contentMode: .fit)
                    .overlay {
                        ProgressView()
                    }
            }
        }
    }

    // MARK: - Details Section

    private var detailsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                if let mealType = entry.mealType {
                    Label(mealType.displayName, systemImage: mealType.icon)
                        .font(.subheadline)
                        .foregroundColor(.accentColor)
                        .padding(.horizontal, 12)
                        .padding(.vertical, 6)
                        .background(Color.accentColor.opacity(0.1))
                        .clipShape(Capsule())
                }

                Spacer()

                VStack(alignment: .trailing) {
                    Text(entry.createdAt.formatted(date: .abbreviated, time: .omitted))
                        .font(.subheadline)
                    Text(entry.createdAt.formatted(date: .omitted, time: .shortened))
                        .font(.caption)
                        .foregroundColor(.secondary)
                }
            }

            if let text = entry.text, !text.isEmpty {
                Text(text)
                    .font(.body)
                    .padding(.top, 4)
            }
        }
    }

    // MARK: - Tags Section

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Tags")
                .font(.headline)

            FlowLayout(spacing: 8) {
                ForEach(entry.tags) { tag in
                    Text(tag.name)
                        .font(.caption)
                        .padding(.horizontal, 10)
                        .padding(.vertical, 5)
                        .background(Color(.systemGray5))
                        .clipShape(Capsule())
                }
            }
        }
    }

    // MARK: - Actions

    private func loadFullImage() async {
        guard let filename = entry.photoFileName else { return }

        let image = await Task.detached(priority: .userInitiated) {
            PhotoStorageService.shared.loadPhoto(filename: filename)
        }.value

        await MainActor.run {
            self.fullImage = image
        }
    }

    private func deleteEntry() {
        if let filename = entry.photoFileName {
            PhotoStorageService.shared.deletePhoto(filename: filename)
        }
        modelContext.delete(entry)
        dismiss()
    }
}

// MARK: - Flow Layout for Tags

struct FlowLayout: Layout {
    var spacing: CGFloat = 8

    func sizeThatFits(proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) -> CGSize {
        let result = FlowResult(in: proposal.width ?? 0, subviews: subviews, spacing: spacing)
        return result.size
    }

    func placeSubviews(in bounds: CGRect, proposal: ProposedViewSize, subviews: Subviews, cache: inout ()) {
        let result = FlowResult(in: bounds.width, subviews: subviews, spacing: spacing)

        for (index, subview) in subviews.enumerated() {
            subview.place(at: CGPoint(x: bounds.minX + result.positions[index].x,
                                       y: bounds.minY + result.positions[index].y),
                          proposal: .unspecified)
        }
    }

    struct FlowResult {
        var size: CGSize = .zero
        var positions: [CGPoint] = []

        init(in maxWidth: CGFloat, subviews: Subviews, spacing: CGFloat) {
            var x: CGFloat = 0
            var y: CGFloat = 0
            var rowHeight: CGFloat = 0

            for subview in subviews {
                let size = subview.sizeThatFits(.unspecified)

                if x + size.width > maxWidth && x > 0 {
                    x = 0
                    y += rowHeight + spacing
                    rowHeight = 0
                }

                positions.append(CGPoint(x: x, y: y))
                rowHeight = max(rowHeight, size.height)
                x += size.width + spacing
            }

            self.size = CGSize(width: maxWidth, height: y + rowHeight)
        }
    }
}

#Preview {
    NavigationStack {
        FoodEntryDetailView(entry: FoodEntry(
            text: "Delicious homemade pasta with tomato sauce and fresh basil",
            photoFileName: nil,
            mealType: .dinner
        ))
    }
}
