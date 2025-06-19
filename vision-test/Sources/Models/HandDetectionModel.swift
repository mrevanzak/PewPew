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
  let leftFingerPoints: [CGPoint]
  let rightFingerPoints: [CGPoint]
  let leftWristPoint: CGPoint?
  let rightWristPoint: CGPoint?
  let leftPalmPoint: CGPoint?
  let rightPalmPoint: CGPoint?
  let isDetected: Bool
  let confidence: Float
  
  static let empty = HandDetectionData(
    boundingBoxes: [],
    fingerPointsPerHand: [],
    leftFingerPoints: [],
    rightFingerPoints: [],
    leftWristPoint: nil,
    rightWristPoint: nil,
    leftPalmPoint: nil,
    rightPalmPoint: nil,
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
