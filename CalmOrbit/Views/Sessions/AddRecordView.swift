//
//  AddRecordView.swift
//  CalmOrbit
//
//  Create or edit a session/note record. Supports "Save" and "Add Another".
//

import SwiftUI

struct AddRecordView: View {
    @EnvironmentObject private var store: DataStore
    @Environment(\.palette) private var p
    @Environment(\.presentationMode) private var presentationMode

    var editing: SessionRecord?

    @State private var title = ""
    @State private var programID: UUID?
    @State private var date = Date()
    @State private var category: RecordCategory = .session
    @State private var minutes = 5
    @State private var comment = ""
    @State private var mood: MoodType?
    @State private var toast: String?

    private var isValid: Bool { !title.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        ZStack {
            ScreenBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    ScreenHeader(title: editing == nil ? "Add Record" : "Edit Record", leading: .close)

                    AppTextField(title: "Title", placeholder: "Session title", text: $title)

                    ChipSelector(title: "Category", items: RecordCategory.allCases,
                                 selection: $category, label: { $0.title }, icon: { $0.icon })

                    if category == .session {
                        StepperField(title: "Minutes", value: $minutes, range: 0...180, unit: "min")
                    }

                    programPicker

                    datePickerCard

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Mood")
                            .font(AppFont.subhead)
                            .foregroundColor(p.textSecondary)
                        MoodPicker(selection: $mood, compact: true)
                    }

                    NotesField(title: "Comment", placeholder: "Optional comment", text: $comment)

                    Button(editing == nil ? "Save" : "Update") { save(dismiss: true) }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(!isValid)

                    if editing == nil {
                        Button("Save & Add Another") { save(dismiss: false) }
                            .buttonStyle(SecondaryButtonStyle())
                            .disabled(!isValid)
                    }

                    Color.clear.frame(height: 30)
                }
                .padding(.horizontal, 20)
            }
            .onTapGesture { dismissKeyboard() }
        }
        .onAppear(perform: loadIfEditing)
        .toast($toast)
    }

    private var programPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Program")
                .font(AppFont.subhead)
                .foregroundColor(p.textSecondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    chip(title: "None", active: programID == nil) { programID = nil }
                    ForEach(store.activePrograms) { program in
                        chip(title: program.name, active: programID == program.id) { programID = program.id }
                    }
                }
            }
        }
    }

    private func chip(title: String, active: Bool, action: @escaping () -> Void) -> some View {
        Button {
            Haptics.shared.selection()
            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { action() }
        } label: {
            Text(title)
                .font(AppFont.subhead)
                .foregroundColor(active ? p.onAccent : p.textSecondary)
                .padding(.vertical, 9).padding(.horizontal, 14)
                .background(Capsule().fill(active ? p.accent : p.card))
                .overlay(Capsule().stroke(active ? Color.clear : p.divider, lineWidth: 1))
        }
        .buttonStyle(PressableStyle())
    }

    private var datePickerCard: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Date")
                .font(AppFont.subhead)
                .foregroundColor(p.textSecondary)
            DatePicker("", selection: $date)
                .labelsHidden()
                .datePickerStyle(CompactDatePickerStyle())
                .accentColor(p.accent)
                .padding(14)
                .frame(maxWidth: .infinity, alignment: .leading)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(p.card))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(p.divider, lineWidth: 1))
        }
    }

    private func loadIfEditing() {
        guard let record = editing else { return }
        title = record.title
        programID = record.programID
        date = record.date
        category = record.category
        minutes = Int(record.valueMinutes.rounded())
        comment = record.comment
        mood = record.mood
    }

    private func save(dismiss: Bool) {
        guard isValid else { return }
        dismissKeyboard()
        let value = category == .session ? Double(minutes) : 0
        if var record = editing {
            record.title = title.trimmingCharacters(in: .whitespaces)
            record.programID = programID
            record.date = date
            record.category = category
            record.valueMinutes = value
            record.comment = comment
            record.mood = mood
            store.updateRecord(record)
            Haptics.shared.notify(.success)
            presentationMode.wrappedValue.dismiss()
            return
        }

        let record = SessionRecord(title: title.trimmingCharacters(in: .whitespaces),
                                   programID: programID, date: date, category: category,
                                   valueMinutes: value, comment: comment, mood: mood)
        store.addRecord(record)
        Haptics.shared.notify(.success)

        if dismiss {
            presentationMode.wrappedValue.dismiss()
        } else {
            toast = "Saved"
            title = ""
            comment = ""
            minutes = 5
            mood = nil
            date = Date()
        }
    }
}
