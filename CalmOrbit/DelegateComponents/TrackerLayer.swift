import AppsFlyerLib
import Foundation

final class TrackerLayer: BootShell {
    private weak var host: AppDelegate?
    init(_ inner: BootLayer, host: AppDelegate) {
        self.host = host
        super.init(inner)
    }
    override func boot() {
        let sdk = AppsFlyerLib.shared()
        sdk.appsFlyerDevKey = Orbit.beaconKey
        sdk.appleAppID = Orbit.appCode
        sdk.delegate = host
        sdk.deepLinkDelegate = host
        sdk.isDebug = false
        super.boot()
    }
}
