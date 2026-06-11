//
//  SplashView.swift
//  CalmOrbit
//
//  Thematic launch animation. Three simultaneous layers:
//   1. a shifting radial background gradient,
//   2. drifting bubbles + orbiting dots (midground loop),
//   3. the central orb + "Calm Orbit +" title entrance (foreground).
//  A single coordinator timer stages the sequence and the designed exit
//  (orb scales up and implodes into the app). All loops reset in onDisappear.
//

import SwiftUI

struct SplashView: View {
    @Environment(\.palette) private var p
    let onFinish: () -> Void

    @State private var isVisible = true
    @State private var bgIn = false
    @State private var orbIn = false
    @State private var pulse = false
    @State private var titleIn = false
    @State private var orbit = false
    @State private var exit = false
    @State private var coordinator: Timer?

    var body: some View {
        ZStack {
            // Layer 1 — shifting background gradient
            LinearGradient(colors: [p.bgDeep, p.bg, p.bgSoft],
                           startPoint: bgIn ? .topLeading : .top,
                           endPoint: bgIn ? .bottomTrailing : .bottom)
                .ignoresSafeArea()
                .opacity(bgIn ? 1 : 0.4)

            // Layer 2 — midground drifting bubbles + orbiting dots
            BubblesBackground(count: 16, isActive: isVisible)
                .opacity(bgIn ? 1 : 0)

            ZStack {
                ForEach(0..<3) { i in
                    Circle()
                        .fill(p.cyan.opacity(0.5))
                        .frame(width: 10, height: 10)
                        .offset(y: -130)
                        .rotationEffect(.degrees((orbit ? 360 : 0) + Double(i) * 120))
                        .opacity(orbIn ? 0.8 : 0)
                }
            }
            .scaleEffect(exit ? 1.6 : 1)

            // Layer 3 — foreground orb + title
            VStack(spacing: 26) {
                OrbView(scale: orbIn ? (pulse ? 1.06 : 0.98) : 0.2,
                        intensity: orbIn ? 1 : 0.2,
                        size: 190)
                    .scaleEffect(exit ? 2.4 : 1)
                    .opacity(exit ? 0 : 1)

                VStack(spacing: 8) {
                    Text("Calm Orbit +")
                        .font(AppFont.rounded(34, .bold))
                        .foregroundColor(p.textPrimary)
                    Text("Breathe. Slow down.")
                        .font(AppFont.callout)
                        .foregroundColor(p.textSecondary)
                }
                .opacity(titleIn && !exit ? 1 : 0)
                .offset(y: titleIn ? 0 : 18)
                .scaleEffect(exit ? 1.1 : 1)
            }
            .offset(y: -10)
        }
        .onAppear { startSequence() }
        .onDisappear { teardown() }
    }

    private func startSequence() {
        isVisible = true
        // Stage 1 (0–0.6s): background builds in.
        withAnimation(.easeOut(duration: 0.6)) { bgIn = true }

        var step = 0
        let timer = Timer.scheduledTimer(withTimeInterval: 0.75, repeats: true) { t in
            step += 1
            switch step {
            case 1: // ~0.75s — Stage 2: orb + orbiting dots appear
                withAnimation(.spring(response: 0.6, dampingFraction: 0.6)) {
                    orbIn = true
                }
                withAnimation(.linear(duration: 6).repeatForever(autoreverses: false)) {
                    orbit = true
                }
                withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) {
                    pulse = true
                }
            case 2: // ~1.5s — Stage 3: title spring entrance
                withAnimation(.spring(response: 0.6, dampingFraction: 0.7)) {
                    titleIn = true
                }
            case 3: // ~2.25s — brief hold then designed exit (implode)
                withAnimation(.easeIn(duration: 0.55)) { exit = true }
            case 4: // ~3.0s — hand off to the app
                t.invalidate()
                onFinish()
            default:
                break
            }
        }
        RunLoop.main.add(timer, forMode: .common)
        coordinator = timer
    }

    private func teardown() {
        isVisible = false
        pulse = false
        orbit = false
        coordinator?.invalidate()
        coordinator = nil
    }
}
