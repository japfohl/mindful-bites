import SwiftUI

struct SettingsView: View {
    var settings: SettingsService
    var notifications: NotificationService

    @State private var weightUnit: WeightUnit
    @State private var weightReminderEnabled: Bool
    @State private var weightReminderTime: Date
    @State private var showingPermissionAlert = false

    init(settings: SettingsService = .shared, notifications: NotificationService = .shared) {
        self.settings = settings
        self.notifications = notifications
        _weightUnit = State(initialValue: settings.weightUnit)
        _weightReminderEnabled = State(initialValue: settings.weightReminderEnabled)
        _weightReminderTime = State(initialValue: settings.weightReminderTime)
    }

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
                        settings.weightUnit = newValue
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
                            settings.weightReminderTime = newValue
                            Task {
                                await notifications.syncWithSettings()
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
                settings.weightReminderEnabled = true
                await notifications.syncWithSettings()
            } else {
                // Permission denied - revert the toggle
                weightReminderEnabled = false
                showingPermissionAlert = true
            }
        } else {
            settings.weightReminderEnabled = false
            notifications.cancelWeightReminder()
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
