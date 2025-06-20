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
/// Uses Vision framework to analyze camera frames and detect hand positions
class HandDetectionService: ObservableObject {
  // Published properties for UI updates
  @Published var handDetectionData = HandDetectionData.empty
  
  // Vision request for hand pose detection
  private var handPoseRequest: VNDetectHumanHandPoseRequest
  
  init() {
    // Initialize hand pose detection request
    handPoseRequest = VNDetectHumanHandPoseRequest()
    handPoseRequest.maximumHandCount = 2  // Detect up to 10 hands
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
    
    var leftFingerPoints: [CGPoint] = []
    var rightFingerPoints: [CGPoint] = []
    var leftWristPoint: CGPoint?
    var rightWristPoint: CGPoint?
    var leftPalmPoint: CGPoint?
    var rightPalmPoint: CGPoint?
    
    // Process each hand observation
    results.forEach { observation in
      guard observation.confidence > 0.5 else { return }
      guard let recognizedPoints = try? observation.recognizedPoints(.all) else { return }
      
      // List of all finger joint keys
      let fingerKeys: [VNHumanHandPoseObservation.JointName] = [
        .thumbTip, .thumbIP, .thumbMP, .thumbCMC,
        .indexTip, .indexDIP, .indexPIP, .indexMCP,
        .middleTip, .middleDIP, .middlePIP, .middleMCP,
        .ringTip, .ringDIP, .ringPIP, .ringMCP,
        .littleTip, .littleDIP, .littlePIP, .littleMCP,
      ]
      
      // Extract finger points for this hand
      let fingerPoints: [CGPoint] = fingerKeys.compactMap { key in
        if let point = recognizedPoints[key], point.confidence > 0.5 {
          return CGPoint(x: point.location.x, y: point.location.y)
        }
        return nil
      }
      
      // Extract wrist point for this hand
      let wristPoint: CGPoint? = {
        if let wrist = recognizedPoints[.wrist], wrist.confidence > 0.5 {
          return CGPoint(x: wrist.location.x, y: wrist.location.y)
        }
        return nil
      }()
      
      // Assign to left or right hand based on chirality
      if observation.chirality == .left {
        leftFingerPoints = fingerPoints
        leftWristPoint = wristPoint
        // Calculate palm as average of wrist and MCPs
        let mcpKeys: [VNHumanHandPoseObservation.JointName] = [.thumbCMC, .indexMCP, .middleMCP, .ringMCP, .littleMCP]
        let mcpPoints = mcpKeys.compactMap { key in
          if let point = recognizedPoints[key], point.confidence > 0.5 {
            return CGPoint(x: point.location.x, y: point.location.y)
          }
          return nil
        }
        if let wrist = wristPoint, !mcpPoints.isEmpty {
          let allPalm = [wrist] + mcpPoints
          leftPalmPoint = CGPoint(
            x: allPalm.map { $0.x }.reduce(0, +) / CGFloat(allPalm.count),
            y: allPalm.map { $0.y }.reduce(0, +) / CGFloat(allPalm.count)
          )
        }
      } else if observation.chirality == .right {
        rightFingerPoints = fingerPoints
        rightWristPoint = wristPoint
        let mcpKeys: [VNHumanHandPoseObservation.JointName] = [.thumbCMC, .indexMCP, .middleMCP, .ringMCP, .littleMCP]
        let mcpPoints = mcpKeys.compactMap { key in
          if let point = recognizedPoints[key], point.confidence > 0.5 {
            return CGPoint(x: point.location.x, y: point.location.y)
          }
          return nil
        }
        if let wrist = wristPoint, !mcpPoints.isEmpty {
          let allPalm = [wrist] + mcpPoints
          rightPalmPoint = CGPoint(
            x: allPalm.map { $0.x }.reduce(0, +) / CGFloat(allPalm.count),
            y: allPalm.map { $0.y }.reduce(0, +) / CGFloat(allPalm.count)
          )
        }
      }
    }
    
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
    let averageConfidence = results.isEmpty ? 0.0 : results.reduce(0.0) { $0 + $1.confidence } / Float(results.count)
    
    // Update published properties with separated left/right data
    handDetectionData = HandDetectionData(
      boundingBoxes: [],
      fingerPointsPerHand: allFingerPoints,
      leftFingerPoints: leftFingerPoints,
      rightFingerPoints: rightFingerPoints,
      leftWristPoint: leftWristPoint,
      rightWristPoint: rightWristPoint,
      leftPalmPoint: leftPalmPoint,
      rightPalmPoint: rightPalmPoint,
      isDetected: !leftFingerPoints.isEmpty || !rightFingerPoints.isEmpty,
      confidence: averageConfidence
    )
  }
  
  /// Returns true if any hand is currently open (shoot gesture)
  func isAnyHandOpen() -> Bool {
    return getHandStates().contains(.open)
  }

  /// Returns true if any hand is currently closed (fist)
  func isAnyHandClosed() -> Bool {
    return getHandStates().contains(.closed)
  }

  /// Returns the state (open/closed) for each detected hand
  func getHandStates() -> [HandState] {
    var states: [HandState] = []
    if let leftPalm = handDetectionData.leftPalmPoint, handDetectionData.leftFingerPoints.count >= 5 {
      let isOpen = HandDetectionService.isHandOpen(fingerPoints: handDetectionData.leftFingerPoints, palm: leftPalm)
      states.append(isOpen ? .open : .closed)
    }
    if let rightPalm = handDetectionData.rightPalmPoint, handDetectionData.rightFingerPoints.count >= 5 {
      let isOpen = HandDetectionService.isHandOpen(fingerPoints: handDetectionData.rightFingerPoints, palm: rightPalm)
      states.append(isOpen ? .open : .closed)
    }
    return states
  }

  enum HandState { case open, closed }

  /// Determines if a hand is open (shoot gesture) by checking if all finger tips are far from the palm
  static func isHandOpen(fingerPoints: [CGPoint], palm: CGPoint) -> Bool {
    guard fingerPoints.count >= 5 else { return false }
    let distances = fingerPoints.map { tip in hypot(tip.x - palm.x, tip.y - palm.y) }
    let avg = distances.reduce(0, +) / CGFloat(distances.count)
    print("[HandDetectionService] avg finger-palm distance: \(avg) (threshold: 0.12)")
    return avg > 0.10 // normalized threshold, may need tuning
  }
  
  // Returns true if the specified hand is open
  func isHandOpen(hand: String) -> Bool {
    if hand == "left", let leftPalm = handDetectionData.leftPalmPoint, handDetectionData.leftFingerPoints.count >= 5 {
      return HandDetectionService.isHandOpen(fingerPoints: handDetectionData.leftFingerPoints, palm: leftPalm)
    }
    if hand == "right", let rightPalm = handDetectionData.rightPalmPoint, handDetectionData.rightFingerPoints.count >= 5 {
      return HandDetectionService.isHandOpen(fingerPoints: handDetectionData.rightFingerPoints, palm: rightPalm)
    }
    return false
  }
  // Returns true if the specified hand is closed
  func isHandClosed(hand: String) -> Bool {
    if hand == "left", let leftPalm = handDetectionData.leftPalmPoint, handDetectionData.leftFingerPoints.count >= 5 {
      return !HandDetectionService.isHandOpen(fingerPoints: handDetectionData.leftFingerPoints, palm: leftPalm)
    }
    if hand == "right", let rightPalm = handDetectionData.rightPalmPoint, handDetectionData.rightFingerPoints.count >= 5 {
      return !HandDetectionService.isHandOpen(fingerPoints: handDetectionData.rightFingerPoints, palm: rightPalm)
    }
    return false
  }
}

