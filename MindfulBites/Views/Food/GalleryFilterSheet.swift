import SwiftUI
import SwiftData

struct GalleryFilter: Equatable {
    var startDate: Date?
    var endDate: Date?
    var selectedTagIDs: Set<UUID> = []

    var isActive: Bool {
        startDate != nil || endDate != nil || !selectedTagIDs.isEmpty
    }

    mutating func clear() {
        startDate = nil
        endDate = nil
        selectedTagIDs.removeAll()
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

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    Toggle("Filter by date", isOn: $useDateRange)

                    if useDateRange {
                        DatePicker("From", selection: $localStartDate, displayedComponents: .date)
                        DatePicker("To", selection: $localEndDate, displayedComponents: .date)
                    }
                } header: {
                    Text("Date Range")
                }

                Section {
                    if allTags.isEmpty {
                        Text("No tags created yet")
                            .foregroundColor(.secondary)
                    } else {
                        ForEach(allTags) { tag in
                            Button {
                                toggleTag(tag)
                            } label: {
                                HStack {
                                    Text(tag.name)
                                        .foregroundColor(.primary)
                                    Spacer()
                                    if localSelectedTagIDs.contains(tag.id) {
                                        Image(systemName: "checkmark")
                                            .foregroundColor(.accentColor)
                                    }
                                }
                            }
                        }
                    }
                } header: {
                    Text("Tags")
                } footer: {
                    if !allTags.isEmpty {
                        Text("Select tags to filter. Photos with any selected tag will be shown.")
                    }
                }
            }
            .navigationTitle("Filter Gallery")
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
                    .disabled(!useDateRange && localSelectedTagIDs.isEmpty)
                }
            }
            .onAppear {
                loadCurrentFilter()
            }
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
    }

    private func applyFilter() {
        filter.startDate = useDateRange ? localStartDate.startOfDay : nil
        filter.endDate = useDateRange ? Calendar.current.date(byAdding: .day, value: 1, to: localEndDate.startOfDay) : nil
        filter.selectedTagIDs = localSelectedTagIDs
        dismiss()
    }

    private func clearFilters() {
        useDateRange = false
        localSelectedTagIDs.removeAll()
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
