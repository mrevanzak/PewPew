//
//  FingerPointsOverlay.swift
//  pewpew
//
//  Enhanced finger points overlay with accurate hand skeleton visualization
//

import SwiftUI

/// Enhanced finger points overlay with proper hand structure visualization
/// Optimized for iPad and larger screens with improved accuracy
struct FingerPointsOverlay: View {
  @ObservedObject var handDetectionService: HandDetectionService
  let viewSize: CGSize

  var body: some View {
    Canvas { context, size in
      // Direct drawing for maximum performance with enhanced visualization
      for hand in handDetectionService.handDetectionData.hands {
        // Draw hand skeleton structure
        drawHandSkeleton(context: context, hand: hand, size: size)
      }
    }
    .allowsHitTesting(false)
    .blendMode(.normal)
  }

  /// Draw complete hand skeleton with proper finger connections
  private func drawHandSkeleton(context: GraphicsContext, hand: HandPoints, size: CGSize) {
    // Draw wrist as central point
    drawPoint(context: context, point: hand.wrist, size: size, color: .red, radius: 8)

    // Draw thumb chain with connections
    drawFingerChain(
      context: context, wrist: hand.wrist, fingerPoints: hand.thumb, size: size, color: .orange)

    // Draw index finger chain with connections
    drawFingerChain(
      context: context, wrist: hand.wrist, fingerPoints: hand.index, size: size, color: .yellow)

    // Draw middle finger chain with connections
    drawFingerChain(
      context: context, wrist: hand.wrist, fingerPoints: hand.middle, size: size, color: .green)

    // Draw ring finger chain with connections
    drawFingerChain(
      context: context, wrist: hand.wrist, fingerPoints: hand.ring, size: size, color: .blue)

    // Draw little finger chain with connections
    drawFingerChain(
      context: context, wrist: hand.wrist, fingerPoints: hand.little, size: size, color: .purple)
  }

  /// Draw finger chain with proper connections between joints
  private func drawFingerChain(
    context: GraphicsContext, wrist: CGPoint, fingerPoints: [CGPoint], size: CGSize, color: Color
  ) {
    guard !fingerPoints.isEmpty else { return }

    // Draw line from wrist to first finger joint
    var path = Path()
    path.move(to: wrist)
    path.addLine(to: fingerPoints[0])
    context.stroke(path, with: .color(color), lineWidth: 4)

    // Draw connections between finger joints
    for i in 0..<fingerPoints.count {
      let currentPoint = fingerPoints[i]

      // Draw joint point
      drawPoint(context: context, point: currentPoint, size: size, color: color, radius: 6)

      // Draw line to next joint
      if i < fingerPoints.count - 1 {
        var jointPath = Path()
        jointPath.move(to: currentPoint)
        jointPath.addLine(to: fingerPoints[i + 1])
        context.stroke(jointPath, with: .color(color), lineWidth: 4)
      }
    }
  }

  /// Draw individual joint point
  private func drawPoint(
    context: GraphicsContext, point: CGPoint, size: CGSize, color: Color, radius: CGFloat
  ) {
    let circlePath = Path(
      ellipseIn: CGRect(
        x: point.x - radius,
        y: point.y - radius,
        width: radius * 2,
        height: radius * 2
      )
    )
    context.fill(circlePath, with: .color(color))

    // Add subtle stroke for better visibility
    context.stroke(circlePath, with: .color(.white), lineWidth: 2)
  }
}
