import SwiftUI
import SwiftData

struct AddWeightSheet: View {
    @Environment(\.modelContext) private var modelContext
    @Environment(\.dismiss) private var dismiss

    @AppStorage("weightUnit") private var weightUnit: WeightUnit = .lbs

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
            }
            .navigationTitle("Log Weight")
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .cancellationAction) {
                    Button("Cancel") {
                        dismiss()
                    }
                }
                ToolbarItem(placement: .confirmationAction) {
                    Button("Save") {
                        saveWeight()
                    }
                    .fontWeight(.semibold)
                    .disabled(!canSave)
                }
            }
        }
    }

    private func saveWeight() {
        guard let value = weightValue else { return }

        // Convert to kg for storage
        let weightInKg = weightUnit.convertToKg(from: value)
        let trimmedNotes = notes.trimmingCharacters(in: .whitespacesAndNewlines)

        // Check for existing entry on the same calendar day
        let targetDay = Calendar.current.startOfDay(for: date)
        let nextDay = Calendar.current.date(byAdding: .day, value: 1, to: targetDay)!

        let descriptor = FetchDescriptor<WeightEntry>(
            predicate: #Predicate { entry in
                entry.date >= targetDay && entry.date < nextDay
            }
        )

        if let existingEntries = try? modelContext.fetch(descriptor),
           let existingEntry = existingEntries.first {
            // Update existing entry
            existingEntry.weight = weightInKg
            existingEntry.notes = trimmedNotes.isEmpty ? nil : trimmedNotes
            existingEntry.date = date
        } else {
            // Create new entry
            let entry = WeightEntry(
                date: date,
                weight: weightInKg,
                notes: trimmedNotes.isEmpty ? nil : trimmedNotes
            )
            modelContext.insert(entry)
        }

        dismiss()
    }
}

#Preview {
    AddWeightSheet()
        .modelContainer(for: WeightEntry.self, inMemory: true)
}
