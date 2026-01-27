import SwiftUI

struct SettingsView: View {
    @AppStorage("weightUnit") private var weightUnit: String = WeightUnit.kg.rawValue
    @AppStorage("foodReminderEnabled") private var foodReminderEnabled = false
    @AppStorage("weightReminderEnabled") private var weightReminderEnabled = false

    var body: some View {
        NavigationStack {
            Form {
                Section("Units") {
                    Picker("Weight Unit", selection: $weightUnit) {
                        ForEach(WeightUnit.allCases) { unit in
                            Text(unit.displayName).tag(unit.rawValue)
                        }
                    }
                }

                Section("Reminders") {
                    Toggle("Food Logging Reminder", isOn: $foodReminderEnabled)
                    Toggle("Weight Logging Reminder", isOn: $weightReminderEnabled)
                }

                Section("About") {
                    LabeledContent("Version", value: "1.0.0")
                }
            }
            .navigationTitle("Settings")
        }
    }
}

#Preview {
    SettingsView()
}
