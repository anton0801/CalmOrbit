//
//  OnboardingView.swift
//  CalmOrbit
//
//  Three-page onboarding. Each page has a unique illustrated scene and a
//  distinct interactive element: tap-to-burst, drag-to-expand and
//  drag-parallax. Looping animations are reset in onDisappear.
//

import SwiftUI

struct OnboardingView: View {
    @Environment(\.palette) private var p
    let onFinish: () -> Void

    @State private var index = 0
    private let pageCount = 3

    var body: some View {
        ZStack {
            ScreenBackground()

            VStack(spacing: 0) {
                HStack {
                    Spacer()
                    Button("Skip") {
                        Haptics.shared.selection()
                        onFinish()
                    }
                    .font(AppFont.callout)
                    .foregroundColor(p.textSecondary)
                    .padding(.horizontal, 20)
                    .padding(.vertical, 12)
                }

                TabView(selection: $index) {
                    OnboardingPage1().tag(0)
                    OnboardingPage2().tag(1)
                    OnboardingPage3().tag(2)
                }
                .tabViewStyle(PageTabViewStyle(indexDisplayMode: .never))

                pageDots

                Button(index == pageCount - 1 ? "Start" : "Next") {
                    Haptics.shared.impact(.light)
                    if index == pageCount - 1 {
                        onFinish()
                    } else {
                        withAnimation(.spring(response: 0.4, dampingFraction: 0.8)) { index += 1 }
                    }
                }
                .buttonStyle(PrimaryButtonStyle())
                .padding(.horizontal, 24)
                .padding(.top, 6)
                .padding(.bottom, 28)
            }
        }
    }

    private var pageDots: some View {
        HStack(spacing: 8) {
            ForEach(0..<pageCount, id: \.self) { i in
                Capsule()
                    .fill(i == index ? p.accent : p.divider)
                    .frame(width: i == index ? 24 : 8, height: 8)
                    .animation(.spring(response: 0.4, dampingFraction: 0.7), value: index)
            }
        }
        .padding(.vertical, 12)
    }
}

// MARK: - Page 1: tap to burst

private struct BurstParticle: Identifiable {
    let id = UUID()
    let angle: Double
    let distance: CGFloat
    let size: CGFloat
}

private struct BurstParticleView: View {
    let particle: BurstParticle
    let color: Color
    @State private var go = false

    var body: some View {
        let radians = particle.angle * .pi / 180
        Circle()
            .fill(color)
            .frame(width: particle.size, height: particle.size)
            .offset(x: go ? cos(radians) * particle.distance : 0,
                    y: go ? sin(radians) * particle.distance : 0)
            .opacity(go ? 0 : 1)
            .onAppear { withAnimation(.easeOut(duration: 0.7)) { go = true } }
    }
}

private struct OnboardingPage1: View {
    @Environment(\.palette) private var p
    @State private var pulse = false
    @State private var particles: [BurstParticle] = []

    var body: some View {
        VStack(spacing: 26) {
            Spacer()
            ZStack {
                ForEach(particles) { particle in
                    BurstParticleView(particle: particle, color: p.cyanHi)
                }
                OrbView(scale: pulse ? 1.05 : 0.95, size: 168)
                    .onTapGesture { burst() }
            }
            .frame(height: 240)

            Text("Tap the orb")
                .font(AppFont.caption)
                .foregroundColor(p.textMuted)

            textBlock(title: "Understand the problem",
                      body: "Stress builds up through the day — often without you noticing.")
            Spacer()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.2).repeatForever(autoreverses: true)) { pulse = true }
        }
        .onDisappear {
            pulse = false
            particles = []
        }
    }

    private func burst() {
        Haptics.shared.impact(.medium)
        let new = (0..<12).map { i in
            BurstParticle(angle: Double(i) / 12 * 360,
                          distance: CGFloat.random(in: 92...140),
                          size: CGFloat.random(in: 6...12))
        }
        particles.append(contentsOf: new)
        let ids = Set(new.map { $0.id })
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.8) {
            particles.removeAll { ids.contains($0.id) }
        }
    }
}

// MARK: - Page 2: drag to expand

private struct OnboardingPage2: View {
    @Environment(\.palette) private var p
    @State private var pulse = false
    @State private var dragScale: CGFloat = 1

    var body: some View {
        VStack(spacing: 26) {
            Spacer()
            ZStack {
                Circle()
                    .stroke(p.accent.opacity(0.3), lineWidth: 1)
                    .frame(width: 250, height: 250)
                    .scaleEffect(dragScale)
                OrbView(scale: (pulse ? 1.03 : 0.97) * dragScale, size: 168)
            }
            .frame(height: 260)
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { value in
                        let magnitude = sqrt(value.translation.width * value.translation.width
                                             + value.translation.height * value.translation.height)
                        dragScale = 1 + min(magnitude / 260, 0.7)
                    }
                    .onEnded { _ in
                        Haptics.shared.impact(.light)
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.55)) { dragScale = 1 }
                    }
            )

            Text("Drag the orb")
                .font(AppFont.caption)
                .foregroundColor(p.textMuted)

            textBlock(title: "Build a habit",
                      body: "Keep your calm in one place — sessions, mood and streaks together.")
            Spacer()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.4).repeatForever(autoreverses: true)) { pulse = true }
        }
        .onDisappear { pulse = false; dragScale = 1 }
    }
}

// MARK: - Page 3: drag parallax

private struct OnboardingPage3: View {
    @Environment(\.palette) private var p
    @State private var pulse = false
    @State private var parallax: CGFloat = 0

    private let chips: [(String, CGFloat, CGFloat, CGFloat)] = [
        ("moon.zzz.fill", -110, -60, 0.05),
        ("face.smiling.fill", 120, -30, 0.12),
        ("bell.badge.fill", -90, 70, 0.18),
        ("chart.bar.fill", 100, 90, 0.1)
    ]

    var body: some View {
        VStack(spacing: 26) {
            Spacer()
            ZStack {
                ForEach(0..<chips.count, id: \.self) { i in
                    let chip = chips[i]
                    floatingChip(icon: chip.0)
                        .offset(x: chip.1 + parallax * chip.3, y: chip.2)
                }
                OrbView(scale: pulse ? 1.04 : 0.96, size: 150)
                    .offset(x: parallax * 0.22)
            }
            .frame(height: 260)
            .contentShape(Rectangle())
            .gesture(
                DragGesture()
                    .onChanged { parallax = $0.translation.width }
                    .onEnded { _ in
                        Haptics.shared.selection()
                        withAnimation(.spring(response: 0.5, dampingFraction: 0.7)) { parallax = 0 }
                    }
            )

            Text("Drag to look around")
                .font(AppFont.caption)
                .foregroundColor(p.textMuted)

            textBlock(title: "Feel the change",
                      body: "Use sessions, mood and gentle reminders to feel calmer over time.")
            Spacer()
        }
        .onAppear {
            withAnimation(.easeInOut(duration: 2.6).repeatForever(autoreverses: true)) { pulse = true }
        }
        .onDisappear { pulse = false; parallax = 0 }
    }

    private func floatingChip(icon: String) -> some View {
        ZStack {
            Circle().fill(p.card).frame(width: 54, height: 54)
            Circle().stroke(p.divider, lineWidth: 1).frame(width: 54, height: 54)
            Image(systemName: icon)
                .font(.system(size: 22, weight: .semibold))
                .foregroundColor(p.accentHi)
        }
        .shadow(color: p.shadow, radius: 10, x: 0, y: 6)
    }
}

// MARK: - Shared text block

private func textBlock(title: String, body: String) -> some View {
    TextBlock(title: title, message: body)
}

private struct TextBlock: View {
    @Environment(\.palette) private var p
    let title: String
    let message: String

    var body: some View {
        VStack(spacing: 10) {
            Text(title)
                .font(AppFont.rounded(24, .bold))
                .foregroundColor(p.textPrimary)
                .multilineTextAlignment(.center)
            Text(message)
                .font(AppFont.body)
                .foregroundColor(p.textSecondary)
                .multilineTextAlignment(.center)
        }
        .padding(.horizontal, 32)
    }
}
