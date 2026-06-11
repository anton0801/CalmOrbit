//
//  NotificationManager.swift
//  CalmOrbit
//
//  Thin wrapper over UNUserNotificationCenter for scheduling and cancelling
//  the app's reminders. Publishes the current authorization state.
//

import Foundation
import UserNotifications

final class NotificationManager: ObservableObject {
    static let shared = NotificationManager()
    private init() {}

    @Published var isAuthorized: Bool = false

    enum ID {
        static let breathing = "reminder-breathing"
        static let mood = "reminder-mood"
        static let weekly = "reminder-weekly"
    }

    func refreshStatus() {
        UNUserNotificationCenter.current().getNotificationSettings { settings in
            DispatchQueue.main.async {
                self.isAuthorized = settings.authorizationStatus == .authorized
                    || settings.authorizationStatus == .provisional
            }
        }
    }

    func requestAuthorization(_ completion: ((Bool) -> Void)? = nil) {
        UNUserNotificationCenter.current()
            .requestAuthorization(options: [.alert, .sound, .badge]) { granted, _ in
                DispatchQueue.main.async {
                    self.isAuthorized = granted
                    completion?(granted)
                }
            }
    }

    // MARK: Scheduling

    func scheduleDaily(id: String, title: String, body: String, hour: Int, minute: Int) {
        cancel(id: id)
        let content = makeContent(title: title, body: body)
        var comps = DateComponents()
        comps.hour = hour
        comps.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        add(id: id, content: content, trigger: trigger)
    }

    func scheduleWeekly(id: String, title: String, body: String, weekday: Int, hour: Int, minute: Int) {
        cancel(id: id)
        let content = makeContent(title: title, body: body)
        var comps = DateComponents()
        comps.weekday = weekday
        comps.hour = hour
        comps.minute = minute
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: true)
        add(id: id, content: content, trigger: trigger)
    }

    /// One-off reminder at a specific date (used for tasks).
    func scheduleAt(id: String, title: String, body: String, date: Date) {
        cancel(id: id)
        guard date > Date() else { return }
        let content = makeContent(title: title, body: body)
        let comps = Calendar.current.dateComponents([.year, .month, .day, .hour, .minute], from: date)
        let trigger = UNCalendarNotificationTrigger(dateMatching: comps, repeats: false)
        add(id: id, content: content, trigger: trigger)
    }

    func cancel(id: String) {
        UNUserNotificationCenter.current().removePendingNotificationRequests(withIdentifiers: [id])
    }

    func cancelAll() {
        UNUserNotificationCenter.current().removeAllPendingNotificationRequests()
    }

    // MARK: Helpers

    private func makeContent(title: String, body: String) -> UNMutableNotificationContent {
        let content = UNMutableNotificationContent()
        content.title = title
        content.body = body
        content.sound = .default
        return content
    }

    private func add(id: String, content: UNNotificationContent, trigger: UNNotificationTrigger) {
        let request = UNNotificationRequest(identifier: id, content: content, trigger: trigger)
        UNUserNotificationCenter.current().add(request, withCompletionHandler: nil)
    }

    static func hourMinute(from date: Date) -> (Int, Int) {
        let c = Calendar.current.dateComponents([.hour, .minute], from: date)
        return (c.hour ?? 9, c.minute ?? 0)
    }

    static func date(hour: Int, minute: Int) -> Date {
        Calendar.current.date(bySettingHour: hour, minute: minute, second: 0, of: Date()) ?? Date()
    }
}
