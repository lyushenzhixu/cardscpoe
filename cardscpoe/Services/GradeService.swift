import CoreImage
import CoreImage.CIFilterBuiltins
import Foundation
import UIKit
@preconcurrency import Vision

@MainActor
final class GradeService {
    static let shared = GradeService()

    private let context = CIContext()

    private init() {}

    func analyze(image: UIImage) async -> GradeBreakdown {
        guard let cgImage = image.cgImage else {
            return .init(centering: 8.8, corners: 8.6, edges: 8.5, surface: 8.4)
        }

        async let centering = detectCenteringScore(cgImage: cgImage)
        async let corners = detectCornerScore(cgImage: cgImage)
        async let edges = detectEdgeScore(cgImage: cgImage)
        async let surface = detectSurfaceScore(cgImage: cgImage)

        return GradeBreakdown(
            centering: await centering,
            corners: await corners,
            edges: await edges,
            surface: await surface
        )
    }

    private func detectCenteringScore(cgImage: CGImage) async -> Double {
        await withCheckedContinuation { continuation in
            let request = VNDetectRectanglesRequest { request, _ in
                guard let rect = (request.results as? [VNRectangleObservation])?.first else {
                    continuation.resume(returning: 8.8)
                    return
                }
                let centerX = (rect.topLeft.x + rect.topRight.x + rect.bottomLeft.x + rect.bottomRight.x) / 4
                let centerY = (rect.topLeft.y + rect.topRight.y + rect.bottomLeft.y + rect.bottomRight.y) / 4
                let dx = abs(centerX - 0.5)
                let dy = abs(centerY - 0.5)
                let drift = min(1.0, (dx + dy) * 2.5)
                let score = max(6.5, 10.0 - (drift * 3.0))
                continuation.resume(returning: self.roundToTenth(score))
            }
            request.minimumConfidence = 0.55
            request.maximumObservations = 1
            let handler = VNImageRequestHandler(cgImage: cgImage, options: [:])
            DispatchQueue.global(qos: .userInitiated).async {
                do {
                    try handler.perform([request])
                } catch {
                    continuation.resume(returning: 8.8)
                }
            }
        }
    }

    private func detectCornerScore(cgImage: CGImage) async -> Double {
        let brightness = averageBrightness(cgImage: cgImage)
        let score = max(6.8, min(10.0, 9.7 - (brightness - 0.55) * 1.4))
        return roundToTenth(score)
    }

    private func detectEdgeScore(cgImage: CGImage) async -> Double {
        let contrast = edgeContrast(cgImage: cgImage)
        let score = max(6.5, min(10.0, 7.0 + contrast * 3.2))
        return roundToTenth(score)
    }

    private func detectSurfaceScore(cgImage: CGImage) async -> Double {
        let variance = luminanceVariance(cgImage: cgImage)
        let score = max(6.2, min(10.0, 9.8 - variance * 2.8))
        return roundToTenth(score)
    }

    private func averageBrightness(cgImage: CGImage) -> Double {
        let image = CIImage(cgImage: cgImage)
        let extent = image.extent
        guard let filter = CIFilter(name: "CIAreaAverage") else { return 0.6 }
        filter.setValue(image, forKey: kCIInputImageKey)
        filter.setValue(CIVector(cgRect: extent), forKey: kCIInputExtentKey)
        guard let output = filter.outputImage else { return 0.6 }

        var bitmap = [UInt8](repeating: 0, count: 4)
        context.render(output, toBitmap: &bitmap, rowBytes: 4, bounds: CGRect(x: 0, y: 0, width: 1, height: 1), format: .RGBA8, colorSpace: nil)
        return (Double(bitmap[0]) + Double(bitmap[1]) + Double(bitmap[2])) / (3.0 * 255.0)
    }

    private func edgeContrast(cgImage: CGImage) -> Double {
        let image = CIImage(cgImage: cgImage)
        let filter = CIFilter.edges()
        filter.inputImage = image
        filter.intensity = 2.0
        guard let output = filter.outputImage else { return 0.55 }
        return min(1.0, averageBrightness(cgImage: context.createCGImage(output, from: output.extent) ?? cgImage))
    }

    private func luminanceVariance(cgImage: CGImage) -> Double {
        let image = CIImage(cgImage: cgImage)
        let extent = image.extent
        guard
            let avgFilter = CIFilter(name: "CIAreaAverage"),
            let minFilter = CIFilter(name: "CIAreaMinimum"),
            let maxFilter = CIFilter(name: "CIAreaMaximum")
        else {
            return 0.3
        }

        avgFilter.setValue(image, forKey: kCIInputImageKey)
        avgFilter.setValue(CIVector(cgRect: extent), forKey: kCIInputExtentKey)
        minFilter.setValue(image, forKey: kCIInputImageKey)
        minFilter.setValue(CIVector(cgRect: extent), forKey: kCIInputExtentKey)
        maxFilter.setValue(image, forKey: kCIInputImageKey)
        maxFilter.setValue(CIVector(cgRect: extent), forKey: kCIInputExtentKey)

        guard
            let avg = avgFilter.outputImage,
            let minImage = minFilter.outputImage,
            let maxImage = maxFilter.outputImage
        else {
            return 0.3
        }

        let avgBrightness = pixelBrightness(avg)
        let minBrightness = pixelBrightness(minImage)
        let maxBrightness = pixelBrightness(maxImage)
        return max(0, min(1.0, (maxBrightness - minBrightness) * (1.0 - abs(avgBrightness - 0.5))))
    }

    private func roundToTenth(_ value: Double) -> Double {
        (value * 10).rounded() / 10
    }

    private func pixelBrightness(_ image: CIImage) -> Double {
        var bitmap = [UInt8](repeating: 0, count: 4)
        context.render(
            image,
            toBitmap: &bitmap,
            rowBytes: 4,
            bounds: CGRect(x: 0, y: 0, width: 1, height: 1),
            format: .RGBA8,
            colorSpace: nil
        )
        return (Double(bitmap[0]) + Double(bitmap[1]) + Double(bitmap[2])) / (3.0 * 255.0)
    }
}
