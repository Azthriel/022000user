import CoreLocation
import Flutter
import UIKit
import UserNotifications
import Firebase

@main
@objc class AppDelegate: FlutterAppDelegate { // Eliminada conformidad redundante
    private let CHANNEL = "com.biocalden.smartlife.sime/native"

    var deviceToken: Data?

    override func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {

        // Inicializar Firebase
        FirebaseApp.configure()

        // Solicitar permisos de notificación
        UNUserNotificationCenter.current().delegate = self
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { (granted, error) in
            if granted {
                DispatchQueue.main.async {
                    application.registerForRemoteNotifications()
                }
            }
        }

        let flutterViewController = window?.rootViewController as! FlutterViewController
        let methodChannel = FlutterMethodChannel(
            name: CHANNEL,
            binaryMessenger: flutterViewController.binaryMessenger)

        methodChannel.setMethodCallHandler {
            [weak self] (call: FlutterMethodCall, result: @escaping FlutterResult) in
            switch call.method {
            case "isLocationServiceEnabled":
                result(CLLocationManager.locationServicesEnabled())
            case "openLocationSettings":
                if let url = URL(string: UIApplication.openSettingsURLString) {
                    UIApplication.shared.open(url, options: [:], completionHandler: nil)
                }
                result(nil)
            case "onTokenReceived":
                if let deviceToken = self?.deviceToken {
                    let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
                    result(token)
                } else {
                    result(FlutterError(code: "UNAVAILABLE", message: "Device token is not available", details: nil))
                }
            default:
                result(FlutterMethodNotImplemented)
            }
        }

        GeneratedPluginRegistrant.register(with: self)
        return super.application(application, didFinishLaunchingWithOptions: launchOptions)
    }

    override func application(_ application: UIApplication, didRegisterForRemoteNotificationsWithDeviceToken deviceToken: Data) {
        self.deviceToken = deviceToken
        // Convertir el token a una cadena
        let token = deviceToken.map { String(format: "%02.2hhx", $0) }.joined()
        print("Device Token: \(token)")

        // Enviar el token a Flutter
        if let flutterViewController = window?.rootViewController as? FlutterViewController {
            let methodChannel = FlutterMethodChannel(name: CHANNEL, binaryMessenger: flutterViewController.binaryMessenger)
            methodChannel.invokeMethod("onTokenReceived", arguments: token)
        }
    }

    override func application(_ application: UIApplication, didFailToRegisterForRemoteNotificationsWithError error: Error) {
        print("Failed to register for remote notifications: \(error.localizedDescription)")
    }

    // Manejo de notificaciones en primer plano
    override func userNotificationCenter(_ center: UNUserNotificationCenter,
                                willPresent notification: UNNotification,
                                withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void) {
        completionHandler([.alert, .sound]) // Mostrar la notificación incluso si la app está en primer plano
    }

    // Manejo de notificaciones cuando se interactúa con ellas
    override func userNotificationCenter(_ center: UNUserNotificationCenter,
                                didReceive response: UNNotificationResponse,
                                withCompletionHandler completionHandler: @escaping () -> Void) {
        let userInfo = response.notification.request.content.userInfo
        // Aquí puedes manejar los datos de la notificación si es necesario
        completionHandler()
    }
}
