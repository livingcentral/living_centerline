import UIKit
import IQKeyboardManagerSwift
import UserNotifications
import CoreData

@main
class AppDelegate: UIResponder, UIApplicationDelegate, UNUserNotificationCenterDelegate {

    var window: UIWindow?
    let notificationCenter = UNUserNotificationCenter.current()

    func application(
        _ application: UIApplication,
        didFinishLaunchingWithOptions launchOptions: [UIApplication.LaunchOptionsKey: Any]?
    ) -> Bool {
        
        IQKeyboardManager.shared.enable = true
        IQKeyboardManager.shared.shouldResignOnTouchOutside = true
        IQKeyboardManager.shared.enableAutoToolbar = true
                
        //Confirm Delegete and request for permission
                notificationCenter.delegate = self
        UNUserNotificationCenter.current().delegate = self
                let options: UNAuthorizationOptions = [.alert, .sound, .badge]
                notificationCenter.requestAuthorization(options: options) {
                    (didAllow, error) in
                    if !didAllow {
                        print("User has declined notifications")
                    }
                }
        sendLogData(log: "app is opened")
    //    application.applicationIconBadgeNumber = 0
     //   UNUserNotificationCenter.current().removeAllDeliveredNotifications()
        // For iOS 13 and later, SceneDelegate will handle the window. For earlier versions, call the token check.
        if #available(iOS 13.0, *) {
            // Do nothing here; SceneDelegate will handle window and navigation
        } else {
            // Check for either user token or login token for iOS 12 and below
            checkUserToken()
        }
        return true
    }
    // Function to check for user token and navigate accordingly
    func checkUserToken() {
        if let userToken = UserDefaults.standard.value(forKey: "userToken") as? String {
            print("Documents Directory: ", FileManager.default.urls(for: .documentDirectory, in: .userDomainMask).last ?? "Not Found!")
            navigateToHome(token: userToken)
        } else {
            print("No valid user token or login token found. Staying on login screen.")
        }
    }
    
    func applicationDidEnterBackground(_ application: UIApplication) {
        sendLogData(log: "app Did Enter Background")

    }
    func applicationWillEnterForeground(_ application: UIApplication) {
        sendLogData(log: "app Will Enter Foreground")

    }
    
    func applicationWillTerminate(_ application: UIApplication) {
        sendLogData(log: "app will terminate")
    }
    
    // Function to navigate to HomeScreenVC if the token exists
    func navigateToHome(token: String) {
        print("UserToken: \(token)")

        let storyboard = UIStoryboard(name: "HomeSC", bundle: Bundle.main)
        let vc = storyboard.instantiateViewController(withIdentifier: "HomeScreenVC")
        let navVC = UINavigationController(rootViewController: vc)

        self.window = UIWindow(frame: UIScreen.main.bounds)
        self.window?.rootViewController = navVC
        self.window?.makeKeyAndVisible()
    }

    // MARK: UISceneSession Lifecycle (For iOS 13+)

    func application(
        _ application: UIApplication,
        configurationForConnecting connectingSceneSession: UISceneSession,
        options: UIScene.ConnectionOptions
    ) -> UISceneConfiguration {
        return UISceneConfiguration(name: "Default Configuration", sessionRole: connectingSceneSession.role)
    }

    func application(_ application: UIApplication, didDiscardSceneSessions sceneSessions: Set<UISceneSession>) {}
    
    // MARK: - Core Data stack

    lazy var persistentContainer: NSPersistentContainer = {
        /*
         The persistent container for the application. This implementation
         creates and returns a container, having loaded the store for the
         application to it. This property is optional since there are legitimate
         error conditions that could cause the creation of the store to fail.
        */
        let container = NSPersistentContainer(name: "HealthSyncModel")
        container.loadPersistentStores(completionHandler: { (storeDescription, error) in
            if let error = error as NSError? {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                 
                /*
                 Typical reasons for an error here include:
                 * The parent directory does not exist, cannot be created, or disallows writing.
                 * The persistent store is not accessible, due to permissions or data protection when the device is locked.
                 * The device is out of space.
                 * The store could not be migrated to the current model version.
                 Check the error message to determine what the actual problem was.
                 */
                fatalError("Unresolved error \(error), \(error.userInfo)")
            }
        })
        return container
    }()

}
extension UIApplication {
    func setRootVC(_ vc: UIViewController) {
        // Look for the first active window scene
        if let windowScene = UIApplication.shared.connectedScenes
            .filter({ $0.activationState == .foregroundActive })
            .first as? UIWindowScene {
            
            // Access the window in the active scene
            if let window = windowScene.windows.first {
                // Wrap the view controller in a navigation controller
                let navVC = UINavigationController(rootViewController: vc)
                window.rootViewController = navVC
                window.makeKeyAndVisible()
            }
        }
    }
}

// MARK: - Local Notification Methods Starts here

extension AppDelegate {
    func scheduleNotification(notificationType: String, notificationHour: Int, notificationMinute: Int) {
        let notificationCenter = UNUserNotificationCenter.current()

        // Compose the notification
        let content = UNMutableNotificationContent()
        let categoryIdentifier = "DailyNotificationCategory"
        // Old message
//        content.body = "Good Morning! Uploading your health data…"
        // New message
        content.title = "Please open the LCI app to upload your health data"
        content.sound = UNNotificationSound.default
        content.badge = 1
        content.categoryIdentifier = categoryIdentifier

        // Add an attachment if needed
        if notificationType == "Local Notification with Content" {
            let imageName = "app.img.appicon"
            guard let imageURL = Bundle.main.url(forResource: imageName, withExtension: "png") else { return }
            do {
                let attachment = try UNNotificationAttachment(identifier: imageName, url: imageURL, options: .none)
                content.attachments = [attachment]
            } catch {
                print("Attachment error: \(error.localizedDescription)")
            }
        }

        // Set the time for the notification (9:00 AM every day)
        var dateComponents = DateComponents()
//        dateComponents.hour = 09
//        dateComponents.minute = 00
        dateComponents.hour = notificationHour
        dateComponents.minute = notificationMinute
        // Create a calendar-based trigger
        let trigger = UNCalendarNotificationTrigger(dateMatching: dateComponents, repeats: true)

        // Define the request
        let identifier = "DailyMorningNotification"
        let request = UNNotificationRequest(identifier: identifier, content: content, trigger: trigger)

        // Schedule the notification
        notificationCenter.add(request) { error in
            if let error = error {
                print("Error scheduling notification: \(error.localizedDescription)")
            } else {
                print("Notification scheduled for \(notificationHour):\(notificationMinute) daily.")
            }
        }

        // Add actions if the type includes them
        if notificationType == "Local Notification with Action" {
            let snoozeAction = UNNotificationAction(identifier: "snooze", title: "open", options: [.foreground])
            let deleteAction = UNNotificationAction(identifier: "DeleteAction", title: "dismiss", options: [.destructive])
            let category = UNNotificationCategory(identifier: categoryIdentifier,
                                                  actions: [snoozeAction, deleteAction],
                                                  intentIdentifiers: [],
                                                  options: [])
            notificationCenter.setNotificationCategories([category])
        }
    }
    
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        willPresent notification: UNNotification,
        withCompletionHandler completionHandler: @escaping (UNNotificationPresentationOptions) -> Void
    ) {
        // Handle foreground presentation options
        print("Notification received in foreground: \(notification.request.content.body)")
        completionHandler([.sound, .badge])
    }
    func userNotificationCenter(
        _ center: UNUserNotificationCenter,
        didReceive response: UNNotificationResponse,
        withCompletionHandler completionHandler: @escaping () -> Void
    ) {
        // Handle user interaction with the notification
        switch response.actionIdentifier {
        case "snoozeAction":
            print("Snooze action tapped")
            // Add snooze handling logic here
            break
        default:
            print("Default action tapped")
            break
        }
        
        // Call completion handler to let the system know the response is handled
        completionHandler()
    }
}

// MARK: - Core Data Saving support

extension AppDelegate {
    func saveContext () {
        LogManager.shared.addLog(data: "saving core data eontext from app delegate")
        let context = persistentContainer.viewContext
        if context.hasChanges {
            do {
                try context.save()
            } catch {
                // Replace this implementation with code to handle the error appropriately.
                // fatalError() causes the application to generate a crash log and terminate. You should not use this function in a shipping application, although it may be useful during development.
                let nsError = error as NSError
                fatalError("Unresolved error \(nsError), \(nsError.userInfo)")
            }
        }
    }
}

// MARK: Send Log Data

extension AppDelegate {
    private func sendLogData(log: String) {
        LogManager.shared.addLog(data: log)
        LogManager.shared.sendLogsToServer() { result in
            switch result {
                case .success(let value):
                print("Successfully sent log data from app delegate: \(value)")
            case .failure(let error):
                print("Error sending log data from app delegate: \(error)")
            }
        }
    }
}
