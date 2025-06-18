//
//  CollisionDetectionStrategy.swift
//  vision-test
//
//  Collision detection strategy pattern for flexible collision handling
//

import CoreGraphics
import Foundation

/// Protocol defining collision detection strategy interface
protocol CollisionDetectionStrategy {
  /// Check for collision between hands and a shape
  /// - Parameters:
  ///   - hands: Array of hand detection data
  ///   - shapeFrame: Frame of the target shape
  ///   - viewSize: Size of the view for coordinate conversion
  /// - Returns: Collision result with details
  func checkCollision(
    hands: [HandPoints],
    shapeFrame: CGRect,
    viewSize: CGSize
  ) -> CollisionResult
}

/// Target image collision detection strategy
struct TargetImageCollisionStrategy: CollisionDetectionStrategy {
  let baseSize: CGFloat

  init(baseSize: CGFloat = 100) {
    self.baseSize = baseSize
  }

  func checkCollision(
    hands: [HandPoints],
    shapeFrame: CGRect,
    viewSize: CGSize
  ) -> CollisionResult {
    for hand in hands {
      let targetCenter = TargetImageCalculations.calculatePalmPosition(for: hand)
      let targetSize = TargetImageCalculations.calculateTargetSize(for: hand, baseSize: baseSize)

      let collision = CollisionDetection.checkTargetImageCollision(
        targetCenter: targetCenter,
        targetSize: targetSize,
        shapeFrame: shapeFrame
      )

      if collision.hasCollision {
        return collision
      }
    }
    return CollisionResult.noCollision
  }
}

/// Finger points collision detection strategy
struct FingerPointsCollisionStrategy: CollisionDetectionStrategy {
  func checkCollision(
    hands: [HandPoints],
    shapeFrame: CGRect,
    viewSize: CGSize
  ) -> CollisionResult {
    return CollisionDetection.checkFingerCollision(
      hands: hands,
      shapeFrame: shapeFrame,
      viewSize: viewSize
    )
  }
}

/// Index finger tip collision detection strategy
struct IndexFingerTipCollisionStrategy: CollisionDetectionStrategy {
  func checkCollision(
    hands: [HandPoints],
    shapeFrame: CGRect,
    viewSize: CGSize
  ) -> CollisionResult {
    for hand in hands {
      guard let indexTip = hand.index.last else { continue }

      if shapeFrame.contains(indexTip) {
        return CollisionResult(
          hasCollision: true,
          overlapPercentage: 1.0,
          collisionPoint: indexTip
        )
      }
    }
    return CollisionResult.noCollision
  }
}

/// Palm center collision detection strategy
struct PalmCenterCollisionStrategy: CollisionDetectionStrategy {
  func checkCollision(
    hands: [HandPoints],
    shapeFrame: CGRect,
    viewSize: CGSize
  ) -> CollisionResult {
    for hand in hands {
      let palmCenter = TargetImageCalculations.calculatePalmPosition(for: hand)

      if shapeFrame.contains(palmCenter) {
        return CollisionResult(
          hasCollision: true,
          overlapPercentage: 1.0,
          collisionPoint: palmCenter
        )
      }
    }
    return CollisionResult.noCollision
  }
}

/// Collision detection types enum for easy switching
enum CollisionDetectionType: Equatable {
  case targetImage(baseSize: CGFloat = 100)
  case fingerPoints
  case indexFingerTip
  case palmCenter

  /// Create strategy instance from enum case
  func createStrategy() -> CollisionDetectionStrategy {
    switch self {
    case .targetImage(let baseSize):
      return TargetImageCollisionStrategy(baseSize: baseSize)
    case .fingerPoints:
      return FingerPointsCollisionStrategy()
    case .indexFingerTip:
      return IndexFingerTipCollisionStrategy()
    case .palmCenter:
      return PalmCenterCollisionStrategy()
    }
  }

  /// Equatable conformance for SwiftUI onChange support
  static func == (lhs: CollisionDetectionType, rhs: CollisionDetectionType) -> Bool {
    switch (lhs, rhs) {
    case (.targetImage(let lhsSize), .targetImage(let rhsSize)):
      return lhsSize == rhsSize
    case (.fingerPoints, .fingerPoints),
      (.indexFingerTip, .indexFingerTip),
      (.palmCenter, .palmCenter):
      return true
    default:
      return false
    }
  }
}
