//
//  MoleScene.swift
//  vision-test
//
//  SpriteKit scene for mole animation and display
//

import SpriteKit
import SwiftUI

/// SpriteKit scene for animated mole sprites
/// Creates multiple animated moles at random edge positions
class MoleScene: SKScene {
  private let moleCount = 6  // Number of moles to spawn

  override func didMove(to view: SKView) {
    backgroundColor = .clear  // Transparent background for overlay

    let texture = SKTexture(imageNamed: "mole")
    let frameCount = 11  // Adjust based on your sprite sheet
    let frameWidth = texture.size().width / CGFloat(frameCount)

    // Create animation frames
    var frames: [SKTexture] = []
    for i in 0..<frameCount {
      let rect = CGRect(
        x: CGFloat(i) * frameWidth / texture.size().width,
        y: 0,
        width: frameWidth / texture.size().width,
        height: 1.0
      )
      frames.append(SKTexture(rect: rect, in: texture))
    }

    // Create multiple moles at random edge positions
    for _ in 0..<moleCount {
      let sprite = SKSpriteNode(texture: frames[0])
      sprite.position = randomEdgePosition()
      sprite.zPosition = 1
      addChild(sprite)

      // Random animation timing for variety
      let randomDelay = Double.random(in: 0...2.0)
      let animation = SKAction.animate(with: frames, timePerFrame: 0.1)
      let repeatAnimation = SKAction.repeatForever(animation)

      sprite.run(
        SKAction.sequence([
          SKAction.wait(forDuration: randomDelay),
          repeatAnimation,
        ])
      )
    }
  }

  /// Generate random position along the edges of the screen
  /// - Returns: CGPoint representing a position near the edge
  private func randomEdgePosition() -> CGPoint {
    let margin: CGFloat = 50  // Distance from actual edge
    let edges = ["top", "bottom", "left", "right"]
    let randomEdge = edges.randomElement()!

    switch randomEdge {
    case "top":
      return CGPoint(
        x: CGFloat.random(in: margin...(size.width - margin)),
        y: size.height - margin
      )
    case "bottom":
      return CGPoint(
        x: CGFloat.random(in: margin...(size.width - margin)),
        y: margin
      )
    case "left":
      return CGPoint(
        x: margin,
        y: CGFloat.random(in: margin...(size.height - margin))
      )
    case "right":
      return CGPoint(
        x: size.width - margin,
        y: CGFloat.random(in: margin...(size.height - margin))
      )
    default:
      return CGPoint(x: size.width / 2, y: size.height / 2)
    }
  }
}
