import UserNotifications

@MainActor
final class NotificationManager {
    static let shared = NotificationManager()
    private var lastNotified: [String: Date] = [:]

    func requestPermission() async -> Bool {
        let center = UNUserNotificationCenter.current()
        let settings = await center.notificationSettings()
        if settings.authorizationStatus == .authorized { return true }
        return (try? await center.requestAuthorization(options: [.alert, .sound])) ?? false
    }

    func scheduleIfNeeded(for detection: Detection) {
        let now = Date()
        if let last = lastNotified[detection.speciesId],
           now.timeIntervalSince(last) < 86_400 { return }
        lastNotified[detection.speciesId] = now
        schedule(title: detection.commonName, body: "Detected at your station just now.")
    }

    private func schedule(title: String, body: String) {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body  = body
        content.sound = .default
        let request = UNNotificationRequest(
            identifier: UUID().uuidString,
            content: content,
            trigger: nil
        )
        UNUserNotificationCenter.current().add(request)
    }
}
