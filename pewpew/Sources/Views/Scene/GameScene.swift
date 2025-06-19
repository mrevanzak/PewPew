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
  private var circle1: SKSpriteNode?
  private var circle2: SKSpriteNode?

  var currentSequenceNumber = 1
  var totalCirclesInSequence = 0
  var sequenceLabel: SKLabelNode!
  var score = 0
  var scoreLabel: SKLabelNode!
  var isSequenceActive = false

  struct PhysicsCategory {
    static let player: UInt32 = 0x1 << 0
    static let target: UInt32 = 0x1 << 1
  }

  override func didMove(to view: SKView) {
    // Set clear background
    backgroundColor = .clear

    // Add some sample content to demonstrate the scene is working
    setupScene()
    setupUI()
    startSpawning()
  }

  private func setupScene() {
    // Create two circles that will be controlled by hand detection
    physicsWorld.contactDelegate = self
    physicsWorld.gravity = CGVector(dx: 0, dy: 0)
    createHandControlledCircles()
  }

  func setupUI() {
    // Score label
    scoreLabel = SKLabelNode(fontNamed: "Arial-Bold")
    scoreLabel.text = "Score: 0"
    scoreLabel.fontSize = 24
    scoreLabel.fontColor = .white
    scoreLabel.position = CGPoint(x: 100, y: size.height - 50)
    addChild(scoreLabel)

    // Sequence progress label
    sequenceLabel = SKLabelNode(fontNamed: "Arial-Bold")
    sequenceLabel.text = "Next: 1"
    sequenceLabel.fontSize = 20
    sequenceLabel.fontColor = .yellow
    sequenceLabel.position = CGPoint(x: size.width - 100, y: size.height - 50)
    addChild(sequenceLabel)
  }

  private func createHandControlledCircles() {
    // Circle 1 - Blue (for first wrist point)
    circle1 = SKSpriteNode(imageNamed: "target")
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
    circle2 = SKSpriteNode(imageNamed: "target")
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

    // Make circles fully visible when hands are detected
    circle1?.alpha = 1.0
    circle2?.alpha = 1.0

    if handData.isDetected {
      for hand in handData.hands {
        let palmPosition = TargetImageCalculations.calculatePalmPosition(for: hand)
        let viewHeight: CGFloat = size.height
        let mirroredPalmPosition = CGPoint(x: palmPosition.x, y: viewHeight - palmPosition.y)
        let dynamicSize = TargetImageCalculations.calculateTargetSize(for: hand, baseSize: 60)

        if hand.chirality == "left" {
          if let circle1 = circle1 {
            let moveAction = SKAction.move(to: mirroredPalmPosition, duration: 0.1)

            let resizeAction = SKAction.resize(
              toWidth: dynamicSize, height: dynamicSize, duration: 0.1)

            resizeAction.timingMode = .linear
            moveAction.timingMode = .linear
            let groupAction = SKAction.group([moveAction, resizeAction])
            circle1.run(groupAction)
          }
        }

        if hand.chirality == "right" {
          if let circle2 = circle2 {
            let moveAction = SKAction.move(to: mirroredPalmPosition, duration: 0.1)

            let resizeAction = SKAction.resize(
              toWidth: dynamicSize, height: dynamicSize, duration: 0.1)

            resizeAction.timingMode = .linear
            moveAction.timingMode = .linear
            let groupAction = SKAction.group([moveAction, resizeAction])
            circle2.run(groupAction)
          }
        }
      }
    }
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

  func updateSequenceLabel() {
    sequenceLabel.text = "Next: \(currentSequenceNumber)/\(totalCirclesInSequence)"
  }

  //MARK: - Spawning Logic
  func startSpawning() {
    let spawnAction = SKAction.run { [weak self] in
      self?.spawnSequenceOfCircles()
    }
    let waitAction = SKAction.wait(forDuration: 3.0)  // Spawn sequence every 3 seconds
    let sequenceAction = SKAction.sequence([spawnAction, waitAction])
    let repeatAction = SKAction.repeatForever(sequenceAction)

    run(repeatAction, withKey: "spawning")
  }

  func spawnSequenceOfCircles() {
    // Don't spawn if a sequence is already active
    if isSequenceActive {
      return
    }

    // Mark sequence as active
    isSequenceActive = true

    // Reset sequence tracking
    currentSequenceNumber = 1

    // Random number of circles in this sequence (3-6 circles)
    totalCirclesInSequence = Int.random(in: 3...6)

    // Update UI
    updateSequenceLabel()

    // Spawn all circles in the sequence
    for i in 1...totalCirclesInSequence {
      let delay = Double(i - 1) * 0.3  // Stagger spawning by 0.3 seconds

      let spawnAction = SKAction.run { [weak self] in
        self?.spawnNumberedCircle(number: i)
      }
      let waitAction = SKAction.wait(forDuration: delay)
      let delayedSpawn = SKAction.sequence([waitAction, spawnAction])

      run(delayedSpawn)
    }
  }

  func spawnNumberedCircle(number: Int) {
    // Create circle
    let radius = CGFloat.random(in: 25...35)
    let circle = SKShapeNode(circleOfRadius: radius)

    // Color based on sequence position
    let colors: [UIColor] = [.red, .green, .yellow, .orange, .purple, .cyan, .magenta, .brown]
    circle.fillColor = colors[(number - 1) % colors.count]
    circle.strokeColor = .white
    circle.lineWidth = 2

    // Random position on screen (not just at top)
    let randomX = CGFloat.random(in: radius...(size.width - radius))
    let randomY = CGFloat.random(in: (radius + 150)...(size.height - radius - 100))
    circle.position = CGPoint(x: randomX, y: randomY)

    // Store the sequence number in the node's name
    circle.name = "circle_\(number)"

    // Add number label inside circle
    let numberLabel = SKLabelNode(fontNamed: "Arial-Bold")
    numberLabel.text = "\(number)"
    numberLabel.fontSize = 20
    numberLabel.fontColor = .white
    numberLabel.position = CGPoint.zero
    numberLabel.verticalAlignmentMode = .center
    circle.addChild(numberLabel)

    // Add physics body
    circle.physicsBody = SKPhysicsBody(circleOfRadius: radius)
    circle.physicsBody?.categoryBitMask = PhysicsCategory.target
    circle.physicsBody?.contactTestBitMask = PhysicsCategory.player
    circle.physicsBody?.collisionBitMask = 0
    circle.physicsBody?.isDynamic = false  // Make circles static (no movement)

    addChild(circle)

    // Remove circle after time limit and end sequence if time runs out
    let timeoutAction = SKAction.sequence([
      SKAction.wait(forDuration: 12.0),
      SKAction.run { [weak self] in
        // If this circle times out, end the sequence
        if self?.isSequenceActive == true {
          self?.handleSequenceTimeout()
        }
      },
      SKAction.fadeOut(withDuration: 1.0),
      SKAction.removeFromParent(),
    ])
    circle.run(timeoutAction, withKey: "autoRemove")
  }

  // MARK: - Physics Contact
  func didBegin(_ contact: SKPhysicsContact) {
    var targetNode: SKNode?

    // Determine which node is the target circle
    if contact.bodyA.categoryBitMask == PhysicsCategory.target {
      targetNode = contact.bodyA.node
    } else if contact.bodyB.categoryBitMask == PhysicsCategory.target {
      targetNode = contact.bodyB.node
    }

    guard let target = targetNode,
      let nodeName = target.name,
      let numberString = nodeName.components(separatedBy: "_").last,
      let circleNumber = Int(numberString)
    else { return }

    // Check if this is the correct number in sequence
    if circleNumber == currentSequenceNumber {
      // Only allow hit if shot gesture is detected
      handleCorrectHit(target: target, number: circleNumber)
    } else {
      handleWrongHit(target: target, number: circleNumber)
    }
  }

  func handleCorrectHit(target: SKNode, number: Int) {
    // Add score
    score += number * 10  // More points for later numbers in sequence
    scoreLabel.text = "Score: \(score)"

    // Create success effect
    createEffect(at: target.position, text: "+\(number * 10)", color: .green)

    // Remove the target
    target.removeFromParent()

    // Progress to next number in sequence
    currentSequenceNumber += 1
    updateSequenceLabel()

    // Check if sequence is complete
    if currentSequenceNumber > totalCirclesInSequence {
      handleSequenceComplete()
    }

    // Animate score label
    animateScoreLabel()
  }

  func handleWrongHit(target: SKNode, number: Int) {
    // Penalty for wrong sequence
    score = max(0, score - 20)
    scoreLabel.text = "Score: \(score)"

    // Create error effect
    createEffect(at: target.position, text: "WRONG!", color: .red)

    // Flash the target red
    let flashRed = SKAction.colorize(with: .red, colorBlendFactor: 0.8, duration: 0.1)
    let flashBack = SKAction.colorize(with: .clear, colorBlendFactor: 0, duration: 0.1)
    let flashSequence = SKAction.sequence([flashRed, flashBack, flashRed, flashBack])
    target.run(flashSequence)

    // End current sequence and allow new one
    endCurrentSequence()
  }

  func endCurrentSequence() {
    // Remove all remaining circles from current sequence
    enumerateChildNodes(withName: "circle_*") { node, _ in
      node.removeFromParent()
    }

    // Reset sequence state
    currentSequenceNumber = 1
    totalCirclesInSequence = 0
    isSequenceActive = false
    sequenceLabel.text = "Sequence Failed!"

    // Flash sequence label red
    let flashRed = SKAction.colorize(with: .red, colorBlendFactor: 1.0, duration: 0.3)
    let flashBack = SKAction.colorize(with: .yellow, colorBlendFactor: 1.0, duration: 0.3)
    let waitAction = SKAction.wait(forDuration: 1.0)
    let resetText = SKAction.run { [weak self] in
      self?.sequenceLabel.text = "Get Ready..."
    }

    sequenceLabel.run(SKAction.sequence([flashRed, flashBack, waitAction, resetText]))
  }

  func handleSequenceComplete() {
    // Bonus points for completing sequence
    let bonusPoints = totalCirclesInSequence * 20
    score += bonusPoints
    scoreLabel.text = "Score: \(score)"

    // Create completion effect
    createEffect(
      at: CGPoint(x: size.width / 2, y: size.height / 2),
      text: "SEQUENCE COMPLETE!\n+\(bonusPoints) BONUS",
      color: .yellow)

    // Reset for next sequence
    currentSequenceNumber = 1
    totalCirclesInSequence = 0
    isSequenceActive = false  // Allow new sequences to spawn
    sequenceLabel.text = "Get Ready..."

    // Flash screen effect
    let flashOverlay = SKSpriteNode(color: .yellow, size: size)
    flashOverlay.alpha = 0.3
    flashOverlay.position = CGPoint(x: size.width / 2, y: size.height / 2)
    addChild(flashOverlay)

    let fadeOut = SKAction.fadeOut(withDuration: 0.5)
    let remove = SKAction.removeFromParent()
    flashOverlay.run(SKAction.sequence([fadeOut, remove]))
  }

  func handleSequenceTimeout() {
    // Penalty for letting sequence timeout
    score = max(0, score - 30)
    scoreLabel.text = "Score: \(score)"

    // Create timeout effect
    createEffect(
      at: CGPoint(x: size.width / 2, y: size.height / 2),
      text: "TIME OUT!\n-30 POINTS",
      color: .red)

    // End current sequence
    endCurrentSequence()
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
          //          print("Received hand data update - isDetected: \(newData.isDetected), wristPoints: \(newData.fingerPointsPerHand.count)")
          gameScene.updateCirclesWithHandData(newData)
        }
    }
  }
}
