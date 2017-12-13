
import UIKit

extension UIImageView {
    func enableLongPressToSave() {
        self.isUserInteractionEnabled = true

        let longPressGest = UILongPressGestureRecognizer(target: self, action: #selector(longPress(_:)))
        self.addGestureRecognizer(longPressGest)
    }

    @objc func longPress(_ gesture: UILongPressGestureRecognizer) {
        guard gesture.state == .began, let savingImage = image else { return }

        let alert = UIAlertController(title: nil, message: "Save Photo", preferredStyle: .actionSheet)
        let saveAction = UIAlertAction(title: "Save Photo", style: .destructive) { (action) in
            UIImageWriteToSavedPhotosAlbum(savingImage, self, #selector(self.image(_:didFinishSavingWithError:contextInfo:)), nil)
        }
        let cancelAction = UIAlertAction(title: "Cancel", style: .cancel) { (action) in

        }
        alert.addAction(saveAction)
        alert.addAction(cancelAction)


        var controller: UIViewController? = nil
        if let window = UIApplication.shared.delegate?.window {
            if let controller_ = window?.rootViewController {
                controller = controller_
                while let c = controller?.presentedViewController {
                    controller = c
                }
            }
        }
        controller?.present(alert, animated: true, completion: nil)
    }

    @objc func image(_ image: UIImage, didFinishSavingWithError error: Error?, contextInfo: UnsafeRawPointer) {
        if let error = error {
            let ac = UIAlertController(title: "Photo Save Fail!!", message: error.localizedDescription, preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            UIApplication.shared.keyWindow?.rootViewController?.present(ac, animated: true)
        } else {
            let ac = UIAlertController(title: "", message: "Photo Saved", preferredStyle: .alert)
            ac.addAction(UIAlertAction(title: "OK", style: .default))
            UIApplication.shared.keyWindow?.rootViewController?.present(ac, animated: true)
        }
    }
}
