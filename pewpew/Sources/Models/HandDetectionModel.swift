//
//  HandDetectionModel.swift
//  pewpew
//
//  Data models for hand detection
//

import CoreGraphics
import Foundation
import SwiftUI

/// Model representing detected hand points with individual finger joints
struct HandPoints {
  let wrist: CGPoint
  let thumb: [CGPoint]
  let index: [CGPoint]
  let middle: [CGPoint]
  let ring: [CGPoint]
  let little: [CGPoint]
  let chirality: String
}

/// Model representing detected hand data with enhanced accuracy
struct HandDetectionData {
  let hands: [HandPoints]
  let isDetected: Bool
  let confidence: Float

  static let empty = HandDetectionData(
    hands: [],
    isDetected: false,
    confidence: 0.0
  )
}

/// Errors that can occur during hand detection
enum HandDetectionError: Error {
  case captureSessionSetup(reason: String)
  case visionError(error: Error)
  case otherError(error: Error)

  var localizedDescription: String {
    switch self {
    case .captureSessionSetup(let reason):
      return "Camera setup error: \(reason)"
    case .visionError(let error):
      return "Vision processing error: \(error.localizedDescription)"
    case .otherError(let error):
      return "Error: \(error.localizedDescription)"
    }
  }
}

/// Hand gesture states for shooting detection
enum HandGesture {
  case openPalm
  case fist
  case unknown
}

/// Model for tracking hand gesture states and transitions
struct HandGestureState {
  let gesture: HandGesture
  let confidence: Float
  let timestamp: Date

  init(gesture: HandGesture, confidence: Float = 1.0) {
    self.gesture = gesture
    self.confidence = confidence
    self.timestamp = Date()
  }
}
