import Foundation
import Combine

final class Conjunction {

    private var lockBuffer: [AnyHashable: Any] = [:]
    private var echoBuffer: [AnyHashable: Any] = [:]
    private var fuseCancellable: AnyCancellable?

    func absorbLock(_ data: [AnyHashable: Any]) {
        lockBuffer = data
        scheduleAlign()
        if !echoBuffer.isEmpty { align() }
    }

    func absorbEchoes(_ data: [AnyHashable: Any]) {
        guard !UserDefaults.standard.bool(forKey: OrbitKey.primed) else { return }
        echoBuffer = data
        NotificationCenter.default.post(
            name: .echoesArrived,
            object: nil,
            userInfo: ["deeplinksData": data]
        )
        fuseCancellable?.cancel()
        if !lockBuffer.isEmpty { align() }
    }

    private func scheduleAlign() {
        fuseCancellable?.cancel()
        fuseCancellable = Just(())
            .delay(for: .seconds(2.5), scheduler: DispatchQueue.main)
            .sink { [weak self] in self?.align() }
    }

    private func align() {
        fuseCancellable?.cancel()
        fuseCancellable = nil

        var merged = lockBuffer
        for (k, v) in echoBuffer {
            let tag = "deep_\(k)"
            if merged[tag] == nil { merged[tag] = v }
        }

        NotificationCenter.default.post(
            name: .lockArrived,
            object: nil,
            userInfo: ["conversionData": merged]
        )
    }
}
