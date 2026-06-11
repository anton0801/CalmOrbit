//
//  ProgramsView.swift
//  CalmOrbit
//
//  Standalone programs list (used from the More hub) plus the shared
//  ProgramCard component.
//

import SwiftUI

struct ProgramsView: View {
    @EnvironmentObject private var store: DataStore
    @Environment(\.palette) private var p

    @State private var showAdd = false
    @State private var toast: String?

    var body: some View {
        ZStack {
            ScreenBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 14) {
                    ScreenHeader(title: "Programs",
                                 subtitle: "\(store.activePrograms.count) active",
                                 leading: .back,
                                 trailingSystemImage: "plus",
                                 trailingAction: { showAdd = true })

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
                    Color.clear.frame(height: kTabBarInset)
                }
                .padding(.horizontal, 20)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showAdd) {
            AddProgramView().environmentObject(store).environment(\.palette, p)
        }
        .toast($toast)
    }
}

struct ProgramCard: View {
    @Environment(\.palette) private var p
    let program: Program
    let sessions: Int
    let minutes: Double
    var onArchive: () -> Void
    var onDelete: () -> Void

    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            HStack(spacing: 12) {
                ZStack {
                    Circle().fill(program.goal.color.opacity(0.2)).frame(width: 46, height: 46)
                    Image(systemName: program.goal.icon)
                        .font(.system(size: 18, weight: .semibold))
                        .foregroundColor(program.goal.color)
                }
                VStack(alignment: .leading, spacing: 3) {
                    Text(program.name)
                        .font(AppFont.headline)
                        .foregroundColor(p.textPrimary)
                        .lineLimit(1)
                    Text(program.goal.title)
                        .font(AppFont.caption)
                        .foregroundColor(program.goal.color)
                }
                Spacer()
                Menu {
                    Button(action: onArchive) {
                        Label(program.isArchived ? "Unarchive" : "Archive",
                              systemImage: program.isArchived ? "tray.and.arrow.up" : "archivebox")
                    }
                    Button(action: onDelete) { Label("Delete", systemImage: "trash") }
                } label: {
                    Image(systemName: "ellipsis")
                        .font(.system(size: 18, weight: .bold))
                        .foregroundColor(p.textMuted)
                        .frame(width: 36, height: 36)
                }
            }

            HStack(spacing: 10) {
                statChip(icon: "wind", text: "\(sessions) sessions")
                statChip(icon: "timer", text: "\(Int(minutes)) min")
                statChip(icon: "target", text: "\(program.dailyTargetMinutes)m/day")
                Spacer()
                if program.isArchived {
                    Text("Archived")
                        .font(AppFont.tiny)
                        .foregroundColor(p.textMuted)
                        .padding(.horizontal, 8).padding(.vertical, 3)
                        .background(Capsule().fill(p.cardElevated))
                }
            }

            if !program.notes.isEmpty {
                Text(program.notes)
                    .font(AppFont.caption)
                    .foregroundColor(p.textSecondary)
                    .lineLimit(2)
            }
        }
        .cardStyle()
    }

    private func statChip(icon: String, text: String) -> some View {
        HStack(spacing: 4) {
            Image(systemName: icon).font(.system(size: 11, weight: .semibold))
            Text(text).font(AppFont.tiny)
        }
        .foregroundColor(p.textSecondary)
        .padding(.horizontal, 9).padding(.vertical, 6)
        .background(Capsule().fill(p.cardElevated))
    }
}
