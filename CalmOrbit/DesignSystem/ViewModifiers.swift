//
//  ViewModifiers.swift
//  CalmOrbit
//
//  Shared view modifiers: card surface, glow, section header and a screen
//  background that paints the themed gradient edge-to-edge.
//

import SwiftUI

struct CardModifier: ViewModifier {
    @Environment(\.palette) private var p
    var padding: CGFloat
    var cornerRadius: CGFloat
    var elevated: Bool

    func body(content: Content) -> some View {
        content
            .padding(padding)
            .background(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .fill(elevated ? p.cardElevated : p.card)
            )
            .overlay(
                RoundedRectangle(cornerRadius: cornerRadius, style: .continuous)
                    .stroke(p.divider, lineWidth: 1)
            )
            .shadow(color: p.shadow.opacity(p.isDark ? 0.5 : 0.12), radius: 16, x: 0, y: 10)
    }
}

extension View {
    func cardStyle(padding: CGFloat = 18, cornerRadius: CGFloat = 22, elevated: Bool = false) -> some View {
        modifier(CardModifier(padding: padding, cornerRadius: cornerRadius, elevated: elevated))
    }
}

struct GlowModifier: ViewModifier {
    var color: Color
    var radius: CGFloat
    func body(content: Content) -> some View {
        content
            .shadow(color: color, radius: radius)
            .shadow(color: color.opacity(0.6), radius: radius / 2)
    }
}

extension View {
    func glow(_ color: Color, radius: CGFloat = 18) -> some View {
        modifier(GlowModifier(color: color, radius: radius))
    }
}

/// Full-screen themed background gradient with a couple of soft ambient orbs.
struct ScreenBackground: View {
    @Environment(\.palette) private var p
    var body: some View {
        ZStack {
            p.backgroundGradient.ignoresSafeArea()
            Circle()
                .fill(p.accent.opacity(p.isDark ? 0.18 : 0.10))
                .frame(width: 320, height: 320)
                .blur(radius: 90)
                .offset(x: -120, y: -220)
            Circle()
                .fill(p.cyan.opacity(p.isDark ? 0.14 : 0.08))
                .frame(width: 280, height: 280)
                .blur(radius: 90)
                .offset(x: 140, y: 320)
        }
    }
}

struct SectionHeader: View {
    @Environment(\.palette) private var p
    let title: String
    var action: (() -> Void)?
    var actionLabel: String?

    init(_ title: String, actionLabel: String? = nil, action: (() -> Void)? = nil) {
        self.title = title
        self.actionLabel = actionLabel
        self.action = action
    }

    var body: some View {
        HStack {
            Text(title)
                .font(AppFont.headline)
                .foregroundColor(p.textPrimary)
            Spacer()
            if let action = action, let label = actionLabel {
                Button(action: action) {
                    Text(label)
                        .font(AppFont.subhead)
                        .foregroundColor(p.accentHi)
                }
                .buttonStyle(PressableStyle())
            }
        }
    }
}
