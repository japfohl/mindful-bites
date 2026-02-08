import SwiftUI

struct SettingsView: View {
    @State private var weightUnit: WeightUnit = SettingsService.shared.weightUnit
    @State private var weightReminderEnabled: Bool = SettingsService.shared.weightReminderEnabled
    @State private var weightReminderTime: Date = SettingsService.shared.weightReminderTime
    @State private var showingPermissionAlert = false

    private var notifications: NotificationService { NotificationService.shared }

    var body: some View {
        NavigationStack {
            Form {
                Section("Units") {
                    Picker("Weight Unit", selection: $weightUnit) {
                        ForEach(WeightUnit.allCases) { unit in
                            Text(unit.displayName).tag(unit)
                        }
                    }
                    .onChange(of: weightUnit) { _, newValue in
                        SettingsService.shared.weightUnit = newValue
                    }
                }

                Section {
                    Toggle("Weight Logging Reminder", isOn: $weightReminderEnabled)
                        .onChange(of: weightReminderEnabled) { _, newValue in
                            Task {
                                await handleWeightReminderToggle(newValue)
                            }
                        }

                    if weightReminderEnabled {
                        DatePicker(
                            "Reminder Time",
                            selection: $weightReminderTime,
                            displayedComponents: .hourAndMinute
                        )
                        .onChange(of: weightReminderTime) { _, newValue in
                            SettingsService.shared.weightReminderTime = newValue
                            Task {
                                await NotificationService.shared.syncWithSettings()
                            }
                        }
                    }
                } header: {
                    Text("Reminders")
                } footer: {
                    Text("Get a daily reminder for your morning weigh-in")
                }

                Section("Meal Times") {
                    NavigationLink {
                        MealTimeSection()
                    } label: {
                        Label("Customize Meal Times", systemImage: "clock")
                    }
                }

                CloudBackupSection()

                Section("About") {
                    LabeledContent("Version", value: "1.0.0")
                }
            }
            .navigationTitle("Settings")
            .alert("Notifications Disabled", isPresented: $showingPermissionAlert) {
                Button("Open Settings") {
                    if let url = URL(string: UIApplication.openSettingsURLString) {
                        UIApplication.shared.open(url)
                    }
                }
                Button("Cancel", role: .cancel) {}
            } message: {
                Text("Please enable notifications in Settings to receive reminders.")
            }
        }
    }

    private func handleWeightReminderToggle(_ enabled: Bool) async {
        if enabled {
            let granted = await requestNotificationPermissionIfNeeded()
            if granted {
                SettingsService.shared.weightReminderEnabled = true
                await NotificationService.shared.syncWithSettings()
            } else {
                // Permission denied - revert the toggle
                weightReminderEnabled = false
                showingPermissionAlert = true
            }
        } else {
            SettingsService.shared.weightReminderEnabled = false
            NotificationService.shared.cancelWeightReminder()
        }
    }

    @MainActor
    private func requestNotificationPermissionIfNeeded() async -> Bool {
        await notifications.checkAuthorizationStatus()

        switch notifications.authorizationStatus {
        case .authorized, .provisional:
            return true
        case .notDetermined:
            return await notifications.requestPermission()
        case .denied, .ephemeral:
            return false
        @unknown default:
            return false
        }
    }
}

#Preview {
    SettingsView()
}
