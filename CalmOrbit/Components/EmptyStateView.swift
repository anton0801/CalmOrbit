//
//  EmptyStateView.swift
//  CalmOrbit
//

import SwiftUI

struct EmptyStateView: View {
    @Environment(\.palette) private var p
    let icon: String
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 14) {
            ZStack {
                Circle()
                    .fill(p.accent.opacity(0.15))
                    .frame(width: 84, height: 84)
                Image(systemName: icon)
                    .font(.system(size: 32, weight: .semibold))
                    .foregroundColor(p.accentHi)
            }
            Text(title)
                .font(AppFont.headline)
                .foregroundColor(p.textPrimary)
            Text(message)
                .font(AppFont.subhead)
                .foregroundColor(p.textSecondary)
                .multilineTextAlignment(.center)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 40)
        .padding(.horizontal, 24)
    }
}
