import SwiftUI
import SwiftData
import PhotosUI

struct EditFoodEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    let entry: FoodEntry

    @State private var title: String = ""
    @State private var text: String = ""
    @State private var mealType: MealType = .snack
    @State private var selectedTags: [Tag] = []

    @State private var selectedImage: UIImage?
    @State private var existingPhotoFilename: String?
    @State private var photoWasDeleted = false

    @State private var showingCamera = false
    @State private var photosPickerItem: PhotosPickerItem?

    private var canSave: Bool {
        (selectedImage != nil || existingPhotoFilename != nil && !photoWasDeleted) ||
        !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    titleSection
                    photoSection
                    descriptionSection
                    mealTypeSection
                    tagsSection
                }
                .padding()
            }
            .navigationTitle("Edit Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveChanges()
                    }
                    .fontWeight(.semibold)
                    .disabled(!canSave)
                }
            }
            .sheet(isPresented: $showingCamera) {
                CameraPicker { image in
                    selectedImage = image
                    photoWasDeleted = false
                }
            }
            .onChange(of: photosPickerItem) { _, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        selectedImage = image
                        photoWasDeleted = false
                    }
                }
            }
            .task {
                loadEntryData()
            }
        }
    }

    private func loadEntryData() {
        title = entry.title
        text = entry.text ?? ""
        mealType = entry.mealType ?? .snack
        selectedTags = entry.tags
        existingPhotoFilename = entry.photoFileName

        // Load existing photo
        if let filename = entry.photoFileName {
            selectedImage = PhotoStorageService.shared.loadPhoto(filename: filename)
        }
    }

    // MARK: - Title Section

    private var titleSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Title")
                .font(.headline)

            TextField("e.g., Lunch with Mom", text: $title)
                .textFieldStyle(.plain)
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Photo Section

    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Photo")
                .font(.headline)

            if let image = selectedImage, !photoWasDeleted {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    Button {
                        selectedImage = nil
                        photoWasDeleted = true
                        photosPickerItem = nil
                    } label: {
                        Image(systemName: "xmark.circle.fill")
                            .font(.title2)
                            .foregroundStyle(.white, .black.opacity(0.6))
                    }
                    .padding(8)
                }
            } else {
                HStack(spacing: 16) {
                    if CameraPicker.isAvailable {
                        Button {
                            showingCamera = true
                        } label: {
                            photoButtonLabel(icon: "camera", title: "Camera")
                        }
                    }

                    PhotosPicker(selection: $photosPickerItem, matching: .images) {
                        photoButtonLabel(icon: "photo.on.rectangle", title: "Photos")
                    }
                }
            }
        }
    }

    private func photoButtonLabel(icon: String, title: String) -> some View {
        VStack(spacing: 8) {
            Image(systemName: icon)
                .font(.title)
            Text(title)
                .font(.subheadline)
        }
        .frame(maxWidth: .infinity)
        .frame(height: 100)
        .background(Color(.systemGray6))
        .clipShape(RoundedRectangle(cornerRadius: 12))
        .foregroundColor(.accentColor)
    }

    // MARK: - Description Section

    private var descriptionSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Description")
                .font(.headline)

            TextField("What did you have?", text: $text, axis: .vertical)
                .lineLimit(3...6)
                .textFieldStyle(.plain)
                .padding()
                .background(Color(.systemGray6))
                .clipShape(RoundedRectangle(cornerRadius: 12))
        }
    }

    // MARK: - Meal Type Section

    private var mealTypeSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Meal Type")
                .font(.headline)

            MealTypePicker(selection: $mealType)
        }
    }

    // MARK: - Tags Section

    private var tagsSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Tags")
                .font(.headline)

            TagPicker(selectedTags: $selectedTags)
        }
    }

    // MARK: - Save

    private func saveChanges() {
        // Handle photo changes
        if photoWasDeleted {
            // Delete old photo file
            if let oldFilename = existingPhotoFilename {
                PhotoStorageService.shared.deletePhoto(filename: oldFilename)
                Task { await ThumbnailCache.shared.removeThumbnail(for: oldFilename) }
            }
            entry.photoFileName = nil
        } else if let newImage = selectedImage, existingPhotoFilename == nil || photoWasDeleted {
            // New photo was selected (either replacing or adding new)
            if let oldFilename = existingPhotoFilename {
                PhotoStorageService.shared.deletePhoto(filename: oldFilename)
                Task { await ThumbnailCache.shared.removeThumbnail(for: oldFilename) }
            }
            entry.photoFileName = PhotoStorageService.shared.savePhoto(newImage)
        }

        // Update other fields
        let trimmedTitle = title.trimmingCharacters(in: .whitespacesAndNewlines)
        entry.title = trimmedTitle.isEmpty ? FoodEntry.defaultTitle(for: entry.createdAt) : trimmedTitle

        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)
        entry.text = trimmedText.isEmpty ? nil : trimmedText

        entry.mealType = mealType
        entry.tags = selectedTags

        dismiss()
    }
}

#Preview {
    let entry = FoodEntry(
        title: "Test Entry",
        text: "Some food description",
        mealType: .lunch
    )

    return EditFoodEntryView(entry: entry)
        .modelContainer(for: [FoodEntry.self, Tag.self], inMemory: true)
}
