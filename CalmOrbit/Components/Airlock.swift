import Foundation
import UIKit
import UserNotifications

protocol Airlock {
    func request() async -> Bool
    func armUplink()
}

final class HatchAirlock: Airlock {

    func request() async -> Bool {
        await withCheckedContinuation { (continuation: CheckedContinuation<Bool, Never>) in
            let hatch = OneHatch()
            UNUserNotificationCenter.current().requestAuthorization(
                options: [.alert, .sound, .badge]
            ) { granted, error in
                if let error = error {
                    print("\(Orbit.logSat) Airlock error: \(error)")
                }
                DispatchQueue.main.async {
                    guard hatch.crack() else { return }
                    continuation.resume(returning: granted)
                }
            }
        }
    }

    func armUplink() {
        DispatchQueue.main.async {
            UIApplication.shared.registerForRemoteNotifications()
        }
    }
}

final class OneHatch {
    private var cracked = false
    private let lock = NSLock()

    func crack() -> Bool {
        lock.lock()
        defer { lock.unlock() }
        guard !cracked else { return false }
        cracked = true
        return true
    }
}
