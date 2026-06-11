//
//  AddProgramView.swift
//  CalmOrbit
//
//  Create or edit a program.
//

import SwiftUI

struct AddProgramView: View {
    @EnvironmentObject private var store: DataStore
    @Environment(\.palette) private var p
    @Environment(\.presentationMode) private var presentationMode

    var editing: Program?

    @State private var name = ""
    @State private var goal: Goal = .calm
    @State private var dailyTarget = 10
    @State private var startDate = Date()
    @State private var notes = ""

    private var isValid: Bool { !name.trimmingCharacters(in: .whitespaces).isEmpty }

    var body: some View {
        ZStack {
            ScreenBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    ScreenHeader(title: editing == nil ? "New Program" : "Edit Program", leading: .close)

                    AppTextField(title: "Program name", placeholder: "e.g. Morning Calm", text: $name)

                    ChipSelector(title: "Goal", items: Goal.allCases, selection: $goal,
                                 label: { $0.title }, icon: { $0.icon })

                    StepperField(title: "Daily target", value: $dailyTarget, range: 1...120, unit: "min")

                    VStack(alignment: .leading, spacing: 8) {
                        Text("Start date")
                            .font(AppFont.subhead)
                            .foregroundColor(p.textSecondary)
                        DatePicker("", selection: $startDate, displayedComponents: .date)
                            .labelsHidden()
                            .datePickerStyle(CompactDatePickerStyle())
                            .accentColor(p.accent)
                            .padding(14)
                            .frame(maxWidth: .infinity, alignment: .leading)
                            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(p.card))
                            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(p.divider, lineWidth: 1))
                    }

                    NotesField(title: "Notes", placeholder: "What is this program for?", text: $notes)

                    Button(editing == nil ? "Save Program" : "Update Program") { save() }
                        .buttonStyle(PrimaryButtonStyle())
                        .disabled(!isValid)

                    Color.clear.frame(height: 30)
                }
                .padding(.horizontal, 20)
            }
            .onTapGesture { dismissKeyboard() }
        }
        .onAppear(perform: loadIfEditing)
    }

    private func loadIfEditing() {
        guard let program = editing else { return }
        name = program.name
        goal = program.goal
        dailyTarget = program.dailyTargetMinutes
        startDate = program.startDate
        notes = program.notes
    }

    private func save() {
        guard isValid else { return }
        dismissKeyboard()
        if var program = editing {
            program.name = name.trimmingCharacters(in: .whitespaces)
            program.goal = goal
            program.dailyTargetMinutes = dailyTarget
            program.startDate = startDate
            program.notes = notes
            store.updateProgram(program)
        } else {
            let program = Program(name: name.trimmingCharacters(in: .whitespaces), goal: goal,
                                  dailyTargetMinutes: dailyTarget, startDate: startDate, notes: notes)
            store.addProgram(program)
        }
        Haptics.shared.notify(.success)
        presentationMode.wrappedValue.dismiss()
    }
}
