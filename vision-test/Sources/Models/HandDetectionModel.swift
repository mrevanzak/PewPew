//
//  HandDetectionModel.swift
//  vision-test
//
//  Data models for hand detection
//

import CoreGraphics
import Foundation

/// Model representing detected hand points with individual finger joints
struct HandPoints {
    let wrist: CGPoint
    let thumb: [CGPoint]
    let index: [CGPoint]
    let middle: [CGPoint]
    let ring: [CGPoint]
    let little: [CGPoint]
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
