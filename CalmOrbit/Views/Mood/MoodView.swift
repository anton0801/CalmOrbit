//
//  MoodView.swift
//  CalmOrbit
//
//  Mood tracker: quick log, 7-day trend, filterable moments list, plus links
//  to the calendar and a compare panel.
//

import SwiftUI

struct MoodView: View {
    @EnvironmentObject private var store: DataStore
    @Environment(\.palette) private var p

    @State private var quickMood: MoodType?
    @State private var filter: MoodType?
    @State private var showLog = false
    @State private var showCompare = false
    @State private var toast: String?

    private var moments: [MoodEntry] { store.moments(for: filter) }

    var body: some View {
        NavigationView {
            ZStack {
                ScreenBackground()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 16) {
                        ScreenHeader(title: "Mood",
                                     subtitle: "Track how you feel",
                                     trailingSystemImage: "plus",
                                     trailingAction: { showLog = true })

                        quickLogCard
                        trendCard
                        filterChips
                        momentsList
                        Color.clear.frame(height: kTabBarInset)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showLog) {
            LogMoodView(onSaved: { toast = "Mood logged" })
                .environmentObject(store).environment(\.palette, p)
        }
        .sheet(isPresented: $showCompare) {
            MoodCompareView().environmentObject(store).environment(\.palette, p)
        }
        .toast($toast)
    }

    // MARK: Quick log

    private var quickLogCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader("Quick log")
            MoodPicker(selection: $quickMood, compact: true)
            HStack(spacing: 12) {
                Button("Save") {
                    if let mood = quickMood {
                        store.addMood(MoodEntry(date: Date(), mood: mood))
                        Haptics.shared.notify(.success)
                        toast = "Mood logged"
                        withAnimation { quickMood = nil }
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .disabled(quickMood == nil)

                Button {
                    showLog = true
                } label: {
                    Image(systemName: "square.and.pencil")
                        .font(.system(size: 17, weight: .semibold))
                        .foregroundColor(p.accentHi)
                        .frame(width: 54, height: 54)
                        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(p.card))
                        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(p.divider, lineWidth: 1))
                }
                .buttonStyle(PressableStyle())
            }
        }
        .cardStyle()
    }

    // MARK: Trend

    private var trendCard: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack {
                SectionHeader("7-day trend")
                Spacer()
                NavigationLink(destination: CalendarView()) {
                    HStack(spacing: 4) {
                        Image(systemName: "calendar")
                        Text("Calendar")
                    }
                    .font(AppFont.subhead)
                    .foregroundColor(p.accentHi)
                }
            }
            LineChartView(values: store.moodTrend(days: 7), height: 120, yMin: 0, yMax: 5)
            HStack {
                Button {
                    showCompare = true
                } label: {
                    Label("Compare", systemImage: "chart.bar.xaxis")
                        .font(AppFont.subhead)
                        .foregroundColor(p.cyan)
                }
                Spacer()
                Text("Higher = calmer")
                    .font(AppFont.tiny)
                    .foregroundColor(p.textMuted)
            }
        }
        .cardStyle()
    }

    // MARK: Filter

    private var filterChips: some View {
        ScrollView(.horizontal, showsIndicators: false) {
            HStack(spacing: 8) {
                filterChip(title: "All", color: p.accent, active: filter == nil) { filter = nil }
                ForEach(MoodType.allCases) { mood in
                    filterChip(title: mood.title, color: mood.color, active: filter == mood) {
                        filter = (filter == mood) ? nil : mood
                    }
                }
            }
        }
    }

    private func filterChip(title: String, color: Color, active: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.shared.selection()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { action() }
        } label: {
            Text(title)
                .font(AppFont.subhead)
                .foregroundColor(active ? p.onAccent : p.textSecondary)
                .padding(.vertical, 8).padding(.horizontal, 14)
                .background(Capsule().fill(active ? color : p.card))
                .overlay(Capsule().stroke(active ? Color.clear : p.divider, lineWidth: 1))
        }
        .buttonStyle(PressableStyle())
    }

    // MARK: Moments

    private var momentsList: some View {
        VStack(spacing: 12) {
            if moments.isEmpty {
                EmptyStateView(icon: "face.smiling",
                               title: "No moments yet",
                               message: "Log how you feel to build your mood history.")
            } else {
                ForEach(moments) { entry in
                    momentRow(entry)
                }
            }
        }
    }

    private func momentRow(_ entry: MoodEntry) -> some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(entry.mood.color.opacity(0.2)).frame(width: 44, height: 44)
                Text(entry.mood.emoji).font(.system(size: 20))
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(entry.mood.title)
                    .font(AppFont.callout)
                    .foregroundColor(p.textPrimary)
                Text(entry.note.isEmpty ? dateString(entry.date) : entry.note)
                    .font(AppFont.caption)
                    .foregroundColor(p.textSecondary)
                    .lineLimit(1)
            }
            Spacer()
            Menu {
                Button {
                    store.deleteMood(entry)
                    Haptics.shared.notify(.warning)
                    toast = "Removed"
                } label: { Label("Delete", systemImage: "trash") }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 16, weight: .bold))
                    .foregroundColor(p.textMuted)
                    .frame(width: 36, height: 36)
            }
        }
        .cardStyle(padding: 14)
    }

    private func dateString(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "MMM d · HH:mm"
        return f.string(from: date)
    }
}

// MARK: - Compare panel

struct MoodCompareView: View {
    @EnvironmentObject private var store: DataStore
    @Environment(\.palette) private var p

    private var counts: [(MoodType, Int)] {
        MoodType.allCases.map { mood in
            (mood, store.moods.filter { $0.mood == mood }.count)
        }
    }

    private var maxCount: Int { max(counts.map { $0.1 }.max() ?? 1, 1) }

    var body: some View {
        ZStack {
            ScreenBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    ScreenHeader(title: "Compare moods", leading: .close)

                    if store.moods.isEmpty {
                        EmptyStateView(icon: "chart.bar.xaxis",
                                       title: "No data",
                                       message: "Log a few moods to compare them.")
                    } else {
                        VStack(spacing: 14) {
                            ForEach(counts, id: \.0) { mood, count in
                                HStack(spacing: 12) {
                                    Text(mood.emoji).font(.system(size: 22)).frame(width: 30)
                                    Text(mood.title)
                                        .font(AppFont.callout)
                                        .foregroundColor(p.textPrimary)
                                        .frame(width: 80, alignment: .leading)
                                    GeometryReader { geo in
                                        ZStack(alignment: .leading) {
                                            Capsule().fill(p.divider.opacity(0.4))
                                            Capsule().fill(mood.color)
                                                .frame(width: max(geo.size.width * CGFloat(count) / CGFloat(maxCount), count == 0 ? 0 : 12))
                                        }
                                    }
                                    .frame(height: 16)
                                    Text("\(count)")
                                        .font(AppFont.caption)
                                        .foregroundColor(p.textSecondary)
                                        .frame(width: 26, alignment: .trailing)
                                }
                            }
                        }
                        .cardStyle()

                        if let top = counts.max(by: { $0.1 < $1.1 }), top.1 > 0 {
                            HStack(spacing: 10) {
                                Text(top.0.emoji).font(.system(size: 30))
                                VStack(alignment: .leading, spacing: 2) {
                                    Text("Most frequent")
                                        .font(AppFont.caption).foregroundColor(p.textMuted)
                                    Text(top.0.title)
                                        .font(AppFont.headline).foregroundColor(p.textPrimary)
                                }
                                Spacer()
                            }
                            .cardStyle()
                        }
                    }
                    Color.clear.frame(height: 30)
                }
                .padding(.horizontal, 20)
            }
        }
    }
}
