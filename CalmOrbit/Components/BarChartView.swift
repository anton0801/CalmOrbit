//
//  BarChartView.swift
//  CalmOrbit
//
//  Custom animated bar chart (no Swift Charts dependency). Animates bars up
//  on appear and resets on disappear.
//

import SwiftUI

struct BarChartView: View {
    @Environment(\.palette) private var p
    let values: [DayValue]
    var height: CGFloat = 150
    var accent: Color?
    @State private var appear = false

    private var maxValue: Double { max(values.map(\.value).max() ?? 1, 1) }

    var body: some View {
        let tint = accent ?? p.accent
        HStack(alignment: .bottom, spacing: 6) {
            ForEach(values) { item in
                VStack(spacing: 6) {
                    ZStack(alignment: .bottom) {
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(p.divider.opacity(0.35))
                            .frame(height: height)
                        RoundedRectangle(cornerRadius: 6, style: .continuous)
                            .fill(LinearGradient(colors: [tint, tint.opacity(0.45)],
                                                 startPoint: .top, endPoint: .bottom))
                            .frame(height: appear ? barHeight(item.value) : 2)
                    }
                    Text(weekdayLetter(item.date))
                        .font(.system(size: 9, weight: .semibold))
                        .foregroundColor(p.textMuted)
                }
                .frame(maxWidth: .infinity)
            }
        }
        .onAppear {
            withAnimation(.spring(response: 0.7, dampingFraction: 0.8)) { appear = true }
        }
        .onDisappear { appear = false }
    }

    private func barHeight(_ value: Double) -> CGFloat {
        max(CGFloat(value / maxValue) * height, 2)
    }

    private func weekdayLetter(_ date: Date) -> String {
        let f = DateFormatter()
        f.dateFormat = "EEEEE"
        return f.string(from: date)
    }
}
