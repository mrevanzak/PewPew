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

    // Randomly spawn alien without ufo (e.g. 50% chance)
    if Double.random(in: 0...1) < 0.50 {
      let spawnLeft = Bool.random()
      spawnAlienWithoutUfo(onLeft: spawnLeft)
      return
    }

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

    animateTarget(target, to: endPosition)
  }

  // MARK: - Target Creation

  private func createBulletTarget(size: CGFloat) -> SKSpriteNode {
    let texture = SKTexture(imageNamed: AssetName.lootbox)
    let aspectRatio = texture.size().width / texture.size().height
    let targetSize = CGSize(width: size * aspectRatio * 2, height: size * 2)

    let target = SKSpriteNode(texture: texture, color: .clear, size: targetSize)
    target.name = NodeName.bulletTarget
    target.physicsBody = SKPhysicsBody(texture: texture, size: targetSize)
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

  private func animateTarget(_ target: SKSpriteNode, to endPosition: CGPoint) {
    let distance = hypot(endPosition.x - target.position.x, endPosition.y - target.position.y)
    let speed = CGFloat.random(in: GameConfiguration.Target.targetSpeed)
    let duration = distance / speed
    
    let moveAction = SKAction.move(to: endPosition, duration: duration)
    let removeAction = SKAction.removeFromParent()
    
    let wiggle = SKAction.sequence([
      SKAction.rotate(byAngle: 0.08, duration: 0.18),
      SKAction.rotate(byAngle: -0.16, duration: 0.36),
      SKAction.rotate(byAngle: 0.08, duration: 0.18),
    ])
    let wiggleForever = SKAction.repeatForever(wiggle)
    target.run(wiggleForever)
    
    
    target.run(SKAction.sequence([moveAction, removeAction]))
  }

  // MARK: - Alien Without UFO
  func spawnAlienWithoutUfo(onLeft: Bool) {
    guard let scene = scene else { return }
    // Find the building node
    let buildingName = onLeft ? "leftBuilding" : "rightBuilding"
    guard let building = scene.childNode(withName: buildingName) as? SKSpriteNode else { return }

    // Prevent more than one alienWithoutUfo on this building
    let alienTag = onLeft ? "alienWithoutUfo_left" : "alienWithoutUfo_right"
    if scene.childNode(withName: alienTag) != nil { return }

    let texture = SKTexture(imageNamed: "alienWithoutUfo")
    let aspectRatio = texture.size().width / texture.size().height
    let size = building.size.width * 0.4 // slightly smaller than building width
    let alienSize = CGSize(width: size * aspectRatio, height: size)

    let alien = SKSpriteNode(texture: texture, color: .clear, size: alienSize)
    alien.physicsBody = SKPhysicsBody(texture: texture, size: alienSize)
    setupPhysicsBody(for: alien)
    alien.setScale(0.0)
    // Tag for uniqueness
    alien.userData = NSMutableDictionary()
    alien.userData?["alienWithoutUfoTag"] = alienTag
    alien.name = alienTag

    // Position at the top edge of the building, offset a bit downward
    let x: CGFloat
    if onLeft {
      // Top left edge
      x = building.position.x + 15 - building.size.width / 2 + alienSize.width / 2
    } else {
      // Top right edge
      x = building.position.x - 15 + building.size.width / 2 - alienSize.width / 2
    }
    let yOffset: CGFloat = -alienSize.height * 0.30
    let y = building.position.y + building.size.height / 2 + alienSize.height / 2 + yOffset
    alien.position = CGPoint(x: x, y: y)
    scene.addChild(alien)

    // Animate: pop in, stay, then pop out
    let popIn = SKAction.scale(to: 1.0, duration: 0.18)
    let wait = SKAction.wait(forDuration:10)
    let popOut = SKAction.scale(to: 0.0, duration: 0.18)
    let remove = SKAction.removeFromParent()
    let sequence = SKAction.sequence([popIn, wait, popOut, remove])
    alien.run(sequence)
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
