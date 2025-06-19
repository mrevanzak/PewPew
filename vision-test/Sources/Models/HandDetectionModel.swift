//
//  HandDetectionModel.swift
//  vision-test
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

/// Model representing a sequence circle in the game
struct SequenceCircle: Identifiable {
  let id = UUID()
  let sequenceNumber: Int
  let position: CGPoint
  let size: CGFloat
  let color: Color
  let spawnTime: Date
  var isHit: Bool = false

  init(sequenceNumber: Int, position: CGPoint, size: CGFloat = 80, color: Color = .blue) {
    self.sequenceNumber = sequenceNumber
    self.position = position
    self.size = size
    self.color = color
    self.spawnTime = Date()
  }
}

/// Game state for sequence-based gameplay
struct GameState {
  var health: Int = 3
  var score: Int = 0
  var currentSequence: Int = 1
  var nextSequenceToSpawn: Int = 1
  var isGameOver: Bool = false
  var isGameWon: Bool = false

  // Game configuration
  let maxHealth: Int = 3
  let maxSequenceNumbers: Int = 5
  let circleLifetime: TimeInterval = 5.0

  mutating func reset() {
    health = maxHealth
    score = 0
    currentSequence = 1
    nextSequenceToSpawn = 1
    isGameOver = false
    isGameWon = false
  }

  mutating func takeDamage() {
    health = max(0, health - 1)
    if health <= 0 {
      isGameOver = true
    }
  }

  mutating func scorePoint() {
    score += 1
    currentSequence += 1

    // Check if player completed the sequence
    if currentSequence > maxSequenceNumbers {
      isGameWon = true
    }
  }

  mutating func resetSequence() {
    currentSequence = 1
    nextSequenceToSpawn = 1
  }
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
