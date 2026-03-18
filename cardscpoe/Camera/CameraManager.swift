import AVFoundation
import Combine
import SwiftUI

final class CameraManager: NSObject, ObservableObject {
    enum CameraError: Error {
        case permissionDenied
        case setupFailed
        case captureFailed
    }

    @Published var isSessionRunning = false
    @Published var authorizationGranted = false
    /// The last captured full-resolution image (used to freeze preview)
    @Published var frozenImage: UIImage?

    let session = AVCaptureSession()
    private let output = AVCapturePhotoOutput()
    private var continuation: CheckedContinuation<UIImage, Error>?

    override init() {
        super.init()
    }

    func requestPermissionAndConfigure() async {
        switch AVCaptureDevice.authorizationStatus(for: .video) {
        case .authorized:
            authorizationGranted = true
            configureSessionIfNeeded()
        case .notDetermined:
            let granted = await AVCaptureDevice.requestAccess(for: .video)
            await MainActor.run {
                self.authorizationGranted = granted
                if granted {
                    self.configureSessionIfNeeded()
                }
            }
        default:
            authorizationGranted = false
        }
    }

    func startSession() {
        guard authorizationGranted else { return }
        frozenImage = nil
        if !session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                self.session.startRunning()
                DispatchQueue.main.async {
                    self.isSessionRunning = self.session.isRunning
                }
            }
        }
    }

    func stopSession() {
        if session.isRunning {
            DispatchQueue.global(qos: .userInitiated).async {
                self.session.stopRunning()
                DispatchQueue.main.async {
                    self.isSessionRunning = self.session.isRunning
                }
            }
        }
    }

    func capturePhoto() async throws -> UIImage {
        try await withCheckedThrowingContinuation { continuation in
            self.continuation = continuation
            let settings = AVCapturePhotoSettings()
            settings.flashMode = .off
            output.capturePhoto(with: settings, delegate: self)
        }
    }

    /// Unfreeze and restart live preview
    func unfreezePreview() {
        frozenImage = nil
    }

    private func configureSessionIfNeeded() {
        guard session.inputs.isEmpty else { return }

        session.beginConfiguration()
        session.sessionPreset = .photo

        guard
            let camera = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .back),
            let input = try? AVCaptureDeviceInput(device: camera),
            session.canAddInput(input),
            session.canAddOutput(output)
        else {
            session.commitConfiguration()
            return
        }

        session.addInput(input)
        session.addOutput(output)
        session.commitConfiguration()
    }
}

extension CameraManager: AVCapturePhotoCaptureDelegate {
    func photoOutput(
        _ output: AVCapturePhotoOutput,
        didFinishProcessingPhoto photo: AVCapturePhoto,
        error: Error?
    ) {
        if let error {
            continuation?.resume(throwing: error)
            continuation = nil
            return
        }
        guard let data = photo.fileDataRepresentation(), let image = UIImage(data: data) else {
            continuation?.resume(throwing: CameraError.captureFailed)
            continuation = nil
            return
        }
        // Freeze the preview with the captured image
        DispatchQueue.main.async {
            self.frozenImage = image
        }
        continuation?.resume(returning: image)
        continuation = nil
    }
}

// MARK: - Image Cropping

extension UIImage {
    /// Crops the image to a centered rectangle matching the viewfinder aspect ratio (5:7, like a card).
    /// The `frameFraction` is how much of the screen width/height the viewfinder covers.
    func croppedToCardFrame() -> UIImage {
        guard let cgImage = self.cgImage else { return self }

        let imgW = CGFloat(cgImage.width)
        let imgH = CGFloat(cgImage.height)

        // Card aspect ratio ~5:7 (width:height), viewfinder is roughly 65% of screen width
        let cardAspect: CGFloat = 5.0 / 7.0
        let frameFractionW: CGFloat = 0.62  // viewfinder width as fraction of image width
        let frameFractionH: CGFloat = frameFractionW / cardAspect * (imgW / imgH)

        let cropW = imgW * frameFractionW
        let cropH = min(imgH * frameFractionH, imgH * 0.75) // cap at 75% of image height
        let cropX = (imgW - cropW) / 2.0
        // Viewfinder is slightly above center on screen
        let cropY = (imgH - cropH) / 2.0 - imgH * 0.02

        let cropRect = CGRect(
            x: max(0, cropX),
            y: max(0, cropY),
            width: min(cropW, imgW - max(0, cropX)),
            height: min(cropH, imgH - max(0, cropY))
        )

        guard let cropped = cgImage.cropping(to: cropRect) else { return self }
        return UIImage(cgImage: cropped, scale: self.scale, orientation: self.imageOrientation)
    }
}

struct CameraPreview: UIViewRepresentable {
    let session: AVCaptureSession

    func makeUIView(context _: Context) -> PreviewView {
        let view = PreviewView()
        view.videoPreviewLayer.videoGravity = .resizeAspectFill
        view.videoPreviewLayer.session = session
        return view
    }

    func updateUIView(_ uiView: PreviewView, context _: Context) {
        uiView.videoPreviewLayer.session = session
    }
}

final class PreviewView: UIView {
    override class var layerClass: AnyClass { AVCaptureVideoPreviewLayer.self }
    var videoPreviewLayer: AVCaptureVideoPreviewLayer { layer as! AVCaptureVideoPreviewLayer }
}
