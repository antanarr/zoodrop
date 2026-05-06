import UIKit

// This extension provides a clean, reusable way to find the root UIViewController.
extension UIViewController {
    static func findRootViewController() -> UIViewController? {
        UIApplication.shared.connectedScenes
            .compactMap { $0 as? UIWindowScene }
            .first?
            .windows
            .first(where: { $0.isKeyWindow })?
            .rootViewController
    }
}
