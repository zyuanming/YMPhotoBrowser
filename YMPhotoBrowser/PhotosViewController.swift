

import UIKit

public typealias PhotosViewControllerReferenceViewHandler = (_ photo: PhotoViewable) -> (UIView?)
public typealias PhotosViewControllerNavigateToPhotoHandler = (_ photo: PhotoViewable) -> ()
public typealias PhotosViewControllerDismissHandler = (_ viewController: PhotosViewController) -> ()
public typealias PhotosViewControllerLongPressHandler = (_ photo: PhotoViewable, _ gestureRecognizer: UILongPressGestureRecognizer) -> ()


public class PhotosViewController: UIViewController, UIPageViewControllerDataSource, UIPageViewControllerDelegate {

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
    private(set) var backgroundImageView = UIImageView()
    
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

    let photoTransitionDelegate = PhotoTransitionDelegate()
    
    
    // MARK: - Initialization
    
    deinit {
        pageViewController.delegate = nil
        pageViewController.dataSource = nil
    }
    
    required public init?(coder aDecoder: NSCoder) {
        dataSource = PhotosDataSource(photos: [])
        super.init(nibName: nil, bundle: nil)
        initialSetupWith()
    }
    
    override init(nibName nibNameOrNil: String!, bundle nibBundleOrNil: Bundle!) {
        dataSource = PhotosDataSource(photos: [])
        super.init(nibName: nil, bundle: nil)
        initialSetupWith()
    }

    public init(photos: [PhotoViewable], initialPhoto: PhotoViewable? = nil, referenceView: UIView? = nil) {
        dataSource = PhotosDataSource(photos: photos)
        super.init(nibName: nil, bundle: nil)
        initialSetupWith(initialPhoto, referenceView)
        overlayView = PhotosOverlayView(frame: CGRect.zero)
        overlayView?.photosViewController = self
    }

    
    // MARK: - View Life Cycle

    override public func viewDidLoad() {
        super.viewDidLoad()
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
        if !photoTransitionDelegate.interactiveDismissal {
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
        photoTransitionDelegate.transitionAnimator.startingView = startingView
        photoTransitionDelegate.transitionAnimator.photo = currentPhoto

        if let currentPhoto = currentPhoto {
            photoTransitionDelegate.transitionAnimator.endingView = referenceViewForPhotoWhenDismissingHandler?(currentPhoto)
        } else {
            photoTransitionDelegate.transitionAnimator.endingView = nil
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
    private func initialSetupWith(_ initialPhoto: PhotoViewable? = nil, _ referenceView: UIView? = nil) {
        if let photo = initialPhoto, dataSource.containsPhoto(photo) {
            setUpPageViewController(photo)
            setUpTransition(startingView: referenceView, startingPhoto: photo)
            
        } else if let photo = dataSource.photos.first {
            setUpPageViewController(photo)
            setUpTransition(startingView: referenceView, startingPhoto: photo)
        }
    }
    
    private func setUpPageViewController(_ photo: PhotoViewable) {
        pageViewController = UIPageViewController(transitionStyle: .scroll, navigationOrientation: .horizontal, options: [UIPageViewControllerOptionInterPageSpacingKey: 16.0])
        pageViewController.view.backgroundColor = UIColor.clear
        pageViewController.delegate = self
        pageViewController.dataSource = self
        let photoViewController = initializePhotoViewControllerForPhoto(photo)
        pageViewController.setViewControllers([photoViewController], direction: .forward, animated: false, completion: nil)
        
        photo.loadImageWithCompletionHandler { [weak self] (image, _) in
            self?.addBlurBackgroundImage(image)
        }
        
        updateCurrentPhotosInformation()
    }
    
    private func setUpTransition(startingView: UIView?, startingPhoto: PhotoViewable?) {
        photoTransitionDelegate.transitionAnimator.startingView = startingView
        photoTransitionDelegate.transitionAnimator.photo = startingPhoto
        photoTransitionDelegate.transitionAnimator.endingView = currentPhotoViewController?.scalingImageView.imageView
        self.modalPresentationStyle = .custom
        self.transitioningDelegate = photoTransitionDelegate
        self.modalPresentationCapturesStatusBarAppearance = true
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
            currentPhoto.loadImageWithCompletionHandler({ [weak self] (image, _) in
                self?.backgroundImageView.image = image
            })
        }
    }
    
    private func initializePhotoViewControllerForPhoto(_ photo: PhotoViewable) -> PhotoViewController {
        let photoViewController = PhotoViewController(photo: photo)
        singleTapGestureRecognizer.require(toFail: photoViewController.doubleTapGestureRecognizer)
        photoViewController.longPressGestureHandler = { [weak self] gesture in
            guard let longPressGestureHandler = self?.longPressGestureHandler else { return }
            longPressGestureHandler(photo, gesture)
        }
        return photoViewController
    }
    
    func addBlurBackgroundImage(_ image: UIImage?) {
        backgroundImageView.frame = view.bounds
        backgroundImageView.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        backgroundImageView.image = image
        backgroundImageView.contentMode = .scaleAspectFill
        var blurContentView: UIVisualEffectView?
        if #available(iOS 10.0, *) {
            blurContentView = UIVisualEffectView(effect: UIBlurEffect(style: .regular))
        } else {
            blurContentView = UIVisualEffectView(effect: UIBlurEffect(style: .dark))
        }
        blurContentView!.frame = backgroundImageView.bounds
        blurContentView!.autoresizingMask = [.flexibleWidth, .flexibleHeight]
        view.insertSubview(backgroundImageView, at: 0)
        backgroundImageView.addSubview(blurContentView!)
    }
}


// MARK: - Gesture Recognizers

extension PhotosViewController {
    @objc private func handlePanGestureRecognizer(_ gestureRecognizer: UIPanGestureRecognizer) {
        if gestureRecognizer.state == .began {
            photoTransitionDelegate.interactiveDismissal = true
            dismiss(animated: true, completion: nil)
        } else {
            photoTransitionDelegate.interactiveDismissal = gestureRecognizer.state != .ended
            photoTransitionDelegate.interactiveAnimator.handlePanWithPanGestureRecognizer(gestureRecognizer, viewToPan: pageViewController.view, anchorPoint: CGPoint(x: view.bounds.midX, y: view.bounds.midY))
        }
    }
    
    @objc private func handleSingleTapGestureRecognizer(_ gestureRecognizer: UITapGestureRecognizer) {
        self.dismiss(animated: true, completion: nil)
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
