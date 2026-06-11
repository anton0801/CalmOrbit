//
//  OrbView.swift
//  CalmOrbit
//
//  The living breathing orb. The parent supplies `scale` (animated elsewhere)
//  and `intensity` for the glow. Renders a radial purple→cyan gradient core,
//  layered glows, a glossy highlight and a thin rim.
//

import SwiftUI

struct OrbView: View {
    @Environment(\.palette) private var p
    var scale: CGFloat
    var intensity: CGFloat = 1
    var size: CGFloat = 250

    var body: some View {
        ZStack {
            // Outer ambient glow
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [p.accent.opacity(0.45 * Double(intensity)), .clear]),
                        center: .center, startRadius: 0, endRadius: size * 0.85
                    )
                )
                .frame(width: size * 1.7, height: size * 1.7)
                .scaleEffect(scale)
                .blur(radius: 18)

            // Secondary cyan halo
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [p.cyan.opacity(0.30 * Double(intensity)), .clear]),
                        center: .center, startRadius: 0, endRadius: size * 0.7
                    )
                )
                .frame(width: size * 1.35, height: size * 1.35)
                .scaleEffect(scale)
                .blur(radius: 14)

            // Core orb
            Circle()
                .fill(
                    RadialGradient(
                        gradient: Gradient(colors: [p.cyanHi, p.accentHi, p.accent, p.accentActive]),
                        center: UnitPoint(x: 0.36, y: 0.30),
                        startRadius: 2, endRadius: size * 0.72
                    )
                )
                .frame(width: size, height: size)
                .overlay(
                    Circle()
                        .stroke(
                            LinearGradient(colors: [.white.opacity(0.5), .clear],
                                           startPoint: .topLeading, endPoint: .bottomTrailing),
                            lineWidth: 1.5
                        )
                )
                .overlay(
                    // glossy top highlight
                    Ellipse()
                        .fill(Color.white.opacity(0.22))
                        .frame(width: size * 0.42, height: size * 0.26)
                        .blur(radius: 8)
                        .offset(x: -size * 0.12, y: -size * 0.24)
                )
                .scaleEffect(scale)
                .shadow(color: p.glowPurple, radius: 34 * intensity)
                .shadow(color: p.glowCyan, radius: 20 * intensity)
        }
        .frame(width: size, height: size)
        .accessibilityHidden(true)
    }
}
