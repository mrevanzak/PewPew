import SpriteKit
import SwiftUI

/// Manages hand tracking circles and gesture detection
final class HandTracker: HandTracking {

  // MARK: - Properties
  private weak var scene: SKScene?
  private let coordinateConverter: CoordinateConverting
  private let projectileManager: ProjectileManaging
  private weak var handDetectionService: HandDetectionService?

  // Hand circle references
  private var leftHandCircle: SKSpriteNode?
  private var rightHandCircle: SKSpriteNode?

  // Gesture tracking state
  private var lastLeftHandClosed = false
  private var lastRightHandClosed = false

  // MARK: - Initialization
  init(
    scene: SKScene?,
    coordinateConverter: CoordinateConverting,
    projectileManager: ProjectileManaging,
    handDetectionService: HandDetectionService?
  ) {
    self.scene = scene
    self.coordinateConverter = coordinateConverter
    self.projectileManager = projectileManager
    self.handDetectionService = handDetectionService
  }

  // MARK: - HandTracking Implementation

  func updateHandCircles(with handData: HandDetectionData) {
    updateLeftHandCircle(with: handData)
    updateRightHandCircle(with: handData)
    
    if !handData.isDetected {
      removeAllHandCircles()
    }
  }

  func detectShootGesture(for handData: HandDetectionData) {
    guard let handDetectionService = getHandDetectionService() else { return }

    detectLeftHandGesture(handData: handData, service: handDetectionService)
    detectRightHandGesture(handData: handData, service: handDetectionService)
  }

  // MARK: - Private Helpers

  private func updateLeftHandCircle(with handData: HandDetectionData) {
    if let leftPalm = handData.leftPalmPoint {
      let scenePoint = coordinateConverter.convertToSceneCoordinates(leftPalm)
      
      if let leftHandCircle = leftHandCircle {
        if leftHandCircle.parent == nil {
          scene?.addChild(leftHandCircle)
        }
        animateHandCircle(leftHandCircle, to: scenePoint)
      } else {
        leftHandCircle = createHandCircle(for: .left, at: leftPalm)
        if let leftHandCircle = leftHandCircle {
          scene?.addChild(leftHandCircle)
        }
      }
    } else {
      if let leftHandCircle = leftHandCircle {
        leftHandCircle.removeFromParent()
      }
    }
  }

  private func updateRightHandCircle(with handData: HandDetectionData) {
    if let rightPalm = handData.rightPalmPoint {
      let scenePoint = coordinateConverter.convertToSceneCoordinates(rightPalm)
      
      if let rightHandCircle = rightHandCircle {
        if rightHandCircle.parent == nil {
          scene?.addChild(rightHandCircle)
        }
        animateHandCircle(rightHandCircle, to: scenePoint)
      } else {
        rightHandCircle = createHandCircle(for: .right, at: rightPalm)
        if let rightHandCircle = rightHandCircle {
          scene?.addChild(rightHandCircle)
        }
      }
    } else {
      if let rightHandCircle = rightHandCircle {
        rightHandCircle.removeFromParent()
      }
    }
  }

  private func createHandCircle(for hand: HandType, at position: CGPoint) -> SKSpriteNode {
    let texture = SKTexture(imageNamed: AssetName.shootMark)
    let aspectRatio = texture.size().height / texture.size().width
    let size = CGSize(
      width: GameConfiguration.UI.handCircleSize,
      height: GameConfiguration.UI.handCircleSize * aspectRatio
    )

    let sprite = SKSpriteNode(texture: texture, color: .clear, size: size)
    sprite.name = hand == .left ? NodeName.leftHandCircle : NodeName.rightHandCircle
    sprite.position = position
    sprite.zPosition = 1000  // Always on top
    sprite.alpha = 1.0

    // Setup physics
    sprite.physicsBody = SKPhysicsBody(texture: texture, size: size)
    sprite.physicsBody?.categoryBitMask = GameConfiguration.Physics.Category.player
    sprite.physicsBody?.contactTestBitMask = GameConfiguration.Physics.Category.target
    sprite.physicsBody?.collisionBitMask = 0
    sprite.physicsBody?.isDynamic = true

    return sprite
  }

  private func animateHandCircle(_ circle: SKSpriteNode, to position: CGPoint) {
    let moveAction = SKAction.move(
      to: position, duration: GameConfiguration.Timing.handAnimationDuration)
    moveAction.timingMode = .easeOut
    circle.run(moveAction)
  }

  private func removeAllHandCircles() {
    leftHandCircle?.removeFromParent()
    rightHandCircle?.removeFromParent()
  }

  private func detectLeftHandGesture(handData: HandDetectionData, service: HandDetectionService) {
    let leftOpen = service.isHandOpen(hand: "left")
    let leftClosed = service.isHandClosed(hand: "left")

    // Detect open gesture after closed (shoot gesture)
    if lastLeftHandClosed && leftOpen, let leftPalm = handData.leftPalmPoint {
      let targetPosition = coordinateConverter.convertToSceneCoordinates(leftPalm)
      projectileManager.spawnProjectile(at: targetPosition)
    }

    lastLeftHandClosed = leftClosed
  }

  private func detectRightHandGesture(handData: HandDetectionData, service: HandDetectionService) {
    let rightOpen = service.isHandOpen(hand: "right")
    let rightClosed = service.isHandClosed(hand: "right")

    // Detect open gesture after closed (shoot gesture)
    if lastRightHandClosed && rightOpen, let rightPalm = handData.rightPalmPoint {
      let targetPosition = coordinateConverter.convertToSceneCoordinates(rightPalm)
      projectileManager.spawnProjectile(at: targetPosition)
    }

    lastRightHandClosed = rightClosed
  }

  // Helper to get hand detection service
  private func getHandDetectionService() -> HandDetectionService? {
    return handDetectionService
  }
}

// MARK: - Hand Type Enum
enum HandType {
  case left
  case right
}
