//
//  MoodPicker.swift
//  CalmOrbit
//
//  Horizontal mood selector used by the dashboard, mood and session-complete
//  screens.
//

import SwiftUI

struct MoodPicker: View {
    @Environment(\.palette) private var p
    @Binding var selection: MoodType?
    var compact: Bool = false

    var body: some View {
        HStack(spacing: compact ? 8 : 10) {
            ForEach(MoodType.allCases) { mood in
                let selected = selection == mood
                Button {
                    Haptics.shared.impact(.light)
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) {
                        selection = selected ? nil : mood
                    }
                } label: {
                    VStack(spacing: 6) {
                        Text(mood.emoji)
                            .font(.system(size: compact ? 22 : 26))
                        Text(mood.title)
                            .font(AppFont.tiny)
                            .foregroundColor(selected ? p.textPrimary : p.textMuted)
                            .lineLimit(1)
                            .minimumScaleFactor(0.7)
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, compact ? 9 : 12)
                    .background(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .fill(selected ? mood.color.opacity(0.20) : p.card)
                    )
                    .overlay(
                        RoundedRectangle(cornerRadius: 16, style: .continuous)
                            .stroke(selected ? mood.color : p.divider, lineWidth: selected ? 2 : 1)
                    )
                    .scaleEffect(selected ? 1.05 : 1)
                }
                .buttonStyle(PressableStyle())
            }
        }
    }
}
