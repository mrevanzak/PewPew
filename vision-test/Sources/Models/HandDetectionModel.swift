//
//  HandDetectionModel.swift
//  vision-test
//
//  Data models for hand detection
//

import CoreGraphics
import Foundation

/// Model representing detected hand data
struct HandDetectionData {
  let boundingBoxes: [CGRect]
  let fingerPointsPerHand: [[CGPoint]]
  let isDetected: Bool
  let confidence: Float

  static let empty = HandDetectionData(
    boundingBoxes: [],
    fingerPointsPerHand: [],
    isDetected: false,
    confidence: 0.0
  )
}

/// Model for collision detection results
struct CollisionResult {
  let hasCollision: Bool
  let overlapPercentage: CGFloat
  let collisionPoint: CGPoint?

  static let noCollision = CollisionResult(
    hasCollision: false,
    overlapPercentage: 0.0,
    collisionPoint: nil
  )
}
