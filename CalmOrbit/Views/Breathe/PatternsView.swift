//
//  PatternsView.swift
//  CalmOrbit
//
//  Manage breathing patterns: filter, add, edit, archive and delete.
//

import SwiftUI

struct PatternsView: View {
    @EnvironmentObject private var store: DataStore
    @Environment(\.palette) private var p

    enum PatternFilter: String, CaseIterable, Hashable {
        case all, active, archived
        var title: String { rawValue.capitalized }
    }

    @State private var filter: PatternFilter = .active
    @State private var showAdd = false
    @State private var editing: BreathingPattern?
    @State private var toast: String?

    private var filtered: [BreathingPattern] {
        switch filter {
        case .all:      return store.patterns
        case .active:   return store.patterns.filter { !$0.isArchived }
        case .archived: return store.patterns.filter { $0.isArchived }
        }
    }

    var body: some View {
        ZStack {
            ScreenBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    ScreenHeader(title: "Patterns",
                                 subtitle: "\(store.activePatterns.count) active",
                                 leading: .back,
                                 trailingSystemImage: "plus",
                                 trailingAction: { showAdd = true })

                    SegmentedPicker(items: PatternFilter.allCases, selection: $filter) { $0.title }

                    if filtered.isEmpty {
                        EmptyStateView(icon: "wind",
                                       title: "No patterns",
                                       message: "Add a breathing pattern to get started.")
                    } else {
                        ForEach(filtered) { pattern in
                            patternCard(pattern)
                        }
                    }
                    Color.clear.frame(height: kTabBarInset)
                }
                .padding(.horizontal, 20)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showAdd) {
            AddPatternView().environmentObject(store).environment(\.palette, p)
        }
        .sheet(item: $editing) { pattern in
            AddPatternView(editing: pattern).environmentObject(store).environment(\.palette, p)
        }
        .toast($toast)
    }

    private func patternCard(_ pattern: BreathingPattern) -> some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(pattern.accent.opacity(0.2)).frame(width: 46, height: 46)
                Image(systemName: "wind")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(pattern.accent)
            }
            VStack(alignment: .leading, spacing: 3) {
                HStack(spacing: 6) {
                    Text(pattern.name)
                        .font(AppFont.headline)
                        .foregroundColor(p.textPrimary)
                    if pattern.isArchived {
                        Text("Archived")
                            .font(AppFont.tiny)
                            .foregroundColor(p.textMuted)
                            .padding(.horizontal, 6).padding(.vertical, 2)
                            .background(Capsule().fill(p.cardElevated))
                    }
                }
                Text("\(pattern.ratioText) · \(pattern.cycles) cycles · \(pattern.durationText)")
                    .font(AppFont.caption)
                    .foregroundColor(p.textSecondary)
            }
            Spacer()
            Menu {
                Button { editing = pattern } label: { Label("Edit", systemImage: "pencil") }
                Button {
                    store.toggleArchivePattern(pattern)
                    toast = pattern.isArchived ? "Restored" : "Archived"
                } label: {
                    Label(pattern.isArchived ? "Unarchive" : "Archive",
                          systemImage: pattern.isArchived ? "tray.and.arrow.up" : "archivebox")
                }
                Button {
                    store.deletePattern(pattern)
                    Haptics.shared.notify(.warning)
                    toast = "Deleted"
                } label: { Label("Delete", systemImage: "trash") }
            } label: {
                Image(systemName: "ellipsis")
                    .font(.system(size: 18, weight: .bold))
                    .foregroundColor(p.textMuted)
                    .frame(width: 40, height: 40)
            }
        }
        .cardStyle(padding: 14)
    }
}
