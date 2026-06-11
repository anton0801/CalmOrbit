//
//  RecordDetailView.swift
//  CalmOrbit
//
//  Detail for a single record with Edit / Duplicate / Create Task / Delete.
//

import SwiftUI

struct RecordDetailView: View {
    @EnvironmentObject private var store: DataStore
    @Environment(\.palette) private var p
    @Environment(\.presentationMode) private var presentationMode

    let record: SessionRecord

    @State private var showEdit = false
    @State private var toast: String?

    /// Always read the latest version from the store so edits reflect live.
    private var current: SessionRecord { store.record(record.id) ?? record }

    var body: some View {
        ZStack {
            ScreenBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    ScreenHeader(title: "Record", leading: .back)

                    heroCard

                    detailRows

                    if !current.comment.isEmpty {
                        VStack(alignment: .leading, spacing: 8) {
                            Text("Note")
                                .font(AppFont.subhead)
                                .foregroundColor(p.textSecondary)
                            Text(current.comment)
                                .font(AppFont.body)
                                .foregroundColor(p.textPrimary)
                                .frame(maxWidth: .infinity, alignment: .leading)
                        }
                        .cardStyle()
                    }

                    actionButtons

                    Color.clear.frame(height: kTabBarInset)
                }
                .padding(.horizontal, 20)
            }
        }
        .navigationBarHidden(true)
        .sheet(isPresented: $showEdit) {
            AddRecordView(editing: current).environmentObject(store).environment(\.palette, p)
        }
        .toast($toast)
    }

    private var heroCard: some View {
        VStack(spacing: 12) {
            ZStack {
                Circle()
                    .fill(LinearGradient(colors: [p.accentHi, p.cyan],
                                         startPoint: .topLeading, endPoint: .bottomTrailing))
                    .frame(width: 70, height: 70)
                Image(systemName: current.category.icon)
                    .font(.system(size: 28, weight: .bold))
                    .foregroundColor(p.onAccent)
            }
            Text(current.title)
                .font(AppFont.title)
                .foregroundColor(p.textPrimary)
                .multilineTextAlignment(.center)
            if current.category == .session {
                Text(current.minutesText)
                    .font(AppFont.headline)
                    .foregroundColor(p.cyan)
            }
        }
        .frame(maxWidth: .infinity)
        .cardStyle()
    }

    private var detailRows: some View {
        VStack(spacing: 0) {
            detailRow("Category", current.category.title, "tag")
            divider
            detailRow("Date", dateString(current.date), "calendar")
            if let program = store.program(current.programID) {
                divider
                detailRow("Program", program.name, "square.stack.3d.up")
            }
            if let mood = current.mood {
                divider
                detailRow("Mood", "\(mood.emoji)  \(mood.title)", "face.smiling")
            }
            if let pattern = store.pattern(current.patternID) {
                divider
                detailRow("Pattern", pattern.ratioText, "wind")
            }
        }
        .cardStyle(padding: 4)
    }

    private var divider: some View {
        Rectangle().fill(p.divider).frame(height: 1).padding(.horizontal, 14)
    }

    private func detailRow(_ label: String, _ value: String, _ icon: String) -> some View {
        HStack(spacing: 12) {
            Image(systemName: icon)
                .font(.system(size: 15, weight: .semibold))
                .foregroundColor(p.accentHi)
                .frame(width: 24)
            Text(label)
                .font(AppFont.callout)
                .foregroundColor(p.textSecondary)
            Spacer()
            Text(value)
                .font(AppFont.callout)
                .foregroundColor(p.textPrimary)
                .lineLimit(1)
        }
        .padding(.vertical, 14)
        .padding(.horizontal, 12)
    }

    private var actionButtons: some View {
        VStack(spacing: 12) {
            HStack(spacing: 12) {
                Button { showEdit = true } label: { Label("Edit", systemImage: "pencil") }
                    .buttonStyle(SecondaryButtonStyle())
                Button {
                    store.duplicate(current)
                    Haptics.shared.impact(.light)
                    toast = "Duplicated"
                } label: { Label("Duplicate", systemImage: "plus.square.on.square") }
                    .buttonStyle(SecondaryButtonStyle())
            }
            Button {
                let due = Calendar.current.date(byAdding: .day, value: 1, to: Date()) ?? Date()
                store.addTask(HabitTask(title: current.title, detail: "From a saved session",
                                        dueDate: due, repeatsDaily: false))
                Haptics.shared.notify(.success)
                toast = "Task created"
            } label: { Label("Create Task", systemImage: "checklist") }
                .buttonStyle(SoftButtonStyle())

            Button {
                store.deleteRecord(current)
                Haptics.shared.notify(.warning)
                presentationMode.wrappedValue.dismiss()
            } label: {
                Label("Delete", systemImage: "trash")
                    .font(AppFont.callout)
                    .foregroundColor(p.danger)
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 12)
            }
        }
    }

    private func dateString(_ date: Date) -> String {
        let f = DateFormatter(); f.dateFormat = "EEE, MMM d · HH:mm"
        return f.string(from: date)
    }
}
