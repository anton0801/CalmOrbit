//
//  MoreView.swift
//  CalmOrbit
//
//  Hub that links to the remaining sections: sounds, reports, streak, tasks,
//  recommendations, programs, patterns, notifications and settings.
//

import SwiftUI

struct MoreView: View {
    @EnvironmentObject private var store: DataStore
    @Environment(\.palette) private var p

    var body: some View {
        NavigationView {
            ZStack {
                ScreenBackground()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        ScreenHeader(title: "More", subtitle: "Tools & settings")

                        summaryCard

                        sectionTitle("Practice")
                        row(icon: "speaker.wave.2.fill", title: "Sounds",
                            subtitle: "Ambient calm soundscapes", tint: p.cyan) { SoundsView() }
                        row(icon: "lightbulb.fill", title: "Recommendations",
                            subtitle: "\(store.activeRecommendations.count) tips for you", tint: p.warning) { RecommendationsView() }
                        row(icon: "wind", title: "Patterns",
                            subtitle: "\(store.activePatterns.count) breathing patterns", tint: p.accent) { PatternsView() }
                        row(icon: "square.stack.3d.up.fill", title: "Programs",
                            subtitle: "\(store.activePrograms.count) active programs", tint: p.indigoSoft) { ProgramsView() }

                        sectionTitle("Insights")
                        row(icon: "chart.bar.fill", title: "Reports",
                            subtitle: "Minutes, mood & sessions", tint: p.accentHi) { ReportsView() }
                        row(icon: "flame.fill", title: "Streak",
                            subtitle: "Current \(store.currentStreak) · best \(store.bestStreak)", tint: p.warning) { StreakView() }
                        row(icon: "checklist", title: "Tasks",
                            subtitle: "Reminders & habits", tint: p.success) { TasksView() }

                        sectionTitle("App")
                        row(icon: "bell.fill", title: "Notifications",
                            subtitle: "Breathing & mood reminders", tint: p.cyan) { NotificationsView() }
                        row(icon: "gearshape.fill", title: "Settings",
                            subtitle: "Theme, sound, haptics, data", tint: p.indigoSoft) { SettingsView() }

                        Color.clear.frame(height: kTabBarInset)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
    }

    private var summaryCard: some View {
        HStack(spacing: 16) {
            OrbView(scale: 0.95, intensity: 0.8, size: 70).frame(width: 80, height: 80)
            VStack(alignment: .leading, spacing: 4) {
                Text("Calm Orbit +")
                    .font(AppFont.headline)
                    .foregroundColor(p.textPrimary)
                Text("\(Int(store.totalCalmMinutes)) calm minutes · \(store.totalSessions) sessions")
                    .font(AppFont.caption)
                    .foregroundColor(p.textSecondary)
            }
            Spacer()
        }
        .cardStyle()
    }

    private func sectionTitle(_ text: String) -> some View {
        HStack {
            Text(text)
                .font(AppFont.subhead)
                .foregroundColor(p.textMuted)
            Spacer()
        }
        .padding(.top, 6)
        .padding(.horizontal, 4)
    }

    private func row<Destination: View>(icon: String, title: String, subtitle: String,
                                        tint: Color, @ViewBuilder destination: () -> Destination) -> some View {
        NavigationLink(destination: destination()) {
            HStack(spacing: 14) {
                ZStack {
                    Circle().fill(tint.opacity(0.16)).frame(width: 44, height: 44)
                    Image(systemName: icon)
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(tint)
                }
                VStack(alignment: .leading, spacing: 2) {
                    Text(title)
                        .font(AppFont.callout)
                        .foregroundColor(p.textPrimary)
                    Text(subtitle)
                        .font(AppFont.caption)
                        .foregroundColor(p.textSecondary)
                        .lineLimit(1)
                }
                Spacer()
                Image(systemName: "chevron.right")
                    .font(.system(size: 13, weight: .semibold))
                    .foregroundColor(p.textMuted)
            }
            .cardStyle(padding: 14)
        }
        .buttonStyle(PressableStyle())
    }
}
