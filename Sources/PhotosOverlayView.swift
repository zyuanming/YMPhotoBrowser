

import UIKit

class PhotosOverlayView: UIView {
    private(set) var navigationBar: UINavigationBar!
    private var closeButton: UIButton?
    private(set) var navigationItem: UINavigationItem!
    weak var photosViewController: PhotosViewController?
    private var currentPhoto: PhotoViewable?

    var leftBarButtonItem: UIBarButtonItem? {
        didSet {
            navigationItem.leftBarButtonItem = leftBarButtonItem
        }
    }
    var rightBarButtonItem: UIBarButtonItem? {
        didSet {
            navigationItem.rightBarButtonItem = rightBarButtonItem
        }
    }
    var titleTextAttributes: [NSAttributedStringKey : Any] = [:] {
        didSet {
            navigationBar.titleTextAttributes = titleTextAttributes
        }
    }

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupNavigationBar()
        setupCaptionLabel()
    }

    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }

    // Pass the touches down to other views
    override func hitTest(_ point: CGPoint, with event: UIEvent?) -> UIView? {
        if let hitView = super.hitTest(point, with: event) , hitView != self {
            return hitView
        }
        return nil
    }

    func setHidden(_ hidden: Bool, animated: Bool) {
        if self.isHidden == hidden {
            return
        }

        if animated {
            self.isHidden = false
            self.alpha = hidden ? 1.0 : 0.0

            UIView.animate(withDuration: 0.3, delay: 0.0, options: [.allowAnimatedContent, .allowUserInteraction], animations: { () -> Void in
                self.alpha = hidden ? 0.0 : 1.0
            }, completion: { result in
                self.alpha = 1.0
                self.isHidden = hidden
            })
        } else {
            self.isHidden = hidden
        }
    }

    func populateWithPhoto(_ photo: PhotoViewable) {
        self.currentPhoto = photo

        if let photosViewController = photosViewController {
            if let index = photosViewController.dataSource.indexOfPhoto(photo) {
                let indexString = "\(index+1)/\(photosViewController.dataSource.numberOfPhotos)"
                let title = NSAttributedString(string: indexString,
                                               attributes: [
                                                NSAttributedStringKey.font: UIFont.systemFont(ofSize: 15),
                                                NSAttributedStringKey.foregroundColor: UIColor.white])
                closeButton?.setAttributedTitle(title, for: .normal)
            }
        }
    }

    @objc private func closeButtonTapped(_ sender: UIBarButtonItem) {
        photosViewController?.dismiss(animated: true, completion: nil)
    }

    private func setupNavigationBar() {
        navigationBar = UINavigationBar()
        navigationBar.translatesAutoresizingMaskIntoConstraints = false
        navigationBar.backgroundColor = UIColor.clear
        navigationBar.barTintColor = nil
        navigationBar.isTranslucent = true
        navigationBar.shadowImage = UIImage()
        navigationBar.setBackgroundImage(UIImage(), for: .default)

        navigationItem = UINavigationItem(title: "")
        navigationBar.items = [navigationItem]
        addSubview(navigationBar)

        let topConstraint = NSLayoutConstraint(item: navigationBar, attribute: .top, relatedBy: .equal, toItem: self, attribute: .top, multiplier: 1.0, constant: 0.0)
        let widthConstraint = NSLayoutConstraint(item: navigationBar, attribute: .width, relatedBy: .equal, toItem: self, attribute: .width, multiplier: 1.0, constant: 0.0)
        let horizontalPositionConstraint = NSLayoutConstraint(item: navigationBar, attribute: .centerX, relatedBy: .equal, toItem: self, attribute: .centerX, multiplier: 1.0, constant: 0.0)
        self.addConstraints([topConstraint,widthConstraint,horizontalPositionConstraint])


        let rightButton = UIButton(frame: CGRect(x: 0, y: 0, width: 84, height: 30))
        rightButton.setBackgroundImage(UIImage(named: "photo_dismiss"), for: .normal)
        rightButton.titleEdgeInsets = UIEdgeInsets(top: 0, left: 0, bottom: 0, right: 21)
        rightButton.addTarget(self, action: #selector(closeButtonTapped(_:)), for: .touchUpInside)
        rightBarButtonItem = UIBarButtonItem(customView: rightButton)
        closeButton = rightButton
    }

    private func setupCaptionLabel() {

    }

}






