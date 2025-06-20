//
//  HandDetectionService.swift
//  pewpew
//
//  Service for detecting hands in camera feed using Vision framework
//

import AVFoundation
import CoreGraphics
import Foundation
import UIKit
import Vision

/// Service responsible for hand detection and tracking
/// Uses Vision framework to analyze camera frames and detect hand positions with enhanced accuracy
class HandDetectionService: ObservableObject {
  // Published properties for UI updates
  @Published var handDetectionData = HandDetectionData.empty
  @Published var currentHandGestures: [String: HandGestureState] = [:]  // Chirality -> GestureState
  @Published var shootingTrigger = false  // Instant trigger for shooting
  @Published var triggeringHand: HandPoints? = nil  // Hand that triggered the shooting

  // Vision request for hand pose detection
  private var handPoseRequest: VNDetectHumanHandPoseRequest

  // Preview layer reference for coordinate conversion
  weak var previewLayer: AVCaptureVideoPreviewLayer?

  // Current video orientation for proper coordinate conversion
  private var currentVideoOrientation: AVCaptureVideoOrientation = .portrait

  // Gesture detection state tracking
  private var previousGestures: [String: HandGesture] = [:]
  private let gestureStabilityThreshold = 2  // Require 2 consecutive frames for stability
  private var gestureCounters: [String: [HandGesture: Int]] = [:]
  private var lastShootTime: [String: Date] = [:]  // Prevent rapid-fire shooting
  private var transitionProcessed: [String: Bool] = [:]  // Track if transition was already processed
  private var handPositions: [String: CGPoint] = [:]  // Track hand positions for stability
  private var lastValidTransitionTime: Date = Date.distantPast  // Global cooldown

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

    // Process hand gestures for shooting detection
    processHandGestures(detectedHands)
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

// MARK: - Hand Gesture Detection Extension
extension HandDetectionService {
  /// Process hand gestures to detect palm-to-fist transitions for shooting
  private func processHandGestures(_ hands: [HandPoints]) {
    var currentFrameGestures: [String: HandGesture] = [:]

    // Global cooldown to prevent any shooting for a short period
    let currentTime = Date()
    let globalCooldown: TimeInterval = 0.5
    let canShootGlobally = currentTime.timeIntervalSince(lastValidTransitionTime) >= globalCooldown

    // Only process if we have exactly one or two hands (prevent confusion with multiple hands)
    guard hands.count <= 2 else {
      return
    }

    // Detect current gesture for each hand
    for hand in hands {
      let gesture = detectHandGesture(hand)
      let palmPosition = TargetImageCalculations.calculatePalmPosition(for: hand)

      // Check if this hand position is stable (not jumping around)
      let isPositionStable: Bool
      if let previousPos = handPositions[hand.chirality] {
        let distance = sqrt(
          pow(palmPosition.x - previousPos.x, 2) + pow(palmPosition.y - previousPos.y, 2))
        isPositionStable = distance < 50  // Hand hasn't moved more than 50 pixels
      } else {
        isPositionStable = true  // First detection
      }

      // Update hand position
      handPositions[hand.chirality] = palmPosition

      currentFrameGestures[hand.chirality] = gesture

      // Only process gestures if position is stable
      if isPositionStable {
        // Initialize counter if needed
        if gestureCounters[hand.chirality] == nil {
          gestureCounters[hand.chirality] = [.openPalm: 0, .fist: 0, .unknown: 0]
        }

        // Update gesture counter
        gestureCounters[hand.chirality]?[gesture, default: 0] += 1

        // Reset other gesture counters
        for gestureType in [HandGesture.openPalm, .fist, .unknown] {
          if gestureType != gesture {
            gestureCounters[hand.chirality]?[gestureType] = 0
          }
        }

        // Check for stable gesture detection
        if let count = gestureCounters[hand.chirality]?[gesture], count >= gestureStabilityThreshold
        {
          let previousGesture = previousGestures[hand.chirality]

          // Only trigger if THIS SPECIFIC HAND transitioned from fist to open palm
          // AND we can shoot globally AND we haven't processed this transition
          if previousGesture == .fist && gesture == .openPalm && canShootGlobally {
            if transitionProcessed[hand.chirality] != true {
              triggerShooting(for: hand)
              lastShootTime[hand.chirality] = currentTime
              lastValidTransitionTime = currentTime
              transitionProcessed[hand.chirality] = true
            }
          }

          // Reset transition flag when returning to fist (ready for next shot)
          if gesture == .fist {
            transitionProcessed[hand.chirality] = false
          }

          // Update gesture state
          currentHandGestures[hand.chirality] = HandGestureState(gesture: gesture)
          previousGestures[hand.chirality] = gesture

          // Reset counter after stable detection
          gestureCounters[hand.chirality]?[gesture] = 0
        }
      }
    }

    // Clean up gestures for hands no longer detected
    let detectedChiralities = Set(hands.map { $0.chirality })
    for chirality in currentHandGestures.keys {
      if !detectedChiralities.contains(chirality) {
        currentHandGestures.removeValue(forKey: chirality)
        previousGestures.removeValue(forKey: chirality)
        gestureCounters.removeValue(forKey: chirality)
        transitionProcessed.removeValue(forKey: chirality)
        lastShootTime.removeValue(forKey: chirality)
        handPositions.removeValue(forKey: chirality)
      }
    }
  }

  /// Detect hand gesture based on finger positions
  private func detectHandGesture(_ hand: HandPoints) -> HandGesture {
    // Calculate if fingers are extended or curled
    let thumbExtended = isThumbExtended(hand)
    let indexExtended = isFingerExtended(hand.index)
    let middleExtended = isFingerExtended(hand.middle)
    let ringExtended = isFingerExtended(hand.ring)
    let littleExtended = isFingerExtended(hand.little)

    let extendedFingers = [
      thumbExtended, indexExtended, middleExtended, ringExtended, littleExtended,
    ]
    let extendedCount = extendedFingers.filter { $0 }.count

    // More lenient gesture detection for easier triggering
    if extendedCount >= 3 {  // Reduced from 4 to 3
      return .openPalm
    } else if extendedCount <= 2 {  // Increased from 1 to 2
      return .fist
    } else {
      return .unknown
    }
  }

  /// Check if a finger is extended based on joint positions
  private func isFingerExtended(_ fingerPoints: [CGPoint]) -> Bool {
    guard fingerPoints.count >= 4 else { return false }

    // Points are ordered from base to tip: [MCP, PIP, DIP, TIP]
    let mcp = fingerPoints[0]  // Base joint
    let pip = fingerPoints[1]  // First joint
    let dip = fingerPoints[2]  // Second joint
    let tip = fingerPoints[3]  // Fingertip

    // Calculate the distances from base to each joint
    let mcpToPip = distance(from: mcp, to: pip)
    let mcpToDip = distance(from: mcp, to: dip)
    let mcpToTip = distance(from: mcp, to: tip)

    // More lenient finger extension detection
    // A finger is extended if the tip is reasonably far from the base
    let isExtended = mcpToTip > mcpToPip * 1.2  // Reduced strictness

    return isExtended
  }

  /// Check if thumb is extended (different logic due to thumb anatomy)
  private func isThumbExtended(_ hand: HandPoints) -> Bool {
    guard hand.thumb.count >= 4 else { return false }

    // For thumb: [CMC, MCP, IP, TIP]
    let cmc = hand.thumb[0]  // Base
    let tip = hand.thumb[3]  // Tip

    // Distance from wrist to thumb tip vs wrist to thumb base
    let wristToTip = distance(from: hand.wrist, to: tip)
    let wristToBase = distance(from: hand.wrist, to: cmc)

    // More lenient thumb detection
    return wristToTip > wristToBase * 1.1  // Reduced from 1.3 to 1.1
  }

  /// Calculate distance between two points
  private func distance(from point1: CGPoint, to point2: CGPoint) -> CGFloat {
    let dx = point2.x - point1.x
    let dy = point2.y - point1.y
    return sqrt(dx * dx + dy * dy)
  }

  /// Trigger shooting event when palm-to-fist gesture detected
  private func triggerShooting(for hand: HandPoints) {
    // Store the hand that triggered the shooting
    triggeringHand = hand

    // Set shooting trigger to true momentarily for instant response
    shootingTrigger = true

    // Reset trigger after a very short delay to allow for detection
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.05) { [weak self] in
      self?.shootingTrigger = false
      self?.triggeringHand = nil
    }

    // Provide haptic feedback for instant response
    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    impactFeedback.impactOccurred()
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
