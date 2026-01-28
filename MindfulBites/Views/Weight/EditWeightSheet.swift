import SwiftUI
import SwiftData

struct EditWeightSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @AppStorage("weightUnit") private var weightUnit: WeightUnit = .lbs

    let entry: WeightEntry

    @State private var weightString: String = ""
    @State private var notes: String = ""
    @State private var date: Date = Date()

    private var weightValue: Double? {
        Double(weightString)
    }

    private var canSave: Bool {
        guard let value = weightValue else { return false }
        return value > 0
    }

    var body: some View {
        NavigationStack {
            Form {
                Section {
                    HStack {
                        TextField("Weight", text: $weightString)
                            .keyboardType(.decimalPad)
                            .font(.title2)

                        Text(weightUnit.abbreviation)
                            .foregroundColor(.secondary)
                    }
                } header: {
                    Text("Weight")
                }

                Section {
                    DatePicker("Date & Time", selection: $date)
                } header: {
                    Text("Date & Time")
                }

                Section {
                    TextField("How are you feeling?", text: $notes, axis: .vertical)
                        .lineLimit(2...4)
                } header: {
                    Text("Notes (Optional)")
                }

                Section {
                    Button(role: .destructive) {
                        deleteEntry()
                    } label: {
                        HStack {
                            Spacer()
                            Text("Delete Entry")
                            Spacer()
                        }
                    }
                }
            }
            .navigationTitle("Edit Weight")
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
            .onAppear {
                loadEntryData()
            }
        }
    }

    private func loadEntryData() {
        let displayWeight = weightUnit.convert(fromKg: entry.weight)
        weightString = String(format: "%.1f", displayWeight)
        notes = entry.notes ?? ""
        date = entry.date
    }

    private func saveChanges() {
        guard let value = weightValue else { return }

        let weightInKg = weightUnit.convertToKg(from: value)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)

        entry.weight = weightInKg
        entry.notes = trimmedNotes.isEmpty ? nil : trimmedNotes
        entry.date = date

        dismiss()
    }

    private func deleteEntry() {
        modelContext.delete(entry)
        dismiss()
    }
}

#Preview {
    let entry = WeightEntry(date: Date(), weight: 70.0, notes: "Feeling good")

    return EditWeightSheet(entry: entry)
        .modelContainer(for: WeightEntry.self, inMemory: true)
}
