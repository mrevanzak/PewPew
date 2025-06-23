import SpriteKit
import SwiftUI

// MARK: - Game State Management Protocol
protocol GameStateManaging: ObservableObject {
  var score: Int { get set }
  var bullets: Int { get set }
  var isGameOver: Bool { get set }
  var gameStarted: Bool { get set }

  func startGame()
  func stopGame()
  func gameOver(finalScore: Int?)
  func replayGame()
}

// MARK: - Target Spawning Protocol
protocol TargetSpawning: AnyObject {
  func startSpawning()
  func stopSpawning()
  func spawnTarget()
}

// MARK: - Projectile Management Protocol
protocol ProjectileManaging: AnyObject {
  func spawnProjectile(at position: CGPoint)
  func canFireProjectile() -> Bool
}

// MARK: - Hand Tracking Protocol
protocol HandTracking: AnyObject {
  func updateHandCircles(with handData: HandDetectionData)
  func detectShootGesture(for handData: HandDetectionData)
}

// MARK: - Collision Handling Protocol
protocol CollisionHandling: AnyObject {
  func handleTargetHit(_ target: SKNode)
  func handleBulletTargetHit(_ target: SKNode)
  func handleProjectileCollision(projectile: SKNode, target: SKNode)
}

// MARK: - Score Management Protocol
protocol ScoreManaging: AnyObject {
  var currentScore: Int { get }
  var currentBullets: Int { get }

  func addScore(_ points: Int)
  func addBullets(_ count: Int)
  func useBullet() -> Bool
  func resetScore()
}

// MARK: - UI Update Protocol
protocol GameUIUpdating: AnyObject {
  func updateScoreDisplay(_ score: Int)
  func updateBulletsDisplay(_ bullets: Int)
  func showEffect(at position: CGPoint, text: String, color: UIColor)
  func animateScoreLabel()
  func animateBulletLabel()
}

// MARK: - Coordinate Conversion Protocol
protocol CoordinateConverting: AnyObject {
  func convertToSceneCoordinates(_ normalizedPoint: CGPoint) -> CGPoint
  func clampToScreenBounds(_ point: CGPoint) -> CGPoint
}

// MARK: - Game Engine Protocol
protocol GameEngine: AnyObject {
  var scoreManager: ScoreManaging { get }
  var isActive: Bool { get set }

  func startGame()
  func endGame(finalScore: Int)
  func pauseGame()
  func resumeGame()
}
