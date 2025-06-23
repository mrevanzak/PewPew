import SpriteKit

/// Handles coordinate conversion between normalized Vision coordinates and SpriteKit scene coordinates
final class CoordinateConverter: CoordinateConverting {

  // MARK: - Properties
  private weak var scene: SKScene?

  // MARK: - Initialization
  init(scene: SKScene?) {
    self.scene = scene
  }

  // MARK: - CoordinateConverting Implementation

  func convertToSceneCoordinates(_ normalizedPoint: CGPoint) -> CGPoint {
    guard let scene = scene else { return .zero }

    // Convert normalized coordinates (0-1) to scene coordinates
    // Vision framework uses normalized coordinates with origin at bottom-left
    // SpriteKit also uses bottom-left origin, but we need to flip X for camera
    let x = (1.0 - normalizedPoint.x) * scene.frame.width
    let y = normalizedPoint.y * scene.frame.height

    return clampToScreenBounds(CGPoint(x: x, y: y))
  }

  func clampToScreenBounds(_ point: CGPoint) -> CGPoint {
    guard let scene = scene else { return point }

    let margin = GameConfiguration.UI.screenMargin
    let clampedX = max(margin, min(scene.frame.width - margin, point.x))
    let clampedY = max(margin, min(scene.frame.height - margin, point.y))

    return CGPoint(x: clampedX, y: clampedY)
  }

  // MARK: - Additional Helpers

  /// Convert a point from scene coordinates back to normalized coordinates
  func convertToNormalizedCoordinates(_ scenePoint: CGPoint) -> CGPoint {
    guard let scene = scene else { return .zero }

    let normalizedX = 1.0 - (scenePoint.x / scene.frame.width)
    let normalizedY = scenePoint.y / scene.frame.height

    return CGPoint(x: normalizedX, y: normalizedY)
  }

  /// Check if a point is within the scene bounds
  func isPointInBounds(_ point: CGPoint) -> Bool {
    guard let scene = scene else { return false }

    return point.x >= 0 && point.x <= scene.frame.width && point.y >= 0
      && point.y <= scene.frame.height
  }
}
