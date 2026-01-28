import SwiftUI
import SwiftData

struct WeightView: View {
    @Environment(\.modelContext) private var modelContext
    @Query(sort: \WeightEntry.date, order: .reverse) private var allEntries: [WeightEntry]

    @AppStorage("weightUnit") private var weightUnit: WeightUnit = .lbs
    @State private var selectedTimeframe: Timeframe = .oneMonth
    @State private var showingAddSheet = false
    @State private var entryToEdit: WeightEntry?

    private var filteredEntries: [WeightEntry] {
        guard let startDate = selectedTimeframe.startDate else {
            return allEntries
        }
        return allEntries.filter { $0.date >= startDate }
    }

    var body: some View {
        NavigationStack {
            Group {
                if allEntries.isEmpty {
                    ContentUnavailableView(
                        "No Weight Logged Yet",
                        systemImage: "scalemass",
                        description: Text("Tap the + button to log your weight")
                    )
                } else {
                    ScrollView {
                        VStack(spacing: 20) {
                            VStack(spacing: 12) {
                                chartSection
                                trendBadge
                            }
                            entriesSection
                        }
                        .padding()
                    }
                }
            }
            .navigationBarTitleDisplayMode(.inline)
            .toolbar {
                ToolbarItem(placement: .topBarLeading) {
                    timeframeMenu
                }

                ToolbarItem(placement: .topBarTrailing) {
                    Button {
                        showingAddSheet = true
                    } label: {
                        Image(systemName: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddSheet) {
                AddWeightSheet()
            }
            .sheet(item: $entryToEdit) { entry in
                EditWeightSheet(entry: entry)
            }
        }
    }

    // MARK: - Chart Section

    private var chartSection: some View {
        WeightChartView(entries: filteredEntries, weightUnit: weightUnit)
            .padding()
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 16))
            .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
    }

    @ViewBuilder
    private var trendBadge: some View {
        let sortedEntries = filteredEntries.sorted { $0.date < $1.date }

        if sortedEntries.count >= 2,
           let first = sortedEntries.first,
           let last = sortedEntries.last {
            let firstWeight = weightUnit.convert(fromKg: first.weight)
            let lastWeight = weightUnit.convert(fromKg: last.weight)
            let change = lastWeight - firstWeight
            let days = last.date.timeIntervalSince(first.date) / 86400.0

            if days >= 5 {
                // Show weekly rate
                let weeklyRate = change / (days / 7.0)
                WeightTrendBadge(
                    change: weeklyRate,
                    unit: weightUnit,
                    label: "/week"
                )
            } else {
                // Show total change
                let dayCount = Int(days)
                let timeLabel = dayCount == 1 ? "1 day" : "\(dayCount) days"
                WeightTrendBadge(
                    change: change,
                    unit: weightUnit,
                    label: "in \(timeLabel)"
                )
            }
        }
    }

    private var timeframeMenu: some View {
        Menu {
            ForEach(Timeframe.allCases) { timeframe in
                Button {
                    withAnimation(.easeInOut(duration: 0.2)) {
                        selectedTimeframe = timeframe
                    }
                } label: {
                    if selectedTimeframe == timeframe {
                        Label(timeframe.rawValue, systemImage: "checkmark")
                    } else {
                        Text(timeframe.rawValue)
                    }
                }
            }
        } label: {
            HStack(spacing: 4) {
                Text(selectedTimeframe.rawValue)
                    .fontWeight(.medium)
                Image(systemName: "chevron.down")
                    .font(.caption2)
            }
            .foregroundColor(.accentColor)
        }
    }

    // MARK: - Entries Section

    private var entriesSection: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("History")
                .font(.headline)
                .padding(.horizontal, 4)

            LazyVStack(spacing: 0) {
                ForEach(filteredEntries) { entry in
                    Button {
                        entryToEdit = entry
                    } label: {
                        WeightEntryRow(entry: entry, weightUnit: weightUnit)
                    }
                    .buttonStyle(.plain)
                    .contextMenu {
                        Button {
                            entryToEdit = entry
                        } label: {
                            Label("Edit", systemImage: "pencil")
                        }

                        Button(role: .destructive) {
                            deleteEntry(entry)
                        } label: {
                            Label("Delete", systemImage: "trash")
                        }
                    }

                    if entry.id != filteredEntries.last?.id {
                        Divider()
                            .padding(.leading, 16)
                    }
                }
            }
            .background(Color(.systemBackground))
            .clipShape(RoundedRectangle(cornerRadius: 12))
            .shadow(color: .black.opacity(0.05), radius: 8, y: 2)
        }
    }

    private func deleteEntry(_ entry: WeightEntry) {
        modelContext.delete(entry)
    }
}

// MARK: - Weight Entry Row

struct WeightEntryRow: View {
    let entry: WeightEntry
    let weightUnit: WeightUnit

    private var displayWeight: String {
        let converted = weightUnit.convert(fromKg: entry.weight)
        return String(format: "%.1f %@", converted, weightUnit.abbreviation)
    }

    private var changeFromPrevious: Double? {
        // This would require access to the previous entry
        // For now, we'll just show the weight
        nil
    }

    private var formattedDateTime: String {
        let formatter = DateFormatter()
        formatter.dateStyle = .medium
        formatter.timeStyle = .short
        return formatter.string(from: entry.date)
    }

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 4) {
                Text(formattedDateTime)
                    .font(.subheadline)

                if let notes = entry.notes, !notes.isEmpty {
                    Text(notes)
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .lineLimit(1)
                }
            }

            Spacer()

            Text(displayWeight)
                .font(.title3)
                .fontWeight(.medium)
                .monospacedDigit()
        }
        .padding()
        .contentShape(Rectangle())
    }
}

// MARK: - Weight Trend Badge

struct WeightTrendBadge: View {
    let change: Double
    let unit: WeightUnit
    let label: String

    private var direction: String {
        if abs(change) < 0.1 { return "Stable" }
        return change < 0 ? "Down" : "Up"
    }

    private var color: Color {
        if abs(change) < 0.1 { return .secondary }
        return change < 0 ? .green : .orange
    }

    private var icon: String {
        if abs(change) < 0.1 { return "equal" }
        return change < 0 ? "arrow.down.right" : "arrow.up.right"
    }

    var body: some View {
        HStack(spacing: 6) {
            Image(systemName: icon)
                .font(.caption)
                .foregroundColor(color)

            Text("\(direction) \(String(format: "%.1f", abs(change))) \(unit.abbreviation) \(label)")
                .font(.subheadline)
                .foregroundColor(color)
        }
        .padding(.horizontal, 12)
        .padding(.vertical, 6)
        .background(color.opacity(0.1))
        .clipShape(Capsule())
    }
}

#Preview {
    WeightView()
        .modelContainer(for: WeightEntry.self, inMemory: true)
}
