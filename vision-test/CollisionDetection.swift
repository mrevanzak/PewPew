//
//  CollisionDetection.swift
//  vision-test
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
  /// - Returns: True if any hand intersects with the shape
  static func isHandCollidingWithShape(handBoxes: [CGRect], shapeFrame: CGRect) -> Bool {
    return handBoxes.contains { handBox in
      handBox.intersects(shapeFrame)
    }
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
