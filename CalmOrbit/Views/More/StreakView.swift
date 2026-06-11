//
//  StreakView.swift
//  CalmOrbit
//
//  Streak overview with a flame hero, current/best stats and a 5-week
//  activity heatmap.
//

import SwiftUI

struct StreakView: View {
    @EnvironmentObject private var store: DataStore
    @Environment(\.palette) private var p
    private let cal = Calendar.current

    var body: some View {
        ZStack {
            ScreenBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    ScreenHeader(title: "Streak", subtitle: "Keep your calm going", leading: .back)

                    heroCard
                    statsRow
                    heatmapCard
                    Color.clear.frame(height: kTabBarInset)
                }
                .padding(.horizontal, 20)
            }
        }
        .navigationBarHidden(true)
    }

    private var heroCard: some View {
        VStack(spacing: 10) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [p.warning.opacity(0.4), p.accent.opacity(0.2)],
                                         startPoint: .top, endPoint: .bottom))
                    .frame(width: 120, height: 120)
                    .blur(radius: 8)
                Image(systemName: "flame.fill")
                    .font(.system(size: 56))
                    .foregroundColor(p.warning)
            }
            Text("\(store.currentStreak)")
                .font(AppFont.rounded(48, .heavy))
                .foregroundColor(p.textPrimary)
            Text(store.currentStreak == 1 ? "day streak" : "day streak")
                .font(AppFont.callout)
                .foregroundColor(p.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .cardStyle()
    }

    private var statsRow: some View {
        HStack(spacing: 14) {
            StatTile(icon: "trophy.fill", title: "Best streak", value: "\(store.bestStreak)", accent: p.warning)
            StatTile(icon: "wind", title: "Total sessions", value: "\(store.totalSessions)", accent: p.cyan)
        }
    }

    private var heatmapCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            SectionHeader("Last 5 weeks")
            let days = lastDays(35)
            let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)
            LazyVGrid(columns: columns, spacing: 6) {
                ForEach(days, id: \.self) { day in
                    let active = store.isStreakDay(day)
                    let minutes = store.minutes(on: day)
                    RoundedRectangle(cornerRadius: 7, style: .continuous)
                        .fill(active ? cellColor(minutes) : p.cardElevated)
                        .frame(height: 30)
                        .overlay(
                            cal.isDateInToday(day)
                                ? RoundedRectangle(cornerRadius: 7).stroke(p.accentHi, lineWidth: 1.5)
                                : nil
                        )
                }
            }
            HStack(spacing: 8) {
                Text("Less").font(AppFont.tiny).foregroundColor(p.textMuted)
                ForEach(0..<4) { i in
                    RoundedRectangle(cornerRadius: 4)
                        .fill(p.success.opacity(0.3 + Double(i) * 0.23))
                        .frame(width: 16, height: 12)
                }
                Text("More").font(AppFont.tiny).foregroundColor(p.textMuted)
                Spacer()
            }
        }
        .cardStyle()
    }

    private func cellColor(_ minutes: Double) -> Color {
        let intensity = min(0.35 + minutes / 20.0, 1.0)
        return p.success.opacity(intensity)
    }

    private func lastDays(_ count: Int) -> [Date] {
        let today = cal.startOfDay(for: Date())
        return (0..<count).reversed().compactMap { offset in
            cal.date(byAdding: .day, value: -offset, to: today)
        }
    }
}
