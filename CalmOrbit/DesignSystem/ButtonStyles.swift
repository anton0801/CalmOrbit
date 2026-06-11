//
//  ButtonStyles.swift
//  CalmOrbit
//
//  Reusable button styles (Primary / Secondary / Soft / Icon) that read the
//  active palette from the environment and animate on press.
//

import SwiftUI

struct PrimaryButtonStyle: ButtonStyle {
    var fullWidth: Bool = true
    func makeBody(configuration: Configuration) -> some View {
        Render(configuration: configuration, fullWidth: fullWidth)
    }

    private struct Render: View {
        let configuration: ButtonStyleConfiguration
        let fullWidth: Bool
        @Environment(\.palette) private var p
        @Environment(\.isEnabled) private var isEnabled

        var body: some View {
            configuration.label
                .font(AppFont.rounded(17, .semibold))
                .foregroundColor(p.onAccent)
                .frame(maxWidth: fullWidth ? .infinity : nil)
                .padding(.vertical, 16)
                .padding(.horizontal, fullWidth ? 0 : 24)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(LinearGradient(colors: [p.accentHi, p.accent, p.accentActive],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                )
                .shadow(color: p.glowPurple, radius: configuration.isPressed ? 6 : 16, x: 0, y: 7)
                .opacity(isEnabled ? 1 : 0.45)
                .scaleEffect(configuration.isPressed ? 0.97 : 1)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
        }
    }
}

struct SecondaryButtonStyle: ButtonStyle {
    var fullWidth: Bool = true
    func makeBody(configuration: Configuration) -> some View {
        Render(configuration: configuration, fullWidth: fullWidth)
    }

    private struct Render: View {
        let configuration: ButtonStyleConfiguration
        let fullWidth: Bool
        @Environment(\.palette) private var p
        @Environment(\.isEnabled) private var isEnabled

        var body: some View {
            configuration.label
                .font(AppFont.rounded(17, .semibold))
                .foregroundColor(p.textPrimary)
                .frame(maxWidth: fullWidth ? .infinity : nil)
                .padding(.vertical, 16)
                .padding(.horizontal, fullWidth ? 0 : 24)
                .background(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .fill(p.cardElevated)
                )
                .overlay(
                    RoundedRectangle(cornerRadius: 18, style: .continuous)
                        .stroke(p.divider, lineWidth: 1)
                )
                .opacity(isEnabled ? 1 : 0.45)
                .scaleEffect(configuration.isPressed ? 0.97 : 1)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
        }
    }
}

struct SoftButtonStyle: ButtonStyle {
    var fullWidth: Bool = true
    func makeBody(configuration: Configuration) -> some View {
        Render(configuration: configuration, fullWidth: fullWidth)
    }

    private struct Render: View {
        let configuration: ButtonStyleConfiguration
        let fullWidth: Bool
        @Environment(\.palette) private var p
        @Environment(\.isEnabled) private var isEnabled

        var body: some View {
            configuration.label
                .font(AppFont.rounded(16, .semibold))
                .foregroundColor(p.accentHi)
                .frame(maxWidth: fullWidth ? .infinity : nil)
                .padding(.vertical, 14)
                .padding(.horizontal, fullWidth ? 0 : 20)
                .background(
                    RoundedRectangle(cornerRadius: 16, style: .continuous)
                        .fill(p.accent.opacity(p.isDark ? 0.16 : 0.12))
                )
                .opacity(isEnabled ? 1 : 0.45)
                .scaleEffect(configuration.isPressed ? 0.97 : 1)
                .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
        }
    }
}

/// Press-scale style for icon / pill buttons.
struct PressableStyle: ButtonStyle {
    var scale: CGFloat = 0.92
    func makeBody(configuration: Configuration) -> some View {
        configuration.label
            .scaleEffect(configuration.isPressed ? scale : 1)
            .animation(.spring(response: 0.3, dampingFraction: 0.6), value: configuration.isPressed)
    }
}
