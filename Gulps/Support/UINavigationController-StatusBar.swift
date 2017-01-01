import UIKit


extension UINavigationController {
  open override var preferredStatusBarStyle : UIStatusBarStyle {
    return .lightContent
  }

  open override var childViewControllerForStatusBarHidden : UIViewController? {
    return self.topViewController
  }
}
