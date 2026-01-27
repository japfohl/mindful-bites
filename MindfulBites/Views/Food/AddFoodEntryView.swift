import SwiftUI
import SwiftData
import PhotosUI

struct AddFoodEntryView: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @State private var selectedImage: UIImage?
    @State private var text: String = ""
    @State private var mealType: MealType?
    @State private var selectedTags: [Tag] = []

    @State private var showingCamera = false
    @State private var showingPhotoPicker = false
    @State private var photosPickerItem: PhotosPickerItem?

    private var canSave: Bool {
        selectedImage != nil || !text.trimmingCharacters(in: .whitespacesAndNewlines).isEmpty
    }

    var body: some View {
        NavigationStack {
            ScrollView {
                VStack(spacing: 24) {
                    photoSection
                    textSection
                    mealTypeSection
                    tagsSection
                }
                .padding()
            }
            .navigationTitle("Add Entry")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveEntry()
                    }
                    .fontWeight(.semibold)
                    .disabled(!canSave)
                }
            }
            .sheet(isPresented: $showingCamera) {
                CameraPicker { image in
                    selectedImage = image
                }
            }
            .onChange(of: photosPickerItem) { _, newValue in
                Task {
                    if let data = try? await newValue?.loadTransferable(type: Data.self),
                       let image = UIImage(data: data) {
                        selectedImage = image
                    }
                }
            }
        }
    }

    // MARK: - Photo Section

    private var photoSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("Photo")
                .font(.headline)

            if let image = selectedImage {
                ZStack(alignment: .topTrailing) {
                    Image(uiImage: image)
                        .resizable()
                        .scaledToFill()
                        .frame(height: 200)
                        .frame(maxWidth: .infinity)
                        .clipShape(RoundedRectangle(cornerRadius: 12))

                    Button {
                        selectedImage = nil
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

    // MARK: - Text Section

    private var textSection: some View {
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

    private func saveEntry() {
        var photoFilename: String?

        if let image = selectedImage {
            photoFilename = PhotoStorageService.shared.savePhoto(image)
        }

        let trimmedText = text.trimmingCharacters(in: .whitespacesAndNewlines)

        let entry = FoodEntry(
            text: trimmedText.isEmpty ? nil : trimmedText,
            photoFileName: photoFilename,
            mealType: mealType,
            tags: selectedTags
        )

        modelContext.insert(entry)
        dismiss()
    }
}

#Preview {
    AddFoodEntryView()
        .modelContainer(for: FoodEntry.self, inMemory: true)
}
