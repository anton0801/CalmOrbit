//
//  LineChartView.swift
//  CalmOrbit
//
//  Custom animated line chart with gradient area fill and dots. Draws the
//  line with an animated trim on appear.
//

import SwiftUI

struct LineChartView: View {
    @Environment(\.palette) private var p
    let values: [DayValue]
    var height: CGFloat = 150
    var accent: Color?
    var yMin: Double = 0
    var yMax: Double = 5
    @State private var progress: CGFloat = 0

    var body: some View {
        let tint = accent ?? p.accentHi
        GeometryReader { geo in
            let pts = points(in: geo.size)
            ZStack {
                if pts.count > 1 {
                    areaPath(pts, in: geo.size)
                        .fill(LinearGradient(colors: [tint.opacity(0.28), .clear],
                                             startPoint: .top, endPoint: .bottom))
                        .opacity(Double(progress))
                    linePath(pts)
                        .trim(from: 0, to: progress)
                        .stroke(tint, style: StrokeStyle(lineWidth: 3, lineCap: .round, lineJoin: .round))
                }
                ForEach(pts.indices, id: \.self) { i in
                    Circle()
                        .fill(tint)
                        .frame(width: 6, height: 6)
                        .overlay(Circle().stroke(p.bg, lineWidth: 1.5))
                        .position(pts[i])
                        .opacity(Double(progress))
                }
            }
        }
        .frame(height: height)
        .onAppear { withAnimation(.easeInOut(duration: 0.9)) { progress = 1 } }
        .onDisappear { progress = 0 }
    }

    private func points(in size: CGSize) -> [CGPoint] {
        guard !values.isEmpty else { return [] }
        let range = max(yMax - yMin, 0.001)
        let stepX = values.count > 1 ? size.width / CGFloat(values.count - 1) : 0
        return values.enumerated().map { idx, item in
            let clamped = min(max(item.value, yMin), yMax)
            let ratio = (clamped - yMin) / range
            let x = values.count > 1 ? CGFloat(idx) * stepX : size.width / 2
            let y = size.height - CGFloat(ratio) * size.height
            return CGPoint(x: x, y: y)
        }
    }

    private func linePath(_ pts: [CGPoint]) -> Path {
        var path = Path()
        guard let first = pts.first else { return path }
        path.move(to: first)
        for pt in pts.dropFirst() { path.addLine(to: pt) }
        return path
    }

    private func areaPath(_ pts: [CGPoint], in size: CGSize) -> Path {
        var path = Path()
        guard let first = pts.first, let last = pts.last else { return path }
        path.move(to: CGPoint(x: first.x, y: size.height))
        path.addLine(to: first)
        for pt in pts.dropFirst() { path.addLine(to: pt) }
        path.addLine(to: CGPoint(x: last.x, y: size.height))
        path.closeSubpath()
        return path
    }
}
