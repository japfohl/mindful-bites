import SwiftUI
import SwiftData

struct TagPicker: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \Tag.name) private var allTags: [Tag]

    @Binding var selectedTags: [Tag]
    @State private var newTagName: String = ""
    @State private var isAddingTag = false

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            if allTags.isEmpty && !isAddingTag {
                Button {
                    isAddingTag = true
                } label: {
                    Label("Add your first tag", systemImage: "plus.circle")
                        .font(.subheadline)
                }
                .frame(maxWidth: .infinity, alignment: .leading)
            } else if !allTags.isEmpty {
                FlowLayout(spacing: 8) {
                    ForEach(allTags) { tag in
                        TagChip(
                            tag: tag,
                            isSelected: selectedTags.contains(where: { $0.id == tag.id }),
                            onTap: { toggleTag(tag) },
                            onDelete: { deleteTag(tag) }
                        )
                    }

                    if !isAddingTag {
                        Button {
                            isAddingTag = true
                        } label: {
                            Image(systemName: "plus.circle.fill")
                                .font(.title3)
                                .foregroundColor(.accentColor)
                        }
                    }
                }
            }

            if isAddingTag {
                HStack {
                    TextField("Tag name", text: $newTagName)
                        .textFieldStyle(.roundedBorder)
                        .submitLabel(.done)
                        .onSubmit(createTag)

                    Button("Add") {
                        createTag()
                    }
                    .disabled(newTagName.trimmingCharacters(in: .whitespaces).isEmpty)

                    Button {
                        isAddingTag = false
                        newTagName = ""
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .foregroundColor(.secondary)
                    }
                }
            }
        }
    }

    private func toggleTag(_ tag: Tag) {
        if let index = selectedTags.firstIndex(where: { $0.id == tag.id }) {
            selectedTags.remove(at: index)
        } else {
            selectedTags.append(tag)
        }
    }

    private func createTag() {
        let trimmedName = newTagName.trimmingCharacters(in: .whitespaces)
        guard !trimmedName.isEmpty else { return }

        // Check for duplicate
        guard !allTags.contains(where: { $0.name.lowercased() == trimmedName.lowercased() }) else {
            newTagName = ""
            isAddingTag = false
            return
        }

        let tag = Tag(name: trimmedName)
        modelContext.insert(tag)
        selectedTags.append(tag)
        newTagName = ""
        isAddingTag = false
    }

    private func deleteTag(_ tag: Tag) {
        selectedTags.removeAll { $0.id == tag.id }
        modelContext.delete(tag)
    }
}

struct TagChip: View {
    let tag: Tag
    let isSelected: Bool
    let onTap: () -> Void
    let onDelete: () -> Void

    @State private var showingDelete = false

    var body: some View {
        Button {
            onTap()
        } label: {
            Text(tag.name)
                .font(.caption)
                .padding(.horizontal, 12)
                .padding(.vertical, 6)
                .background(isSelected ? Color.accentColor : Color(.systemGray5))
                .foregroundColor(isSelected ? .white : .primary)
                .clipShape(Capsule())
        }
        .buttonStyle(.plain)
        .contextMenu {
            Button(role: .destructive) {
                onDelete()
            } label: {
                Label("Delete Tag", systemImage: "trash")
            }
        }
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var selectedTags: [Tag] = []

        var body: some View {
            TagPicker(selectedTags: $selectedTags)
                .padding()
        }
    }

    return PreviewWrapper()
        .modelContainer(for: Tag.self, inMemory: true)
}
