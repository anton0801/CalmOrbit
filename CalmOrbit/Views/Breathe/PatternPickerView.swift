//
//  PatternPickerView.swift
//  CalmOrbit
//
//  Sheet for choosing the active breathing pattern. Includes a shortcut to
//  add a new pattern.
//

import SwiftUI

struct PatternPickerView: View {
    @EnvironmentObject private var store: DataStore
    @Environment(\.palette) private var p
    @Environment(\.presentationMode) private var presentationMode

    let selectedID: UUID
    let onSelect: (BreathingPattern) -> Void

    @State private var showAdd = false

    var body: some View {
        ZStack {
            ScreenBackground()
            ScrollView(showsIndicators: false) {
                VStack(spacing: 12) {
                    ScreenHeader(title: "Patterns",
                                 subtitle: "Choose a breathing pattern",
                                 leading: .close,
                                 trailingSystemImage: "plus",
                                 trailingAction: { showAdd = true })

                    ForEach(store.activePatterns) { pattern in
                        Button {
                            Haptics.shared.impact(.light)
                            onSelect(pattern)
                            presentationMode.wrappedValue.dismiss()
                        } label: {
                            PatternRow(pattern: pattern, selected: pattern.id == selectedID)
                        }
                        .buttonStyle(PressableStyle())
                    }

                    Color.clear.frame(height: 30)
                }
                .padding(.horizontal, 20)
            }
        }
        .sheet(isPresented: $showAdd) {
            AddPatternView()
                .environmentObject(store)
                .environment(\.palette, p)
        }
    }
}

struct PatternRow: View {
    @Environment(\.palette) private var p
    let pattern: BreathingPattern
    var selected: Bool = false

    var body: some View {
        HStack(spacing: 14) {
            ZStack {
                Circle().fill(pattern.accent.opacity(0.2)).frame(width: 46, height: 46)
                Image(systemName: "wind")
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(pattern.accent)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(pattern.name)
                    .font(AppFont.headline)
                    .foregroundColor(p.textPrimary)
                Text("\(pattern.ratioText) · \(pattern.cycles) cycles · \(pattern.durationText)")
                    .font(AppFont.caption)
                    .foregroundColor(p.textSecondary)
            }
            Spacer()
            Image(systemName: selected ? "checkmark.circle.fill" : "chevron.right")
                .font(.system(size: selected ? 20 : 14, weight: .semibold))
                .foregroundColor(selected ? p.success : p.textMuted)
        }
        .cardStyle(padding: 14)
    }
}
