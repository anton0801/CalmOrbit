//
//  NotificationsView.swift
//  CalmOrbit
//
//  Schedule breathing reminders, mood checks and a weekly summary via
//  UNUserNotificationCenter.
//

import SwiftUI

struct NotificationsView: View {
    @Environment(\.palette) private var p
    @ObservedObject private var notif = NotificationManager.shared

    @AppStorage("notif_breathing_on") private var breathingOn = false
    @AppStorage("notif_breathing_hour") private var breathingHour = 8
    @AppStorage("notif_breathing_min") private var breathingMin = 0

    @AppStorage("notif_mood_on") private var moodOn = false
    @AppStorage("notif_mood_hour") private var moodHour = 20
    @AppStorage("notif_mood_min") private var moodMin = 0

    @AppStorage("notif_weekly_on") private var weeklyOn = false
    @AppStorage("notif_weekly_weekday") private var weeklyWeekday = 2
    @AppStorage("notif_weekly_hour") private var weeklyHour = 9
    @AppStorage("notif_weekly_min") private var weeklyMin = 0

    @State private var toast: String?

    private let weekdays = ["Sun", "Mon", "Tue", "Wed", "Thu", "Fri", "Sat"]

    var body: some View {
        ZStack {
            ScreenBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    ScreenHeader(title: "Notifications", subtitle: "Gentle nudges", leading: .back)

                    authCard

                    reminderCard(title: "Breathing reminder",
                                 subtitle: "A nudge to take a calm break",
                                 icon: "wind",
                                 isOn: $breathingOn,
                                 time: timeBinding($breathingHour, $breathingMin))

                    reminderCard(title: "Mood check",
                                 subtitle: "Log how your day felt",
                                 icon: "face.smiling",
                                 isOn: $moodOn,
                                 time: timeBinding($moodHour, $moodMin))

                    weeklyCard

                    Button("Save Notifications") { save() }
                        .buttonStyle(PrimaryButtonStyle())

                    Color.clear.frame(height: kTabBarInset)
                }
                .padding(.horizontal, 20)
            }
        }
        .navigationBarHidden(true)
        .onAppear { notif.refreshStatus() }
        .toast($toast)
    }

    private var authCard: some View {
        HStack(spacing: 12) {
            Image(systemName: notif.isAuthorized ? "checkmark.seal.fill" : "exclamationmark.triangle.fill")
                .font(.system(size: 22))
                .foregroundColor(notif.isAuthorized ? p.success : p.warning)
            VStack(alignment: .leading, spacing: 2) {
                Text(notif.isAuthorized ? "Notifications enabled" : "Notifications off")
                    .font(AppFont.callout)
                    .foregroundColor(p.textPrimary)
                Text(notif.isAuthorized ? "You're all set." : "Tap allow to enable reminders.")
                    .font(AppFont.caption)
                    .foregroundColor(p.textSecondary)
            }
            Spacer()
            if !notif.isAuthorized {
                Button("Allow") {
                    notif.requestAuthorization { granted in
                        toast = granted ? "Enabled" : "Denied in Settings"
                    }
                }
                .buttonStyle(SoftButtonStyle(fullWidth: false))
            }
        }
        .cardStyle()
    }

    private func reminderCard(title: String, subtitle: String, icon: String,
                              isOn: Binding<Bool>, time: Binding<Date>) -> some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(p.accent.opacity(0.16)).frame(width: 42, height: 42)
                    Image(systemName: icon).foregroundColor(p.accentHi)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title).font(AppFont.callout).foregroundColor(p.textPrimary)
                    Text(subtitle).font(AppFont.caption).foregroundColor(p.textSecondary)
                }
                Spacer()
                Toggle("", isOn: isOn).labelsHidden().toggleStyle(SwitchToggleStyle(tint: p.accent))
            }
            if isOn.wrappedValue {
                HStack {
                    Text("Time").font(AppFont.subhead).foregroundColor(p.textSecondary)
                    Spacer()
                    DatePicker("", selection: time, displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .accentColor(p.accent)
                }
            }
        }
        .cardStyle()
    }

    private var weeklyCard: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(p.cyan.opacity(0.16)).frame(width: 42, height: 42)
                    Image(systemName: "calendar.badge.clock").foregroundColor(p.cyan)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text("Weekly calm summary").font(AppFont.callout).foregroundColor(p.textPrimary)
                    Text("A recap of your week").font(AppFont.caption).foregroundColor(p.textSecondary)
                }
                Spacer()
                Toggle("", isOn: $weeklyOn).labelsHidden().toggleStyle(SwitchToggleStyle(tint: p.accent))
            }
            if weeklyOn {
                HStack {
                    Text("Day").font(AppFont.subhead).foregroundColor(p.textSecondary)
                    Spacer()
                    Menu {
                        ForEach(0..<7) { i in
                            Button(fullWeekday(i)) { weeklyWeekday = i + 1 }
                        }
                    } label: {
                        HStack(spacing: 6) {
                            Text(weekdays[max(0, min(6, weeklyWeekday - 1))])
                            Image(systemName: "chevron.down").font(.system(size: 11))
                        }
                        .font(AppFont.subhead)
                        .foregroundColor(p.accentHi)
                    }
                }
                HStack {
                    Text("Time").font(AppFont.subhead).foregroundColor(p.textSecondary)
                    Spacer()
                    DatePicker("", selection: timeBinding($weeklyHour, $weeklyMin), displayedComponents: .hourAndMinute)
                        .labelsHidden()
                        .accentColor(p.accent)
                }
            }
        }
        .cardStyle()
    }

    // MARK: Helpers

    private func timeBinding(_ hour: Binding<Int>, _ minute: Binding<Int>) -> Binding<Date> {
        Binding(
            get: { NotificationManager.date(hour: hour.wrappedValue, minute: minute.wrappedValue) },
            set: {
                let hm = NotificationManager.hourMinute(from: $0)
                hour.wrappedValue = hm.0
                minute.wrappedValue = hm.1
            }
        )
    }

    private func fullWeekday(_ index: Int) -> String {
        DateFormatter().weekdaySymbols[index]
    }

    private func save() {
        notif.requestAuthorization { granted in
            guard granted else {
                toast = "Enable notifications in Settings"
                return
            }
            applySchedule()
            toast = "Notifications saved"
        }
    }

    private func applySchedule() {
        if breathingOn {
            notif.scheduleDaily(id: NotificationManager.ID.breathing,
                                title: "Time to breathe",
                                body: "Take a calm moment with Calm Orbit +.",
                                hour: breathingHour, minute: breathingMin)
        } else {
            notif.cancel(id: NotificationManager.ID.breathing)
        }

        if moodOn {
            notif.scheduleDaily(id: NotificationManager.ID.mood,
                                title: "How do you feel?",
                                body: "Log your mood in Calm Orbit +.",
                                hour: moodHour, minute: moodMin)
        } else {
            notif.cancel(id: NotificationManager.ID.mood)
        }

        if weeklyOn {
            notif.scheduleWeekly(id: NotificationManager.ID.weekly,
                                 title: "Your weekly calm summary",
                                 body: "See how your week of breathing went.",
                                 weekday: weeklyWeekday, hour: weeklyHour, minute: weeklyMin)
        } else {
            notif.cancel(id: NotificationManager.ID.weekly)
        }
        Haptics.shared.notify(.success)
    }
}
