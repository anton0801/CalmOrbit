//
//  Typography.swift
//  CalmOrbit
//
//  Rounded system font scale used across the app for a soft, calm feel.
//

import SwiftUI

enum AppFont {
    static func rounded(_ size: CGFloat, _ weight: Font.Weight = .regular) -> Font {
        .system(size: size, weight: weight, design: .rounded)
    }

    static var hero: Font { rounded(34, .bold) }
    static var largeTitle: Font { rounded(28, .bold) }
    static var title: Font { rounded(22, .bold) }
    static var headline: Font { rounded(18, .semibold) }
    static var body: Font { rounded(16, .regular) }
    static var callout: Font { rounded(15, .medium) }
    static var subhead: Font { rounded(14, .medium) }
    static var caption: Font { rounded(12, .medium) }
    static var tiny: Font { rounded(11, .semibold) }
    static var numeralLarge: Font { rounded(44, .heavy) }
}

extension Text {
    func styledTitle(_ palette: Palette) -> Text {
        self.font(AppFont.title).foregroundColor(palette.textPrimary)
    }
}
