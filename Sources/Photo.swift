
import Foundation
import UIKit
import Kingfisher

public protocol PhotoViewable: class {
    var image: UIImage? { get }
    var thumbnailImage: UIImage? { get }
    var imageURL: URL? { get set }
    var thumbnailImageURL: URL? { get set }
    
    func loadImageWithCompletionHandler(_ completion: @escaping (_ image: UIImage?, _ error: Error?) -> ())
    func loadThumbnailImageWithCompletionHandler(_ completion: @escaping (_ image: UIImage?, _ error: Error?) -> ())
    func getCachedImage(_ url: URL?) -> UIImage?
    func hasCachedImage(_ url: URL?) -> Bool
}

class Photo: PhotoViewable {
    var image: UIImage?
    var thumbnailImage: UIImage?
    
    var imageURL: URL?
    var thumbnailImageURL: URL?
    
    public init(image: UIImage?, thumbnailImage: UIImage?) {
        self.image = image
        self.thumbnailImage = thumbnailImage
    }
    
    public init(imageURL: URL?, thumbnailImageURL: URL?) {
        self.imageURL = imageURL
        self.thumbnailImageURL = thumbnailImageURL
    }
    
    public init (imageURL: URL?, thumbnailImage: UIImage?) {
        self.imageURL = imageURL
        self.thumbnailImage = thumbnailImage
    }
    
    func loadImageWithCompletionHandler(_ completion: @escaping (_ image: UIImage?, _ error: Error?) -> ()) {
        if let image = image {
            completion(image, nil)
            return
        }
        loadImageWithURL(imageURL, completion: completion)
    }
    func loadThumbnailImageWithCompletionHandler(_ completion: @escaping (_ image: UIImage?, _ error: Error?) -> ()) {
        if let thumbnailImage = thumbnailImage {
            completion(thumbnailImage, nil)
            return
        }
        loadImageWithURL(thumbnailImageURL, completion: completion)
    }

    func getCachedImage(_ url: URL?) -> UIImage? {
        guard let url = url else { return nil }

        let imageCache = ImageCache.default
        var cachedImage: UIImage?
        let result = imageCache.isImageCached(forKey: url.cacheKey)
        if result.cached == true {
            if result.cacheType == .memory {
                cachedImage = imageCache.retrieveImageInMemoryCache(forKey: url.cacheKey)
            } else if result.cacheType == .disk {
                cachedImage = imageCache.retrieveImageInDiskCache(forKey: url.cacheKey)
            }
        }

        return cachedImage
    }

    func hasCachedImage(_ url: URL?) -> Bool {
        guard let url = url else { return false }

        return ImageCache.default.isImageCached(forKey: url.cacheKey).cached
    }

    func loadImageWithURL(_ url: URL?, completion: @escaping (_ image: UIImage?, _ error: Error?) -> ()) {
        guard let url = url else { return }

        ImageDownloader.default.downloadImage(with: url, options: [], progressBlock: nil) { (image, error, _, _) in
            if error != nil {
                completion(nil, error)
            } else if let image = image {
                ImageCache.default.store(image, forKey: url.cacheKey)
                completion(image, nil)
            } else {
                completion(nil, NSError(domain: "PhotoDomain", code: -1, userInfo: [NSLocalizedDescriptionKey: "Couldn't load image"]))
            }
        }
    }
}

func ==<T: Photo>(lhs: T, rhs: T) -> Bool {
    return lhs === rhs
}
