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
  // Published properties for UI updates
  @Published var handDetectionData = HandDetectionData.empty

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
      handDetectionData = HandDetectionData.empty
      return
    }

    // Extract finger points for each hand
    let allFingerPoints: [[CGPoint]] = results.compactMap { observation in
      guard observation.confidence > 0.5 else { return nil }
      guard let recognizedPoints = try? observation.recognizedPoints(.all) else {
        return nil
      }

      // List of all finger joint keys
      let fingerKeys: [VNHumanHandPoseObservation.JointName] = [
        .thumbTip, .thumbIP, .thumbMP, .thumbCMC,
        .indexTip, .indexDIP, .indexPIP, .indexMCP,
        .middleTip, .middleDIP, .middlePIP, .middleMCP,
        .ringTip, .ringDIP, .ringPIP, .ringMCP,
        .littleTip, .littleDIP, .littlePIP, .littleMCP,
      ]

      let points: [CGPoint] = fingerKeys.compactMap { key in
        if let point = recognizedPoints[key], point.confidence > 0.5 {
          return CGPoint(x: point.location.x, y: point.location.y)
        }
        return nil
      }
      return points
    }

    // Calculate average confidence
    let averageConfidence =
      results.isEmpty ? 0.0 : results.reduce(0.0) { $0 + $1.confidence } / Float(results.count)

    // Update published properties
    handDetectionData = HandDetectionData(
      boundingBoxes: [],  // Will be calculated if needed
      fingerPointsPerHand: allFingerPoints,
      isDetected: !allFingerPoints.isEmpty,
      confidence: averageConfidence
    )
  }
}
