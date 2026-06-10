import UIKit

final class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func scene(_ scene: UIScene,
               willConnectTo session: UISceneSession,
               options connectionOptions: UIScene.ConnectionOptions) {
        guard let windowScene = scene as? UIWindowScene else { return }

        let root = ContentViewController()
        let nav = UINavigationController(rootViewController: root)
        nav.setNavigationBarHidden(true, animated: false)

        let win = UIWindow(windowScene: windowScene)
        win.rootViewController = nav
        // The web app is permanently dark (#0d0d0d, forced by its own
        // CSS); pin the native sheets to match so Settings/History
        // don't flash a white UI inside a dark app.
        win.overrideUserInterfaceStyle = .dark
        win.makeKeyAndVisible()
        self.window = win
    }
}
