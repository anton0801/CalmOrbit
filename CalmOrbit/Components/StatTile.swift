//
//  StatTile.swift
//  CalmOrbit
//

import SwiftUI

struct StatTile: View {
    @Environment(\.palette) private var p
    let icon: String
    let title: String
    let value: String
    var accent: Color?
    var caption: String?

    var body: some View {
        let tint = accent ?? p.accent
        VStack(alignment: .leading, spacing: 12) {
            ZStack {
                Circle().fill(tint.opacity(0.16)).frame(width: 38, height: 38)
                Image(systemName: icon)
                    .font(.system(size: 16, weight: .semibold))
                    .foregroundColor(tint)
            }
            VStack(alignment: .leading, spacing: 3) {
                Text(value)
                    .font(AppFont.rounded(24, .bold))
                    .foregroundColor(p.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.6)
                Text(title)
                    .font(AppFont.caption)
                    .foregroundColor(p.textSecondary)
                if let caption = caption {
                    Text(caption)
                        .font(AppFont.tiny)
                        .foregroundColor(p.textMuted)
                }
            }
        }
        .frame(maxWidth: .infinity, alignment: .leading)
        .cardStyle(padding: 16)
    }
}
