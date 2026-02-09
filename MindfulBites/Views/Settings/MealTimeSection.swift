import SwiftUI

struct MealTimeSection: View {
    var settings: SettingsService = .shared
    @State private var showingResetConfirmation = false

    var body: some View {
        Form {
            Section {
                mealTimeRow(
                    title: "Breakfast",
                    icon: "sunrise",
                    startBinding: Binding(
                        get: { settings.mealTimeRanges.breakfast.startDate },
                        set: { settings.mealTimeRanges.breakfast.startDate = $0 }
                    ),
                    endBinding: Binding(
                        get: { settings.mealTimeRanges.breakfast.endDate },
                        set: { settings.mealTimeRanges.breakfast.endDate = $0 }
                    )
                )
            } header: {
                Text("Breakfast")
            } footer: {
                Text("Food logged during this time will default to Breakfast")
            }

            Section {
                mealTimeRow(
                    title: "Lunch",
                    icon: "sun.max",
                    startBinding: Binding(
                        get: { settings.mealTimeRanges.lunch.startDate },
                        set: { settings.mealTimeRanges.lunch.startDate = $0 }
                    ),
                    endBinding: Binding(
                        get: { settings.mealTimeRanges.lunch.endDate },
                        set: { settings.mealTimeRanges.lunch.endDate = $0 }
                    )
                )
            } header: {
                Text("Lunch")
            }

            Section {
                mealTimeRow(
                    title: "Dinner",
                    icon: "moon",
                    startBinding: Binding(
                        get: { settings.mealTimeRanges.dinner.startDate },
                        set: { settings.mealTimeRanges.dinner.startDate = $0 }
                    ),
                    endBinding: Binding(
                        get: { settings.mealTimeRanges.dinner.endDate },
                        set: { settings.mealTimeRanges.dinner.endDate = $0 }
                    )
                )
            } header: {
                Text("Dinner")
            } footer: {
                Text("Times outside these ranges will default to Snack")
            }

            Section {
                Button("Reset to Defaults") {
                    showingResetConfirmation = true
                }
                .foregroundColor(.red)
            }
        }
        .navigationTitle("Meal Times")
        .navigationBarTitleDisplayMode(.inline)
        .confirmationDialog(
            "Reset Meal Times",
            isPresented: $showingResetConfirmation,
            titleVisibility: .visible
        ) {
            Button("Reset to Defaults", role: .destructive) {
                settings.resetMealTimeRangesToDefaults()
            }
            Button("Cancel", role: .cancel) {}
        } message: {
            Text("This will reset all meal times to their default values.")
        }
    }

    @ViewBuilder
    private func mealTimeRow(
        title: String,
        icon: String,
        startBinding: Binding<Date>,
        endBinding: Binding<Date>
    ) -> some View {
        DatePicker(
            "Start",
            selection: startBinding,
            displayedComponents: .hourAndMinute
        )

        DatePicker(
            "End",
            selection: endBinding,
            displayedComponents: .hourAndMinute
        )
    }
}

#Preview {
    NavigationStack {
        MealTimeSection()
    }
}
