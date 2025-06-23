import SpriteKit
import SwiftUI

/// Target spawner with animations and improved positioning
final class TargetSpawner: TargetSpawning {

  // MARK: - Properties
  private weak var scene: SKScene?
  private var isSpawning = false
  private let scoreManager: ScoreManaging

  // MARK: - Initialization
  init(scene: SKScene?, scoreManager: ScoreManaging) {
    self.scene = scene
    self.scoreManager = scoreManager
  }

  // MARK: - TargetSpawning Implementation

  func startSpawning() {
    guard !isSpawning, let scene = scene else { return }

    isSpawning = true

    let spawnAction = SKAction.run { [weak self] in
      self?.spawnTarget()
    }

    let waitAction = SKAction.wait(forDuration: GameConfiguration.Timing.spawningInterval)
    let sequenceAction = SKAction.sequence([spawnAction, waitAction])
    let repeatAction = SKAction.repeatForever(sequenceAction)

    scene.run(repeatAction, withKey: "spawning")
  }

  func stopSpawning() {
    isSpawning = false
    scene?.removeAction(forKey: "spawning")
  }

  func spawnTarget() {
    guard let scene = scene, isSpawning else { return }

    let targetSize = CGFloat.random(
      in: GameConfiguration.Target.minSize...GameConfiguration.Target.maxSize)
    let shouldSpawnBulletTarget =
      scoreManager.currentScore > 0
      && Double.random(in: 0...1) < GameConfiguration.Target.bulletTargetSpawnChance

    let (target, isAlien) =
      shouldSpawnBulletTarget
      ? (createBulletTarget(size: targetSize), false) : (createAlienTarget(size: targetSize), true)

    let (startPosition, endPosition) = calculateTargetPath(
      for: target, shouldSpawnBulletTarget: shouldSpawnBulletTarget)

    target.position = startPosition
    scene.addChild(target)

    animateTarget(target, to: endPosition, isAlien: isAlien)
  }

  // MARK: - Target Creation

  private func createBulletTarget(size: CGFloat) -> SKSpriteNode {
    let target = SKSpriteNode(color: .cyan, size: CGSize(width: size, height: size))
    target.name = NodeName.bulletTarget
    target.physicsBody = SKPhysicsBody(rectangleOf: target.size)
    setupPhysicsBody(for: target)
    return target
  }

  private func createAlienTarget(size: CGFloat) -> SKSpriteNode {
    let texture = SKTexture(imageNamed: AssetName.alien)
    let aspectRatio = texture.size().width / texture.size().height
    let targetSize = CGSize(width: size * aspectRatio, height: size)

    let target = SKSpriteNode(texture: texture, color: .clear, size: targetSize)
    target.name = NodeName.alienTarget
    target.physicsBody = SKPhysicsBody(texture: texture, size: targetSize)
    setupPhysicsBody(for: target)
    return target
  }

  private func setupPhysicsBody(for target: SKSpriteNode) {
    target.physicsBody?.categoryBitMask = GameConfiguration.Physics.Category.target
    target.physicsBody?.contactTestBitMask =
      GameConfiguration.Physics.Category.player | GameConfiguration.Physics.Category.projectile
    target.physicsBody?.collisionBitMask = 0
    target.physicsBody?.isDynamic = true
    target.physicsBody?.affectedByGravity = false
  }

  // MARK: - Path Calculation

  private func calculateTargetPath(for target: SKSpriteNode, shouldSpawnBulletTarget: Bool)
    -> (CGPoint, CGPoint)
  {
    guard let scene = scene else { return (.zero, .zero) }

    let radius = max(target.size.width, target.size.height) / 2

    if shouldSpawnBulletTarget {
      // Enhanced bullet targets - spawn higher and move down
      let x = CGFloat.random(in: radius...(scene.size.width - radius))
      let startPosition = CGPoint(x: x, y: (scene.size.height * 0.85) + radius)
      let endPosition = CGPoint(x: x, y: -radius)
      return (startPosition, endPosition)
    } else {
      // Enhanced alien targets - improved positioning
      let minY = radius + scene.size.height * GameConfiguration.Target.minYPosition
      let maxY = scene.size.height * 0.9 - radius
      let y = CGFloat.random(in: minY...maxY)

      let startFromLeft = Bool.random()
      let startPosition =
        startFromLeft ? CGPoint(x: -radius, y: y) : CGPoint(x: scene.size.width + radius, y: y)
      let endPosition =
        startFromLeft ? CGPoint(x: scene.size.width + radius, y: y) : CGPoint(x: -radius, y: y)

      return (startPosition, endPosition)
    }
  }

  // MARK: - Animation

  private func animateTarget(_ target: SKSpriteNode, to endPosition: CGPoint, isAlien: Bool) {
    let distance = hypot(endPosition.x - target.position.x, endPosition.y - target.position.y)
    let speed = CGFloat.random(in: GameConfiguration.Target.targetSpeed)
    let duration = distance / speed

    let moveAction = SKAction.move(to: endPosition, duration: duration)
    let removeAction = SKAction.removeFromParent()

    // Add wiggle animation for aliens (UFOs)
    if isAlien {
      let wiggle = SKAction.sequence([
        SKAction.rotate(byAngle: 0.08, duration: 0.18),
        SKAction.rotate(byAngle: -0.16, duration: 0.36),
        SKAction.rotate(byAngle: 0.08, duration: 0.18),
      ])
      let wiggleForever = SKAction.repeatForever(wiggle)
      target.run(wiggleForever)
    }

    target.run(SKAction.sequence([moveAction, removeAction]))
  }
}

// MARK: - Node Names
enum NodeName {
  static let bulletTarget = "bullet_target"
  static let alienTarget = "moving_circle"
  static let projectile = "projectile"
  static let leftHandCircle = "handCircle_left"
  static let rightHandCircle = "handCircle_right"
}
