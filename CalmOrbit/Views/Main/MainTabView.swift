//
//  MainTabView.swift
//  CalmOrbit
//
//  Hosts the five tabs and the floating custom tab bar. The selected tab is
//  rebuilt on switch so each screen starts fresh and breathing timers don't
//  leak into the background.
//

import SwiftUI

/// Shared bottom inset so scroll content clears the floating tab bar.
let kTabBarInset: CGFloat = 96

struct MainTabView: View {
    @Environment(\.palette) private var p
    @State private var tab: AppTab = .dashboard

    var body: some View {
        ZStack(alignment: .bottom) {
            p.bg.ignoresSafeArea()

            ZStack {
                switch tab {
                case .dashboard: DashboardView(goToTab: switchTab)
                case .sessions:  SessionsView()
                case .breathe:   BreatheView()
                case .mood:      MoodView()
                case .more:      MoreView()
                }
            }
            .transition(.opacity)

            CustomTabBar(selection: Binding(
                get: { tab },
                set: { switchTab($0) }
            ))
        }
    }

    private func switchTab(_ newTab: AppTab) {
        withAnimation(.easeInOut(duration: 0.25)) { tab = newTab }
    }
}
