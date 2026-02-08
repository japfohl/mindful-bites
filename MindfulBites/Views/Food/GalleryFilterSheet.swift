import SwiftUI
import SwiftData

struct GalleryFilter: Equatable {
    var startDate: Date?
    var endDate: Date?
    var selectedTagIDs: Set<UUID> = []
    var selectedMealTypes: Set<MealType> = []

    var isActive: Bool {
        startDate != nil || endDate != nil || !selectedTagIDs.isEmpty || !selectedMealTypes.isEmpty
    }

    mutating func clear() {
        startDate = nil
        endDate = nil
        selectedTagIDs.removeAll()
        selectedMealTypes.removeAll()
    }
}

struct GalleryFilterSheet: View {
    @Environment(\.dismiss) private var dismiss
    @Query(sort: \Tag.name) private var allTags: [Tag]

    @Binding var filter: GalleryFilter

    @State private var localStartDate: Date = Calendar.current.date(byAdding: .month, value: -1, to: Date()) ?? Date()
    @State private var localEndDate: Date = Date()
    @State private var useDateRange: Bool = false
    @State private var localSelectedTagIDs: Set<UUID> = []
    @State private var localSelectedMealTypes: Set<MealType> = []
    @State private var showingFromPicker: Bool = false
    @State private var showingToPicker: Bool = false

    private let dateFormatter: DateFormatter = {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .none
        return formatter
    }()

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Filter by date", isOn: $useDateRange)

                    if useDateRange {
                        Button {
                            withAnimation {
                                showingFromPicker.toggle()
                                if showingFromPicker { showingToPicker = false }
                            }
                        } label: {
                            HStack {
                                Text("From")
                                    .foregroundColor(.primary)
                                Spacer()
                                Text(dateFormatter.string(from: localStartDate))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 7)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Capsule())
                                    .foregroundColor(.primary)
                            }
                        }

                        if showingFromPicker {
                            DatePicker("", selection: $localStartDate, in: ...localEndDate, displayedComponents: .date)
                                .datePickerStyle(.graphical)
                                .labelsHidden()
                        }

                        Button {
                            withAnimation {
                                showingToPicker.toggle()
                                if showingToPicker { showingFromPicker = false }
                            }
                        } label: {
                            HStack {
                                Text("To")
                                    .foregroundColor(.primary)
                                Spacer()
                                Text(dateFormatter.string(from: localEndDate))
                                    .padding(.horizontal, 14)
                                    .padding(.vertical, 7)
                                    .background(.ultraThinMaterial)
                                    .clipShape(Capsule())
                                    .foregroundColor(.primary)
                            }
                        }

                        if showingToPicker {
                            DatePicker("", selection: $localEndDate, in: localStartDate..., displayedComponents: .date)
                                .datePickerStyle(.graphical)
                                .labelsHidden()
                        }
                    }
                } header: {
                    Text("Date Range")
                }

                Section {
                    ForEach(MealType.allCases) { mealType in
                        Button {
                            toggleMealType(mealType)
                        } label: {
                            HStack {
                                Image(systemName: mealType.icon)
                                    .frame(width: 24)
                                Text(mealType.displayName)
                                    .foregroundColor(.primary)
                                Spacer()
                                if localSelectedMealTypes.contains(mealType) {
                                    Image(systemName: "checkmark")
                                        .foregroundColor(.accentColor)
                                }
                            }
                        }
                    }
                } header: {
                    Text("Meal Type")
                } footer: {
                    Text("Show only entries of selected meal types")
                }

                Section {
                    if allTags.isEmpty {
                        Text("No tags created yet")
                            .foregroundColor(.secondary)
                    } else {
                        FlowLayout(spacing: 8) {
                            ForEach(allTags) { tag in
                                let isSelected = localSelectedTagIDs.contains(tag.id)
                                Button {
                                    toggleTag(tag)
                                } label: {
                                    Text(tag.name)
                                        .font(.subheadline)
                                        .padding(.horizontal, 12)
                                        .padding(.vertical, 6)
                                        .background(isSelected ? Color.accentColor : Color(.tertiarySystemFill))
                                        .foregroundColor(isSelected ? .white : .primary)
                                        .clipShape(Capsule())
                                }
                                .buttonStyle(.plain)
                            }
                        }
                        .padding(.vertical, 4)
                    }
                } header: {
                    Text("Tags")
                } footer: {
                    if !allTags.isEmpty {
                        Text("Tap to select. Entries with any selected tag will be shown.")
                    }
                }
            }
            .navigationTitle("Filter")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }

                ToolbarItem(placement: .confirmationAction) {
                    Button("Apply") {
                        applyFilter()
                    }
                }

                ToolbarItem(placement: .bottomBar) {
                    Button("Clear Filters") {
                        clearFilters()
                    }
                    .disabled(!useDateRange && localSelectedTagIDs.isEmpty && localSelectedMealTypes.isEmpty)
                }
            }
            .onAppear {
                loadCurrentFilter()
            }
        }
    }

    private func toggleMealType(_ mealType: MealType) {
        if localSelectedMealTypes.contains(mealType) {
            localSelectedMealTypes.remove(mealType)
        } else {
            localSelectedMealTypes.insert(mealType)
        }
    }

    private func toggleTag(_ tag: Tag) {
        if localSelectedTagIDs.contains(tag.id) {
            localSelectedTagIDs.remove(tag.id)
        } else {
            localSelectedTagIDs.insert(tag.id)
        }
    }

    private func loadCurrentFilter() {
        useDateRange = filter.startDate != nil || filter.endDate != nil
        if let start = filter.startDate {
            localStartDate = start
        }
        if let end = filter.endDate {
            localEndDate = end
        }
        localSelectedTagIDs = filter.selectedTagIDs
        localSelectedMealTypes = filter.selectedMealTypes
    }

    private func applyFilter() {
        filter.startDate = useDateRange ? localStartDate.startOfDay : nil
        filter.endDate = useDateRange ? Calendar.current.date(byAdding: .day, value: 1, to: localEndDate.startOfDay) : nil
        filter.selectedTagIDs = localSelectedTagIDs
        filter.selectedMealTypes = localSelectedMealTypes
        dismiss()
    }

    private func clearFilters() {
        useDateRange = false
        localSelectedTagIDs.removeAll()
        localSelectedMealTypes.removeAll()
    }
}

#Preview {
    struct PreviewWrapper: View {
        @State private var filter = GalleryFilter()

        var body: some View {
            GalleryFilterSheet(filter: $filter)
        }
    }

    return PreviewWrapper()
        .modelContainer(for: Tag.self, inMemory: true)
}
