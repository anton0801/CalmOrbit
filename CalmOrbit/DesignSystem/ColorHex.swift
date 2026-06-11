//
//  ColorHex.swift
//  CalmOrbit
//
//  Hex initializer for Color so the design palette can be defined inline
//  without color assets. Supports "RRGGBB" and "AARRGGBB" (with or without #).
//

import SwiftUI

extension Color {
    /// Create a color from a hex string. Accepts "#RRGGBB", "RRGGBB",
    /// "#AARRGGBB" or "AARRGGBB". An explicit `alpha` overrides the 6-digit case.
    init(hex: String, alpha: Double = 1.0) {
        var string = hex.trimmingCharacters(in: .whitespacesAndNewlines)
        if string.hasPrefix("#") { string.removeFirst() }

        var value: UInt64 = 0
        Scanner(string: string).scanHexInt64(&value)

        let r, g, b, a: Double
        switch string.count {
        case 8: // AARRGGBB
            a = Double((value & 0xFF00_0000) >> 24) / 255.0
            r = Double((value & 0x00FF_0000) >> 16) / 255.0
            g = Double((value & 0x0000_FF00) >> 8) / 255.0
            b = Double(value & 0x0000_00FF) / 255.0
        case 6: // RRGGBB
            a = alpha
            r = Double((value & 0xFF0000) >> 16) / 255.0
            g = Double((value & 0x00FF00) >> 8) / 255.0
            b = Double(value & 0x0000FF) / 255.0
        default:
            a = alpha; r = 0; g = 0; b = 0
        }
        self.init(.sRGB, red: r, green: g, blue: b, opacity: a)
    }
}
