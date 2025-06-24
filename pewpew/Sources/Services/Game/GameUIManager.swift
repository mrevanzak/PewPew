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
    bulletLabel?.text = "\(bullets)"
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

    // Create background sprite
    let scoreBackground = SKSpriteNode(imageNamed: AssetName.scoreBoard)
    scoreBackground.name = "scoreBackground"
    scoreBackground.size = CGSize(width: 200, height: 60)

    scoreLabel = SKLabelNode(fontNamed: "Worktalk")
    scoreLabel?.text = "Score: 0"
    scoreLabel?.fontSize = GameConfiguration.UI.labelFontSize
    scoreLabel?.fontColor = .white

    updateLabelPositions()

    if let scoreLabel = scoreLabel {
      // Add background first (behind the label)
      scene.addChild(scoreBackground)
      // Position the background at the same location as the label
      scoreBackground.position = scoreLabel.position
      // Add the label on top
      scene.addChild(scoreLabel)
    }
  }

  private func setupBulletLabel() {
    guard let scene = scene else { return }

    // Create background sprite
    let bulletBackground = SKSpriteNode(imageNamed: AssetName.bullet)
    bulletBackground.name = "bulletBackground"
    bulletBackground.size = CGSize(width: 60, height: 140)
    bulletBackground.zRotation = -(CGFloat.pi / 2)

    bulletLabel = SKLabelNode(fontNamed: "Worktalk")
    bulletLabel?.text = "\(GameConfiguration.Game.initialBullets)"
    bulletLabel?.fontSize = GameConfiguration.UI.labelFontSize
    bulletLabel?.fontColor = .white

    updateLabelPositions()

    if let bulletLabel = bulletLabel {
      // Add background first (behind the label)
      scene.addChild(bulletBackground)
      // Position the background at the same location as the label
      bulletBackground.position = bulletLabel.position
      // Add the label on top
      scene.addChild(bulletLabel)
    }
  }

  private func updateLabelPositions() {
    guard let scene = scene else { return }

    let padding = GameConfiguration.UI.labelPadding

    // Position score label at top left
    if let scoreLabel = scoreLabel {
      scoreLabel.position = CGPoint(
        x: padding + scoreLabel.frame.width / 2,
        y: scene.size.height - padding
      )

      // Update score background position
      if let scoreBackground = scene.childNode(withName: "scoreBackground") {
        scoreBackground.position =
          CGPoint(x: scoreLabel.position.x, y: scoreLabel.position.y + scoreLabel.frame.height / 2)
      }
    }

    // Position bullet label at bottom left
    if let bulletLabel = bulletLabel {
      bulletLabel.position = CGPoint(
        x: padding + bulletLabel.frame.width / 2,
        y: padding + bulletLabel.frame.height / 2
      )

      // Update bullet background position
      if let bulletBackground = scene.childNode(withName: "bulletBackground") {
        bulletBackground.position =
          CGPoint(
            x: bulletLabel.position.x, y: bulletLabel.position.y + bulletLabel.frame.height / 2)

        bulletLabel.position.x = bulletLabel.position.x - 28
      }
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
