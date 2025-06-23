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
  // MARK: - Properties
  private var leftHandCircle: SKSpriteNode?
  private var rightHandCircle: SKSpriteNode?

  weak var viewModel: GameViewModel?
  var scoreLabel: SKLabelNode!
  var bulletLabel: SKLabelNode!
  var isSpawning = false
  let maxBullets = 100

  // Gesture and hand tracking
  private var pendingShootTarget: SKNode?
  private var pendingHand: String?  // "left" or "right"
  private var waitingForShootGesture = false
  private var lastHandWasClosed = false
  private var lastLeftHandClosed = false
  private var lastRightHandClosed = false
  var handDetectionService: HandDetectionService?

  // MARK: - Physics Categories
  struct PhysicsCategory {
    static let player: UInt32 = 0x1 << 0
    static let target: UInt32 = 0x1 << 1
  }

  // MARK: - Lifecycle
  override func didMove(to view: SKView) {
    backgroundColor = .clear
    setupScene()
    setupUI()
    startSpawning()
  }

  // MARK: - Scene Setup
  private func setupScene() {
    physicsWorld.contactDelegate = self
    physicsWorld.gravity = CGVector(dx: 0, dy: 0)
    // Dynamic circle creation will be handled in updateCirclesWithHandData
  }

  func setupUI() {
    setupScoreLabel()
    setupBulletLabel()
  }

  private func setupScoreLabel() {
    scoreLabel = SKLabelNode(fontNamed: "Arial-Bold")
    scoreLabel.text = "Score: \(viewModel?.score ?? 0)"
    scoreLabel.fontSize = 24
    scoreLabel.fontColor = .white
    scoreLabel.position = CGPoint(x: 100, y: size.height - 50)
    addChild(scoreLabel)
  }

  private func setupBulletLabel() {
    bulletLabel = SKLabelNode(fontNamed: "Arial-Bold")
    bulletLabel.text = "Bullets: \(viewModel?.bullets ?? 0)"
    bulletLabel.fontSize = 24
    bulletLabel.fontColor = .yellow
    bulletLabel.position = CGPoint(x: 100, y: size.height - 90)
    addChild(bulletLabel)
  }

  // MARK: - Dynamic Circle Management
  private func createHandCircle(for hand: String, at position: CGPoint) -> SKSpriteNode {
    let texture = SKTexture(imageNamed: "shootMark")
    let size = CGSize(width: 70, height: 70 * (texture.size().height / texture.size().width))
    let sprite = SKSpriteNode(texture: texture, color: .clear, size: size)
    sprite.name = "handCircle_\(hand)"
    sprite.position = position  // Set position directly to hand position
    sprite.zPosition = 1000  // Always on top
    sprite.physicsBody = SKPhysicsBody(texture: texture, size: size)
    sprite.physicsBody?.categoryBitMask = PhysicsCategory.player
    sprite.physicsBody?.contactTestBitMask = PhysicsCategory.target
    sprite.physicsBody?.collisionBitMask = 0
    sprite.physicsBody?.isDynamic = true
    return sprite
  }

  private func updateCirclesForHands(_ handData: HandDetectionData) {
    // Handle left hand circle
    if let leftPalm = handData.leftPalmPoint {
      let leftScenePoint = convertToSceneCoordinates(leftPalm)

      // Create left circle if it doesn't exist - spawn instantly at hand position
      if leftHandCircle == nil {
        leftHandCircle = createHandCircle(for: "left", at: leftScenePoint)
        addChild(leftHandCircle!)
      } else {
        // Update existing circle position with smooth animation
        let moveAction = SKAction.move(to: leftScenePoint, duration: 0.1)
        moveAction.timingMode = .easeOut
        leftHandCircle!.run(moveAction)
      }

      leftHandCircle!.zPosition = 1000
      leftHandCircle!.alpha = 1.0
    } else {
      // Remove left circle if hand not detected
      leftHandCircle?.removeFromParent()
      leftHandCircle = nil
    }

    // Handle right hand circle
    if let rightPalm = handData.rightPalmPoint {
      let rightScenePoint = convertToSceneCoordinates(rightPalm)

      // Create right circle if it doesn't exist - spawn instantly at hand position
      if rightHandCircle == nil {
        rightHandCircle = createHandCircle(for: "right", at: rightScenePoint)
        addChild(rightHandCircle!)
      } else {
        // Update existing circle position with smooth animation
        let moveAction = SKAction.move(to: rightScenePoint, duration: 0.1)
        moveAction.timingMode = .easeOut
        rightHandCircle!.run(moveAction)
      }

      rightHandCircle!.zPosition = 1000
      rightHandCircle!.alpha = 1.0
    } else {
      // Remove right circle if hand not detected
      rightHandCircle?.removeFromParent()
      rightHandCircle = nil
    }

    // If no hands detected at all, ensure both circles are removed
    if !handData.isDetected {
      leftHandCircle?.removeFromParent()
      leftHandCircle = nil
      rightHandCircle?.removeFromParent()
      rightHandCircle = nil
    }
  }

  // Function to update circle positions based on hand detection data
  func updateCirclesWithHandData(_ handData: HandDetectionData) {
    if let service = handDetectionService {
      print(
        "Hand states: \(service.getHandStates()) | Any open: \(service.isAnyHandOpen()) | Any closed: \(service.isAnyHandClosed())"
      )
      // Detect shoot gesture for left hand
      let leftOpen = service.isHandOpen(hand: "left")
      let leftClosed = service.isHandClosed(hand: "left")
      if lastLeftHandClosed && leftOpen, let leftPalm = handData.leftPalmPoint {
        spawnProjectile(at: convertToSceneCoordinates(leftPalm))
      }
      lastLeftHandClosed = leftClosed
      // Detect shoot gesture for right hand
      let rightOpen = service.isHandOpen(hand: "right")
      let rightClosed = service.isHandClosed(hand: "right")
      if lastRightHandClosed && rightOpen, let rightPalm = handData.rightPalmPoint {
        spawnProjectile(at: convertToSceneCoordinates(rightPalm))
      }
      lastRightHandClosed = rightClosed
    }

    // Get detected palm points
    let palmPoints = [handData.leftPalmPoint, handData.rightPalmPoint].compactMap { $0 }
    let detectedHandCount = palmPoints.count

    // Update circle count based on detected hands
    updateCirclesForHands(handData)

    // After updating positions, check for shoot gesture if needed
    checkForShootGesture()
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
    guard !isSpawning else { return }
    isSpawning = true
    let spawnAction = SKAction.run { [weak self] in
      self?.spawnMovingCircle()
    }
    let waitAction = SKAction.wait(forDuration: 1.0)
    let sequenceAction = SKAction.sequence([spawnAction, waitAction])
    let repeatAction = SKAction.repeatForever(sequenceAction)
    run(repeatAction, withKey: "spawning")
  }

  func spawnMovingCircle() {
    let baseSize: CGFloat = CGFloat.random(in: 50...70)  // Bigger than before
    let isBulletTarget = (viewModel?.score ?? 0) > 0 && Double.random(in: 0...1) < 0.2
    let circle: SKSpriteNode
    var isAlien = false
    if isBulletTarget {
      // Square for bullet target
      circle = SKSpriteNode(color: .cyan, size: CGSize(width: baseSize, height: baseSize))
      circle.name = "bullet_target"
      // Use rectangle hitbox for bullet target
      circle.physicsBody = SKPhysicsBody(rectangleOf: CGSize(width: baseSize, height: baseSize))
    } else {
      // Alien image for normal target
      let texture = SKTexture(imageNamed: "alien")
      let aspectRatio = texture.size().width / texture.size().height
      let height = baseSize
      let width = baseSize * aspectRatio
      circle = SKSpriteNode(
        texture: texture, color: .clear, size: CGSize(width: width, height: height))
      circle.name = "moving_circle"
      // Use texture-based hitbox for alien
      circle.physicsBody = SKPhysicsBody(texture: texture, size: circle.size)
      isAlien = true
    }
    circle.physicsBody?.categoryBitMask = PhysicsCategory.target
    circle.physicsBody?.contactTestBitMask = PhysicsCategory.player | (0x1 << 2)
    circle.physicsBody?.collisionBitMask = 0
    circle.physicsBody?.isDynamic = true
    circle.physicsBody?.affectedByGravity = false
    // Set start and end positions
    var startPosition = CGPoint.zero
    var endPosition = CGPoint.zero
    let radius = max(circle.size.width, circle.size.height) / 2
    if isBulletTarget {
      let x = CGFloat.random(in: radius...(size.width-radius))
      startPosition = CGPoint(x: x, y: (size.height * 0.85) + radius)
      endPosition = CGPoint(x: x, y: -radius)
    } else {
      let edges = ["left", "right"]
      let startEdge = edges.randomElement() ?? "left"
      let minY = radius + size.height * 0.2
      let maxY = size.height * 0.9 - radius
      switch startEdge {
      case "left":
        let y = CGFloat.random(in: minY...maxY)
        startPosition = CGPoint(x: -radius, y: y)
        endPosition = CGPoint(x: size.width + radius, y: y)
      case "right":
        let y = CGFloat.random(in: minY...maxY)
        startPosition = CGPoint(x: size.width + radius, y: y)
        endPosition = CGPoint(x: -radius, y: y)
      default:
        break
      }
    }
    circle.position = startPosition
    addChild(circle)
    let distance = hypot(endPosition.x - startPosition.x, endPosition.y - startPosition.y)
    let speed: CGFloat = CGFloat.random(in: 100...250)
    let duration = distance / speed
    let moveAction = SKAction.move(to: endPosition, duration: duration)
    let removeAction = SKAction.removeFromParent()
    // Add wiggle for alien (ufo)
    if isAlien {
      let wiggle = SKAction.sequence([
        SKAction.rotate(byAngle: 0.08, duration: 0.18),
        SKAction.rotate(byAngle: -0.16, duration: 0.36),
        SKAction.rotate(byAngle: 0.08, duration: 0.18)
      ])
      let wiggleForever = SKAction.repeatForever(wiggle)
      circle.run(wiggleForever)
    }
    circle.run(SKAction.sequence([moveAction, removeAction]))
  }

  // MARK: - Physics Contact
  func didBegin(_ contact: SKPhysicsContact) {
    let names = [contact.bodyA.node?.name, contact.bodyB.node?.name]
    if names.contains("projectile")
      && (names.contains("moving_circle") || names.contains("bullet_target"))
    {
      // Find nodes
      let projectile =
        contact.bodyA.node?.name == "projectile" ? contact.bodyA.node : contact.bodyB.node
      let circle =
        contact.bodyA.node?.name == "moving_circle" || contact.bodyA.node?.name == "bullet_target"
        ? contact.bodyA.node : contact.bodyB.node
      if let circle = circle, let projectile = projectile {
        if circle.name == "bullet_target" {
          handleBulletHit(target: circle)
        } else {
          handleCorrectHit(target: circle)
        }
        projectile.removeFromParent()
      }
      return
    }
    var targetNode: SKNode?
    if contact.bodyA.categoryBitMask == PhysicsCategory.target {
      targetNode = contact.bodyA.node
    } else if contact.bodyB.categoryBitMask == PhysicsCategory.target {
      targetNode = contact.bodyB.node
    }
    guard let target = targetNode else { return }
    if !waitingForShootGesture, let service = handDetectionService {
      // Find which hand is closest to the target
      let targetPos = target.position
      var minDist: CGFloat = .greatestFiniteMagnitude
      var closestHand: String? = nil

      // Check left hand if available
      if let leftPalm = service.handDetectionData.leftPalmPoint {
        let leftScene = convertToSceneCoordinates(leftPalm)
        let dist = hypot(leftScene.x - targetPos.x, leftScene.y - targetPos.y)
        if dist < minDist {
          minDist = dist
          closestHand = "left"
        }
      }

      // Check right hand if available
      if let rightPalm = service.handDetectionData.rightPalmPoint {
        let rightScene = convertToSceneCoordinates(rightPalm)
        let dist = hypot(rightScene.x - targetPos.x, rightScene.y - targetPos.y)
        if dist < minDist {
          minDist = dist
          closestHand = "right"
        }
      }

      if let hand = closestHand {
        pendingShootTarget = target
        pendingHand = hand
        waitingForShootGesture = true
        lastHandWasClosed = service.isHandClosed(hand: hand)
      }
    }
  }

  func checkForShootGesture() {
    // Remove scoring logic from shoot gesture
    // Only allow projectile to score
    guard waitingForShootGesture, pendingShootTarget != nil, pendingHand != nil,
      handDetectionService != nil
    else { return }
    let handOpen = false  // Disable scoring on gesture
    if handOpen && lastHandWasClosed {
      // No-op: do not score here
      pendingShootTarget = nil
      pendingHand = nil
      waitingForShootGesture = false
      lastHandWasClosed = false
    }
  }

  func handleCorrectHit(target: SKNode) {
    // Only apply effect if this is an alien (not bullet target)
    if let sprite = target as? SKSpriteNode, sprite.name == "moving_circle" {
        // Impact effect
        createImpactEffect(at: sprite.position)
        // Change texture to alienCrash
        let crashTexture = SKTexture(imageNamed: "alienCrash")
        let setCrash = SKAction.run { sprite.texture = crashTexture }
        let fadeOut = SKAction.fadeOut(withDuration: 0.4)
        let remove = SKAction.removeFromParent()
        let crashSequence = SKAction.sequence([setCrash, fadeOut, remove])
        sprite.run(crashSequence)
    } else {
        target.removeFromParent()
    }
    viewModel?.score += 10
    scoreLabel.text = "Score: \(viewModel?.score ?? 0)"
    createEffect(at: target.position, text: "+10", color: .green)
    animateScoreLabel()
  }

  // Impact effect for alien hit
  private func createImpactEffect(at position: CGPoint) {
    let impact = SKShapeNode(circleOfRadius: 32)
    impact.position = position
    impact.strokeColor = .red
    impact.lineWidth = 4
    impact.fillColor = UIColor.red.withAlphaComponent(0.3)
    impact.zPosition = 999
    addChild(impact)
    let scaleUp = SKAction.scale(to: 1.8, duration: 0.18)
    let fadeOut = SKAction.fadeOut(withDuration: 0.18)
    let remove = SKAction.removeFromParent()
    let group = SKAction.group([scaleUp, fadeOut])
    impact.run(SKAction.sequence([group, remove]))
  }

  func handleBulletHit(target: SKNode) {
    let gain = 10
    if let vm = viewModel {
      vm.bullets = min(vm.bullets + gain, maxBullets)
      bulletLabel.text = "Bullets: \(vm.bullets)"
    }
    createEffect(at: target.position, text: "+\(gain) Bullets", color: .cyan)
    target.removeFromParent()
    animateBulletLabel()
  }

  func animateBulletLabel() {
    let scaleUp = SKAction.scale(to: 1.2, duration: 0.1)
    let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
    let scaleSequence = SKAction.sequence([scaleUp, scaleDown])
    bulletLabel.run(scaleSequence)
  }

  func animateScoreLabel() {
    let scaleUp = SKAction.scale(to: 1.2, duration: 0.1)
    let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
    let scaleSequence = SKAction.sequence([scaleUp, scaleDown])
    scoreLabel.run(scaleSequence)
  }

  var onGameOver: (() -> Void)?

  func spawnProjectile(at targetPosition: CGPoint) {
    guard let vm = viewModel, vm.bullets > 0 else { return }
    vm.bullets -= 1
    bulletLabel.text = "Bullets: \(vm.bullets)"
    if vm.bullets == 0 {
      onGameOver?()
      removeAllActions()
      isSpawning = false
      return
    }
    // Start at bottom center
    let start = CGPoint(x: size.width / 2, y: 0)
    let projectile = SKShapeNode(circleOfRadius: 12)
    projectile.fillColor = .white
    projectile.strokeColor = .yellow
    projectile.lineWidth = 2
    projectile.position = start
    projectile.name = "projectile"
    projectile.physicsBody = SKPhysicsBody(circleOfRadius: 12)
    projectile.physicsBody?.categoryBitMask = 0x1 << 2  // Projectile category
    projectile.physicsBody?.contactTestBitMask = PhysicsCategory.target
    projectile.physicsBody?.collisionBitMask = 0
    projectile.physicsBody?.isDynamic = true
    projectile.physicsBody?.affectedByGravity = false
    addChild(projectile)
    // Calculate direction vector
    let dx = targetPosition.x - start.x
    let dy = targetPosition.y - start.y
    let distance = sqrt(dx * dx + dy * dy)
    let speed: CGFloat = 900.0  // points per second
    let duration = distance / speed
    let moveAction = SKAction.move(to: targetPosition, duration: duration)
    let removeAction = SKAction.removeFromParent()
    projectile.run(SKAction.sequence([moveAction, removeAction]))
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

  override func didChangeSize(_ oldSize: CGSize) {
    super.didChangeSize(oldSize)
    // Place labels at the top left with padding
    let padding: CGFloat = 24
    scoreLabel?.position = CGPoint(
      x: padding + scoreLabel.frame.width / 2, y: size.height - padding)
    bulletLabel?.position = CGPoint(
      x: padding + bulletLabel.frame.width / 2,
      y: size.height - padding - scoreLabel.frame.height - 8)
  }

  func resetScene() {
    // Remove all targets and projectiles
    removeAllChildren()
    // Clear the hand circle references since children were removed
    leftHandCircle = nil
    rightHandCircle = nil
    setupUI()
    isSpawning = false
    removeAllActions()
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
  @State private var gameScene: GameScene

  init(viewModel: GameViewModel) {
    self.viewModel = viewModel
    let scene = GameScene()
    scene.handDetectionService = viewModel.handDetectionService
    scene.viewModel = viewModel
    scene.onGameOver = { [weak viewModel] in
      DispatchQueue.main.async {
        viewModel?.gameOver(finalScore: viewModel?.score ?? 0)
      }
    }
    _gameScene = State(initialValue: scene)
  }

  var body: some View {
    GeometryReader { geometry in
      SpriteKitView(scene: gameScene)
        .onAppear {
          gameScene.size = geometry.size
          gameScene.scaleMode = .aspectFill
          gameScene.updateCirclesWithHandData(viewModel.handDetectionService.handDetectionData)
        }
        .onReceive(viewModel.handDetectionService.$handDetectionData) { newData in
          gameScene.updateCirclesWithHandData(newData)
        }
        .onChange(of: viewModel.score) { _, newScore in
          gameScene.scoreLabel?.text = "Score: \(newScore)"
        }
        .onChange(of: viewModel.bullets) { _, newBullets in
          gameScene.bulletLabel?.text = "Bullets: \(newBullets)"
        }
        .onChange(of: viewModel.isGameOver) { _, isGameOver in
          if !isGameOver {
            gameScene.resetScene()
            gameScene.startSpawning()
          }
        }
    }
  }
}
