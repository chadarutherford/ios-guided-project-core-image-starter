import UIKit
import CoreImage
import CoreImage.CIFilterBuiltins
import Photos

class PhotoFilterViewController: UIViewController {
    
    // --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    // MARK: - Outlets
	@IBOutlet weak var brightnessSlider: UISlider!
	@IBOutlet weak var contrastSlider: UISlider!
	@IBOutlet weak var saturationSlider: UISlider!
	@IBOutlet weak var imageView: UIImageView!
    
    // --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    // MARK: - Properties
    private var context = CIContext(options: nil)
    private var originalImage: UIImage? {
        didSet {
            guard let originalImage = originalImage else { return }
            var scaledSize = imageView.bounds.size
            let scale = UIScreen.main.scale
            scaledSize = CGSize(width: scaledSize.width * scale, height: scaledSize.height * scale)
            scaledImage = originalImage.imageByScaling(toSize: scaledSize)
        }
    }
    
    private var scaledImage: UIImage? {
        didSet {
            updateImage()
        }
    }
    
    // --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
    // MARK: - View Controller Life Cycle
	override func viewDidLoad() {
		super.viewDidLoad()
        originalImage = imageView.image
	}
    
    private func updateImage() {
        if let scaledImage = scaledImage {
            imageView.image = filter(scaledImage)
        } else {
            imageView.image = nil
        }
    }
    
    private func filter(_ image: UIImage) -> UIImage? {
        guard let cgImage = image.cgImage else { return nil }
        let ciImage = CIImage(cgImage: cgImage)
        let filter = CIFilter.colorControls()
        filter.inputImage = ciImage
        filter.brightness = brightnessSlider.value
        filter.contrast = contrastSlider.value
        filter.saturation = saturationSlider.value
        
        guard let outputCIImage = filter.outputImage else { return nil }
        guard let outputCGImage = context.createCGImage(outputCIImage, from: CGRect(origin: .zero, size: image.size)) else { return nil }
        return UIImage(cgImage: outputCGImage)
    }
    
    private func showImagePicker() {
        let imagePicker = UIImagePickerController()
        imagePicker.sourceType = .photoLibrary
        imagePicker.delegate = self
        present(imagePicker, animated: true)
    }
    
    // --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
	// MARK: - Actions
	@IBAction func choosePhotoButtonPressed(_ sender: Any) {
        showImagePicker()
	}
	
	@IBAction func savePhotoButtonPressed(_ sender: UIButton) {
        guard let originalImage = originalImage else { return }
        guard let processedImage = filter(originalImage.flattened) else { return }
        PHPhotoLibrary.requestAuthorization { status in
            guard status == .authorized else { fatalError("User did not authorize app to save photos") }
            PHPhotoLibrary.shared().performChanges({ PHAssetCreationRequest.creationRequestForAsset(from: processedImage) }) { completion, error in
                if let error = error {
                    print("Error saving photo: \(error.localizedDescription)")
                    return
                }
                DispatchQueue.main.async { print("Saved Image!") }
            }
        }
	}
    
    // --- --- --- --- --- --- --- --- --- --- --- --- --- --- ---
	// MARK: - Slider events
	@IBAction func brightnessChanged(_ sender: UISlider) {
        updateImage()
	}
	
	@IBAction func contrastChanged(_ sender: UISlider) {
        updateImage()
	}
	
	@IBAction func saturationChanged(_ sender: UISlider) {
        updateImage()
	}
}

extension PhotoFilterViewController: UIImagePickerControllerDelegate, UINavigationControllerDelegate {
    func imagePickerController(_ picker: UIImagePickerController, didFinishPickingMediaWithInfo info: [UIImagePickerController.InfoKey : Any]) {
        guard let image = info[UIImagePickerController.InfoKey.originalImage] as? UIImage else { return }
        originalImage = image
        picker.dismiss(animated: true)
    }
    
    func imagePickerControllerDidCancel(_ picker: UIImagePickerController) {
        picker.dismiss(animated: true)
    }
}
