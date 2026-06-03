import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {

    var window: UIWindow?

    func scene(_ scene: UIScene, willConnectTo session: UISceneSession, options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = (scene as? UIWindowScene) else { return }

        // Check for either userToken or userLoginToken
        if let userToken = UserDefaults.standard.value(forKey: "userToken") as? String {
            print("UserToken: \(userToken)")
            sendLogData(log: "user logged in successfully with userToken will navigate to home screen")
            navigateToHome(windowScene: windowScene)
            
        } else if let userLoginToken = UserDefaults.standard.value(forKey: "userLoginToken") as? String {
            print("UserLoginToken: \(userLoginToken)")
            sendLogData(log: "user logged in successfully with UserLoginToken will navigate to home screen")
            navigateToHome(windowScene: windowScene)
        } else {
            print("No user token found. Staying on login screen or other.")
        }
    }

    // Function to navigate to HomeScreenVC
    private func navigateToHome(windowScene: UIWindowScene) {
        // Initialize the storyboard and view controller
        let storyboard = UIStoryboard(name: "HomeSC", bundle: Bundle.main)
        let vc = storyboard.instantiateViewController(withIdentifier: "HomeScreenVC")

        // Create a navigation controller with the HomeScreenVC
        let navVC = UINavigationController(rootViewController: vc)

        // Set the navigation controller as the rootViewController
        window = UIWindow(windowScene: windowScene)
        window?.rootViewController = navVC
        window?.makeKeyAndVisible()
    }
    /*
     i want to log data for whatever happening in my app so i need structure
     */
    // MARK: UIScene Lifecycle Methods (optional implementations)

    func sceneDidDisconnect(_ scene: UIScene) {
        // Called as the scene is being released by the system.
    }

    func sceneDidBecomeActive(_ scene: UIScene) {
        // Called when the scene has moved from an inactive state to an active state.
    }

    func sceneWillResignActive(_ scene: UIScene) {
        // Called when the scene will move from active to inactive.
    }

    func sceneWillEnterForeground(_ scene: UIScene) {
        // Called as the scene transitions from the background to the foreground.
    }

    func sceneDidEnterBackground(_ scene: UIScene) {
        // Called as the scene transitions from the foreground to the background.
    }
}

extension SceneDelegate {
    private func sendLogData(log: String) {
        LogManager.shared.addLog(data: log)
        LogManager.shared.sendLogsToServer() { result in
            switch result {
                case .success(let value):
                print("Successfully sent log data: \(value)")
            case .failure(let error):
                print("Error sending log data: \(error)")
            }
        }
    }
}
