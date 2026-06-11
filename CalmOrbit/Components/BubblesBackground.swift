//
//  BubblesBackground.swift
//  CalmOrbit
//
//  Floating cyan bubbles that drift upward in an infinite loop. Bubble specs
//  are deterministic (index-derived) so they don't re-randomize on redraw.
//  The loop is bound to `isActive` and reset in onDisappear to avoid leaks.
//

import SwiftUI

private struct Bubble: Identifiable {
    let id: Int
    let x: CGFloat
    let size: CGFloat
    let opacity: Double
    let duration: Double
    let delay: Double
}

struct BubblesBackground: View {
    @Environment(\.palette) private var p
    var count: Int = 14
    var isActive: Bool = true
    var tint: Color? = nil

    @State private var animate = false
    private let bubbles: [Bubble]

    init(count: Int = 14, isActive: Bool = true, tint: Color? = nil) {
        self.count = count
        self.isActive = isActive
        self.tint = tint
        var generated: [Bubble] = []
        generated.reserveCapacity(count)
        for i in 0..<count {
            let x: CGFloat = CGFloat((i * 67 + 13) % 100) / 100.0
            let size: CGFloat = CGFloat(12 + (i * 37) % 28)
            let opacity: Double = 0.08 + Double((i * 53) % 5) * 0.04
            let duration: Double = 7.0 + Double((i * 29) % 8)
            let delay: Double = Double(i) * 0.45
            generated.append(Bubble(id: i, x: x, size: size, opacity: opacity,
                                    duration: duration, delay: delay))
        }
        self.bubbles = generated
    }

    var body: some View {
        GeometryReader { geo in
            ZStack {
                ForEach(bubbles) { bubble in
                    Circle()
                        .fill((tint ?? p.cyan).opacity(bubble.opacity))
                        .frame(width: bubble.size, height: bubble.size)
                        .blur(radius: bubble.size * 0.08)
                        .position(
                            x: bubble.x * geo.size.width,
                            y: animate ? -bubble.size : geo.size.height + bubble.size
                        )
                        .animation(
                            Animation.linear(duration: bubble.duration)
                                .repeatForever(autoreverses: false)
                                .delay(bubble.delay),
                            value: animate
                        )
                }
            }
        }
        .allowsHitTesting(false)
        .onAppear { if isActive { animate = true } }
        .onDisappear { animate = false }
    }
}
