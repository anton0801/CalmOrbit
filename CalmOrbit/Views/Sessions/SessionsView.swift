//
//  SessionsView.swift
//  CalmOrbit
//
//  History of session records plus the programs list. Add, open, filter.
//

import SwiftUI

struct SessionsView: View {
    @EnvironmentObject private var store: DataStore
    @Environment(\.palette) private var p

    enum Segment: String, CaseIterable, Hashable {
        case records, programs
        var title: String { rawValue.capitalized }
    }
    enum RecordFilter: String, CaseIterable, Hashable {
        case all, sessions, notes
        var title: String { rawValue.capitalized }
    }

    @State private var segment: Segment = .records
    @State private var recordFilter: RecordFilter = .all
    @State private var showAddRecord = false
    @State private var showAddProgram = false
    @State private var toast: String?

    private var filteredRecords: [SessionRecord] {
        switch recordFilter {
        case .all:      return store.recordsSorted
        case .sessions: return store.recordsSorted.filter { $0.category == .session }
        case .notes:    return store.recordsSorted.filter { $0.category == .note }
        }
    }

    var body: some View {
        NavigationView {
            ZStack {
                ScreenBackground()
                ScrollView(showsIndicators: false) {
                    VStack(spacing: 14) {
                        ScreenHeader(title: "Sessions",
                                     subtitle: "\(store.totalSessions) sessions · \(Int(store.totalCalmMinutes)) min",
                                     trailingSystemImage: "plus",
                                     trailingAction: addTapped)

                        SegmentedPicker(items: Segment.allCases, selection: $segment) { $0.title }

                        if segment == .records {
                            recordsSection
                        } else {
                            programsSection
                        }
                        Color.clear.frame(height: kTabBarInset)
                    }
                    .padding(.horizontal, 20)
                }
            }
            .navigationBarHidden(true)
        }
        .navigationViewStyle(StackNavigationViewStyle())
        .sheet(isPresented: $showAddRecord) {
            AddRecordView().environmentObject(store).environment(\.palette, p)
        }
        .sheet(isPresented: $showAddProgram) {
            AddProgramView().environmentObject(store).environment(\.palette, p)
        }
        .toast($toast)
    }

    private func addTapped() {
        if segment == .records { showAddRecord = true } else { showAddProgram = true }
    }

    // MARK: Records

    private var recordsSection: some View {
        VStack(spacing: 12) {
            SegmentedPicker(items: RecordFilter.allCases, selection: $recordFilter) { $0.title }

            if filteredRecords.isEmpty {
                EmptyStateView(icon: "list.bullet.rectangle",
                               title: "No records",
                               message: "Your sessions and notes will appear here.")
            } else {
                ForEach(filteredRecords) { record in
                    NavigationLink(destination: RecordDetailView(record: record)) {
                        RecordRow(record: record)
                    }
                    .buttonStyle(PressableStyle())
                }
            }
        }
    }

    // MARK: Programs

    private var programsSection: some View {
        VStack(spacing: 12) {
            if store.programs.isEmpty {
                EmptyStateView(icon: "square.stack.3d.up",
                               title: "No programs",
                               message: "Create a program to group your sessions.")
            } else {
                ForEach(store.programs) { program in
                    ProgramCard(program: program,
                                sessions: store.sessionsCount(for: program),
                                minutes: store.minutes(for: program),
                                onArchive: {
                                    store.toggleArchiveProgram(program)
                                    toast = program.isArchived ? "Restored" : "Archived"
                                },
                                onDelete: {
                                    store.deleteProgram(program)
                                    Haptics.shared.notify(.warning)
                                    toast = "Deleted"
                                })
                }
            }
        }
    }
}

struct RecordRow: View {
    @Environment(\.palette) private var p
    let record: SessionRecord

    var body: some View {
        HStack(spacing: 12) {
            ZStack {
                Circle().fill(p.accent.opacity(0.15)).frame(width: 44, height: 44)
                Image(systemName: record.category.icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(p.accentHi)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(record.title)
                    .font(AppFont.callout)
                    .foregroundColor(p.textPrimary)
                    .lineLimit(1)
                Text(dateString(record.date))
                    .font(AppFont.caption)
                    .foregroundColor(p.textMuted)
            }
            Spacer()
            VStack(alignment: .trailing, spacing: 4) {
                if record.category == .session {
                    Text(record.minutesText)
                        .font(AppFont.caption)
                        .foregroundColor(p.cyan)
                }
                if let mood = record.mood {
                    Text(mood.emoji).font(.system(size: 16))
                }
            }
        }
        .cardStyle(padding: 14)
    }

    private func dateString(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "MMM d · HH:mm"
        return f.string(from: date)
    }
}
