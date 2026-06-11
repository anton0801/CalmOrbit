//
//  SegmentedPicker.swift
//  CalmOrbit
//
//  Custom animated segmented control with a sliding accent pill.
//

import SwiftUI

struct SegmentedPicker<T: Hashable>: View {
    @Environment(\.palette) private var p
    let items: [T]
    @Binding var selection: T
    let title: (T) -> String
    @Namespace private var ns

    var body: some View {
        HStack(spacing: 4) {
            ForEach(items, id: \.self) { item in
                let selected = item == selection
                Button {
                    Haptics.shared.selection()
                    withAnimation(.spring(response: 0.35, dampingFraction: 0.8)) {
                        selection = item
                    }
                } label: {
                    Text(title(item))
                        .font(AppFont.subhead)
                        .foregroundColor(selected ? p.onAccent : p.textSecondary)
                        .frame(maxWidth: .infinity)
                        .padding(.vertical, 9)
                        .background(
                            ZStack {
                                if selected {
                                    RoundedRectangle(cornerRadius: 12, style: .continuous)
                                        .fill(p.accent)
                                        .matchedGeometryEffect(id: "segPill", in: ns)
                                }
                            }
                        )
                }
                .buttonStyle(PressableStyle())
            }
        }
        .padding(4)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(p.card))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(p.divider, lineWidth: 1))
    }
}
