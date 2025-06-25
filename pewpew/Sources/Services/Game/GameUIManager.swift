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
    // setupBuildings() removed from here
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

    // Remove old score label and background if they exist
    scene.childNode(withName: "scoreBackground")?.removeFromParent()
    scoreLabel?.removeFromParent()

    // Create background sprite
    let scoreBackground = SKSpriteNode(imageNamed: AssetName.scoreBoard)
    scoreBackground.name = "scoreBackground"
    scoreBackground.size = CGSize(width: 200, height: 60)

    scoreLabel = SKLabelNode(fontNamed: "Worktalk")
    scoreLabel?.text = "Score: 0"
    scoreLabel?.fontSize = GameConfiguration.UI.labelFontSize
    scoreLabel?.fontColor = .white

    if let scoreLabel = scoreLabel {
      // Add background and label to scene first
      scene.addChild(scoreBackground)
      scene.addChild(scoreLabel)
    }
    // Now update positions (frame is correct)
    updateLabelPositions()
  }

  private func setupBulletLabel() {
    guard let scene = scene else { return }

    // Remove old bullet label and background if they exist
    scene.childNode(withName: "bulletBackground")?.removeFromParent()
    bulletLabel?.removeFromParent()

    // Create background sprite
    let bulletBackground = SKSpriteNode(imageNamed: AssetName.bullet)
    bulletBackground.name = "bulletBackground"
    bulletBackground.size = CGSize(width: 80, height: 180)
    bulletBackground.zRotation = -(CGFloat.pi / 2)

    bulletLabel = SKLabelNode(fontNamed: "Worktalk")
    bulletLabel?.text = "\(GameConfiguration.Game.initialBullets)"
    bulletLabel?.fontSize = 48
    bulletLabel?.fontColor = .white

    if let bulletLabel = bulletLabel {
      // Add background and label to scene first
      scene.addChild(bulletBackground)
      scene.addChild(bulletLabel)
    }
    // Now update positions (frame is correct)
    updateLabelPositions()
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
      x: UIPositioning.baseXPosition - 10,
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

  // MARK: - Building Layout
  func layoutBuildings(for size: CGSize) {
    guard let scene = scene else { return }
    // Remove old buildings if any
    scene.childNode(withName: "leftBuilding")?.removeFromParent()
    scene.childNode(withName: "rightBuilding")?.removeFromParent()

    let buildingTexture = SKTexture(imageNamed: "building")
    let buildingSize = CGSize(width: size.width * 0.18, height: size.height * 0.6)
    let yPos = buildingSize.height / 2 // bottom aligned

    // Left building (flipped horizontally)
    let leftBuilding = SKSpriteNode(texture: buildingTexture)
    leftBuilding.size = buildingSize
    leftBuilding.position = CGPoint(x: leftBuilding.size.width / 2, y: yPos)
    leftBuilding.zPosition = -1
    leftBuilding.name = "leftBuilding"
    leftBuilding.xScale = -1 // flip horizontally
    scene.addChild(leftBuilding)

    // Right building
    let rightBuilding = SKSpriteNode(texture: buildingTexture)
    rightBuilding.size = buildingSize
    rightBuilding.position = CGPoint(x: size.width - rightBuilding.size.width / 2, y: yPos)
    rightBuilding.zPosition = -1
    rightBuilding.name = "rightBuilding"
    scene.addChild(rightBuilding)
  }

  // MARK: - Scene Size Changes
  func updateForSceneSize() {
    updateLabelPositions()
  }
}
