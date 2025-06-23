//
//  GameScene.swift
//  pewpew
//
//  Clean SpriteKit scene focused on rendering and physics
//

import SpriteKit
import SwiftUI
import Combine

// MARK: - Clean Game Scene
final class GameScene: SKScene {

  // MARK: - Properties
  weak var viewModel: GameViewModel?
  var handDetectionService: HandDetectionService?
  var onGameOver: (() -> Void)?

  // MARK: - Components
  private var scoreManager: ScoreManager?
  private var targetSpawner: TargetSpawner?
  private var handTracker: HandTracker?
  private var projectileManager: ProjectileManager?
  private var uiManager: GameUIManager?
  private var coordinateConverter: CoordinateConverter?

  // Combine subscriptions for observing score/bullets
  private var subscriptions = Set<AnyCancellable>()

  // MARK: - Lifecycle
  override func didMove(to view: SKView) {
    setupScene()
    setupComponents()
    setupUI()
  }

  // MARK: - Setup
  private func setupScene() {
    backgroundColor = .clear
    physicsWorld.contactDelegate = self
    physicsWorld.gravity = CGVector(dx: 0, dy: 0)
  }

  private func setupComponents() {
    guard let viewModel = viewModel else { return }

    scoreManager = viewModel.scoreManager
    coordinateConverter = CoordinateConverter(scene: self)

    guard let scoreManager = scoreManager,
      let coordinateConverter = coordinateConverter
    else { return }

    // Observe score and bullets changes
    scoreManager.$currentScore
      .receive(on: RunLoop.main)
      .sink { [weak self] _ in
        self?.updateUIWithCurrentValues()
      }
      .store(in: &subscriptions)
    scoreManager.$currentBullets
      .receive(on: RunLoop.main)
      .sink { [weak self] _ in
        self?.updateUIWithCurrentValues()
      }
      .store(in: &subscriptions)

    projectileManager = ProjectileManager(scene: self, scoreManager: scoreManager)
    targetSpawner = TargetSpawner(scene: self, scoreManager: scoreManager)

    guard let projectileManager = projectileManager else { return }

    handTracker = HandTracker(
      scene: self,
      coordinateConverter: coordinateConverter,
      projectileManager: projectileManager,
      handDetectionService: handDetectionService
    )

    uiManager = GameUIManager(scene: self)
  }

  private func setupUI() {
    uiManager?.setupUI()
    updateUIWithCurrentValues()
  }

  private func updateUIWithCurrentValues() {
    guard let scoreManager = scoreManager else { return }
    uiManager?.updateScoreDisplay(scoreManager.currentScore)
    uiManager?.updateBulletsDisplay(scoreManager.currentBullets)
  }

  // MARK: - Public Interface

  func startSpawning() {
    targetSpawner?.startSpawning()
  }

  func stopSpawning() {
    targetSpawner?.stopSpawning()
  }

  func resetScene() {
    removeAllChildren()
    targetSpawner?.stopSpawning()
    setupUI()
  }

  func updateCirclesWithHandData(_ handData: HandDetectionData) {
    handTracker?.updateHandCircles(with: handData)
    handTracker?.detectShootGesture(for: handData)
  }

  // MARK: - Scene Size Changes
  override func didChangeSize(_ oldSize: CGSize) {
    super.didChangeSize(oldSize)
    uiManager?.updateForSceneSize()
  }
}

// MARK: - Physics Contact Delegate
extension GameScene: SKPhysicsContactDelegate {

  func didBegin(_ contact: SKPhysicsContact) {
    handleProjectileCollision(contact: contact)
  }

  private func handleProjectileCollision(contact: SKPhysicsContact) {
    let names = [contact.bodyA.node?.name, contact.bodyB.node?.name]

    // Check for projectile-target collision
    if names.contains(NodeName.projectile)
      && (names.contains(NodeName.alienTarget) || names.contains(NodeName.bulletTarget))
    {

      let projectile =
        contact.bodyA.node?.name == NodeName.projectile ? contact.bodyA.node : contact.bodyB.node
      let target =
        contact.bodyA.node?.name == NodeName.alienTarget
          || contact.bodyA.node?.name == NodeName.bulletTarget
        ? contact.bodyA.node : contact.bodyB.node

      guard let projectileNode = projectile,
        let targetNode = target
      else { return }

      handleTargetHit(targetNode)
      projectileNode.removeFromParent()
    }
  }

  private func handleTargetHit(_ target: SKNode) {
    guard let scoreManager = scoreManager,
      let uiManager = uiManager
    else { return }

    if target.name == NodeName.bulletTarget {
      // Bullet target gives bullets
      scoreManager.addBullets(GameConfiguration.Game.bulletReward)
      uiManager.showEffect(
        at: target.position,
        text: "+\(GameConfiguration.Game.bulletReward) Bullets",
        color: .cyan)
      uiManager.animateBulletLabel()
    } else {
      // Alien target gives score with enhanced effects
      scoreManager.addScore(GameConfiguration.Game.targetScoreValue)

      // Enhanced alien hit effect
      if let sprite = target as? SKSpriteNode, sprite.name == NodeName.alienTarget {
        createImpactEffect(at: sprite.position)
        createAlienCrashEffect(for: sprite)
      }

      uiManager.showEffect(
        at: target.position,
        text: "+\(GameConfiguration.Game.targetScoreValue)",
        color: .green)
      uiManager.animateScoreLabel()
    }

    // Remove target if it's not an alien (aliens are handled by crash effect)
    if target.name != NodeName.alienTarget {
      target.removeFromParent()
    }
  }

  // MARK: - Enhanced Effects

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

  private func createAlienCrashEffect(for sprite: SKSpriteNode) {
    // Stop all existing actions (movement and wiggle)
    sprite.removeAllActions()

    let crashTexture = SKTexture(imageNamed: AssetName.alienCrash)

    // Create a better death animation sequence
    let stopMovement = SKAction.run {
      sprite.physicsBody?.velocity = CGVector(dx: 0, dy: 0)
    }

    let shortPause = SKAction.wait(forDuration: 0.1)
    let setCrash = SKAction.run { sprite.texture = crashTexture }
    let holdDeadImage = SKAction.wait(forDuration: 0.2)  // Show dead alien longer
    let fadeOut = SKAction.fadeOut(withDuration: 0.4)
    let remove = SKAction.removeFromParent()

    let crashSequence = SKAction.sequence([
      stopMovement,
      shortPause,
      setCrash,
      holdDeadImage,
      fadeOut,
      remove,
    ])

    sprite.run(crashSequence)
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
        viewModel?.gameOver(finalScore: viewModel?.scoreManager.currentScore)
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
          gameScene.startSpawning()
        }
        .onReceive(viewModel.handDetectionService.$handDetectionData) { newData in
          gameScene.updateCirclesWithHandData(newData)
        }
        .onChange(of: viewModel.isGameOver) { _, isGameOver in
          if isGameOver {
            gameScene.stopSpawning()
          } else {
            gameScene.resetScene()
            gameScene.startSpawning()
          }
        }
    }
  }
}
