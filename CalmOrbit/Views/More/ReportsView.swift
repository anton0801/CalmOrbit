//
//  ReportsView.swift
//  CalmOrbit
//
//  Analytics: minutes by day, mood trend and sessions by program, with PDF
//  and data export.
//

import SwiftUI

struct ReportsView: View {
    @EnvironmentObject private var store: DataStore
    @Environment(\.palette) private var p
    @StateObject private var vm = ReportsViewModel()
    @State private var toast: String?

    private var rangeMinutes: [DayValue] { store.minutesByDay(days: vm.range.days) }
    private var rangeMood: [DayValue] { store.moodTrend(days: vm.range.days) }

    private var totalRangeMinutes: Int {
        Int(rangeMinutes.reduce(0) { $0 + $1.value })
    }
    private var rangeSessions: Int {
        let cutoff = Calendar.current.date(byAdding: .day, value: -vm.range.days, to: Date()) ?? Date()
        return store.records.filter { $0.category == .session && $0.date >= cutoff }.count
    }
    private var avgMood: String {
        let scored = rangeMood.filter { $0.value > 0 }
        guard !scored.isEmpty else { return "—" }
        let avg = scored.reduce(0) { $0 + $1.value } / Double(scored.count)
        return String(format: "%.1f", avg)
    }

    var body: some View {
        ZStack {
            ScreenBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    ScreenHeader(title: "Reports", subtitle: "Your calm, visualized", leading: .back)

                    SegmentedPicker(items: ReportRange.allCases, selection: $vm.range) { $0.title }

                    statsRow
                    minutesCard
                    moodCard
                    programsCard
                    exportButtons
                    Color.clear.frame(height: kTabBarInset)
                }
                .padding(.horizontal, 20)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $vm.isSharing) {
            ShareSheet(items: [vm.shareURL].compactMap { $0 })
        }
        .toast($toast)
    }

    private var statsRow: some View {
        HStack(spacing: 12) {
            miniStat(value: "\(totalRangeMinutes)", label: "Minutes", tint: p.cyan)
            miniStat(value: "\(rangeSessions)", label: "Sessions", tint: p.accentHi)
            miniStat(value: avgMood, label: "Avg mood", tint: p.success)
        }
    }

    private func miniStat(value: String, label: String, tint: Color) -> some View {
        VStack(spacing: 4) {
            Text(value).font(AppFont.rounded(22, .bold)).foregroundColor(tint)
            Text(label).font(AppFont.tiny).foregroundColor(p.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 14)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(p.card))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(p.divider, lineWidth: 1))
    }

    private var minutesCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader("Minutes by day")
            BarChartView(values: rangeMinutes, height: 150, accent: p.accent)
        }
        .cardStyle()
        .id("minutes-\(vm.range.rawValue)")
    }

    private var moodCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader("Mood trend")
            LineChartView(values: rangeMood, height: 150, accent: p.accentHi, yMin: 0, yMax: 5)
        }
        .cardStyle()
        .id("mood-\(vm.range.rawValue)")
    }

    private var programsCard: some View {
        VStack(alignment: .leading, spacing: 14) {
            SectionHeader("Sessions by program")
            let data = store.sessionsByProgram()
            if data.isEmpty {
                Text("No programs yet.")
                    .font(AppFont.subhead)
                    .foregroundColor(p.textMuted)
            } else {
                let maxCount = max(data.map { $0.count }.max() ?? 1, 1)
                VStack(spacing: 12) {
                    ForEach(data) { item in
                        HStack(spacing: 10) {
                            Text(item.program.name)
                                .font(AppFont.caption)
                                .foregroundColor(p.textSecondary)
                                .frame(width: 86, alignment: .leading)
                                .lineLimit(1)
                            GeometryReader { geo in
                                ZStack(alignment: .leading) {
                                    Capsule().fill(p.divider.opacity(0.4))
                                    Capsule().fill(item.program.goal.color)
                                        .frame(width: barWidth(item.count, maxCount, geo.size.width))
                                }
                            }
                            .frame(height: 16)
                            Text("\(item.count)")
                                .font(AppFont.caption)
                                .foregroundColor(p.textPrimary)
                                .frame(width: 24, alignment: .trailing)
                        }
                    }
                }
            }
        }
        .cardStyle()
    }

    private func barWidth(_ count: Int, _ maxCount: Int, _ width: CGFloat) -> CGFloat {
        guard count > 0 else { return 0 }
        return max(width * CGFloat(count) / CGFloat(maxCount), 14)
    }

    private var exportButtons: some View {
        HStack(spacing: 12) {
            Button {
                vm.exportPDF(store: store)
                toast = "PDF ready"
            } label: { Label("Export PDF", systemImage: "doc.richtext") }
                .buttonStyle(SecondaryButtonStyle())

            Button {
                vm.shareData(store: store)
                toast = "Sharing data"
            } label: { Label("Share", systemImage: "square.and.arrow.up") }
                .buttonStyle(SecondaryButtonStyle())
        }
    }
}
