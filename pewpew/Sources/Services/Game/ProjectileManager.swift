import SpriteKit

/// Manages projectile spawning and lifecycle
final class ProjectileManager: ProjectileManaging {

  // MARK: - Properties
  private weak var scene: SKScene?
  private let scoreManager: ScoreManaging

  // MARK: - Initialization
  init(scene: SKScene?, scoreManager: ScoreManaging) {
    self.scene = scene
    self.scoreManager = scoreManager
  }

  // MARK: - ProjectileManaging Implementation

  func spawnProjectile(at targetPosition: CGPoint) {
    guard canFireProjectile(),
      let scene = scene,
      scoreManager.useBullet()
    else { return }

    let projectile = createProjectile()
    let startPosition = CGPoint(x: scene.size.width / 2, y: 0)
    projectile.position = startPosition

    scene.addChild(projectile)
    animateProjectile(projectile, to: targetPosition)

    // Check for game over after using bullet
    if scoreManager.currentBullets <= 0 {
      DispatchQueue.main.asyncAfter(deadline: .now() + 0.1) {
        // Notify that game should end
        NotificationCenter.default.post(name: .gameOverNotification, object: nil)
      }
    }
  }

  func canFireProjectile() -> Bool {
    return scoreManager.currentBullets > 0
  }

  // MARK: - Private Helpers

  private func createProjectile() -> SKShapeNode {
    let projectile = SKShapeNode(circleOfRadius: GameConfiguration.UI.projectileRadius)
    projectile.fillColor = .white
    projectile.strokeColor = .yellow
    projectile.lineWidth = 2
    projectile.name = NodeName.projectile

    // Setup physics
    projectile.physicsBody = SKPhysicsBody(circleOfRadius: GameConfiguration.UI.projectileRadius)
    projectile.physicsBody?.categoryBitMask = GameConfiguration.Physics.Category.projectile
    projectile.physicsBody?.contactTestBitMask = GameConfiguration.Physics.Category.target
    projectile.physicsBody?.collisionBitMask = 0
    projectile.physicsBody?.isDynamic = true
    projectile.physicsBody?.affectedByGravity = false

    return projectile
  }

  private func animateProjectile(_ projectile: SKNode, to targetPosition: CGPoint) {
    let startPosition = projectile.position
    let distance = hypot(targetPosition.x - startPosition.x, targetPosition.y - startPosition.y)
    let duration = distance / GameConfiguration.Game.projectileSpeed

    let moveAction = SKAction.move(to: targetPosition, duration: duration)
    let removeAction = SKAction.removeFromParent()

    projectile.run(SKAction.sequence([moveAction, removeAction]))
  }
}

// MARK: - Notification Extension
extension Notification.Name {
  static let gameOverNotification = Notification.Name("GameOverNotification")
}
