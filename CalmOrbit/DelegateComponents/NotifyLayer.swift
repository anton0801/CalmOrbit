import Foundation
import SwiftUI

final class NotifyLayer: BootShell {
    private weak var host: AppDelegate?
    init(_ inner: BootLayer, host: AppDelegate) {
        self.host = host
        super.init(inner)
    }
    override func boot() {
        UNUserNotificationCenter.current().delegate = host
        super.boot()
    }
}
