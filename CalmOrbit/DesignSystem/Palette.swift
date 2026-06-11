//
//  Palette.swift
//  CalmOrbit
//
//  Semantic color palette. A dark variant built from the exact spec colors and
//  a derived light variant. The active palette is chosen from the resolved
//  ColorScheme and injected through the environment so every view re-skins
//  instantly when the theme changes.
//

import SwiftUI

struct Palette {
    let isDark: Bool

    // Backgrounds
    let bg: Color
    let bgDeep: Color
    let bgSoft: Color

    // Surfaces
    let card: Color
    let cardElevated: Color
    let divider: Color
    let hairline: Color

    // Primary accent (orb / breathing)
    let accent: Color
    let accentActive: Color
    let accentHi: Color

    // Secondary accent (water / calm)
    let cyan: Color
    let cyanActive: Color
    let cyanHi: Color

    // Structural accent
    let indigo: Color
    let indigoSoft: Color

    // Status
    let success: Color
    let inProgress: Color
    let warning: Color
    let danger: Color

    // Text
    let textPrimary: Color
    let textSecondary: Color
    let textMuted: Color
    let onAccent: Color

    // Effects
    let glowPurple: Color
    let glowCyan: Color
    let glowSoft: Color
    let shadow: Color

    // Chart
    let chartBg: Color

    /// Two-stop orb gradient colors (radial #8B5CF6 -> #22D3EE).
    var orbColors: [Color] { [accent, cyan] }

    var accentGradient: LinearGradient {
        LinearGradient(colors: [accent, accentActive],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    var cyanGradient: LinearGradient {
        LinearGradient(colors: [cyan, cyanActive],
                       startPoint: .topLeading, endPoint: .bottomTrailing)
    }

    /// Ambient app background gradient.
    var backgroundGradient: LinearGradient {
        LinearGradient(colors: [bgDeep, bg, bgSoft],
                       startPoint: .top, endPoint: .bottom)
    }

    static func make(for scheme: ColorScheme) -> Palette {
        scheme == .dark ? .dark : .light
    }

    static let dark = Palette(
        isDark: true,
        bg: Color(hex: "0B1020"),
        bgDeep: Color(hex: "070A16"),
        bgSoft: Color(hex: "131A30"),
        card: Color(hex: "171F38"),
        cardElevated: Color(hex: "1F2A48"),
        divider: Color(hex: "2A3658"),
        hairline: Color.white.opacity(0.05),
        accent: Color(hex: "8B5CF6"),
        accentActive: Color(hex: "7C3AED"),
        accentHi: Color(hex: "A78BFA"),
        cyan: Color(hex: "22D3EE"),
        cyanActive: Color(hex: "06B6D4"),
        cyanHi: Color(hex: "67E8F9"),
        indigo: Color(hex: "6366F1"),
        indigoSoft: Color(hex: "818CF8"),
        success: Color(hex: "34D399"),
        inProgress: Color(hex: "22D3EE"),
        warning: Color(hex: "FBBF24"),
        danger: Color(hex: "F87171"),
        textPrimary: Color(hex: "EEF2FF"),
        textSecondary: Color(hex: "B8C0E0"),
        textMuted: Color(hex: "6B7398"),
        onAccent: Color(hex: "0B1020"),
        glowPurple: Color(hex: "8B5CF6", alpha: 0.45),
        glowCyan: Color(hex: "22D3EE", alpha: 0.35),
        glowSoft: Color(hex: "A78BFA", alpha: 0.25),
        shadow: Color.black.opacity(0.7),
        chartBg: Color(hex: "070A16")
    )

    static let light = Palette(
        isDark: false,
        bg: Color(hex: "EEF0FA"),
        bgDeep: Color(hex: "E3E6F4"),
        bgSoft: Color(hex: "F7F8FD"),
        card: Color(hex: "FFFFFF"),
        cardElevated: Color(hex: "F1F2FB"),
        divider: Color(hex: "DCE0EF"),
        hairline: Color.black.opacity(0.05),
        accent: Color(hex: "7C3AED"),
        accentActive: Color(hex: "6D28D9"),
        accentHi: Color(hex: "8B5CF6"),
        cyan: Color(hex: "0891B2"),
        cyanActive: Color(hex: "0E7490"),
        cyanHi: Color(hex: "22D3EE"),
        indigo: Color(hex: "4F46E5"),
        indigoSoft: Color(hex: "6366F1"),
        success: Color(hex: "059669"),
        inProgress: Color(hex: "0891B2"),
        warning: Color(hex: "D97706"),
        danger: Color(hex: "DC2626"),
        textPrimary: Color(hex: "171F38"),
        textSecondary: Color(hex: "4A5478"),
        textMuted: Color(hex: "8A92AE"),
        onAccent: Color(hex: "FFFFFF"),
        glowPurple: Color(hex: "8B5CF6", alpha: 0.30),
        glowCyan: Color(hex: "22D3EE", alpha: 0.25),
        glowSoft: Color(hex: "A78BFA", alpha: 0.20),
        shadow: Color.black.opacity(0.18),
        chartBg: Color(hex: "EDEFFa")
    )
}

// MARK: - Environment injection

private struct PaletteKey: EnvironmentKey {
    static let defaultValue: Palette = .dark
}

extension EnvironmentValues {
    var palette: Palette {
        get { self[PaletteKey.self] }
        set { self[PaletteKey.self] = newValue }
    }
}
