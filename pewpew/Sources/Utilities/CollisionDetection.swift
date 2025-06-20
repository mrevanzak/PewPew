//
//  CollisionDetection.swift
//  pewpew
//
//  Utility for collision detection between hands and overlay shapes
//

import CoreGraphics
import Foundation

/// Utility class for detecting collisions between hand bounding boxes and UI shapes
struct CollisionDetection {

  /// Check if any hand bounding box intersects with a target shape
  /// - Parameters:
  ///   - handBoxes: Array of hand bounding boxes in view coordinates
  ///   - shapeFrame: Frame of the target shape in view coordinates
  /// - Returns: True if any hand intersectlmn s with the shape
  static func isHandCollidingWithShape(handBoxes: [CGRect], shapeFrame: CGRect) -> Bool {
    return handBoxes.contains { handBox in
      handBox.intersects(shapeFrame)
    }
  }

  /// Check if finger points collide with a shape
  /// - Parameters:
  ///   - fingerPoints: Array of finger point arrays (per hand)
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
