//
//  FormControls.swift
//  CalmOrbit
//
//  Themed form inputs used across the add/edit screens. iOS 14 friendly
//  (no FocusState) — keyboard is dismissed with a tap helper.
//

import SwiftUI
import UIKit

func dismissKeyboard() {
    UIApplication.shared.sendAction(#selector(UIResponder.resignFirstResponder),
                                    to: nil, from: nil, for: nil)
}

struct AppTextField: View {
    @Environment(\.palette) private var p
    let title: String
    var placeholder: String = ""
    @Binding var text: String
    var keyboard: UIKeyboardType = .default

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppFont.subhead)
                .foregroundColor(p.textSecondary)
            TextField(placeholder, text: $text)
                .font(AppFont.body)
                .foregroundColor(p.textPrimary)
                .keyboardType(keyboard)
                .padding(14)
                .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(p.card))
                .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(p.divider, lineWidth: 1))
        }
    }
}

struct NotesField: View {
    @Environment(\.palette) private var p
    let title: String
    var placeholder: String = "Add a note…"
    @Binding var text: String

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppFont.subhead)
                .foregroundColor(p.textSecondary)
            ZStack(alignment: .topLeading) {
                if text.isEmpty {
                    Text(placeholder)
                        .font(AppFont.body)
                        .foregroundColor(p.textMuted)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 18)
                }
                TextEditor(text: $text)
                    .font(AppFont.body)
                    .foregroundColor(p.textPrimary)
                    .frame(minHeight: 92)
                    .padding(8)
            }
            .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(p.card))
            .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(p.divider, lineWidth: 1))
        }
    }
}

struct StepperField: View {
    @Environment(\.palette) private var p
    let title: String
    @Binding var value: Int
    var range: ClosedRange<Int> = 0...120
    var step: Int = 1
    var unit: String = ""

    var body: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppFont.subhead)
                    .foregroundColor(p.textSecondary)
                Text(unit.isEmpty ? "\(value)" : "\(value) \(unit)")
                    .font(AppFont.rounded(18, .semibold))
                    .foregroundColor(p.textPrimary)
            }
            Spacer()
            HStack(spacing: 14) {
                stepButton("minus") {
                    if value - step >= range.lowerBound { value -= step; Haptics.shared.selection() }
                }
                Text("\(value)")
                    .font(AppFont.rounded(18, .bold))
                    .foregroundColor(p.textPrimary)
                    .frame(minWidth: 34)
                stepButton("plus") {
                    if value + step <= range.upperBound { value += step; Haptics.shared.selection() }
                }
            }
        }
        .padding(14)
        .background(RoundedRectangle(cornerRadius: 14, style: .continuous).fill(p.card))
        .overlay(RoundedRectangle(cornerRadius: 14, style: .continuous).stroke(p.divider, lineWidth: 1))
    }

    private func stepButton(_ icon: String, action: @escaping () -> Void) -> some View {
        Button(action: action) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .bold))
                .foregroundColor(p.onAccent)
                .frame(width: 34, height: 34)
                .background(Circle().fill(p.accent))
        }
        .buttonStyle(PressableStyle())
    }
}

/// Generic labeled chip selector (used for Goal, category, etc.).
struct ChipSelector<T: Hashable>: View {
    @Environment(\.palette) private var p
    let title: String
    let items: [T]
    @Binding var selection: T
    let label: (T) -> String
    var icon: ((T) -> String)?

    var body: some View {
        VStack(alignment: .leading, spacing: 8) {
            Text(title)
                .font(AppFont.subhead)
                .foregroundColor(p.textSecondary)
            ScrollView(.horizontal, showsIndicators: false) {
                HStack(spacing: 8) {
                    ForEach(items, id: \.self) { item in
                        let selected = item == selection
                        Button {
                            Haptics.shared.selection()
                            withAnimation(.spring(response: 0.3, dampingFraction: 0.7)) { selection = item }
                        } label: {
                            HStack(spacing: 6) {
                                if let icon = icon {
                                    Image(systemName: icon(item)).font(.system(size: 13, weight: .semibold))
                                }
                                Text(label(item)).font(AppFont.subhead)
                            }
                            .foregroundColor(selected ? p.onAccent : p.textSecondary)
                            .padding(.vertical, 9)
                            .padding(.horizontal, 14)
                            .background(
                                Capsule().fill(selected ? p.accent : p.card)
                            )
                            .overlay(Capsule().stroke(selected ? Color.clear : p.divider, lineWidth: 1))
                        }
                        .buttonStyle(PressableStyle())
                    }
                }
            }
        }
    }
}
