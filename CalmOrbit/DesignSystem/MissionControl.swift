import Foundation
import AppsFlyerLib

actor MissionControl {

    private var telemetry = Telemetry()
    private var primed = false
    private var docked = false
    private var engaged = false

    private let console: Console
    private let beam: AsyncStream<Signal>.Continuation

    nonisolated let signals: AsyncStream<Signal>

    init(console: Console) {
        self.console = console
        var captured: AsyncStream<Signal>.Continuation!
        self.signals = AsyncStream<Signal>(bufferingPolicy: .unbounded) { captured = $0 }
        self.beam = captured
    }

    private func ensurePrimed() {
        guard !primed else { return }
        telemetry = Telemetry.restore(from: console.blackBox.read())
        primed = true
    }

    func warmUp() {
        ensurePrimed()
    }

    func lockOn(_ raw: [String: Any]) {
        ensurePrimed()
        telemetry.fix = raw.mapValues { "\($0)" }
        console.blackBox.write(telemetry.snapshot())
    }

    func relayEchoes(_ raw: [String: Any]) {
        ensurePrimed()
        telemetry.echoes = raw.mapValues { "\($0)" }
        console.blackBox.write(telemetry.snapshot())
    }

    func engage() async {
        ensurePrimed()
        guard !docked, !engaged else { return }
        engaged = true
        defer { engaged = false }

        if let pushURL = UserDefaults.standard.string(forKey: OrbitKey.pushURL), !pushURL.isEmpty {
            settle(routingTo: pushURL)
            return
        }

        guard telemetry.locked else {
            beam.yield(.coasting)
            return
        }

        await replayOrbitIfNeeded()

        guard !docked else { return }

        guard telemetry.locked else {
            beam.yield(.coasting)
            return
        }

        do {
            let url = try await console.downlink.transmit(packet: telemetry.fix.mapValues { $0 as Any })
            settle(routingTo: url)
        } catch {
            tumble()
        }
    }

    private func replayOrbitIfNeeded() async {
        guard telemetry.organicDrift, telemetry.parked, !telemetry.replayed else { return }

        telemetry.replayed = true
        console.blackBox.write(telemetry.snapshot())

        try? await Task.sleep(nanoseconds: 5_000_000_000)

        guard !docked else { return }

        let deviceID = AppsFlyerLib.shared().getAppsFlyerUID()
        do {
            var fetched = try await console.sextant.fix(deviceID: deviceID)
            for (k, v) in telemetry.echoes {
                if fetched[k] == nil { fetched[k] = v }
            }
            telemetry.fix = fetched.mapValues { "\($0)" }
            console.blackBox.write(telemetry.snapshot())
        } catch {
            print("\(Orbit.logSat) Orbit replay soft fail: \(error)")
        }
    }

    private func settle(routingTo url: String) {
        guard !docked else { return }
        let needsAirlock = telemetry.airlockDue

        telemetry.routeURL = url
        telemetry.routeMode = "Active"
        telemetry.parked = false
        docked = true

        console.blackBox.write(telemetry.snapshot())
        console.blackBox.brandRoute(url: url, mode: "Active")
        console.blackBox.raisePrimedFlag()
        UserDefaults.standard.removeObject(forKey: OrbitKey.pushURL)

        beam.yield(needsAirlock ? .hailConsent : .dock)
    }

    private func tumble() {
        guard !docked else { return }
        docked = true
        beam.yield(.tumble)
    }

    func openAirlock() async {
        ensurePrimed()
        let granted = await console.airlock.request()

        telemetry.consentLatched = granted
        telemetry.consentScrubbed = !granted
        telemetry.consentMarkedAt = Date()
        console.blackBox.write(telemetry.snapshot())

        if granted {
            console.airlock.armUplink()
        }

        beam.yield(.dock)
    }

    func deferAirlock() {
        ensurePrimed()
        telemetry.consentMarkedAt = Date()
        console.blackBox.write(telemetry.snapshot())
        beam.yield(.dock)
    }

    func abortDeadline() -> Bool {
        guard !docked else { return false }
        docked = true
        return true
    }
}
