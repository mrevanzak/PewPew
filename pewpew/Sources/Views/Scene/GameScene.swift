//
//  GameScene.swift
//  pewpew
//
//  Created by Gilang Banyu Biru Erassunu on 16/06/25.
//

import SpriteKit
import SwiftUI

// MARK: - Custom SpriteKit Scene
class GameScene: SKScene, ObservableObject, SKPhysicsContactDelegate {
  // Dynamic hand-controlled circles
  private var handCircles: [SKSpriteNode] = []

  // Bullet shooting system
  private var bullets: [SKSpriteNode] = []
  private var activeTargets: [SKSpriteNode] = []

  var score = 0
  var scoreLabel: SKLabelNode!

  struct PhysicsCategory {
    static let player: UInt32 = 0x1 << 0
    static let target: UInt32 = 0x1 << 1
    static let bullet: UInt32 = 0x1 << 2
  }

  override func didMove(to view: SKView) {
    backgroundColor = .clear
    setupScene()
    setupUI()
    startSpawning()
  }

  private func setupScene() {
    physicsWorld.contactDelegate = self
    physicsWorld.gravity = CGVector(dx: 0, dy: 0)
  }

  func setupUI() {
    // Score label
    scoreLabel = SKLabelNode(fontNamed: "Arial-Bold")
    scoreLabel.text = "Score: 0"
    scoreLabel.fontSize = 24
    scoreLabel.fontColor = .white
    scoreLabel.position = CGPoint(x: 100, y: size.height - 50)
    addChild(scoreLabel)
  }

  // MARK: - Hand Circle Management
  private func createHandCircle(for chirality: String) -> SKSpriteNode {
    let circle = SKSpriteNode(imageNamed: "target")
    circle.name = "handCircle_\(chirality)"
    // Remove physics body - hand circles are now purely visual pointers
    circle.alpha = 0.7  // Make slightly transparent to indicate they're just pointers
    return circle
  }

  private func updateHandCircles(for handData: HandDetectionData) {
    if !handData.isDetected || handData.hands.isEmpty {
      // Immediately remove all hand circles when no hands detected
      handCircles.forEach { $0.removeFromParent() }
      handCircles.removeAll()
      return
    }

    // Use position-based tracking instead of relying only on chirality
    let currentHands = handData.hands

    // Special handling for single hand to prevent duplicates
    if currentHands.count == 1 {
      let hand = currentHands[0]

      // If we have any existing circle, update it; otherwise create one
      if let existingCircle = handCircles.first {
        // Update the single existing circle
        existingCircle.name = "handCircle_\(hand.chirality)"
        updateCircleForHand(circle: existingCircle, hand: hand, animated: true)
        existingCircle.alpha = 1.0

        // Remove any extra circles that might exist
        let extraCircles = Array(handCircles.dropFirst())
        extraCircles.forEach { $0.removeFromParent() }
        handCircles = [existingCircle]
      } else {
        // Create the first and only circle
        let newCircle = createHandCircle(for: hand.chirality)
        handCircles = [newCircle]
        addChild(newCircle)
        updateCircleForHand(circle: newCircle, hand: hand, animated: false)
      }
    }
    // Handle multiple hands with position-based tracking
    else {
      var usedCircles: [SKSpriteNode] = []

      // For each detected hand, find the closest existing circle or create new one
      for hand in currentHands {
        let palmPosition = TargetImageCalculations.calculatePalmPosition(for: hand)
        let viewHeight: CGFloat = size.height
        let mirroredPalmPosition = CGPoint(x: palmPosition.x, y: viewHeight - palmPosition.y)

        // Find closest existing circle within reasonable distance that hasn't been used
        var closestCircle: SKSpriteNode?
        var closestDistance: CGFloat = CGFloat.greatestFiniteMagnitude
        let maxTrackingDistance: CGFloat = 120  // Increased distance

        for circle in handCircles {
          if !usedCircles.contains(circle) {
            let distance = sqrt(
              pow(circle.position.x - mirroredPalmPosition.x, 2)
                + pow(circle.position.y - mirroredPalmPosition.y, 2))
            if distance < closestDistance && distance < maxTrackingDistance {
              closestDistance = distance
              closestCircle = circle
            }
          }
        }

        let circle: SKSpriteNode
        if let existing = closestCircle {
          // Update existing circle
          circle = existing
          circle.name = "handCircle_\(hand.chirality)"  // Update chirality
          updateCircleForHand(circle: circle, hand: hand, animated: true)
          circle.alpha = 1.0  // Ensure visibility
          usedCircles.append(circle)
        } else {
          // Create new circle for new hand
          circle = createHandCircle(for: hand.chirality)
          handCircles.append(circle)
          addChild(circle)
          updateCircleForHand(circle: circle, hand: hand, animated: false)
          usedCircles.append(circle)
        }
      }

      // Remove any unused circles
      let unusedCircles = handCircles.filter { !usedCircles.contains($0) }
      unusedCircles.forEach { $0.removeFromParent() }
      handCircles = usedCircles
    }

  }

  private func updateCircleForHand(circle: SKSpriteNode, hand: HandPoints, animated: Bool = true) {
    let palmPosition = TargetImageCalculations.calculatePalmPosition(for: hand)
    let viewHeight: CGFloat = size.height
    let mirroredPalmPosition = CGPoint(x: palmPosition.x, y: viewHeight - palmPosition.y)
    let dynamicSize = TargetImageCalculations.calculateTargetSize(for: hand, baseSize: 60)

    if animated {
      // Smooth movement and resize animations for existing circles
      let moveAction = SKAction.move(to: mirroredPalmPosition, duration: 0.1)
      let resizeAction = SKAction.resize(toWidth: dynamicSize, height: dynamicSize, duration: 0.1)

      moveAction.timingMode = .linear
      resizeAction.timingMode = .linear

      let groupAction = SKAction.group([moveAction, resizeAction])
      circle.run(groupAction)
    } else {
      // Set position and size immediately for new circles
      circle.position = mirroredPalmPosition
      circle.size = CGSize(width: dynamicSize, height: dynamicSize)
    }

    // Ensure circle is visible
    circle.alpha = 1.0
  }

  // Function to update circle positions based on hand detection data
  func updateCirclesWithHandData(_ handData: HandDetectionData) {
    updateHandCircles(for: handData)
  }

  // MARK: - Bullet Shooting System

  /// Fire a bullet from bottom center towards the nearest target or hand position
  func fireBullet(targetPosition: CGPoint? = nil) {
    let startPosition = CGPoint(x: size.width / 2, y: 50)  // Bottom center

    // Determine target position
    let finalTargetPosition: CGPoint
    if let target = targetPosition {
      finalTargetPosition = target
    } else if let nearestTarget = findNearestTarget(to: startPosition) {
      finalTargetPosition = nearestTarget.position
    } else {
      // Fire towards center-top if no target
      finalTargetPosition = CGPoint(x: size.width / 2, y: size.height - 100)
    }

    // Create bullet sprite
    let bullet = SKSpriteNode(color: .yellow, size: CGSize(width: 8, height: 20))
    bullet.position = startPosition
    bullet.name = "bullet"

    // Add physics body for collision detection
    bullet.physicsBody = SKPhysicsBody(rectangleOf: bullet.size)
    bullet.physicsBody?.categoryBitMask = PhysicsCategory.bullet
    bullet.physicsBody?.contactTestBitMask = PhysicsCategory.target
    bullet.physicsBody?.collisionBitMask = 0
    bullet.physicsBody?.isDynamic = true
    bullet.physicsBody?.affectedByGravity = false

    // Calculate movement direction and speed
    let dx = finalTargetPosition.x - startPosition.x
    let dy = finalTargetPosition.y - startPosition.y
    let distance = sqrt(dx * dx + dy * dy)

    let bulletSpeed: CGFloat = 1500  // Much faster for instant response
    let duration = TimeInterval(distance / bulletSpeed)

    // Create movement action
    let moveAction = SKAction.move(to: finalTargetPosition, duration: duration)
    moveAction.timingMode = .linear

    // Remove bullet after reaching target or going off screen
    let removeAction = SKAction.removeFromParent()
    let sequence = SKAction.sequence([moveAction, removeAction])

    // Add bullet to scene and track it
    addChild(bullet)
    bullets.append(bullet)
    bullet.run(sequence) { [weak self] in
      self?.bullets.removeAll { $0 == bullet }
    }

    // Add visual trail effect for better visibility
    addBulletTrail(to: bullet)
  }

  /// Add visual trail effect to bullet
  private func addBulletTrail(to bullet: SKSpriteNode) {
    let trail = SKEmitterNode()
    trail.particleTexture = SKTexture(imageNamed: "spark")  // Will fallback gracefully if not found
    trail.particleBirthRate = 100
    trail.particleLifetime = 0.3
    trail.particleScale = 0.1
    trail.particleScaleRange = 0.05
    trail.particleAlpha = 0.8
    trail.particleAlphaRange = 0.2
    trail.particleColor = .yellow
    trail.particleColorBlendFactor = 1.0
    trail.particleBlendMode = .add
    trail.particlePositionRange = CGVector(dx: 2, dy: 2)
    trail.particleSpeed = 20
    trail.particleSpeedRange = 10
    trail.emissionAngle = .pi / 2
    trail.emissionAngleRange = .pi / 4
    trail.targetNode = self

    bullet.addChild(trail)
  }

  /// Find the nearest target to a given position
  private func findNearestTarget(to position: CGPoint) -> SKSpriteNode? {
    var nearestTarget: SKSpriteNode?
    var nearestDistance: CGFloat = CGFloat.greatestFiniteMagnitude

    // Check all circle targets
    enumerateChildNodes(withName: "target_*") { node, _ in
      if let targetNode = node as? SKShapeNode {
        let distance = sqrt(
          pow(targetNode.position.x - position.x, 2) + pow(targetNode.position.y - position.y, 2))

        if distance < nearestDistance {
          nearestDistance = distance
          nearestTarget = SKSpriteNode()
          nearestTarget?.position = targetNode.position
        }
      }
    }

    return nearestTarget
  }

  /// Handle shooting trigger from hand gesture detection
  func handleShootingTrigger(handPosition: CGPoint? = nil) {
    fireBullet(targetPosition: handPosition)
  }

  // Convert normalized coordinates (0-1) to scene coordinates
  private func convertToSceneCoordinates(_ normalizedPoint: CGPoint) -> CGPoint {
    // Assuming the wrist points are normalized (0-1) coordinates
    // Flip Y coordinate since Vision framework uses bottom-left origin
    // while SpriteKit uses bottom-left origin (they should match)
    let x = (1.0 - normalizedPoint.x) * frame.width
    let y = normalizedPoint.y * frame.height  // Flip Y if needed

    // Clamp to screen bounds with margin
    let margin: CGFloat = 30
    let clampedX = max(margin, min(frame.width - margin, x))
    let clampedY = max(margin, min(frame.height - margin, y))

    return CGPoint(x: clampedX, y: clampedY)
  }

  //MARK: - Spawning Logic
  func startSpawning() {
    let spawnAction = SKAction.run { [weak self] in
      self?.spawnTarget()
    }
    let waitAction = SKAction.wait(forDuration: 1.5)  // Spawn target every 1.5 seconds
    let sequenceAction = SKAction.sequence([spawnAction, waitAction])
    let repeatAction = SKAction.repeatForever(sequenceAction)

    run(repeatAction, withKey: "spawning")
  }

  func spawnTarget() {
    // Create circle
    let radius = CGFloat.random(in: 25...35)
    let circle = SKShapeNode(circleOfRadius: radius)

    // Random color for variety
    let colors: [UIColor] = [.red, .green, .yellow, .orange, .purple, .cyan, .magenta, .brown]
    circle.fillColor = colors.randomElement() ?? .blue
    circle.strokeColor = .white
    circle.lineWidth = 2

    // Random position on screen
    let randomX = CGFloat.random(in: radius...(size.width - radius))
    let randomY = CGFloat.random(in: (radius + 150)...(size.height - radius - 100))
    circle.position = CGPoint(x: randomX, y: randomY)

    // Simple target name without numbers
    circle.name = "target_\(UUID().uuidString)"

    // Add physics body
    circle.physicsBody = SKPhysicsBody(circleOfRadius: radius)
    circle.physicsBody?.categoryBitMask = PhysicsCategory.target
    circle.physicsBody?.contactTestBitMask = PhysicsCategory.bullet
    circle.physicsBody?.collisionBitMask = 0
    circle.physicsBody?.isDynamic = false  // Make circles static (no movement)

    addChild(circle)

    // Remove circle after time limit
    let timeoutAction = SKAction.sequence([
      SKAction.wait(forDuration: 8.0),
      SKAction.fadeOut(withDuration: 1.0),
      SKAction.removeFromParent(),
    ])
    circle.run(timeoutAction, withKey: "autoRemove")
  }

  // MARK: - Physics Contact
  func didBegin(_ contact: SKPhysicsContact) {
    var targetNode: SKNode?
    var bulletNode: SKNode?

    // Only handle bullet-target collisions since hand circles no longer have physics bodies
    if contact.bodyA.categoryBitMask == PhysicsCategory.target
      && contact.bodyB.categoryBitMask == PhysicsCategory.bullet
    {
      targetNode = contact.bodyA.node
      bulletNode = contact.bodyB.node
    } else if contact.bodyA.categoryBitMask == PhysicsCategory.bullet
      && contact.bodyB.categoryBitMask == PhysicsCategory.target
    {
      targetNode = contact.bodyB.node
      bulletNode = contact.bodyA.node
    } else {
      // No relevant collision detected
      return
    }

    guard let target = targetNode,
      let bullet = bulletNode
    else { return }

    // Remove the bullet on impact
    bullet.removeFromParent()
    bullets.removeAll { $0 == bullet }

    // Award points for any hit
    handleTargetHit(target: target)
  }

  func handleTargetHit(target: SKNode) {
    // Add score
    score += 10
    scoreLabel.text = "Score: \(score)"

    // Create success effect
    createEffect(at: target.position, text: "+10", color: .green)

    // Remove the target
    target.removeFromParent()

    // Animate score label
    animateScoreLabel()
  }

  func createEffect(at position: CGPoint, text: String, color: UIColor) {
    let effectLabel = SKLabelNode(fontNamed: "Arial-Bold")
    effectLabel.text = text
    effectLabel.fontSize = 16
    effectLabel.fontColor = color
    effectLabel.position = position
    effectLabel.numberOfLines = 0
    addChild(effectLabel)

    // Animate the effect
    let scaleUp = SKAction.scale(to: 1.5, duration: 0.2)
    let fadeOut = SKAction.fadeOut(withDuration: 0.8)
    let moveUp = SKAction.moveBy(x: 0, y: 50, duration: 1.0)
    let remove = SKAction.removeFromParent()

    let effectSequence = SKAction.sequence([
      scaleUp,
      SKAction.group([fadeOut, moveUp]),
      remove,
    ])

    effectLabel.run(effectSequence)
  }

  func animateScoreLabel() {
    let scaleUp = SKAction.scale(to: 1.2, duration: 0.1)
    let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
    let scaleSequence = SKAction.sequence([scaleUp, scaleDown])
    scoreLabel.run(scaleSequence)
  }
}

// MARK: - SwiftUI Wrapper
struct SpriteKitView: UIViewRepresentable {
  let scene: SKScene

  func makeUIView(context: Context) -> SKView {
    let view = SKView()
    view.backgroundColor = .clear
    view.allowsTransparency = true
    view.presentScene(scene)
    return view
  }

  func updateUIView(_ uiView: SKView, context: Context) {
    // Update if needed
  }
}

// MARK: - SwiftUI View for ZStack
struct SpriteView: View {
  @ObservedObject var viewModel: GameViewModel
  @State private var gameScene = GameScene()

  var body: some View {
    GeometryReader { geometry in
      SpriteKitView(scene: gameScene)
        .onAppear {
          gameScene.size = geometry.size
          gameScene.scaleMode = .aspectFill
          // Update immediately with current data
          gameScene.updateCirclesWithHandData(viewModel.handDetectionService.handDetectionData)
        }
        .onReceive(viewModel.handDetectionService.$handDetectionData) { newData in
          gameScene.updateCirclesWithHandData(newData)
        }
        .onReceive(viewModel.handDetectionService.$shootingTrigger) { shouldShoot in
          if shouldShoot {
            // Get the position of the hand that triggered the shooting
            var targetPosition: CGPoint?

            if let triggeringHand = viewModel.handDetectionService.triggeringHand {
              let palmPosition = TargetImageCalculations.calculatePalmPosition(for: triggeringHand)
              // Convert to scene coordinates (flip Y axis)
              targetPosition = CGPoint(x: palmPosition.x, y: geometry.size.height - palmPosition.y)
            }

            gameScene.handleShootingTrigger(handPosition: targetPosition)
          }
        }
    }
  }
}
