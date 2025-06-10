//
//  FingerPointsOverlay.swift
//  vision-test
//
//  Reusable component for displaying finger tracking points
//

import SwiftUI

/// Real-time optimized finger points overlay that always updates
struct FingerPointsOverlay: View {
  @ObservedObject var handDetectionService: HandDetectionService
  let viewSize: CGSize

  var body: some View {
    Canvas { context, size in
      // Direct drawing for maximum performance
      for handPoints in handDetectionService.handDetectionData.fingerPointsPerHand {
        for point in handPoints {
          let viewPoint = CGPoint(
            x: (1 - point.x) * size.width,
            y: (1 - point.y) * size.height
          )

          context.fill(
            Path(
              ellipseIn: CGRect(
                x: viewPoint.x - 6,
                y: viewPoint.y - 6,
                width: 12,
                height: 12
              )),
            with: .color(.orange)
          )
        }
      }
    }
    .allowsHitTesting(false)
    .blendMode(.normal)
  }
}
