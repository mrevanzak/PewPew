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

    positionScoreUI(in: scene)
    positionBulletUI(in: scene)
  }

  // MARK: - UI Positioning Constants

  private struct UIPositioning {
    static let padding = GameConfiguration.UI.labelPadding
    static let baseXPosition = padding + 48
    static let bulletTextOffset: CGFloat = 56  // Total offset for bullet text positioning
  }

  // MARK: - Score UI Positioning

  private func positionScoreUI(in scene: SKScene) {
    guard let scoreLabel = scoreLabel else { return }

    let scorePosition = CGPoint(
      x: UIPositioning.baseXPosition,
      y: scene.size.height - UIPositioning.padding
    )

    scoreLabel.position = scorePosition
    positionScoreBackground(at: scorePosition, in: scene)
  }

  private func positionScoreBackground(at labelPosition: CGPoint, in scene: SKScene) {
    guard let scoreBackground = scene.childNode(withName: "scoreBackground"),
      let scoreLabel = scoreLabel
    else { return }

    scoreBackground.position = CGPoint(
      x: labelPosition.x,
      y: labelPosition.y + scoreLabel.frame.height / 2
    )
  }

  // MARK: - Bullet UI Positioning

  private func positionBulletUI(in scene: SKScene) {
    guard let bulletLabel = bulletLabel else { return }

    let bulletTextPosition = CGPoint(
      x: UIPositioning.baseXPosition - UIPositioning.bulletTextOffset,
      y: UIPositioning.padding + bulletLabel.frame.height / 2
    )

    let bulletBackgroundPosition = CGPoint(
      x: UIPositioning.baseXPosition - 28,
      y: bulletTextPosition.y + bulletLabel.frame.height / 2
    )

    bulletLabel.position = bulletTextPosition
    positionBulletBackground(at: bulletBackgroundPosition, in: scene)
  }

  private func positionBulletBackground(at position: CGPoint, in scene: SKScene) {
    guard let bulletBackground = scene.childNode(withName: "bulletBackground") else { return }

    bulletBackground.position = position
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
