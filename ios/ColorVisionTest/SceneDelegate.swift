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
        win.makeKeyAndVisible()
        self.window = win
    }
}
