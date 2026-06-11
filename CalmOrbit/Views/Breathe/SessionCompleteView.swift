//
//  SessionCompleteView.swift
//  CalmOrbit
//
//  Shown after a breathing session. Captures the session as a record with an
//  optional program, mood and note.
//

import SwiftUI

struct SessionCompleteView: View {
    @EnvironmentObject private var store: DataStore
    @Environment(\.palette) private var p
    @Environment(\.presentationMode) private var presentationMode

    let minutes: Double
    let cycles: Int
    let pattern: BreathingPattern?

    @State private var title: String
    @State private var mood: MoodType?
    @State private var comment = ""
    @State private var programID: UUID?

    init(minutes: Double, cycles: Int, pattern: BreathingPattern?) {
        self.minutes = minutes
        self.cycles = cycles
        self.pattern = pattern
        _title = State(initialValue: "\(pattern?.name ?? "Breathing") session")
    }

    private var roundedMinutes: Double { (minutes * 10).rounded() / 10 }

    var body: some View {
        ZStack {
            ScreenBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    ScreenHeader(title: "Session complete", leading: .close)

                    summaryCard

                    AppTextField(title: "Title", placeholder: "Session title", text: $title)

                    VStack(alignment: .leading, spacing: 8) {
                        Text("How do you feel now?")
                            .font(AppFont.subhead)
                            .foregroundColor(p.textSecondary)
                        MoodPicker(selection: $mood, compact: true)
                    }

                    programPicker

                    NotesField(title: "Note", placeholder: "Anything to remember?", text: $comment)

                    Button("Save Session") { save() }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(title.trimmingCharacters(in: .whitespaces).isEmpty)

                    Color.clear.frame(height: 30)
                }
                .padding(.horizontal, 20)
            }
            .onTapGesture { dismissKeyboard() }
        }
    }

    private var summaryCard: some View {
        HStack(spacing: 16) {
            OrbView(scale: 0.95, intensity: 0.9, size: 86)
                .frame(width: 96, height: 96)
            VStack(alignment: .leading, spacing: 6) {
                Text("Nice work")
                    .font(AppFont.headline)
                    .foregroundColor(p.textPrimary)
                Text("\(formattedMinutes) · \(cycles) cycle\(cycles == 1 ? "" : "s")")
                    .font(AppFont.callout)
                    .foregroundColor(p.cyan)
                if let pattern = pattern {
                    Text(pattern.ratioText)
                        .font(AppFont.caption)
                        .foregroundColor(p.textMuted)
                }
            }
            Spacer()
        }
        .cardStyle()
    }

    private var formattedMinutes: String {
        if roundedMinutes < 1 { return "\(Int(minutes * 60))s" }
        return roundedMinutes == roundedMinutes.rounded()
            ? "\(Int(roundedMinutes)) min"
            : String(format: "%.1f min", roundedMinutes)
    }

    private var programPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Program")
                .font(AppFont.subhead)
                .foregroundColor(p.textSecondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    programChip(title: "None", active: programID == nil) { programID = nil }
                    ForEach(store.activePrograms) { program in
                        programChip(title: program.name, active: programID == program.id) {
                            programID = program.id
                        }
                    }
                }
            }
        }
    }

    private func programChip(title: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.shared.selection()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { action() }
        } label: {
            Text(title)
                .font(AppFont.subhead)
                .foregroundColor(active ? p.onAccent : p.textSecondary)
                .padding(.vertical, 9)
                .padding(.horizontal, 14)
                .background(Capsule().fill(active ? p.accent : p.card))
                .overlay(Capsule().stroke(active ? Color.clear : p.divider, lineWidth: 1))
        }
        .buttonStyle(PressableStyle())
    }

    private func save() {
        let record = SessionRecord(title: title.trimmingCharacters(in: .whitespaces),
                                   programID: programID,
                                   date: Date(),
                                   category: .session,
                                   valueMinutes: max(roundedMinutes, 0.1),
                                   comment: comment,
                                   mood: mood,
                                   patternID: pattern?.id)
        store.addRecord(record)
        Haptics.shared.notify(.success)
        presentationMode.wrappedValue.dismiss()
    }
}
