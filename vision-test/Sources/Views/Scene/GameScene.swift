//
//  GameScene.swift
//  vision-test
//
//  Created by Gilang Banyu Biru Erassunu on 16/06/25.
//

import SwiftUI
import SpriteKit

// MARK: - Custom SpriteKit Scene
class GameScene: SKScene, ObservableObject, SKPhysicsContactDelegate {
  private var circle1: SKShapeNode?
  private var circle2: SKShapeNode?

  var score = 0
  var scoreLabel: SKLabelNode!
  var isSpawning = false

  // Track contact state for shoot gesture
  private var pendingShootTarget: SKNode?
  private var pendingHand: String? // "left" or "right"
  private var waitingForShootGesture = false
  private var lastHandWasClosed = false
  var handDetectionService: HandDetectionService?

  // Track last hand state for shoot gesture detection
  private var lastLeftHandClosed = false
  private var lastRightHandClosed = false

  struct PhysicsCategory {
    static let player: UInt32 = 0x1 << 0
    static let target: UInt32 = 0x1 << 1
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
    createHandControlledCircles()
  }

  func setupUI() {
    scoreLabel = SKLabelNode(fontNamed: "Arial-Bold")
    scoreLabel.text = "Score: 0"
    scoreLabel.fontSize = 24
    scoreLabel.fontColor = .white
    scoreLabel.position = CGPoint(x: 100, y: size.height - 50)
    addChild(scoreLabel)
  }

  private func createHandControlledCircles() {
    // Circle 1 - Blue (for first wrist point)
    circle1 = SKShapeNode(circleOfRadius: 25)
    circle1?.fillColor = .systemBlue
    circle1?.strokeColor = .white
    circle1?.lineWidth = 3
    circle1?.name = "circle1"
    circle1?.position = CGPoint(x: frame.width * 0.3, y: frame.height * 0.3)
    circle1?.physicsBody = SKPhysicsBody(circleOfRadius: 25)
    circle1?.physicsBody?.categoryBitMask = PhysicsCategory.player
    circle1?.physicsBody?.contactTestBitMask = PhysicsCategory.target
    circle1?.physicsBody?.collisionBitMask = 0
    circle1?.physicsBody?.isDynamic = true
    if let circle1 = circle1 {
      addChild(circle1)
    }
    
    // Circle 2 - Red (for second wrist point)
    circle2 = SKShapeNode(circleOfRadius: 30)
    circle2?.fillColor = .systemRed
    circle2?.strokeColor = .white
    circle2?.lineWidth = 3
    circle2?.name = "circle2"
    circle2?.position = CGPoint(x: frame.width * 0.7, y: frame.height * 0.7)
    circle2?.physicsBody = SKPhysicsBody(circleOfRadius: 25)
    circle2?.physicsBody?.categoryBitMask = PhysicsCategory.player
    circle2?.physicsBody?.contactTestBitMask = PhysicsCategory.target
    circle2?.physicsBody?.collisionBitMask = 0
    circle1?.physicsBody?.isDynamic = true
    if let circle2 = circle2 {
      addChild(circle2)
    }
  }
  
  // Function to update circle positions based on hand detection data
  func updateCirclesWithHandData(_ handData: HandDetectionData) {
    if let service = handDetectionService {
      print("Hand states: \(service.getHandStates()) | Any open: \(service.isAnyHandOpen()) | Any closed: \(service.isAnyHandClosed())")
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
    
    guard handData.isDetected else {
      circle1?.alpha = 0.3
      circle2?.alpha = 0.3
      return
    }
    
    circle1?.alpha = 1.0
    circle2?.alpha = 1.0
    
    if let leftPalmPoint = handData.leftPalmPoint {
      let leftScenePoint = convertToSceneCoordinates(leftPalmPoint)
      if let circle1 = circle1 {
        let moveAction = SKAction.move(to: leftScenePoint, duration: 0.1)
        moveAction.timingMode = .easeOut
        circle1.run(moveAction)
      }
    }
    
    if let rightPalmPoint = handData.rightPalmPoint {
      let rightScenePoint = convertToSceneCoordinates(rightPalmPoint)
      if let circle2 = circle2 {
        let moveAction = SKAction.move(to: rightScenePoint, duration: 0.1)
        moveAction.timingMode = .easeOut
        circle2.run(moveAction)
      }
    }
    
    // If only one hand is detected, hide the second circle
    if handData.fingerPointsPerHand.count == 1 {
      circle2?.alpha = 0.3
    }
    
    // After updating positions, check for shoot gesture if needed
    checkForShootGesture()
  }
  
  // Convert normalized coordinates (0-1) to scene coordinates
  private func convertToSceneCoordinates(_ normalizedPoint: CGPoint) -> CGPoint {
    // Assuming the wrist points are normalized (0-1) coordinates
    // Flip Y coordinate since Vision framework uses bottom-left origin
    // while SpriteKit uses bottom-left origin (they should match)
    let x = (1.0 - normalizedPoint.x) * frame.width
    let y = normalizedPoint.y * frame.height // Flip Y if needed
    
    // Clamp to screen bounds with margin
    let margin: CGFloat = 30
    let clampedX = max(margin, min(frame.width - margin, x))
    let clampedY = max(margin, min(frame.height - margin, y))
    
    return CGPoint(x: clampedX, y: clampedY)
  }
  
  override func touchesBegan(_ touches: Set<UITouch>, with event: UIEvent?) {
    guard let touch = touches.first else { return }
    let location = touch.location(in: self)
    
    // Create a tap effect
    let tapEffect = SKShapeNode(circleOfRadius: 20)
    tapEffect.fillColor = .clear
    tapEffect.strokeColor = .systemYellow
    tapEffect.lineWidth = 3
    tapEffect.position = location
    
    let scaleUp = SKAction.scale(to: 2.0, duration: 0.3)
    let fadeOut = SKAction.fadeOut(withDuration: 0.3)
    let remove = SKAction.removeFromParent()
    let sequence = SKAction.sequence([SKAction.group([scaleUp, fadeOut]), remove])
    
    tapEffect.run(sequence)
    addChild(tapEffect)
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
    let radius = CGFloat.random(in: 25...35)
    let circle = SKShapeNode(circleOfRadius: radius)
    let colors: [UIColor] = [.red, .green, .yellow, .orange, .purple, .cyan, .magenta, .brown]
    circle.fillColor = colors.randomElement() ?? .red
    circle.strokeColor = .white
    circle.lineWidth = 2
    // Random start and end positions on opposite edges
    let edges = ["left", "right", "top", "bottom"]
    let startEdge = edges.randomElement() ?? "left"
    var startPosition = CGPoint.zero
    var endPosition = CGPoint.zero
    switch startEdge {
    case "left":
      startPosition = CGPoint(x: -radius, y: CGFloat.random(in: radius...(size.height-radius)))
      endPosition = CGPoint(x: size.width+radius, y: CGFloat.random(in: radius...(size.height-radius)))
    case "right":
      startPosition = CGPoint(x: size.width+radius, y: CGFloat.random(in: radius...(size.height-radius)))
      endPosition = CGPoint(x: -radius, y: CGFloat.random(in: radius...(size.height-radius)))
    case "top":
      startPosition = CGPoint(x: CGFloat.random(in: radius...(size.width-radius)), y: size.height+radius)
      endPosition = CGPoint(x: CGFloat.random(in: radius...(size.width-radius)), y: -radius)
    case "bottom":
      startPosition = CGPoint(x: CGFloat.random(in: radius...(size.width-radius)), y: -radius)
      endPosition = CGPoint(x: CGFloat.random(in: radius...(size.width-radius)), y: size.height+radius)
    default:
      break
    }
    circle.position = startPosition
    circle.name = "moving_circle"
    circle.physicsBody = SKPhysicsBody(circleOfRadius: radius)
    circle.physicsBody?.categoryBitMask = PhysicsCategory.target
    circle.physicsBody?.contactTestBitMask = PhysicsCategory.player
    circle.physicsBody?.collisionBitMask = 0
    circle.physicsBody?.isDynamic = true
    circle.physicsBody?.affectedByGravity = false
    addChild(circle)
    // Move to the end position
    let distance = hypot(endPosition.x - startPosition.x, endPosition.y - startPosition.y)
    let speed: CGFloat = CGFloat.random(in: 100...250) // points per second
    let duration = distance / speed
    let moveAction = SKAction.move(to: endPosition, duration: duration)
    let removeAction = SKAction.removeFromParent()
    circle.run(SKAction.sequence([moveAction, removeAction]))
  }

  // MARK: - Physics Contact
  func didBegin(_ contact: SKPhysicsContact) {
    let names = [contact.bodyA.node?.name, contact.bodyB.node?.name]
    if names.contains("projectile") && names.contains("moving_circle") {
      // Find nodes
      let projectile = contact.bodyA.node?.name == "projectile" ? contact.bodyA.node : contact.bodyB.node
      let circle = contact.bodyA.node?.name == "moving_circle" ? contact.bodyA.node : contact.bodyB.node
      if let circle = circle, let projectile = projectile {
        handleCorrectHit(target: circle)
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
      if let leftPalm = service.handDetectionData.leftPalmPoint {
        let leftScene = convertToSceneCoordinates(leftPalm)
        let dist = hypot(leftScene.x - targetPos.x, leftScene.y - targetPos.y)
        if dist < minDist {
          minDist = dist
          closestHand = "left"
        }
      }
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
    guard waitingForShootGesture, let target = pendingShootTarget, let hand = pendingHand, let service = handDetectionService else { return }
    let handOpen = service.isHandOpen(hand: hand)
    if handOpen && lastHandWasClosed {
      handleCorrectHit(target: target)
      pendingShootTarget = nil
      pendingHand = nil
      waitingForShootGesture = false
      lastHandWasClosed = false
    }
  }

  func handleCorrectHit(target: SKNode) {
    score += 10
    scoreLabel.text = "Score: \(score)"
    createEffect(at: target.position, text: "+10", color: .green)
    target.removeFromParent()
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
      remove
    ])
    
    effectLabel.run(effectSequence)
  }
  
  func animateScoreLabel() {
    let scaleUp = SKAction.scale(to: 1.2, duration: 0.1)  
    let scaleDown = SKAction.scale(to: 1.0, duration: 0.1)
    let scaleSequence = SKAction.sequence([scaleUp, scaleDown])
    scoreLabel.run(scaleSequence)
  }
  
  func spawnProjectile(at targetPosition: CGPoint) {
    // Start at bottom center
    let start = CGPoint(x: size.width / 2, y: 0)
    let projectile = SKShapeNode(circleOfRadius: 12)
    projectile.fillColor = .white
    projectile.strokeColor = .yellow
    projectile.lineWidth = 2
    projectile.position = start
    projectile.name = "projectile"
    projectile.physicsBody = SKPhysicsBody(circleOfRadius: 12)
    projectile.physicsBody?.categoryBitMask = 0x1 << 2 // Projectile category
    projectile.physicsBody?.contactTestBitMask = PhysicsCategory.target
    projectile.physicsBody?.collisionBitMask = 0
    projectile.physicsBody?.isDynamic = true
    projectile.physicsBody?.affectedByGravity = false
    addChild(projectile)
    // Calculate direction vector
    let dx = targetPosition.x - start.x
    let dy = targetPosition.y - start.y
    let distance = sqrt(dx*dx + dy*dy)
    let speed: CGFloat = 900.0 // points per second
    let duration = distance / speed
    let moveAction = SKAction.move(to: targetPosition, duration: duration)
    let removeAction = SKAction.removeFromParent()
    projectile.run(SKAction.sequence([moveAction, removeAction]))
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
    _gameScene = State(initialValue: scene)
  }
  
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
    }
  }
}

