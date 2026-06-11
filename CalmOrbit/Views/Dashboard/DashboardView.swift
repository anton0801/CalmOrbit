//
//  DashboardView.swift
//  CalmOrbit
//
//  Today's calm overview: minutes, streak, mood and a suggested session, plus
//  quick actions and a recent-activity preview.
//

import SwiftUI

struct DashboardView: View {
    @EnvironmentObject private var store: DataStore
    @Environment(\.palette) private var p
    @AppStorage("user_display_name") private var name = ""

    let goToTab: (AppTab) -> Void

    @State private var showQuickMood = false
    @State private var toast: String?

    var body: some View {
        NavigationView {
            ZStack {
                ScreenBackground()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 18) {
                        headerRow
                        statsRow
                        moodTodayCard
                        suggestedCard
                        quickActions
                        recentActivity
                        Color.clear.frame(height: kTabBarInset)
                    }
                    .padding(.horizontal, 20)
                    .padding(.top, 6)
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showQuickMood) {
            LogMoodView(onSaved: { toast = "Mood logged" })
                .environmentObject(store)
                .environment(\.palette, p)
        }
        .toast($toast)
    }

    // MARK: Header

    private var headerRow: some View {
        HStack(alignment: .center) {
            VStack(alignment: .leading, spacing: 2) {
                Text(greeting)
                    .font(AppFont.subhead)
                    .foregroundColor(p.textSecondary)
                Text(name.isEmpty ? "Welcome back" : name)
                    .font(AppFont.rounded(28, .bold))
                    .foregroundColor(p.textPrimary)
            }
            Spacer()
            ZStack {
                Circle().fill(p.accent.opacity(0.16)).frame(width: 48, height: 48)
                Image(systemName: "moon.stars.fill")
                    .font(.system(size: 20, weight: .semibold))
                    .foregroundColor(p.accentHi)
            }
        }
        .padding(.top, 6)
    }

    private var greeting: String {
        let hour = Calendar.current.component(.hour, from: Date())
        switch hour {
        case 5..<12:  return "Good morning"
        case 12..<17: return "Good afternoon"
        case 17..<22: return "Good evening"
        default:      return "Time to unwind"
        }
    }

    // MARK: Stats

    private var statsRow: some View {
        HStack(spacing: 14) {
            StatTile(icon: "timer", title: "Today's calm",
                     value: "\(Int(store.todayCalmMinutes)) min",
                     accent: p.cyan)
            StatTile(icon: "flame.fill", title: "Current streak",
                     value: "\(store.currentStreak) days",
                     accent: p.warning,
                     caption: "Best \(store.bestStreak)")
        }
    }

    // MARK: Mood today

    private var moodTodayCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader("Mood today")
            if let entry = store.moodToday {
                HStack(spacing: 14) {
                    Text(entry.mood.emoji).font(.system(size: 38))
                    VStack(alignment: .leading, spacing: 2) {
                        Text(entry.mood.title)
                            .font(AppFont.headline)
                            .foregroundColor(p.textPrimary)
                        Text(timeString(entry.date))
                            .font(AppFont.caption)
                            .foregroundColor(p.textMuted)
                    }
                    Spacer()
                    Button("Update") { showQuickMood = true }
                        .buttonStyle(SoftButtonStyle(fullWidth: false))
                }
            } else {
                HStack(spacing: 14) {
                    Image(systemName: "face.dashed")
                        .font(.system(size: 30))
                        .foregroundColor(p.textMuted)
                    Text("How are you feeling?")
                        .font(AppFont.body)
                        .foregroundColor(p.textSecondary)
                    Spacer()
                    Button("Log") { showQuickMood = true }
                        .buttonStyle(SoftButtonStyle(fullWidth: false))
                }
            }
        }
        .cardStyle()
    }

    // MARK: Suggested session

    private var suggestedCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader("Suggested session")
            if let pattern = store.suggestedPattern {
                HStack(spacing: 14) {
                    ZStack {
                        Circle()
                            .fill(LinearGradient(colors: [p.accentHi, p.cyan],
                                                 startPoint: .topLeading, endPoint: .bottomTrailing))
                            .frame(width: 54, height: 54)
                        Image(systemName: "wind")
                            .font(.system(size: 22, weight: .bold))
                            .foregroundColor(p.onAccent)
                    }
                    VStack(alignment: .leading, spacing: 3) {
                        Text(pattern.name)
                            .font(AppFont.headline)
                            .foregroundColor(p.textPrimary)
                        Text("\(pattern.ratioText) · \(pattern.durationText)")
                            .font(AppFont.caption)
                            .foregroundColor(p.textSecondary)
                    }
                    Spacer()
                }
                Button("Start Breathing") {
                    store.lastPatternID = pattern.id
                    goToTab(.breathe)
                }
                .buttonStyle(PrimaryButtonStyle())
            } else {
                Text("Add a breathing pattern to get started.")
                    .font(AppFont.body)
                    .foregroundColor(p.textSecondary)
            }
        }
        .cardStyle()
    }

    // MARK: Quick actions

    private var quickActions: some View {
        HStack(spacing: 12) {
            quickAction(icon: "wind", title: "Breathe", tint: p.accent) {
                goToTab(.breathe)
            }
            quickAction(icon: "face.smiling", title: "Mood", tint: p.cyan) {
                showQuickMood = true
            }
            NavigationLink(destination: ReportsView()) {
                quickActionLabel(icon: "chart.bar.fill", title: "Report", tint: p.indigoSoft)
            }
            .buttonStyle(PressableStyle())
        }
    }

    private func quickAction(icon: String, title: String, tint: Color, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            quickActionLabel(icon: icon, title: title, tint: tint)
        }
        .buttonStyle(PressableStyle())
    }

    private func quickActionLabel(icon: String, title: String, tint: Color) -> some View {
        VStack(spacing: 8) {
            ZStack {
                Circle().fill(tint.opacity(0.16)).frame(width: 44, height: 44)
                Image(systemName: icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(tint)
            }
            Text(title)
                .font(AppFont.caption)
                .foregroundColor(p.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 18, style: .continuous).fill(p.card))
        .overlay(RoundedRectangle(cornerRadius: 18, style: .continuous).stroke(p.divider, lineWidth: 1))
    }

    // MARK: Recent activity

    private var recentActivity: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader("Recent activity")
            if store.records.isEmpty {
                EmptyStateView(icon: "sparkles",
                               title: "No sessions yet",
                               message: "Start a breathing session to see it here.")
            } else {
                ForEach(store.recordsSorted.prefix(3)) { record in
                    NavigationLink(destination: RecordDetailView(record: record)) {
                        activityRow(record)
                    }
                    .buttonStyle(PressableStyle())
                }
            }
        }
        .cardStyle()
    }

    private func activityRow(_ record: SessionRecord) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(p.accent.opacity(0.15)).frame(width: 40, height: 40)
                Image(systemName: record.category.icon)
                    .font(.system(size: 15, weight: .semibold))
                    .foregroundColor(p.accentHi)
            }
            VStack(alignment: .leading, spacing: 2) {
                Text(record.title)
                    .font(AppFont.callout)
                    .foregroundColor(p.textPrimary)
                    .lineLimit(1)
                Text(dateString(record.date))
                    .font(AppFont.caption)
                    .foregroundColor(p.textMuted)
            }
            Spacer()
            Text(record.minutesText)
                .font(AppFont.caption)
                .foregroundColor(p.cyan)
        }
        .padding(.vertical, 4)
    }

    private func timeString(_ date: Date) -> String {
        let f = DateFormatter(); f.timeStyle = .short
        return f.string(from: date)
    }

    private func dateString(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "MMM d · HH:mm"
        return f.string(from: date)
    }
}
