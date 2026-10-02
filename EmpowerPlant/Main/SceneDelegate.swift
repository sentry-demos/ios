import SentrySwift
import UIKit

class SceneDelegate: UIResponder, UIWindowSceneDelegate {
    var window: UIWindow?

    func sceneDidBecomeActive(_ scene: UIScene) {
        // SDK start runs before a scene is connected. showWidget() builds the
        // injected button on the first connected UIWindowScene. Later calls
        // only make that same button visible again.
        SentrySDK.feedback.showWidget()
    }
}
