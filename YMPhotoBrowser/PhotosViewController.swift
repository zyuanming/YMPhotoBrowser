

import UIKit

public typealias PhotosViewControllerReferenceViewHandler = (_ photo: PhotoViewable) -> (UIView?)
public typealias PhotosViewControllerNavigateToPhotoHandler = (_ photo: PhotoViewable) -> ()
public typealias PhotosViewControllerDismissHandler = (_ viewController: PhotosViewController) -> ()
public typealias PhotosViewControllerLongPressHandler = (_ photo: PhotoViewable, _ gestureRecognizer: UILongPressGestureRecognizer) -> (Bool)


public class PhotosViewController: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate, ImageBlurable {

    public var referenceViewForPhotoWhenDismissingHandler: PhotosViewControllerReferenceViewHandler?
    public var navigateToPhotoHandler: PhotosViewControllerNavigateToPhotoHandler?
    public var willDismissHandler: PhotosViewControllerDismissHandler?
    public var didDismissHandler: PhotosViewControllerDismissHandler?
    public var longPressGestureHandler: PhotosViewControllerLongPressHandler?
    var overlayView: PhotosOverlayView?
    var currentPhotoViewController: PhotoViewController? {
        return pageViewController.viewControllers?.first as? PhotoViewController
    }

    var currentPhoto: PhotoViewable? {
        return currentPhotoViewController?.photo
    }

    private(set) var pageViewController: UIPageViewController!
    private(set) var dataSource: PhotosDataSource
    
    private(set) lazy var singleTapGestureRecognizer: UITapGestureRecognizer = {
        return UITapGestureRecognizer(target: self, action: #selector(PhotosViewController.handleSingleTapGestureRecognizer(_:)))
    }()
    private(set) lazy var panGestureRecognizer: UIPanGestureRecognizer = {
        let gesture = UIPanGestureRecognizer(target: self, action: #selector(PhotosViewController.handlePanGestureRecognizer(_:)))
        gesture.maximumNumberOfTouches = 1

        return gesture
    }()
    
    private var statusBarHidden = false
    private var shouldHandleLongPressGesture = false

    let transitionDelegate = PhotoTransitionDelegate()
    
    
    // MARK: - Initialization
    
    deinit {
        pageViewController.delegate = nil
        pageViewController.dataSource = nil
    }
    
    required public init?(coder aDecoder: NSCoder) {
        dataSource = PhotosDataSource(photos: [])
        super.init(nibName: nil, bundle: nil)
        initialSetupWithInitialPhoto(nil)
    }
    
    override init(nibName nibNameOrNil: String!, bundle nibBundleOrNil: Bundle!) {
        dataSource = PhotosDataSource(photos: [])
        super.init(nibName: nil, bundle: nil)
        initialSetupWithInitialPhoto(nil)
    }

    public init(photos: [PhotoViewable], initialPhoto: PhotoViewable? = nil, referenceView: UIView? = nil) {
        dataSource = PhotosDataSource(photos: photos)
        super.init(nibName: nil, bundle: nil)
        initialSetupWithInitialPhoto(initialPhoto)
        transitionDelegate.transitionAnimator.startingView = referenceView
        transitionDelegate.transitionAnimator.photo = initialPhoto
        transitionDelegate.transitionAnimator.endingView = currentPhotoViewController?.scalingImageView.imageView
        overlayView = PhotosOverlayView(frame: CGRect.zero)
        overlayView?.photosViewController = self
    }

    
    // MARK: - View Life Cycle

    override public func viewDidLoad() {
        super.viewDidLoad()
        addBlurBackground()
        view.tintColor = UIColor.white
        view.backgroundColor = UIColor.black
        navigationController?.navigationBar.isHidden = true
        pageViewController.view.backgroundColor = UIColor.clear
        
        pageViewController.view.addGestureRecognizer(panGestureRecognizer)
        pageViewController.view.addGestureRecognizer(singleTapGestureRecognizer)
        
        addChildViewController(pageViewController)
        view.addSubview(pageViewController.view)
        pageViewController.view.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        pageViewController.didMove(toParentViewController: self)

        setupOverlayView()
    }

    override public func viewWillAppear(_ animated: Bool) {
        super.viewWillAppear(animated)
        statusBarHidden = true
        self.setNeedsStatusBarAppearanceUpdate()
        navigationController?.navigationBar.isHidden = true

    }

    override public func viewDidAppear(_ animated: Bool) {
        super.viewDidAppear(animated)
        overlayView?.setHidden(false, animated: true)
    }

    override public func viewWillDisappear(_ animated: Bool) {
        super.viewWillDisappear(animated)
        if !transitionDelegate.interactiveDismissal {
            navigationController?.navigationBar.isHidden = false
        }
    }
    
    
    // MARK: - View Controller Dismissal
    
    override public func dismiss(animated flag: Bool, completion: (() -> Void)?) {
        if presentedViewController != nil {
            super.dismiss(animated: flag, completion: completion)
            return
        }
        var startingView: UIView?
        if currentPhotoViewController?.scalingImageView.imageView.image != nil {
            startingView = currentPhotoViewController?.scalingImageView.imageView
        }
        transitionDelegate.transitionAnimator.startingView = startingView
        transitionDelegate.transitionAnimator.photo = currentPhoto

        if let currentPhoto = currentPhoto {
            transitionDelegate.transitionAnimator.endingView = referenceViewForPhotoWhenDismissingHandler?(currentPhoto)
        } else {
            transitionDelegate.transitionAnimator.endingView = nil
        }

        let overlayWasHiddenBeforeTransition = overlayView?.isHidden ?? false
        overlayView?.setHidden(true, animated: true)

        willDismissHandler?(self)

        super.dismiss(animated: flag) { () -> Void in
            let isStillOnscreen = self.view.window != nil
            if isStillOnscreen && !overlayWasHiddenBeforeTransition {
                self.overlayView?.setHidden(false, animated: true)
            }

            if !isStillOnscreen {
                self.didDismissHandler?(self)
            }
            completion?()
        }
    }
    
    
    // MARK: - UIResponder
    
    override public func copy(_ sender: Any?) {
        UIPasteboard.general.image = currentPhoto?.image ?? currentPhotoViewController?.scalingImageView.image
    }
    
    override public var canBecomeFirstResponder: Bool {
        return true
    }
    
    override public func canPerformAction(_ action: Selector, withSender sender: Any?) -> Bool {
        if let _ = currentPhoto?.image ?? currentPhotoViewController?.scalingImageView.image , shouldHandleLongPressGesture && action == #selector(NSObject.copy) {
            return true
        }
        return false
    }
    
    
    // MARK: - Status Bar
    
    override public var prefersStatusBarHidden: Bool {
        if let parentStatusBarHidden = presentingViewController?.prefersStatusBarHidden , parentStatusBarHidden == true {
            return parentStatusBarHidden
        }
        return statusBarHidden
    }
    
    override public var preferredStatusBarStyle: UIStatusBarStyle {
        return .default
    }
    
    override public var preferredStatusBarUpdateAnimation: UIStatusBarAnimation {
        return .fade
    }
}


// MARK: - Private Function

extension PhotosViewController {
    private func initialSetupWithInitialPhoto(_ initialPhoto: PhotoViewable? = nil) {
        setupPageViewControllerWithInitialPhoto(initialPhoto)
        modalPresentationStyle = .custom
        transitioningDelegate = transitionDelegate
        modalPresentationCapturesStatusBarAppearance = true
    }
    
    private func setupPageViewControllerWithInitialPhoto(_ initialPhoto: PhotoViewable? = nil) {
        pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: [UIPageViewControllerOptionInterPageSpacingKey: 16.0])
        pageViewController.view.backgroundColor = UIColor.clear
        pageViewController.delegate = self
        pageViewController.dataSource = self
        
        if let photo = initialPhoto , dataSource.containsPhoto(photo) {
            changeToPhoto(photo, animated: false)
        } else if let photo = dataSource.photos.first {
            changeToPhoto(photo, animated: false)
        }
    }
    
    private func setupOverlayView() {
        guard let overlayView = overlayView else { return }
        
        overlayView.photosViewController = self
        
        updateCurrentPhotosInformation()
        
        overlayView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        overlayView.frame = view.bounds
        view.addSubview(overlayView)
        overlayView.setHidden(true, animated: false)
    }
    
    
    
    private func updateCurrentPhotosInformation() {
        if let currentPhoto = currentPhoto {
            overlayView?.populateWithPhoto(currentPhoto)
        }
    }
    
    private func addBlurBackground() {
        if let photo = dataSource.photoAtIndex(0) {
            photo.loadThumbnailImageWithCompletionHandler({ [weak self] (image, _) in
                self?.addBlurBackgroundImage(image)
            })
        }
    }
    
    private func initializePhotoViewControllerForPhoto(_ photo: PhotoViewable) -> PhotoViewController {
        let photoViewController = PhotoViewController(photo: photo)
        singleTapGestureRecognizer.require(toFail: photoViewController.doubleTapGestureRecognizer)
        photoViewController.longPressGestureHandler = { [weak self] gesture in
            guard let weakSelf = self else {
                return
            }
            weakSelf.shouldHandleLongPressGesture = false
            
            if let gestureHandler = weakSelf.longPressGestureHandler {
                weakSelf.shouldHandleLongPressGesture = gestureHandler(photo, gesture)
            }
            weakSelf.shouldHandleLongPressGesture = !weakSelf.shouldHandleLongPressGesture
            
            if weakSelf.shouldHandleLongPressGesture {
                guard let view = gesture.view else {
                    return
                }
                let menuController = UIMenuController.shared
                var targetRect = CGRect.zero
                targetRect.origin = gesture.location(in: view)
                menuController.setTargetRect(targetRect, in: view)
                menuController.setMenuVisible(true, animated: true)
            }
        }
        return photoViewController
    }
}


// MARK: - Public Function

extension PhotosViewController {
    func changeToPhoto(_ photo: PhotoViewable, animated: Bool) {
        if !dataSource.containsPhoto(photo) {
            return
        }
        let photoViewController = initializePhotoViewControllerForPhoto(photo)
        pageViewController.setViewControllers([photoViewController], direction: .forward, animated: animated, completion: nil)
        updateCurrentPhotosInformation()
    }
}


// MARK: - Gesture Recognizers

extension PhotosViewController {
    @objc private func handlePanGestureRecognizer(_ gestureRecognizer: UIPanGestureRecognizer) {
        if gestureRecognizer.state == .began {
            transitionDelegate.interactiveDismissal = true
            dismiss(animated: true, completion: nil)
        } else {
            transitionDelegate.interactiveDismissal = gestureRecognizer.state != .ended
            transitionDelegate.interactiveAnimator.handlePanWithPanGestureRecognizer(gestureRecognizer, viewToPan: pageViewController.view, anchorPoint: CGPoint(x: view.bounds.midX, y: view.bounds.midY))
        }
    }
    
    @objc private func handleSingleTapGestureRecognizer(_ gestureRecognizer: UITapGestureRecognizer) {
        guard let overlayView = overlayView else { return }
        overlayView.setHidden(!overlayView.isHidden, animated: true)
    }
}


// MARK: - UIPageViewControllerDataSource / UIPageViewControllerDelegate

extension PhotosViewController {
    
    @objc public func pageViewController(_ pageViewController: UIPageViewController, viewControllerBefore viewController: UIViewController) -> UIViewController? {
        guard let photoViewController = viewController as? PhotoViewController,
            let photoIndex = dataSource.indexOfPhoto(photoViewController.photo),
            let newPhoto = dataSource[photoIndex-1] else {
                return nil
        }
        return initializePhotoViewControllerForPhoto(newPhoto)
    }
    
    @objc public func pageViewController(_ pageViewController: UIPageViewController, viewControllerAfter viewController: UIViewController) -> UIViewController? {
        guard let photoViewController = viewController as? PhotoViewController,
            let photoIndex = dataSource.indexOfPhoto(photoViewController.photo),
            let newPhoto = dataSource[photoIndex+1] else {
                return nil
        }
        return initializePhotoViewControllerForPhoto(newPhoto)
    }
    
    @objc public func pageViewController(_ pageViewController: UIPageViewController, didFinishAnimating finished: Bool, previousViewControllers: [UIViewController], transitionCompleted completed: Bool) {
        if completed {
            updateCurrentPhotosInformation()
            if let currentPhotoViewController = currentPhotoViewController {
                navigateToPhotoHandler?(currentPhotoViewController.photo)
            }
        }
    }
}


// MARK: - ImageBlurable

protocol ImageBlurable {
    func addBlurBackgroundImage(_ image: UIImage?)
}

extension ImageBlurable where Self: UIViewController {
    func addBlurBackgroundImage(_ image: UIImage?) {
        let backgroundImageView = UIImageView(frame: view.bounds)
        backgroundImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backgroundImageView.image = image
        backgroundImageView.contentMode = .scaleAspectFill
        let blurContentView = UIVisualEffectView(effect: UIBlurEffect(style: .light))
        blurContentView.frame = backgroundImageView.bounds
        blurContentView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.insertSubview(backgroundImageView, at: 0)
        backgroundImageView.addSubview(blurContentView)

        let maskView = UIView(frame: CGRect(origin: CGPoint.zero, size: view.bounds.size))
        maskView.backgroundColor = UIColor(white: 0, alpha: 0.3)
        maskView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.insertSubview(maskView, aboveSubview: backgroundImageView)
    }
}
