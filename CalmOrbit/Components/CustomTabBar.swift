//
//  CustomTabBar.swift
//  CalmOrbit
//
//  Themed floating tab bar with a raised center "Breathe" orb button.
//

import SwiftUI

enum AppTab: Int, CaseIterable, Identifiable {
    case dashboard, sessions, breathe, mood, more
    var id: Int { rawValue }

    var title: String {
        switch self {
        case .dashboard: return "Home"
        case .sessions:  return "Sessions"
        case .breathe:   return "Breathe"
        case .mood:      return "Mood"
        case .more:      return "More"
        }
    }

    var icon: String {
        switch self {
        case .dashboard: return "square.grid.2x2.fill"
        case .sessions:  return "list.bullet.rectangle.fill"
        case .breathe:   return "wind"
        case .mood:      return "face.smiling.fill"
        case .more:      return "ellipsis.circle.fill"
        }
    }
}

struct CustomTabBar: View {
    @Environment(\.palette) private var p
    @Binding var selection: AppTab

    var body: some View {
        HStack(alignment: .center, spacing: 0) {
            ForEach(AppTab.allCases) { tab in
                if tab == .breathe {
                    breatheButton
                } else {
                    tabButton(tab)
                }
            }
        }
        .padding(.horizontal, 10)
        .padding(.top, 8)
        .padding(.bottom, 6)
        .background(
            RoundedRectangle(cornerRadius: 26, style: .continuous)
                .fill(p.card)
                .overlay(RoundedRectangle(cornerRadius: 26, style: .continuous).stroke(p.divider, lineWidth: 1))
                .shadow(color: p.shadow, radius: 18, x: 0, y: 10)
        )
        .padding(.horizontal, 16)
    }

    private func tabButton(_ tab: AppTab) -> some View {
        let selected = selection == tab
        return Button {
            Haptics.shared.selection()
            withAnimation(.spring(response: 0.35, dampingFraction: 0.7)) { selection = tab }
        } label: {
            VStack(spacing: 4) {
                Image(systemName: tab.icon)
                    .font(.system(size: 18, weight: .semibold))
                    .foregroundColor(selected ? p.accentHi : p.textMuted)
                Text(tab.title)
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(selected ? p.accentHi : p.textMuted)
            }
            .frame(maxWidth: .infinity)
            .padding(.vertical, 4)
            .scaleEffect(selected ? 1.08 : 1)
        }
        .buttonStyle(PressableStyle())
    }

    private var breatheButton: some View {
        let selected = selection == .breathe
        return Button {
            Haptics.shared.impact(.medium)
            withAnimation(.spring(response: 0.4, dampingFraction: 0.7)) { selection = .breathe }
        } label: {
            VStack(spacing: 4) {
                ZStack {
                    Circle()
                        .fill(LinearGradient(colors: [p.accentHi, p.accent, p.cyan],
                                             startPoint: .topLeading, endPoint: .bottomTrailing))
                        .frame(width: 54, height: 54)
                        .shadow(color: p.glowPurple, radius: selected ? 16 : 10, x: 0, y: 4)
                    Image(systemName: "wind")
                        .font(.system(size: 22, weight: .bold))
                        .foregroundColor(p.onAccent)
                }
                Text("Breathe")
                    .font(.system(size: 10, weight: .semibold))
                    .foregroundColor(selected ? p.accentHi : p.textMuted)
            }
            .frame(maxWidth: .infinity)
            .offset(y: -10)
            .scaleEffect(selected ? 1.06 : 1)
        }
        .buttonStyle(PressableStyle())
    }
}
