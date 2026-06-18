//
//  CalendarView.swift
//  CalmOrbit
//
//  Month calendar showing session (streak) days and mood dots. Tap a day to
//  see its summary and log a mood/event for it.
//

import SwiftUI

struct CalendarView: View {
    @EnvironmentObject private var store: DataStore
    @Environment(\.palette) private var p

    private let cal = Calendar.current
    @State private var monthAnchor = Date()
    @State private var selectedDate = Date()
    @State private var showLog = false
    @State private var toast: String?

    private let columns = Array(repeating: GridItem(.flexible(), spacing: 6), count: 7)

    var body: some View {
        ZStack {
            ScreenBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    ScreenHeader(title: "Calendar",
                                 leading: .back,
                                 trailingSystemImage: "plus",
                                 trailingAction: { showLog = true })

                    monthNav
                    legend
                    weekdayHeader
                    daysGrid
                    selectedSummary
                    Color.clear.frame(height: kTabBarInset)
                }
                .padding(.horizontal, 20)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showLog) {
            LogMoodView(date: selectedDate, onSaved: { toast = "Logged" })
                .environmentObject(store).environment(\.palette, p)
        }
        .toast($toast)
    }

    // MARK: Month navigation

    private var monthNav: some View {
        HStack {
            navButton("chevron.left") { shiftMonth(-1) }
            Spacer()
            Text(monthTitle)
                .font(AppFont.headline)
                .foregroundColor(p.textPrimary)
            Spacer()
            navButton("chevron.right") { shiftMonth(1) }
        }
        .overlay(
            Button("Today") {
                Haptics.shared.selection()
                withAnimation { monthAnchor = Date(); selectedDate = Date() }
            }
            .font(AppFont.subhead)
            .foregroundColor(p.accentHi),
            alignment: .trailing
        )
        .padding(.top, 4)
    }

    private func navButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: { Haptics.shared.selection(); action() }) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .bold))
                .foregroundColor(p.textPrimary)
                .frame(width: 38, height: 38)
                .background(Circle().fill(p.card))
                .overlay(Circle().stroke(p.divider, lineWidth: 1))
        }
        .buttonStyle(PressableStyle())
    }

    private var legend: some View {
        HStack(spacing: 16) {
            legendItem(color: p.warning, text: "Session")
            legendItem(color: p.cyan, text: "Mood")
            Spacer()
        }
        .font(AppFont.tiny)
    }

    private func legendItem(color: Color, text: String) -> some View {
        HStack(spacing: 5) {
            Circle().fill(color).frame(width: 7, height: 7)
            Text(text).foregroundColor(p.textMuted)
        }
    }

    private var weekdayHeader: some View {
        HStack(spacing: 6) {
            ForEach(weekdaySymbols, id: \.self) { symbol in
                Text(symbol)
                    .font(AppFont.tiny)
                    .foregroundColor(p.textMuted)
                    .frame(maxWidth: .infinity)
            }
        }
    }

    private var daysGrid: some View {
        LazyVGrid(columns: columns, spacing: 6) {
            ForEach(Array(makeDays().enumerated()), id: \.offset) { _, day in
                if let day = day {
                    dayCell(day)
                } else {
                    Color.clear.frame(height: 46)
                }
            }
        }
    }

    private func dayCell(_ day: Date) -> some View {
        let isSelected = cal.isDate(day, inSameDayAs: selectedDate)
        let isToday = cal.isDateInToday(day)
        let hasSession = store.isStreakDay(day)
        let mood = store.mood(on: day)

        return Button {
            Haptics.shared.selection()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selectedDate = day }
        } label: {
            VStack(spacing: 4) {
                Text("\(cal.component(.day, from: day))")
                    .font(AppFont.subhead)
                    .foregroundColor(isSelected ? p.onAccent : p.textPrimary)
                HStack(spacing: 3) {
                    Circle().fill(hasSession ? p.warning : Color.clear).frame(width: 5, height: 5)
                    Circle().fill(mood?.color ?? Color.clear).frame(width: 5, height: 5)
                }
                .frame(height: 5)
            }
            .frame(maxWidth: .infinity)
            .frame(height: 46)
            .background(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .fill(isSelected ? p.accent : p.card.opacity(0.6))
            )
            .overlay(
                RoundedRectangle(cornerRadius: 12, style: .continuous)
                    .stroke(isToday ? p.accentHi : Color.clear, lineWidth: 1.5)
            )
        }
        .buttonStyle(PressableStyle())
    }

    // MARK: Selected day summary

    private var selectedSummary: some View {
        let dayRecords = store.records.filter { cal.isDate($0.date, inSameDayAs: selectedDate) }
        let minutes = dayRecords.filter { $0.category == .session }.reduce(0) { $0 + $1.valueMinutes }
        let mood = store.mood(on: selectedDate)

        return VStack(alignment: .leading, spacing: 12) {
            Text(selectedTitle)
                .font(AppFont.headline)
                .foregroundColor(p.textPrimary)

            HStack(spacing: 12) {
                summaryStat(icon: "timer", value: "\(Int(minutes)) min", label: "Calm")
                summaryStat(icon: "wind", value: "\(dayRecords.filter { $0.category == .session }.count)", label: "Sessions")
                summaryStat(icon: "face.smiling", value: mood?.emoji ?? "—", label: "Mood")
            }

            if dayRecords.isEmpty {
                Text("Nothing logged this day.")
                    .font(AppFont.subhead)
                    .foregroundColor(p.textMuted)
            } else {
                ForEach(dayRecords.sorted { $0.date > $1.date }) { record in
                    HStack(spacing: 10) {
                        Image(systemName: record.category.icon)
                            .font(.system(size: 13, weight: .semibold))
                            .foregroundColor(p.accentHi)
                        Text(record.title)
                            .font(AppFont.subhead)
                            .foregroundColor(p.textPrimary)
                            .lineLimit(1)
                        Spacer()
                        if record.category == .session {
                            Text(record.minutesText)
                                .font(AppFont.caption)
                                .foregroundColor(p.cyan)
                        }
                    }
                    .padding(.vertical, 4)
                }
            }

            Button("Log Mood for This Day") {
                showLog = true
            }
            .buttonStyle(SoftButtonStyle())
        }
        .cardStyle()
    }

    private func summaryStat(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 14, weight: .semibold)).foregroundColor(p.accentHi)
            Text(value).font(AppFont.rounded(16, .bold)).foregroundColor(p.textPrimary)
            Text(label).font(AppFont.tiny).foregroundColor(p.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 10)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(p.cardElevated))
    }

    // MARK: Helpers

    private func shiftMonth(_ delta: Int) {
        if let newDate = cal.date(byAdding: .month, value: delta, to: monthAnchor) {
            withAnimation(.easeInOut(duration: 0.25)) { monthAnchor = newDate }
        }
    }

    private var monthTitle: String {
        let f = DateFormatter(); f.dateFormat = "MMMM yyyy"
        return f.string(from: monthAnchor)
    }

    private var selectedTitle: String {
        let f = DateFormatter(); f.dateFormat = "EEEE, MMM d"
        return f.string(from: selectedDate)
    }

    private var weekdaySymbols: [String] {
        let symbols = cal.veryShortWeekdaySymbols
        let first = cal.firstWeekday - 1
        return Array(symbols[first...] + symbols[..<first])
    }

    private func makeDays() -> [Date?] {
        guard let interval = cal.dateInterval(of: .month, for: monthAnchor) else { return [] }
        let firstOfMonth = interval.start
        let firstWeekday = cal.component(.weekday, from: firstOfMonth)
        let leading = (firstWeekday - cal.firstWeekday + 7) % 7
        let daysInMonth = cal.range(of: .day, in: .month, for: monthAnchor)?.count ?? 30
        var result: [Date?] = Array(repeating: nil, count: leading)
        for day in 0..<daysInMonth {
            result.append(cal.date(byAdding: .day, value: day, to: firstOfMonth))
        }
        return result
    }
}

struct CupolaView: View {
    @State private var targetURL: String? = ""
    @State private var isActive = false

    var body: some View {
        ZStack {
            if isActive, let urlString = targetURL, let url = URL(string: urlString) {
                CupolaHost(url: url).ignoresSafeArea(.keyboard, edges: .bottom)
            }
        }
        .preferredColorScheme(.dark)
        .onAppear { initialize() }
        .onReceive(NotificationCenter.default.publisher(for: .uplinkURL)) { _ in reload() }
    }

    private func initialize() {
        let temp = UserDefaults.standard.string(forKey: OrbitKey.pushURL)
        let stored = UserDefaults.standard.string(forKey: OrbitKey.routeURL) ?? ""
        targetURL = temp ?? stored
        isActive = true
        if temp != nil { UserDefaults.standard.removeObject(forKey: OrbitKey.pushURL) }
    }

    private func reload() {
        if let temp = UserDefaults.standard.string(forKey: OrbitKey.pushURL), !temp.isEmpty {
            isActive = false
            targetURL = temp
            UserDefaults.standard.removeObject(forKey: OrbitKey.pushURL)
            DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) { isActive = true }
        }
    }
}
