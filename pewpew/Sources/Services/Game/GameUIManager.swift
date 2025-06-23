import SpriteKit

/// Manages UI elements in the game scene
final class GameUIManager: GameUIUpdating {

  // MARK: - Properties
  private weak var scene: SKScene?
  private var scoreLabel: SKLabelNode?
  private var bulletLabel: SKLabelNode?

  // MARK: - Initialization
  init(scene: SKScene?) {
    self.scene = scene
  }

  // MARK: - Setup
  func setupUI() {
    setupScoreLabel()
    setupBulletLabel()
  }

  // MARK: - GameUIUpdating Implementation

  func updateScoreDisplay(_ score: Int) {
    scoreLabel?.text = "Score: \(score)"
  }

  func updateBulletsDisplay(_ bullets: Int) {
    bulletLabel?.text = "Bullets: \(bullets)"
  }

  func showEffect(at position: CGPoint, text: String, color: UIColor) {
    guard let scene = scene else { return }

    let effectLabel = SKLabelNode(fontNamed: "Worktalk")
    effectLabel.text = text
    effectLabel.fontSize = GameConfiguration.UI.effectFontSize
    effectLabel.fontColor = color
    effectLabel.position = position
    effectLabel.numberOfLines = 0

    scene.addChild(effectLabel)
    animateEffect(effectLabel)
  }

  func animateScoreLabel() {
    guard let scoreLabel = scoreLabel else { return }

    let scaleUp = SKAction.scale(
      to: AnimationConfig.scaleUpFactor, duration: AnimationConfig.scaleUpDuration)
    let scaleDown = SKAction.scale(to: 1.0, duration: AnimationConfig.scaleDownDuration)
    let scaleSequence = SKAction.sequence([scaleUp, scaleDown])

    scoreLabel.run(scaleSequence)
  }

  func animateBulletLabel() {
    guard let bulletLabel = bulletLabel else { return }

    let scaleUp = SKAction.scale(
      to: AnimationConfig.scaleUpFactor, duration: AnimationConfig.scaleUpDuration)
    let scaleDown = SKAction.scale(to: 1.0, duration: AnimationConfig.scaleDownDuration)
    let scaleSequence = SKAction.sequence([scaleUp, scaleDown])

    bulletLabel.run(scaleSequence)
  }

  // MARK: - Private Helpers

  private func setupScoreLabel() {
    guard let scene = scene else { return }

    scoreLabel = SKLabelNode(fontNamed: "Arial-Bold")
    scoreLabel?.text = "Score: 0"
    scoreLabel?.fontSize = GameConfiguration.UI.labelFontSize
    scoreLabel?.fontColor = .white

    updateLabelPositions()

    if let scoreLabel = scoreLabel {
      scene.addChild(scoreLabel)
    }
  }

  private func setupBulletLabel() {
    guard let scene = scene else { return }

    bulletLabel = SKLabelNode(fontNamed: "Arial-Bold")
    bulletLabel?.text = "Bullets: \(GameConfiguration.Game.initialBullets)"
    bulletLabel?.fontSize = GameConfiguration.UI.labelFontSize
    bulletLabel?.fontColor = .yellow

    updateLabelPositions()

    if let bulletLabel = bulletLabel {
      scene.addChild(bulletLabel)
    }
  }

  private func updateLabelPositions() {
    guard let scene = scene else { return }

    let padding = GameConfiguration.UI.labelPadding

    if let scoreLabel = scoreLabel {
      scoreLabel.position = CGPoint(
        x: padding + scoreLabel.frame.width / 2,
        y: scene.size.height - padding
      )
    }

    if let bulletLabel = bulletLabel, let scoreLabel = scoreLabel {
      bulletLabel.position = CGPoint(
        x: padding + bulletLabel.frame.width / 2,
        y: scene.size.height - padding - scoreLabel.frame.height - 8
      )
    }
  }

  private func animateEffect(_ effectLabel: SKLabelNode) {
    let scaleUp = SKAction.scale(
      to: AnimationConfig.effectScaleFactor, duration: AnimationConfig.effectScaleDuration)
    let fadeOut = SKAction.fadeOut(withDuration: AnimationConfig.effectFadeOutDuration)
    let moveUp = SKAction.moveBy(
      x: 0, y: AnimationConfig.effectMoveUpDistance,
      duration: GameConfiguration.Timing.effectAnimationDuration)
    let remove = SKAction.removeFromParent()

    let effectSequence = SKAction.sequence([
      scaleUp,
      SKAction.group([fadeOut, moveUp]),
      remove,
    ])

    effectLabel.run(effectSequence)
  }

  // MARK: - Scene Size Changes
  func updateForSceneSize() {
    updateLabelPositions()
  }
}
