//
//  TargetImageCalculations.swift
//  pewpew
//
//  Utility for target image position and size calculations
//

import CoreGraphics
import Foundation

/// Utility class for calculating target image position and size based on hand data
struct TargetImageCalculations {

  /// Calculate palm center position from hand points
  /// - Parameter hand: HandPoints structure containing hand landmark data
  /// - Returns: Center position of the palm
  static func calculatePalmPosition(for hand: HandPoints) -> CGPoint {
    // Calculate palm center using wrist and base of fingers
    let basePoints = [
      hand.wrist,
      hand.thumb.count > 0 ? hand.thumb[0] : hand.wrist,
      hand.index.count > 0 ? hand.index[0] : hand.wrist,
      hand.middle.count > 0 ? hand.middle[0] : hand.wrist,
      hand.ring.count > 0 ? hand.ring[0] : hand.wrist,
      hand.little.count > 0 ? hand.little[0] : hand.wrist,
    ]

    let avgX = basePoints.reduce(0) { $0 + $1.x } / CGFloat(basePoints.count)
    let avgY = basePoints.reduce(0) { $0 + $1.y } / CGFloat(basePoints.count)

    return CGPoint(x: avgX, y: avgY)
  }

  /// Calculate dynamic target size based on hand distance from camera
  /// Uses hand span as a proxy for depth - larger span means closer hand
  /// - Parameters:
  ///   - hand: HandPoints structure containing hand landmark data
  ///   - baseSize: Base size for the target image
  /// - Returns: Calculated target size
  static func calculateTargetSize(for hand: HandPoints, baseSize: CGFloat = 200) -> CGFloat {
    let wrist = hand.wrist

    // Get fingertip positions (last element in each finger array)
    guard let thumbTip = hand.thumb.last,
      let indexTip = hand.index.last,
      let middleTip = hand.middle.last,
      let ringTip = hand.ring.last,
      let littleTip = hand.little.last
    else {
      return baseSize * 0.7  // Default size if finger data is incomplete
    }

    // Calculate hand size indicators
    let handSizeIndicator = calculateHandSizeIndicator(
      wrist: wrist,
      thumbTip: thumbTip,
      indexTip: indexTip,
      middleTip: middleTip,
      ringTip: ringTip,
      littleTip: littleTip
    )

    return mapToTargetSize(handSizeIndicator: handSizeIndicator, baseSize: baseSize)
  }

  /// Calculate hand size indicator based on finger distances and span
  /// - Parameters:
  ///   - wrist: Wrist position
  ///   - thumbTip: Thumb tip position
  ///   - indexTip: Index finger tip position
  ///   - middleTip: Middle finger tip position
  ///   - ringTip: Ring finger tip position
  ///   - littleTip: Little finger tip position
  /// - Returns: Hand size indicator value
  private static func calculateHandSizeIndicator(
    wrist: CGPoint,
    thumbTip: CGPoint,
    indexTip: CGPoint,
    middleTip: CGPoint,
    ringTip: CGPoint,
    littleTip: CGPoint
  ) -> CGFloat {
    // Calculate distances from wrist to fingertips
    let fingerDistances = [
      distance(from: wrist, to: thumbTip),
      distance(from: wrist, to: indexTip),
      distance(from: wrist, to: middleTip),
      distance(from: wrist, to: ringTip),
      distance(from: wrist, to: littleTip),
    ]

    // Average distance as hand size indicator
    let averageDistance = fingerDistances.reduce(0, +) / CGFloat(fingerDistances.count)

    // Calculate span between thumb and little finger
    let handSpan = distance(from: thumbTip, to: littleTip)

    // Combine both measurements for better depth estimation
    return (averageDistance + handSpan) / 2.0
  }

  /// Map hand size indicator to target size using linear interpolation
  /// - Parameters:
  ///   - handSizeIndicator: Calculated hand size indicator
  ///   - baseSize: Base size for the target image
  /// - Returns: Mapped target size
  private static func mapToTargetSize(handSizeIndicator: CGFloat, baseSize: CGFloat) -> CGFloat {
    // Define expected range of hand size values
    let minExpectedSize: CGFloat = 50  // When hand is far from camera
    let maxExpectedSize: CGFloat = 200  // When hand is close to camera

    // Clamp the hand size indicator to expected range
    let clampedSize = min(max(handSizeIndicator, minExpectedSize), maxExpectedSize)

    // Map to target size range
    let minTargetSize = baseSize * 0.4  // 40% of base size when far
    let maxTargetSize = baseSize * 1.5  // 150% of base size when close

    // Linear interpolation between min and max target sizes
    let sizeRatio = (clampedSize - minExpectedSize) / (maxExpectedSize - minExpectedSize)
    return minTargetSize + (maxTargetSize - minTargetSize) * sizeRatio
  }

  /// Calculate distance between two points
  /// - Parameters:
  ///   - point1: First point
  ///   - point2: Second point
  /// - Returns: Distance between the points
  private static func distance(from point1: CGPoint, to point2: CGPoint) -> CGFloat {
    let deltaX = point1.x - point2.x
    let deltaY = point1.y - point2.y
    return sqrt(deltaX * deltaX + deltaY * deltaY)
  }
}
