//
//  CollisionDetection.swift
//  pewpew
//
//  Utility for collision detection between hands and overlay shapes
//

import CoreGraphics
import Foundation

/// Utility class for detecting collisions between hand points and UI shapes
struct CollisionDetection {

  /// Check if any hand bounding box intersects with a target shape
  /// - Parameters:
  ///   - handBoxes: Array of hand bounding boxes in view coordinates
  ///   - shapeFrame: Frame of the target shape in view coordinates
  /// - Returns: True if any hand intersects with the shape
  static func isHandCollidingWithShape(handBoxes: [CGRect], shapeFrame: CGRect) -> Bool {
    return handBoxes.contains { handBox in
      handBox.intersects(shapeFrame)
    }
  }

  /// Check if target image collides with a shape
  /// - Parameters:
  ///   - targetCenter: Center position of the target image
  ///   - targetSize: Size of the target image
  ///   - shapeFrame: Frame of the interactive shape
  /// - Returns: Collision result with details
  static func checkTargetImageCollision(
    targetCenter: CGPoint,
    targetSize: CGFloat,
    shapeFrame: CGRect
  ) -> CollisionResult {
    // Create target image frame
    let targetFrame = CGRect(
      x: targetCenter.x - targetSize / 2,
      y: targetCenter.y - targetSize / 2,
      width: targetSize,
      height: targetSize
    )

    // Check if target image frame intersects with shape frame
    if targetFrame.intersects(shapeFrame) {
      // Calculate overlap percentage
      let intersection = targetFrame.intersection(shapeFrame)
      let intersectionArea = intersection.width * intersection.height
      let targetArea = targetFrame.width * targetFrame.height
      let overlapPercentage = intersectionArea / targetArea

      return CollisionResult(
        hasCollision: true,
        overlapPercentage: overlapPercentage,
        collisionPoint: targetCenter
      )
    }

    return CollisionResult.noCollision
  }

  /// Check if finger points collide with a shape - Enhanced version for new hand structure
  /// - Parameters:
  ///   - hands: Array of HandPoints structures
  ///   - shapeFrame: Frame of the target shape
  ///   - viewSize: Size of the view for coordinate conversion
  /// - Returns: Collision result with details
  static func checkFingerCollision(
    hands: [HandPoints],
    shapeFrame: CGRect,
    viewSize: CGSize
  ) -> CollisionResult {
    for hand in hands {
      // Check all finger points for collision
      let allPoints = getAllHandPoints(from: hand)

      for point in allPoints {
        if shapeFrame.contains(point) {
          return CollisionResult(
            hasCollision: true,
            overlapPercentage: 1.0,
            collisionPoint: point
          )
        }
      }
    }
    return CollisionResult.noCollision
  }

  /// Legacy method for backward compatibility
  /// - Parameters:
  ///   - fingerPoints: Array of finger point arrays (per hand) - deprecated
  ///   - shapeFrame: Frame of the target shape
  ///   - viewSize: Size of the view for coordinate conversion
  /// - Returns: Collision result with details
  static func checkFingerCollision(
    fingerPoints: [[CGPoint]],
    shapeFrame: CGRect,
    viewSize: CGSize
  ) -> CollisionResult {
    for handPoints in fingerPoints {
      for point in handPoints {
        // Convert normalized coordinates to view coordinates
        let viewPoint = CGPoint(
          x: (1 - point.x) * viewSize.width,
          y: (1 - point.y) * viewSize.height
        )

        if shapeFrame.contains(viewPoint) {
          return CollisionResult(
            hasCollision: true,
            overlapPercentage: 1.0,
            collisionPoint: viewPoint
          )
        }
      }
    }
    return CollisionResult.noCollision
  }

  /// Extract all points from a hand structure for collision detection
  /// - Parameter hand: HandPoints structure
  /// - Returns: Array of all CGPoints from the hand
  private static func getAllHandPoints(from hand: HandPoints) -> [CGPoint] {
    var allPoints: [CGPoint] = []

    // Add wrist
    allPoints.append(hand.wrist)

    // Add all finger points
    allPoints.append(contentsOf: hand.thumb)
    allPoints.append(contentsOf: hand.index)
    allPoints.append(contentsOf: hand.middle)
    allPoints.append(contentsOf: hand.ring)
    allPoints.append(contentsOf: hand.little)

    return allPoints
  }

  /// Check if a specific point is within any hand bounding box
  /// - Parameters:
  ///   - point: Point to check
  ///   - handBoxes: Array of hand bounding boxes
  /// - Returns: True if point is within any hand box
  static func isPointInHand(point: CGPoint, handBoxes: [CGRect]) -> Bool {
    return handBoxes.contains { handBox in
      handBox.contains(point)
    }
  }

  /// Calculate overlap percentage between hand and shape
  /// - Parameters:
  ///   - handBox: Hand bounding box
  ///   - shapeFrame: Shape frame
  /// - Returns: Overlap percentage (0.0 to 1.0)
  static func overlapPercentage(handBox: CGRect, shapeFrame: CGRect) -> CGFloat {
    let intersection = handBox.intersection(shapeFrame)

    guard !intersection.isNull && !intersection.isEmpty else {
      return 0.0
    }

    let intersectionArea = intersection.width * intersection.height
    let shapeArea = shapeFrame.width * shapeFrame.height

    return intersectionArea / shapeArea
  }
}
