//
//  HandDetectionService.swift
//  pewpew
//
//  Service for detecting hands in camera feed using Vision framework
//

import AVFoundation
import CoreGraphics
import Foundation
import Vision

/// Service responsible for hand detection and tracking
/// Uses Vision framework to analyze camera frames and detect hand positions with enhanced accuracy
class HandDetectionService: ObservableObject {
  // Published properties for UI updates
  @Published var handDetectionData = HandDetectionData.empty

  // Vision request for hand pose detection
  private var handPoseRequest: VNDetectHumanHandPoseRequest

  // Preview layer reference for coordinate conversion
  weak var previewLayer: AVCaptureVideoPreviewLayer?

  // Current video orientation for proper coordinate conversion
  private var currentVideoOrientation: AVCaptureVideoOrientation = .portrait

  init() {
    // Initialize hand pose detection request
    handPoseRequest = VNDetectHumanHandPoseRequest()
    handPoseRequest.maximumHandCount = 10  // Detect up to 10 hands
  }

  /// Set the preview layer for coordinate conversion
  func setPreviewLayer(_ layer: AVCaptureVideoPreviewLayer) {
    previewLayer = layer
  }

  /// Update the current video orientation
  func updateOrientation(_ orientation: AVCaptureVideoOrientation) {
    currentVideoOrientation = orientation
  }

  /// Get CGImagePropertyOrientation based on current video orientation
  private func getImageOrientation() -> CGImagePropertyOrientation {
    // Since Info.plist only supports landscape orientations, we only handle those
    switch currentVideoOrientation {
    case .landscapeLeft:
      return .up
    case .landscapeRight:
      return .down
    case .portrait:
      // Shouldn't happen due to Info.plist, but handle gracefully
      return .right
    case .portraitUpsideDown:
      // Shouldn't happen due to Info.plist, but handle gracefully
      return .left
    @unknown default:
      return .up  // Default to landscape left equivalent
    }
  }

  /// Process a sample buffer from camera to detect hands
  /// - Parameter sampleBuffer: Camera frame data
  func processFrame(_ sampleBuffer: CMSampleBuffer) {
    guard let pixelBuffer = CMSampleBufferGetImageBuffer(sampleBuffer) else {
      return
    }

    // Create vision request handler with proper orientation
    let imageOrientation = getImageOrientation()
    let handler = VNImageRequestHandler(
      cmSampleBuffer: sampleBuffer,
      orientation: imageOrientation,
      options: [:]
    )

    do {
      // Perform hand detection
      try handler.perform([handPoseRequest])

      // Process results on main queue for UI updates
      DispatchQueue.main.async { [weak self] in
        self?.processHandDetectionResults()
      }
    } catch {
      print("Failed to perform hand detection: \(error)")
      DispatchQueue.main.async { [weak self] in
        self?.handDetectionData = HandDetectionData.empty
      }
    }
  }

  /// Process hand detection results and update published properties
  private func processHandDetectionResults() {
    guard let results = handPoseRequest.results else {
      handDetectionData = HandDetectionData.empty
      return
    }

    // Extract hand points for each detected hand
    let detectedHands: [HandPoints] = results.compactMap { observation in
      guard observation.confidence > 0.5 else { return nil }

      do {
        // Get all finger points with proper sorting
        let thumbPoints = try observation.recognizedPoints(.thumb).toSortedThumbArray()
        let indexPoints = try observation.recognizedPoints(.indexFinger).toSortedIndexArray()
        let middlePoints = try observation.recognizedPoints(.middleFinger).toSortedMiddleArray()
        let ringPoints = try observation.recognizedPoints(.ringFinger).toSortedRingArray()
        let littlePoints = try observation.recognizedPoints(.littleFinger).toSortedLittleArray()

        let chirality: String
        switch observation.chirality {
        case .left:
          chirality = "left"
        case .right:
          chirality = "right"
        default:
          chirality = "unknown"

        }

        // Convert to UIKit coordinates
        let thumbPointsFixed = thumbPoints.map {
          $0.location.toUIKitCoordinates(previewLayer: previewLayer)
        }
        let indexPointsFixed = indexPoints.map {
          $0.location.toUIKitCoordinates(previewLayer: previewLayer)
        }
        let middlePointsFixed = middlePoints.map {
          $0.location.toUIKitCoordinates(previewLayer: previewLayer)
        }
        let ringPointsFixed = ringPoints.map {
          $0.location.toUIKitCoordinates(previewLayer: previewLayer)
        }
        let littlePointsFixed = littlePoints.map {
          $0.location.toUIKitCoordinates(previewLayer: previewLayer)
        }
        let wristPointFixed = try observation.recognizedPoint(.wrist).location.toUIKitCoordinates(
          previewLayer: previewLayer)

        let hand = HandPoints(
          wrist: wristPointFixed,
          thumb: thumbPointsFixed,
          index: indexPointsFixed,
          middle: middlePointsFixed,
          ring: ringPointsFixed,
          little: littlePointsFixed,
          chirality: chirality
        )
        return hand
      } catch {
        print("Error processing hand points: \(error)")
        return nil
      }
    }

    // Calculate average confidence
    let averageConfidence =
      results.isEmpty ? 0.0 : results.reduce(0.0) { $0 + $1.confidence } / Float(results.count)

    // Update published properties
    handDetectionData = HandDetectionData(
      hands: detectedHands,
      isDetected: !detectedHands.isEmpty,
      confidence: averageConfidence
    )
  }
}

// MARK: - Extensions for proper hand joint sorting
extension [VNHumanHandPoseObservation.JointName: VNRecognizedPoint] {
  func toSortedThumbArray() -> [VNRecognizedPoint] {
    var arr: [VNRecognizedPoint] = []
    arr.append(self[.thumbTip]!)
    arr.append(self[.thumbIP]!)
    arr.append(self[.thumbMP]!)
    arr.append(self[.thumbCMC]!)
    return arr.reversed()
  }

  func toSortedIndexArray() -> [VNRecognizedPoint] {
    var arr: [VNRecognizedPoint] = []
    arr.append(self[.indexTip]!)
    arr.append(self[.indexDIP]!)
    arr.append(self[.indexPIP]!)
    arr.append(self[.indexMCP]!)
    return arr.reversed()
  }

  func toSortedMiddleArray() -> [VNRecognizedPoint] {
    var arr: [VNRecognizedPoint] = []
    arr.append(self[.middleTip]!)
    arr.append(self[.middleDIP]!)
    arr.append(self[.middlePIP]!)
    arr.append(self[.middleMCP]!)
    return arr.reversed()
  }

  func toSortedRingArray() -> [VNRecognizedPoint] {
    var arr: [VNRecognizedPoint] = []
    arr.append(self[.ringTip]!)
    arr.append(self[.ringDIP]!)
    arr.append(self[.ringPIP]!)
    arr.append(self[.ringMCP]!)
    return arr.reversed()
  }

  func toSortedLittleArray() -> [VNRecognizedPoint] {
    var arr: [VNRecognizedPoint] = []
    arr.append(self[.littleTip]!)
    arr.append(self[.littleDIP]!)
    arr.append(self[.littlePIP]!)
    arr.append(self[.littleMCP]!)
    return arr.reversed()
  }
}

// MARK: - Coordinate conversion extension
extension CGPoint {
  func toUIKitCoordinates(previewLayer: AVCaptureVideoPreviewLayer?) -> CGPoint {
    guard let previewLayer = previewLayer else {
      // Fallback coordinate conversion if no preview layer
      return CGPoint(x: x, y: 1 - y)
    }
    let avFoundationCoords = CGPoint(x: x, y: 1 - y)
    return previewLayer.layerPointConverted(fromCaptureDevicePoint: avFoundationCoords)
  }
}
