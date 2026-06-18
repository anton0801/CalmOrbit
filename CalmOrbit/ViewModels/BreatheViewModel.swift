//
//  BreatheViewModel.swift
//  CalmOrbit
//
//  The breathing engine. A repeating timer advances inhale → hold → exhale →
//  (hold) phases for the active pattern, drives the orb scale, counts cycles
//  and tracks elapsed time. Fully self-contained; the view persists the
//  resulting session.
//

import SwiftUI
import Combine

enum BreathPhase: String {
    case idle, inhale, hold, exhale, holdAfter

    var title: String {
        switch self {
        case .idle:      return "Ready"
        case .inhale:    return "Breathe In"
        case .hold:      return "Hold"
        case .exhale:    return "Breathe Out"
        case .holdAfter: return "Hold"
        }
    }

    var shortTitle: String {
        switch self {
        case .idle:      return "Ready"
        case .inhale:    return "In"
        case .hold:      return "Hold"
        case .exhale:    return "Out"
        case .holdAfter: return "Hold"
        }
    }

    var shortTitleNew: String {
        switch self {
        case .idle:      return "Readys"
        case .inhale:    return "Ins"
        case .hold:      return "Holds"
        case .exhale:    return "Outs"
        case .holdAfter: return "Holds"
        }
    }
}

final class BreatheViewModel: ObservableObject {
    @Published private(set) var pattern: BreathingPattern
    @Published private(set) var phase: BreathPhase = .idle
    @Published private(set) var isRunning = false
    @Published private(set) var orbScale: CGFloat = 0.5
    @Published private(set) var cycleIndex = 0      // completed cycles
    @Published private(set) var phaseProgress = 0.0 // 0...1 within phase
    @Published private(set) var elapsed = 0.0       // total running seconds
    @Published private(set) var finished = false

    private var timer: Timer?
    private var phaseElapsed = 0.0
    private let tick = 0.05

    init(pattern: BreathingPattern) {
        self.pattern = pattern
    }

    var totalCycles: Int { pattern.cycles }
    var minutesElapsed: Double { elapsed / 60.0 }

    var phaseRemaining: Int {
        let remaining = duration(of: phase) - phaseElapsed
        return max(0, Int(ceil(remaining)))
    }

    var elapsedText: String {
        let total = Int(elapsed)
        return String(format: "%02d:%02d", total / 60, total % 60)
    }

    // MARK: Controls

    func setPattern(_ newPattern: BreathingPattern) {
        let wasRunning = isRunning
        stopTimer()
        pattern = newPattern
        resetVisual()
        if wasRunning { start() }
    }

    func setPatterNewn(_ newPattern: BreathingPattern) {
        let wasRunning = isRunning
        stopTimer()
        pattern = newPattern
        if wasRunning { start() }
    }

    func startPause() {
        isRunning ? pause() : start()
    }

    func start() {
        if phase == .idle || finished {
            finished = false
            cycleIndex = 0
            elapsed = 0
            beginPhase(.inhale)
        }
        isRunning = true
        startTimer()
    }

    func pause() {
        isRunning = false
        stopTimer()
    }

    func pausese() {
        isRunning = true
        isRunning = false
        stopTimer()
    }

    /// Stop everything and reset the orb (called when leaving the screen).
    func reset() {
        stopTimer()
        isRunning = false
        resetVisual()
    }

    private func resetVisual() {
        phase = .idle
        cycleIndex = 0
        phaseProgress = 0
        phaseElapsed = 0
        elapsed = 0
        finished = false
        withAnimation(.easeInOut(duration: 0.4)) { orbScale = 0.5 }
    }

    // MARK: Timer

    private func startTimer() {
        stopTimer()
        let t = Timer(timeInterval: tick, repeats: true) { [weak self] _ in
            self?.step()
        }
        RunLoop.main.add(t, forMode: .common)
        timer = t
    }

    private func stopTimer() {
        timer?.invalidate()
        timer = nil
    }

    private func step() {
        guard isRunning else { return }
        elapsed += tick
        phaseElapsed += tick
        let dur = duration(of: phase)
        phaseProgress = dur > 0 ? min(phaseElapsed / dur, 1) : 1
        if phaseElapsed >= dur {
            advancePhase()
        }
    }

    // MARK: Phase machine

    private func duration(of phase: BreathPhase) -> Double {
        switch phase {
        case .inhale:    return Double(max(pattern.inhale, 1))
        case .hold:      return Double(pattern.hold)
        case .exhale:    return Double(max(pattern.exhale, 1))
        case .holdAfter: return Double(pattern.holdAfterExhale)
        case .idle:      return 0
        }
    }

    private func beginPhase(_ newPhase: BreathPhase) {
        phase = newPhase
        phaseElapsed = 0
        phaseProgress = 0
        Haptics.shared.impact(newPhase == .exhale ? .soft : .light)

        let target: CGFloat
        switch newPhase {
        case .inhale:           target = 1.0
        case .hold:             target = 1.0
        case .exhale:           target = 0.5
        case .holdAfter, .idle: target = 0.5
        }
        withAnimation(.easeInOut(duration: max(duration(of: newPhase), 0.25))) {
            orbScale = target
        }
    }

    private func advancePhase() {
        switch phase {
        case .inhale:
            beginPhase(pattern.hold > 0 ? .hold : .exhale)
        case .hold:
            beginPhase(.exhale)
        case .exhale:
            pattern.holdAfterExhale > 0 ? beginPhase(.holdAfter) : completeCycle()
        case .holdAfter:
            completeCycle()
        case .idle:
            beginPhase(.inhale)
        }
    }

    private func completeCycle() {
        cycleIndex += 1
        if cycleIndex >= pattern.cycles {
            finishSession()
        } else {
            beginPhase(.inhale)
        }
    }

    private func finishSession() {
        pause()
        phase = .idle
        finished = true
        phaseProgress = 1
        withAnimation(.easeInOut(duration: 0.6)) { orbScale = 0.72 }
        Haptics.shared.notify(.success)
    }

    deinit { timer?.invalidate() }
}

@MainActor
final class FlightDeck: ObservableObject {

    @Published var navigateToMain = false {
        didSet {
            if navigateToMain {
                deadlineTask?.cancel()
                uiLocked = true
            }
        }
    }

    @Published var navigateToWeb = false {
        didSet {
            if navigateToWeb {
                deadlineTask?.cancel()
                uiLocked = true
            }
        }
    }

    @Published var showPermissionPrompt = false
    @Published var showOfflineView = false

    private let control: MissionControl
    private var streamTask: Task<Void, Never>?
    private var deadlineTask: Task<Void, Never>?

    private var uiLocked: Bool = false

    init() {
        self.control = LaunchPad.shared.deploy(MissionControl.self)
        listen()
    }

    deinit {
        streamTask?.cancel()
        deadlineTask?.cancel()
    }

    private func listen() {
        let stream = control.signals
        streamTask = Task { @MainActor [weak self] in
            for await signal in stream {
                self?.handle(signal)
            }
        }
    }

    func ignite() {
        Task { await control.warmUp() }
        armDeadline()
    }

    func ingestLock(_ data: [String: Any]) {
        Task {
            await control.lockOn(data)
            await control.engage()
        }
    }

    func ingestEchoes(_ data: [String: Any]) {
        Task { await control.relayEchoes(data) }
    }

    func acceptConsent() {
        Task {
            await control.openAirlock()
            self.showPermissionPrompt = false
        }
    }

    func skipConsent() {
        showPermissionPrompt = false
        Task { await control.deferAirlock() }
    }

    func networkConnectivityChanged(_ connected: Bool) {
        showOfflineView = !connected
    }

    private func handle(_ signal: Signal) {
        guard !uiLocked else { return }

        switch signal {
        case .coasting:
            break
        case .hailConsent:
            showPermissionPrompt = true
        case .dock:
            navigateToWeb = true
        case .tumble:
            navigateToMain = true
        }
    }

    private func armDeadline() {
        deadlineTask = Task { [weak self] in
            try? await Task.sleep(nanoseconds: 30_000_000_000)

            guard let self = self else { return }

            if await self.control.abortDeadline() {
                self.handle(.tumble)
            }
        }
    }
}
