
import UIKit

class PhotosTransitionAnimator: NSObject, UIViewControllerAnimatedTransitioning {
    var dismissing: Bool = false
    var startingView: UIView?
    var endingView: UIView?
    var photo: PhotoViewable?
    
    var animationDurationWithZooming = 0.3
    var animationDurationWithoutZooming = 0.3
    var animationDurationFadeRatio = 4.0 / 9.0 {
        didSet(value) {
            animationDurationFadeRatio = min(value, 1.0)
        }
    }
    var animationDurationEndingViewFadeInRatio = 0.1 {
        didSet(value) {
            animationDurationEndingViewFadeInRatio = min(value, 1.0)
        }
    }
    var animationDurationStartingViewFadeOutRatio = 0.05 {
        didSet(value) {
            animationDurationStartingViewFadeOutRatio = min(value, 1.0)
        }
    }
    var zoomingAnimationSpringDamping = 1
    
    var shouldPerformZoomingAnimation: Bool {
        get {
            return self.startingView != nil && self.endingView != nil
        }
    }
    
    func transitionDuration(using transitionContext: UIViewControllerContextTransitioning?) -> TimeInterval {
        if shouldPerformZoomingAnimation {
            return animationDurationWithZooming
        }
        return animationDurationWithoutZooming
    }
    
    func fadeDurationForTransitionContext(_ transitionContext: UIViewControllerContextTransitioning) -> TimeInterval {
        if shouldPerformZoomingAnimation {
            return transitionDuration(using: transitionContext) * animationDurationFadeRatio
        }
        return transitionDuration(using: transitionContext)
    }
    
    // MARK:- UIViewControllerAnimatedTransitioning
    
    func animateTransition(using transitionContext: UIViewControllerContextTransitioning) {
        setupTransitionContainerHierarchyWithTransitionContext(transitionContext)

        if shouldPerformZoomingAnimation {
            if transitionContext.isInteractive {
                performScrollingDismissAnimationWithTransitionContext(transitionContext)
            } else {
                performZoomingAnimationWithTransitionContext(transitionContext)
            }
        }
        performFadeAnimationWithTransitionContext(transitionContext)
    }
    
    func setupTransitionContainerHierarchyWithTransitionContext(_ transitionContext: UIViewControllerContextTransitioning) {
        
        if let toView = transitionContext.view(forKey: UITransitionContextViewKey.to),
           let toViewController = transitionContext.viewController(forKey: UITransitionContextViewControllerKey.to) {
            toView.frame = transitionContext.finalFrame(for: toViewController)
            let containerView = transitionContext.containerView
            
            if !toView.isDescendant(of: containerView) {
                containerView.addSubview(toView)
            }
        }
        
        if dismissing {
            if let fromView = transitionContext.view(forKey: UITransitionContextViewKey.from) {
                transitionContext.containerView.bringSubview(toFront: fromView)
            }
        }
    }
    
    func performFadeAnimationWithTransitionContext(_ transitionContext: UIViewControllerContextTransitioning) {
        let fadeView = dismissing ? transitionContext.view(forKey: UITransitionContextViewKey.from) : transitionContext.view(forKey: UITransitionContextViewKey.to)
        let beginningAlpha: CGFloat = dismissing ? 1.0 : 0.0
        let endingAlpha: CGFloat = dismissing ? 0.0 : 1.0
        
        fadeView?.alpha = beginningAlpha

        UIView.animate(withDuration: fadeDurationForTransitionContext(transitionContext), animations: { () -> Void in
            fadeView?.alpha = endingAlpha
        }) { finished in
            if !self.shouldPerformZoomingAnimation {
                self.completeTransitionWithTransitionContext(transitionContext)
            }
        }
    }

    func performScrollingDismissAnimationWithTransitionContext(_ transitionContext: UIViewControllerContextTransitioning) {

        let containerView = transitionContext.containerView
        guard let startingView = startingView, let endingView = endingView else {
            return
        }

        let snapView = startingView.snapshotView()
        let originFrame = startingView.convert(startingView.bounds, to: containerView)
        snapView.frame = originFrame

        containerView.addSubview(snapView)
        endingView.alpha = 0.0
        startingView.alpha = 0.0
        let slideDown = snapView.center.y > UIScreen.main.bounds.midY
        var finalFrame = originFrame
        finalFrame.origin.y = slideDown ? UIScreen.main.bounds.height : -originFrame.height
        UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0.0, usingSpringWithDamping:CGFloat(zoomingAnimationSpringDamping), initialSpringVelocity:0, options: [], animations: { () -> Void in
            snapView.frame = finalFrame
            endingView.alpha = 1.0
        }) { result in
            startingView.alpha = 1
            snapView.removeFromSuperview()

            self.completeTransitionWithTransitionContext(transitionContext)
        }

        return
    }
    
    func performZoomingAnimationWithTransitionContext(_ transitionContext: UIViewControllerContextTransitioning) {
        
        let containerView = transitionContext.containerView
        guard let startingView = startingView, let endingView = endingView else {
            return
        }

        guard let photo = photo else { return }

        var animatingImage: UIImage?
        if let image = photo.image {
            animatingImage = image
        } else if let thumbnailImage = photo.thumbnailImage {
            animatingImage = thumbnailImage
        } else {
            if let fullImage = photo.getCachedImage(photo.imageURL) {
                animatingImage = fullImage
            } else if let thumbnailImage = photo.getCachedImage(photo.thumbnailImageURL) {
                animatingImage = thumbnailImage
            }
        }

        var finalFrame: CGRect
        var finalCenter: CGPoint
        let imageView = UIImageView()
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true

        if let animatingImage = animatingImage,
                isLongPhoto(for: CGSize(width: animatingImage.size.width, height: animatingImage.size.height)) {

            let imageSize = animatingImage.size

            let cropHeight = min(UIScreen.main.bounds.height, endingView.bounds.height) / endingView.bounds.width * imageSize.width
            let cropRect = CGRect(x: 0, y: 0, width: imageSize.width, height: cropHeight)
            if let imageRef: CGImage = animatingImage.cgImage?.cropping(to: cropRect) {
                let cropped: UIImage = UIImage(cgImage:imageRef)
                imageView.image = cropped
            }

            imageView.frame = CGRect(x: 0, y: 0, width: startingView.frame.width, height: min(startingView.frame.height, UIScreen.main.bounds.height))
            finalFrame = CGRect(x: 0, y: 0, width: endingView.frame.width, height: min(endingView.frame.height, UIScreen.main.bounds.height))
            let centerPoint = endingView.translatedCenterPointToContainerView(containerView)
            if endingView.frame.height > UIScreen.main.bounds.height {
                finalCenter = CGPoint(x: centerPoint.x, y: UIScreen.main.bounds.midY)
                imageView.center = startingView.translatedCenterPointToContainerView(containerView)
            } else {
                finalCenter = centerPoint
                imageView.center = CGPoint(x: UIScreen.main.bounds.midX, y: UIScreen.main.bounds.midY)
            }
        } else {
            imageView.image = animatingImage
            imageView.frame = CGRect(x: 0, y: 0, width: startingView.frame.width, height: startingView.frame.height)
            finalFrame = CGRect(x: 0, y: 0, width: endingView.frame.width, height: endingView.frame.height)
            finalCenter = endingView.translatedCenterPointToContainerView(containerView)
            imageView.center = startingView.translatedCenterPointToContainerView(containerView)
        }

        containerView.addSubview(imageView)
        endingView.alpha = 0.0
        UIView.animate(withDuration: transitionDuration(using: transitionContext), delay: 0.0, usingSpringWithDamping:CGFloat(zoomingAnimationSpringDamping), initialSpringVelocity:0, options: [], animations: { () -> Void in
            imageView.frame = finalFrame
            imageView.center = finalCenter
        }) { result in
            imageView.removeFromSuperview()
            endingView.alpha = 1.0
            self.completeTransitionWithTransitionContext(transitionContext)
        }

        return
    }
    
    func completeTransitionWithTransitionContext(_ transitionContext: UIViewControllerContextTransitioning) {
        if transitionContext.isInteractive {
            if transitionContext.transitionWasCancelled {
                transitionContext.cancelInteractiveTransition()
            } else {
                transitionContext.finishInteractiveTransition()
            }
        }
        transitionContext.completeTransition(!transitionContext.transitionWasCancelled)
    }



    fileprivate func isLongPhoto(for imageSize: CGSize) -> Bool {
        let realHeight = UIScreen.main.bounds.width * CGFloat(imageSize.height) / CGFloat(imageSize.width)

        return realHeight >= UIScreen.main.bounds.height
    }
}