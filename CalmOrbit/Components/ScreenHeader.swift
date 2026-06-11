//
//  ScreenHeader.swift
//  CalmOrbit
//
//  Themed in-view header so the app can hide the system navigation bar and
//  fully control its look. Handles top-level titles, pushed-detail back
//  buttons and sheet close buttons with one component.
//

import SwiftUI

struct ScreenHeader: View {
    enum Leading { case none, back, close }

    @Environment(\.palette) private var p
    @Environment(\.presentationMode) private var presentationMode

    let title: String
    var subtitle: String?
    var leading: Leading = .none
    var trailingSystemImage: String?
    var trailingAction: (() -> Void)?

    var body: some View {
        HStack(alignment: .center, spacing: 12) {
            if leading != .none {
                Button {
                    Haptics.shared.selection()
                    presentationMode.wrappedValue.dismiss()
                } label: {
                    Image(systemName: leading == .back ? "chevron.left" : "xmark")
                        .font(.system(size: 16, weight: .bold))
                        .foregroundColor(p.textPrimary)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(p.card))
                        .overlay(Circle().stroke(p.divider, lineWidth: 1))
                }
                .buttonStyle(PressableStyle())
            }

            VStack(alignment: .leading, spacing: 2) {
                Text(title)
                    .font(AppFont.rounded(26, .bold))
                    .foregroundColor(p.textPrimary)
                    .lineLimit(1)
                    .minimumScaleFactor(0.7)
                if let subtitle = subtitle {
                    Text(subtitle)
                        .font(AppFont.subhead)
                        .foregroundColor(p.textSecondary)
                }
            }

            Spacer(minLength: 8)

            if let icon = trailingSystemImage, let action = trailingAction {
                Button {
                    Haptics.shared.impact(.light)
                    action()
                } label: {
                    Image(systemName: icon)
                        .font(.system(size: 16, weight: .semibold))
                        .foregroundColor(p.accentHi)
                        .frame(width: 40, height: 40)
                        .background(Circle().fill(p.card))
                        .overlay(Circle().stroke(p.divider, lineWidth: 1))
                }
                .buttonStyle(PressableStyle())
            }
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
        .padding(.bottom, 6)
    }
}
