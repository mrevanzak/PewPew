//
//  HandDetectionService.swift
//  vision-test
//
//  Service for detecting hands in camera feed using Vision framework
//

import AVFoundation
import CoreGraphics
import Foundation
import Vision

/// Service responsible for hand detection and tracking
/// Uses Vision framework to analyze camera frames and detect hand positions
class HandDetectionService: ObservableObject {
  // Published property to notify UI of hand position changes
  @Published var handBoundingBoxes: [CGRect] = []
  @Published var isHandDetected: Bool = false

  // Vision request for hand pose detection
  private var handPoseRequest: VNDetectHumanHandPoseRequest

  init() {
    // Initialize hand pose detection request
    handPoseRequest = VNDetectHumanHandPoseRequest()
    handPoseRequest.maximumHandCount = 10  // Detect up to 10 hands
  }

  /// Process a sample buffer from camera to detect hands
  /// - Parameter sampleBuffer: Camera frame data
  func processFrame(_ sampleBuffer: CMSampleBuffer) {
    guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
      return
    }

    // Create vision request handler
    let handler = VNImageRequestHandler(cvPixelBuffer: pixelBuffer, options: [:])

    do {
      // Perform hand detection
      try handler.perform([handPoseRequest])

      // Process results on main queue for UI updates
      DispatchQueue.main.async { [weak self] in
        self?.processHandDetectionResults()
      }
    } catch {
      print("Failed to perform hand detection: \(error)")
    }
  }

  /// Process hand detection results and update published properties
  private func processHandDetectionResults() {
    guard let results = handPoseRequest.results else {
      isHandDetected = false
      handBoundingBoxes = []
      return
    }

    // Extract bounding boxes for detected hands by calculating from landmarks
    let boundingBoxes = results.compactMap { observation -> CGRect? in
      guard observation.confidence > 0.5 else { return nil }

      // Get all hand landmarks to calculate bounding box
      guard let recognizedPoints = try? observation.recognizedPoints(.all) else {
        return nil
      }

      // Filter out low confidence points
      let validPoints = recognizedPoints.values.compactMap { point -> CGPoint? in
        guard point.confidence > 0.5 else { return nil }
        return CGPoint(x: point.location.x, y: point.location.y)
      }

      guard !validPoints.isEmpty else { return nil }

      // Calculate bounding box from landmarks
      let minX = validPoints.map { $0.x }.min() ?? 0
      let maxX = validPoints.map { $0.x }.max() ?? 0
      let minY = validPoints.map { $0.y }.min() ?? 0
      let maxY = validPoints.map { $0.y }.max() ?? 0

      // Add minimal padding to the bounding box
      let padding: CGFloat = 0.02
      let x = max(0, minX - padding)
      let y = max(0, minY - padding)
      let width = min(1 - x, maxX - minX + 2 * padding)
      let height = min(1 - y, maxY - minY + 2 * padding)

      return CGRect(x: x, y: y, width: width, height: height)
    }

    // Update published properties
    handBoundingBoxes = boundingBoxes
    isHandDetected = !boundingBoxes.isEmpty
  }

  /// Convert normalized Vision coordinates to view coordinates
  /// - Parameters:
  ///   - normalizedRect: Bounding box in normalized coordinates (0-1)
  ///   - viewSize: Size of the view displaying the camera feed
  /// - Returns: Bounding box in view coordinate system
  func convertToViewCoordinates(_ normalizedRect: CGRect, viewSize: CGSize) -> CGRect {
    // Vision coordinates: (0,0) is bottom-left, y increases upward
    // SwiftUI coordinates: (0,0) is top-left, y increases downward
    // Note: Camera orientation may require swapping x/y coordinates

    // Swap x and y coordinates to match camera orientation
    // Use the original y as x (with mirroring), and original x as y
    let x = (1.0 - normalizedRect.origin.y - normalizedRect.height) * viewSize.width
    let y = normalizedRect.origin.x * viewSize.height
    let width = normalizedRect.height * viewSize.width
    let height = normalizedRect.width * viewSize.height

    return CGRect(x: x, y: y, width: width, height: height)
  }
}
