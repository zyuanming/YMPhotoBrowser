
import UIKit

class PhotoNavigationController: UINavigationController, UIViewControllerTransitioningDelegate {
    private var statusBarHidden = true

    override init(nibName nibNameOrNil: String!, bundle nibBundleOrNil: Bundle!) {
        super.init(nibName: nil, bundle: nil)
    }

    override init(rootViewController: UIViewController) {
        super.init(rootViewController: rootViewController)

        initialSetupTransintion()
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    private func initialSetupTransintion() {
        if let delegate = viewControllers[0] as? UIViewControllerTransitioningDelegate {
            modalPresentationStyle = .custom
            transitioningDelegate = delegate
            modalPresentationCapturesStatusBarAppearance = true
        }

    }


    // MARK: - View Life Cycle

    override func viewDidLoad() {
        super.viewDidLoad()
    }

}

