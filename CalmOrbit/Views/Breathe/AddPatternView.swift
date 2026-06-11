//
//  AddPatternView.swift
//  CalmOrbit
//
//  Create or edit a breathing pattern. Validates input and persists to the
//  DataStore.
//

import SwiftUI

struct AddPatternView: View {
    @EnvironmentObject private var store: DataStore
    @Environment(\.palette) private var p
    @Environment(\.presentationMode) private var presentationMode

    var editing: BreathingPattern?

    @State private var name = ""
    @State private var inhale = 4
    @State private var hold = 4
    @State private var exhale = 4
    @State private var holdAfter = 0
    @State private var cycles = 6
    @State private var accentHex = "8B5CF6"
    @State private var toast: String?

    private let accents = ["8B5CF6", "22D3EE", "A78BFA", "6366F1", "34D399", "67E8F9"]

    private var isValid: Bool {
        !name.trimmingCharacters(in: .whitespaces).isEmpty && inhale >= 1 && exhale >= 1 && cycles >= 1
    }

    private var previewSeconds: Int {
        (inhale + hold + exhale + holdAfter) * cycles
    }

    var body: some View {
        ZStack {
            ScreenBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 16) {
                    ScreenHeader(title: editing == nil ? "New Pattern" : "Edit Pattern",
                                 leading: .close)

                    previewCard

                    AppTextField(title: "Pattern name", placeholder: "e.g. Evening Calm", text: $name)

                    StepperField(title: "Inhale", value: $inhale, range: 1...20, unit: "sec")
                    StepperField(title: "Hold", value: $hold, range: 0...20, unit: "sec")
                    StepperField(title: "Exhale", value: $exhale, range: 1...20, unit: "sec")
                    StepperField(title: "Hold after exhale", value: $holdAfter, range: 0...20, unit: "sec")
                    StepperField(title: "Cycles", value: $cycles, range: 1...30, unit: "cycles")

                    accentPicker

                    Button(editing == nil ? "Save Pattern" : "Update Pattern") {
                        save()
                    }
                    .buttonStyle(PrimaryButtonStyle())
                    .disabled(!isValid)

                    Color.clear.frame(height: 30)
                }
                .padding(.horizontal, 20)
            }
            .onTapGesture { dismissKeyboard() }
        }
        .onAppear(perform: loadIfEditing)
        .toast($toast)
    }

    private var previewCard: some View {
        VStack(spacing: 10) {
            Text("\(inhale)-\(hold)-\(exhale)\(holdAfter > 0 ? "-\(holdAfter)" : "")")
                .font(AppFont.rounded(30, .heavy))
                .foregroundColor(Color(hex: accentHex))
            Text("\(cycles) cycles · ~\(previewSeconds / 60)m \(previewSeconds % 60)s")
                .font(AppFont.caption)
                .foregroundColor(p.textSecondary)
        }
        .frame(maxWidth: .infinity)
        .cardStyle()
    }

    private var accentPicker: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text("Accent")
                .font(AppFont.subhead)
                .foregroundColor(p.textSecondary)
            HStack(spacing: 12) {
                ForEach(accents, id: \.self) { hex in
                    let selected = hex == accentHex
                    Button {
                        Haptics.shared.selection()
                        withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { accentHex = hex }
                    } label: {
                        Circle()
                            .fill(Color(hex: hex))
                            .frame(width: 34, height: 34)
                            .overlay(Circle().stroke(Color.white, lineWidth: selected ? 3 : 0))
                            .scaleEffect(selected ? 1.12 : 1)
                    }
                    .buttonStyle(PressableStyle())
                }
                Spacer()
            }
        }
    }

    private func loadIfEditing() {
        guard let pattern = editing else { return }
        name = pattern.name
        inhale = pattern.inhale
        hold = pattern.hold
        exhale = pattern.exhale
        holdAfter = pattern.holdAfterExhale
        cycles = pattern.cycles
        accentHex = pattern.accentHex
    }

    private func save() {
        guard isValid else { return }
        dismissKeyboard()
        if var pattern = editing {
            pattern.name = name.trimmingCharacters(in: .whitespaces)
            pattern.inhale = inhale
            pattern.hold = hold
            pattern.exhale = exhale
            pattern.holdAfterExhale = holdAfter
            pattern.cycles = cycles
            pattern.accentHex = accentHex
            store.updatePattern(pattern)
        } else {
            let pattern = BreathingPattern(name: name.trimmingCharacters(in: .whitespaces),
                                           inhale: inhale, hold: hold, exhale: exhale,
                                           holdAfterExhale: holdAfter, cycles: cycles,
                                           accentHex: accentHex)
            store.addPattern(pattern)
        }
        Haptics.shared.notify(.success)
        presentationMode.wrappedValue.dismiss()
    }
}
