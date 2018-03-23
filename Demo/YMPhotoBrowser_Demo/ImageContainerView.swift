
import UIKit
import SnapKit
import Kingfisher
import YMPhotoBrowser

class ImageContainerView: UIView {
    fileprivate var feedModel: Feed?
    fileprivate let maxWidth: CGFloat = 250
    fileprivate let maxHeight: CGFloat = 250
    fileprivate let minHeight: CGFloat = 190
    fileprivate let minWidth: CGFloat = 190
    var containerHeight: CGFloat = 0
    var imageViews: [UIView] = []

    var didClickPreviewHandler: (() -> Void)?
    var didDismissPreviewHandler: (() -> Void)?
    var previewContentInset: UIEdgeInsets = UIEdgeInsets.zero

    override var intrinsicContentSize: CGSize {
        let size = super.intrinsicContentSize
        return CGSize(width: size.width, height: containerHeight)
    }

    func displayImages(feed: Feed) {
        feedModel = feed
        let medias = feed.medias
        var containerHeight: CGFloat = 0
        let multiPhotoWidth: CGFloat = 160
        let multiPhotoMargin: CGFloat = 6 
        let multiPhotoMinHeight: CGFloat = ceil((minHeight - multiPhotoMargin) / 2)
        subviews.forEach { $0.removeFromSuperview() }
        imageViews.removeAll()
        if medias.count > 0 {
            containerHeight = minHeight
            for (i, media) in medias.enumerated() {
                if URL(string: media.thumbnail) != nil {
                    if i == 4 {
                        break
                    }

                    if isLongPhoto(media) {
                        let longView = TVLongImageView()
                        longView.tag = i
                        imageViews.append(longView)
                        addSubview(longView)
                        self.addPreviewAction(forView: longView)
                        longView.setImage(with: media.mediaUrl)
                    } else {
                        let imageView = UIImageView()
                        imageView.backgroundColor = UIColor.lightText
                        imageView.contentMode = .scaleAspectFill
                        imageView.clipsToBounds = true
                        imageView.tag = i
                        addSubview(imageView)
                        imageViews.append(imageView)
                        self.addPreviewAction(forView: imageView)
                        imageView.kf.setImage(with: URL(string: media.mediaUrl))
                    }
                }
            }

            var rects: [CGRect] = []

            switch subviews.count {
            case 1:
                let width: CGFloat = CGFloat(medias.first?.thumbWidth ?? 0)
                let height: CGFloat = CGFloat(medias.first?.thumbHeight ?? 0)
                var containerWidth: CGFloat = 0
                if width > 0 && height > 0 {

                    if width > height {
                        containerWidth = maxWidth
                        containerHeight = minHeight
                    } else if width == height {
                        containerWidth = minHeight
                        containerHeight = minHeight
                    } else {
                        containerWidth = minWidth
                        containerHeight = maxHeight
                    }
                }
                rects.append(CGRect(x: 0, y: 0, width: containerWidth, height: containerHeight))
            case 2:
                rects.append(CGRect(x: 0, y: 0, width: multiPhotoWidth, height: minHeight))
                rects.append(CGRect(x: multiPhotoWidth + multiPhotoMargin, y: 0, width: multiPhotoWidth, height: minHeight))
            case 3:
                rects.append(CGRect(x: 0, y: 0, width: multiPhotoWidth, height: minHeight))
                rects.append(CGRect(x: multiPhotoWidth + multiPhotoMargin, y: 0, width: multiPhotoWidth, height: multiPhotoMinHeight))
                rects.append(CGRect(x: multiPhotoWidth + multiPhotoMargin, y: multiPhotoMinHeight + multiPhotoMargin, width: multiPhotoWidth, height: multiPhotoMinHeight))
            case 4:
                rects.append(CGRect(x: 0, y: 0, width: multiPhotoWidth, height: multiPhotoMinHeight))
                rects.append(CGRect(x: multiPhotoWidth + multiPhotoMargin, y: 0, width: multiPhotoWidth, height: multiPhotoMinHeight))
                rects.append(CGRect(x: 0, y: multiPhotoMinHeight + multiPhotoMargin, width: multiPhotoWidth, height: multiPhotoMinHeight))
                rects.append(CGRect(x: multiPhotoWidth + multiPhotoMargin, y: multiPhotoMinHeight + multiPhotoMargin, width: multiPhotoWidth, height: multiPhotoMinHeight))
            default:
                break
            }
            var idx: Int = 0
            for v in subviews {
                if idx >= rects.count {
                    break
                }
                v.frame = rects[idx]
                idx += 1
            }


            if rects.count == 4 {
                for (index, subview) in subviews.enumerated() {
                    let dotImageView = UIImageView()
                    dotImageView.image = UIImage(named: "photo_\(index + 1)")
                    subview.addSubview(dotImageView)

                    if index == 0 {
                        dotImageView.snp.makeConstraints({ (make) in
                            make.bottom.equalToSuperview().offset(-4 )
                            make.right.equalToSuperview().offset(-4 )
                        })
                    } else if index == 1 {
                        dotImageView.snp.makeConstraints({ (make) in
                            make.bottom.equalToSuperview().offset(-4 )
                            make.left.equalToSuperview().offset(4 )
                        })
                    } else if index == 2 {
                        dotImageView.snp.makeConstraints({ (make) in
                            make.top.equalToSuperview().offset(4 )
                            make.right.equalToSuperview().offset(-4 )
                        })
                    } else if index == 3 {
                        dotImageView.snp.makeConstraints({ (make) in
                            make.top.equalToSuperview().offset(4 )
                            make.left.equalToSuperview().offset(4 )
                        })
                    }
                }
            }
        }

        self.containerHeight = containerHeight
        self.invalidateIntrinsicContentSize()

    }

    private func addPreviewAction(forView view: UIView) {
        let tagGesture = UITapGestureRecognizer(target: self, action: #selector(previewFeed(_:)))
        view.isUserInteractionEnabled = true
        view.addGestureRecognizer(tagGesture)
    }

    @objc func previewFeed(_ gesture: UITapGestureRecognizer) {
        if let feedModel = feedModel,
            let feedImageView = gesture.view, feedModel.medias.count > 0 {

            didClickPreviewHandler?()

            var photos: [Photo] = []

            for medias in feedModel.medias {
                let photo = Photo(imageURL: URL(string: medias.mediaUrl), thumbnailImageURL: URL(string: medias.thumbnail))
                photos.append(photo)
            }

            let clickIndex = feedImageView.tag

            let currentPhoto = photos[clickIndex]
            let galleryPreview = PhotosViewController(photos: photos, initialPhoto: currentPhoto, referenceView: feedImageView)
            galleryPreview.didDismissHandler = { [weak self] (_) in
                self?.didDismissPreviewHandler?()
            }
            galleryPreview.referenceViewForPhotoWhenDismissingHandler = { [weak self] photo in
                if let index = photos.index(where: {$0 === photo}) {
                    return self?.imageViews[index]
                }
                return nil
            }

            var controller: UIViewController? = nil
            if let window = UIApplication.shared.delegate?.window {
                if let controller_ = window?.rootViewController {
                    if let tabController = controller_ as? UITabBarController {
                        controller = tabController.viewControllers?[tabController.selectedIndex]
                    } else {
                        controller = controller_
                    }
                    while let c = controller?.presentedViewController {
                        controller = c
                    }
                }
            }
            controller?.present(galleryPreview, animated: true, completion: nil)

        }
    }

    fileprivate func isLongPhoto(_ media: FeedMedia) -> Bool {
        let realHeight = UIScreen.main.bounds.width * CGFloat(media.height) / CGFloat(media.width)

        return realHeight >= UIScreen.main.bounds.height
    }
}


class TVLongImageView: UIView {
    lazy var imageView: UIImageView = {
        let imageView = UIImageView()
        imageView.backgroundColor = UIColor.lightText
        imageView.contentMode = .scaleAspectFill
        imageView.clipsToBounds = true

        return imageView
    }()

    override init(frame: CGRect) {
        super.init(frame: frame)

        clipsToBounds = true
        backgroundColor = UIColor.lightText
        addSubview(imageView)

        imageView.snp.makeConstraints { (make) in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.top.equalToSuperview()
        }

    }

    func setImage(with urlStr: String) {
        guard let url = URL(string: urlStr) else { return }

        imageView.kf.setImage(with: url, placeholder: nil, options: nil, progressBlock: nil) { [weak self] (image, _, _, _) in
            self?.resetUI()
        }
    }

    func setImage(_ image: UIImage?) {
        imageView.image = image
        resetUI()
    }

    func resetUI() {
        guard let imageSize = imageView.image?.size else { return }

        imageView.snp.remakeConstraints { (make) in
            make.left.equalToSuperview()
            make.right.equalToSuperview()
            make.top.equalToSuperview()
            make.height.equalTo(imageView.snp.width).multipliedBy(imageSize.height / imageSize.width)
        }
    }
    
    required init?(coder aDecoder: NSCoder) {
        fatalError("init(coder:) has not been implemented")
    }
}

