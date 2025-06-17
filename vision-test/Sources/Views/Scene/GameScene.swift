//
//  GameScene.swift
//  vision-test
//
//  Created by Gilang Banyu Biru Erassunu on 16/06/25.
//

import SwiftUI
import SpriteKit

import SwiftUI
import SpriteKit

// MARK: - Custom SpriteKit Scene
class GameScene: SKScene, ObservableObject {
  private var circle1: SKShapeNode?
  private var circle2: SKShapeNode?
  
  override func didMove(to view: SKView) {
    // Set clear background
    backgroundColor = .clear
    
    // Add some sample content to demonstrate the scene is working
    setupScene()
  }
  
  private func setupScene() {
    // Create two circles that will be controlled by hand detection
    createHandControlledCircles()
  }
  
  private func createHandControlledCircles() {
    // Circle 1 - Blue (for first wrist point)
    circle1 = SKShapeNode(circleOfRadius: 25)
    circle1?.fillColor = .systemBlue
    circle1?.strokeColor = .white
    circle1?.lineWidth = 3
    circle1?.name = "circle1"
    circle1?.position = CGPoint(x: frame.width * 0.3, y: frame.height * 0.3)
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
    if let circle2 = circle2 {
      addChild(circle2)
    }
  }
  
  // Function to update circle positions based on hand detection data
  func updateCirclesWithHandData(_ handData: HandDetectionData) {
    print("GameScene: updateCirclesWithHandData called - isDetected: \(handData.isDetected)")
    
    guard handData.isDetected else {
      print("No hands detected, making circles semi-transparent")
      // If no hands detected, hide circles or make them semi-transparent
      circle1?.alpha = 0.3
      circle2?.alpha = 0.3
      return
    }
        
    // Make circles fully visible when hands are detected
    circle1?.alpha = 1.0
    circle2?.alpha = 1.0
        
    if let leftWristPoint = handData.leftWristPoint {
      let leftScenePoint = convertToSceneCoordinates(leftWristPoint)
      if let circle1 = circle1 {
        let moveAction = SKAction.move(to: leftScenePoint, duration: 0.1)
        moveAction.timingMode = .easeOut
        circle1.run(moveAction)
      }
    }
    
    if let rightWristPoint = handData.rightWristPoint {
      let rightScenePoint = convertToSceneCoordinates(rightWristPoint)
      if let circle2 = circle2 {
        let moveAction = SKAction.move(to: rightScenePoint, duration: 0.1)
        moveAction.timingMode = .easeOut
        circle2.run(moveAction)
      }
    }
    
    
//    // Convert wrist points to scene coordinates and update circle positions
//    for (index, wristPoint) in handData.wristPoints.enumerated() {
//      let scenePoint = convertToSceneCoordinates(wristPoint)
//      print("Wrist \(index): \(wristPoint) -> Scene: \(scenePoint)")
//      
//      if index == 0, let circle1 = circle1 {
//        // Smooth movement for circle 1
//        let moveAction = SKAction.move(to: scenePoint, duration: 0.1)
//        moveAction.timingMode = .easeOut
//        circle1.run(moveAction)
//        print("Moving circle1 to \(scenePoint)")
//      } else if index == 1, let circle2 = circle2 {
//        // Smooth movement for circle 2
//        let moveAction = SKAction.move(to: scenePoint, duration: 0.1)
//        moveAction.timingMode = .easeOut
//        circle2.run(moveAction)
//        print("Moving circle2 to \(scenePoint)")
//      }
//    }
    
    // If only one hand is detected, hide the second circle
    if handData.fingerPointsPerHand.count == 1 {
      circle2?.alpha = 0.3
      print("Only one hand detected, hiding circle2")
    }
  }
  
  // Convert normalized coordinates (0-1) to scene coordinates
  private func convertToSceneCoordinates(_ normalizedPoint: CGPoint) -> CGPoint {
    // Assuming the wrist points are normalized (0-1) coordinates
    // Flip Y coordinate since Vision framework uses bottom-left origin
    // while SpriteKit uses bottom-left origin (they should match)
    let x = normalizedPoint.x * frame.width
    let y = (1.0 - normalizedPoint.y) * frame.height // Flip Y if needed
    
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
          print("GameView appeared, scene size: \(geometry.size)")
          // Update immediately with current data
          gameScene.updateCirclesWithHandData(viewModel.handDetectionService.handDetectionData)
        }
        .onReceive(viewModel.handDetectionService.$handDetectionData) { newData in
          print("Received hand data update - isDetected: \(newData.isDetected), wristPoints: \(newData.fingerPointsPerHand.count)")
          gameScene.updateCirclesWithHandData(newData)
        }
    }
  }
}

