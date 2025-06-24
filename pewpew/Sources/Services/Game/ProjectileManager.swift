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

    let startPosition = CGPoint(x: scene.size.width / 2, y: scene.size.height * 0.15)
    let projectile = createProjectile(targetPosition: targetPosition, startPosition: startPosition)
    projectile.position = startPosition

    scene.addChild(projectile)
    animateProjectile(projectile, to: targetPosition)

    // Play shoot sound effect
    let shootSound = SKAction.playSoundFileNamed("revolverShoot.mp3", waitForCompletion: false)
    scene.run(shootSound)

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

  private func createProjectile(targetPosition: CGPoint, startPosition: CGPoint) -> SKSpriteNode {
    let projectile = SKSpriteNode(imageNamed: AssetName.bullet)
    projectile.size = CGSize(width: 15, height: 35)
    projectile.name = NodeName.projectile

    // Calculate angle and rotate projectile to face target
    let deltaX = targetPosition.x - startPosition.x
    let deltaY = targetPosition.y - startPosition.y
    let angle = atan2(deltaY, deltaX) - CGFloat.pi / 2
    projectile.zRotation = angle

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
