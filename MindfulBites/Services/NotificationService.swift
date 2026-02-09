import Foundation
import UserNotifications

protocol NotificationServiceProtocol {
    var authorizationStatus: UNAuthorizationStatus { get }
    @MainActor func checkAuthorizationStatus() async
    @MainActor func requestPermission() async -> Bool
    func scheduleWeightReminder(hour: Int, minute: Int) async
    func cancelWeightReminder()
    func syncWithSettings(settings: SettingsServiceProtocol) async
}

@Observable
final class NotificationService: NotificationServiceProtocol {
    static let shared = NotificationService()

    private let center = UNUserNotificationCenter.current()

    private enum Identifier {
        static let weightReminder = "com.mindfulbites.weightReminder"
    }

    private(set) var authorizationStatus: UNAuthorizationStatus = .notDetermined

    private init() {
        Task {
            await checkAuthorizationStatus()
        }
    }

    // MARK: - Authorization

    @MainActor
    func checkAuthorizationStatus() async {
        let settings = await center.notificationSettings()
        authorizationStatus = settings.authorizationStatus
    }

    @MainActor
    func requestPermission() async -> Bool {
        do {
            let granted = try await center.requestAuthorization(options: [.alert, .sound, .badge])
            await checkAuthorizationStatus()
            return granted
        } catch {
            return false
        }
    }

    // MARK: - Weight Reminder

    func scheduleWeightReminder(hour: Int, minute: Int) async {
        center.removePendingNotificationRequests(withIdentifiers: [Identifier.weightReminder])

        let content = UNMutableNotificationContent()
        content.title = "Morning weigh-in"
        content.body = "A great time to log your weight."
        content.sound = .default

        var dateComponents = DateComponents()
        dateComponents.hour = hour
        dateComponents.minute = minute

        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)
        let request = UNNotificationRequest(
            identifier: Identifier.weightReminder,
            content: content,
            trigger: trigger
        )

        try? await center.add(request)
    }

    func cancelWeightReminder() {
        center.removePendingNotificationRequests(withIdentifiers: [Identifier.weightReminder])
    }

    // MARK: - Sync with Settings

    func syncWithSettings(settings: SettingsServiceProtocol = SettingsService.shared) async {
        if settings.weightReminderEnabled {
            await scheduleWeightReminder(hour: settings.weightReminderHour, minute: settings.weightReminderMinute)
        } else {
            cancelWeightReminder()
        }
    }
}
