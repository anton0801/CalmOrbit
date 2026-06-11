//
//  BreatheView.swift
//  CalmOrbit
//
//  The main breathing screen. A living orb grows on the inhale and shrinks on
//  the exhale, a ring tracks the current phase, and bubbles drift behind it.
//  Ending (or completing) a session opens the save sheet.
//

import SwiftUI

struct BreatheView: View {
    @EnvironmentObject private var store: DataStore
    @Environment(\.palette) private var p

    @StateObject private var vm = BreatheViewModel(pattern: BreatheView.defaultPattern)

    @State private var configured = false
    @State private var showPicker = false
    @State private var showComplete = false
    @State private var completeMinutes = 0.0
    @State private var completeCycles = 0
    @State private var completePattern: BreathingPattern?

    static let defaultPattern = BreathingPattern(name: "Box Breathing", inhale: 4, hold: 4,
                                                 exhale: 4, holdAfterExhale: 4, cycles: 6)

    var body: some View {
        ZStack {
            ScreenBackground()
            BubblesBackground(count: 16, isActive: true)

            VStack(spacing: 0) {
                header
                Spacer(minLength: 8)
                orbArea
                Spacer(minLength: 8)
                infoRow
                Spacer(minLength: 12)
                controls
                Color.clear.frame(height: kTabBarInset - 30)
            }
        }
        .onAppear { configureIfNeeded() }
        .onDisappear { vm.reset() }
        .onChange(of: vm.finished) { finished in
            if finished { presentCompletion() }
        }
        .sheet(isPresented: $showPicker) {
            PatternPickerView(selectedID: vm.pattern.id) { pattern in
                vm.setPattern(pattern)
                store.lastPatternID = pattern.id
            }
            .environmentObject(store)
            .environment(\.palette, p)
        }
        .sheet(isPresented: $showComplete, onDismiss: { vm.reset() }) {
            SessionCompleteView(minutes: completeMinutes,
                                cycles: completeCycles,
                                pattern: completePattern)
                .environmentObject(store)
                .environment(\.palette, p)
        }
    }

    // MARK: Header

    private var header: some View {
        HStack {
            VStack(alignment: .leading, spacing: 2) {
                Text("Breathe")
                    .font(AppFont.rounded(26, .bold))
                    .foregroundColor(p.textPrimary)
                Text(vm.pattern.name)
                    .font(AppFont.subhead)
                    .foregroundColor(p.textSecondary)
            }
            Spacer()
            Button {
                Haptics.shared.selection()
                showPicker = true
            } label: {
                HStack(spacing: 6) {
                    Image(systemName: "slider.horizontal.3")
                    Text("Pattern")
                }
                .font(AppFont.subhead)
                .foregroundColor(p.accentHi)
                .padding(.vertical, 9)
                .padding(.horizontal, 14)
                .background(Capsule().fill(p.card))
                .overlay(Capsule().stroke(p.divider, lineWidth: 1))
            }
            .buttonStyle(PressableStyle())
        }
        .padding(.horizontal, 20)
        .padding(.top, 8)
    }

    // MARK: Orb

    private var orbArea: some View {
        ZStack {
            // Phase ring
            Circle()
                .stroke(p.divider.opacity(0.5), lineWidth: 6)
                .frame(width: 300, height: 300)
            Circle()
                .trim(from: 0, to: CGFloat(vm.phaseProgress))
                .stroke(phaseColor, style: StrokeStyle(lineWidth: 6, lineCap: .round))
                .frame(width: 300, height: 300)
                .rotationEffect(.degrees(-90))

            OrbView(scale: vm.orbScale, intensity: vm.isRunning ? 1 : 0.65, size: 250)

            VStack(spacing: 6) {
                Text(vm.phase.title)
                    .font(AppFont.rounded(24, .bold))
                    .foregroundColor(.white)
                if vm.isRunning {
                    Text("\(vm.phaseRemaining)")
                        .font(AppFont.rounded(40, .heavy))
                        .foregroundColor(.white)
                } else if vm.finished {
                    Text("Done")
                        .font(AppFont.rounded(18, .semibold))
                        .foregroundColor(.white.opacity(0.85))
                } else {
                    Text("Tap start")
                        .font(AppFont.rounded(15, .medium))
                        .foregroundColor(.white.opacity(0.8))
                }
            }
        }
    }

    private var phaseColor: Color {
        switch vm.phase {
        case .inhale:           return p.accentHi
        case .hold, .holdAfter: return p.indigoSoft
        case .exhale:           return p.cyan
        case .idle:             return p.accentHi
        }
    }

    // MARK: Info

    private var infoRow: some View {
        HStack(spacing: 14) {
            infoPill(icon: "repeat", value: "\(min(vm.cycleIndex + (vm.isRunning ? 1 : 0), vm.totalCycles))/\(vm.totalCycles)", label: "Cycle")
            infoPill(icon: "clock", value: vm.elapsedText, label: "Elapsed")
            infoPill(icon: "wind", value: vm.pattern.ratioText, label: "Pattern")
        }
        .padding(.horizontal, 20)
    }

    private func infoPill(icon: String, value: String, label: String) -> some View {
        VStack(spacing: 4) {
            Image(systemName: icon)
                .font(.system(size: 14, weight: .semibold))
                .foregroundColor(p.accentHi)
            Text(value)
                .font(AppFont.rounded(16, .bold))
                .foregroundColor(p.textPrimary)
            Text(label)
                .font(AppFont.tiny)
                .foregroundColor(p.textMuted)
        }
        .frame(maxWidth: .infinity)
        .padding(.vertical, 12)
        .background(RoundedRectangle(cornerRadius: 16, style: .continuous).fill(p.card))
        .overlay(RoundedRectangle(cornerRadius: 16, style: .continuous).stroke(p.divider, lineWidth: 1))
    }

    // MARK: Controls

    private var controls: some View {
        VStack(spacing: 12) {
            Button(startLabel) {
                Haptics.shared.impact(.medium)
                vm.startPause()
            }
            .buttonStyle(PrimaryButtonStyle())
            .padding(.horizontal, 20)

            HStack(spacing: 12) {
                Button {
                    Haptics.shared.selection()
                    showPicker = true
                } label: {
                    Label("Change Pattern", systemImage: "arrow.triangle.2.circlepath")
                }
                .buttonStyle(SecondaryButtonStyle())

                Button {
                    Haptics.shared.impact(.rigid)
                    endSession()
                } label: {
                    Label("End", systemImage: "stop.fill")
                }
                .buttonStyle(SecondaryButtonStyle())
            }
            .padding(.horizontal, 20)
        }
    }

    private var startLabel: String {
        if vm.isRunning { return "Pause" }
        if vm.finished { return "Breathe Again" }
        if vm.elapsed > 0 { return "Resume" }
        return "Start"
    }

    // MARK: Logic

    private func configureIfNeeded() {
        guard !configured else { return }
        configured = true
        let pattern = store.pattern(store.lastPatternID)
            ?? store.suggestedPattern
            ?? store.activePatterns.first
            ?? BreatheView.defaultPattern
        vm.setPattern(pattern)
    }

    private func endSession() {
        let minutes = vm.minutesElapsed
        let cycles = vm.cycleIndex
        vm.pause()
        if minutes >= 0.08 {
            completeMinutes = minutes
            completeCycles = cycles
            completePattern = vm.pattern
            showComplete = true
        } else {
            vm.reset()
        }
    }

    private func presentCompletion() {
        completeMinutes = vm.minutesElapsed
        completeCycles = vm.cycleIndex
        completePattern = vm.pattern
        showComplete = true
    }
}
