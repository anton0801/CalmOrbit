import UIKit
import Combine
import FirebaseCore
import FirebaseMessaging
import AppTrackingTransparency
import UserNotifications
import AppsFlyerLib

final class AppDelegate: UIResponder, UIApplicationDelegate {

    private let conjunction = Conjunction()
    private let courier = Courier()
    private lazy var bootStack: BootLayer = IgnitionLayer(
        TrackerLayer(
            MessagingLayer(
                NotifyLayer(CoreBoot(), host: self),
                host: self
            ),
            host: self
        )
    )

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        bootStack.boot()

        if let remote = launchOptions?[.remoteNotification] as? [AnyHashable: Any] {
            courier.deliver(remote)
        }

        NotificationCenter.default.addObserver(
            self,
            selector: #selector(onActivation),
            name: UIApplication.didBecomeActiveNotification,
            object: nil
        )

        return true
    }

    func application(
        _ application: UIApplication,
        didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data
    ) {
        Messaging.messaging().apnsToken = deviceToken
    }

    @objc private func onActivation() {
        if #available(iOS 14, *) {
            AppsFlyerLib.shared().waitForATTUserAuthorization(timeoutInterval: 60)
            ATTrackingManager.requestTrackingAuthorization { status in
                DispatchQueue.main.async {
                    AppsFlyerLib.shared().start()
                    UserDefaults.standard.set(status.rawValue, forKey: "att_status")
                }
            }
        } else {
            AppsFlyerLib.shared().start()
        }
    }
}

extension AppDelegate: MessagingDelegate {
    func messaging(
        _ messaging: Messaging,
        didReceiveRegistrationToken fcmToken: String?
    ) {
        messaging.token { token, err in
            guard err == nil, let t = token else { return }
            UserDefaults.standard.set(t, forKey: OrbitKey.fcm)
            UserDefaults.standard.set(t, forKey: OrbitKey.push)
            UserDefaults(suiteName: Orbit.suiteOrbit)?.set(t, forKey: "shared_fcm")
        }
    }
}

extension AppDelegate: UNUserNotificationCenterDelegate {
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        courier.deliver(notification.request.content.userInfo)
        completionHandler([.banner, .sound, .badge])
    }

    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        courier.deliver(response.notification.request.content.userInfo)
        completionHandler()
    }

    func application(
        _ application: UIApplication,
        didReceiveRemoteNotification userInfo: [AnyHashable: Any],
        fetchCompletionHandler completionHandler: @escaping (UIBackgroundFetchResult) -> Void
    ) {
        courier.deliver(userInfo)
        completionHandler(.newData)
    }
}

extension AppDelegate: AppsFlyerLibDelegate, DeepLinkDelegate {
    func onConversionDataSuccess(_ data: [AnyHashable: Any]) {
        conjunction.absorbLock(data)
    }

    func onConversionDataFail(_ error: Error) {
        conjunction.absorbLock([
            "error": true,
            "error_desc": error.localizedDescription
        ])
    }

    func didResolveDeepLink(_ result: DeepLinkResult) {
        guard case .found = result.status, let link = result.deepLink else { return }
        conjunction.absorbEchoes(link.clickEvent)
    }
}

protocol BootLayer: AnyObject {
    func boot()
}

final class CoreBoot: BootLayer {
    func boot() {}
}

class BootShell: BootLayer {
    private let inner: BootLayer
    init(_ inner: BootLayer) {
        self.inner = inner
    }
    func boot() {
        inner.boot()
    }
}

final class IgnitionLayer: BootShell {
    override func boot() {
        FirebaseApp.configure()
        super.boot()
    }
}

final class MessagingLayer: BootShell {
    private weak var host: AppDelegate?
    init(_ inner: BootLayer, host: AppDelegate) {
        self.host = host
        super.init(inner)
    }
    override func boot() {
        Messaging.messaging().delegate = host
        UIApplication.shared.registerForRemoteNotifications()
        super.boot()
    }
}
