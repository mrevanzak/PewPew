//
//  GameViewModel.swift
//  vision-test
//
//  ViewModel for game logic and state management
//

import AVFoundation
import Combine
import SwiftUI
import UIKit
import Vision

/// ViewModel managing game state and collision detection logic
class GameViewModel: ObservableObject {
  // Hand detection and camera services
  @Published var handDetectionService = HandDetectionService()
  @Published var cameraManager: CameraManager

  // Sequence-based game state
  @Published var gameState = GameState()
  @Published var sequenceCircles: [SequenceCircle] = []
  @Published var viewSize: CGSize = .zero
  @Published var gameStarted = false

  // Legacy properties for compatibility
  @Published var isShapeVisible = false
  @Published var shapePosition: CGPoint = .zero
  @Published var currentShapeColor: Color = .blue
  var score: Int { gameState.score }

  // Game configuration
  let shapeSize: CGFloat = 80
  private let minSpawnDelay: Double = 2.0
  private let maxSpawnDelay: Double = 4.0
  private let maxActiveCircles: Int = 3

  // Collision detection configuration
  @Published var collisionDetectionType: CollisionDetectionType = .fingerPoints
  private var collisionStrategy: CollisionDetectionStrategy {
    collisionDetectionType.createStrategy()
  }

  private var cancellables = Set<AnyCancellable>()
  private var spawnTimer: Timer?
  private var cleanupTimer: Timer?

  init() {
    let handService = HandDetectionService()
    self.handDetectionService = handService
    self.cameraManager = CameraManager(handDetectionService: handService)

    setupSubscriptions()
  }

  /// Setup reactive subscriptions for collision detection
  private func setupSubscriptions() {
    // Monitor hand detection data changes for collision detection
    handDetectionService.$handDetectionData
      .receive(on: DispatchQueue.main)
      .sink { [weak self] _ in
        self?.checkSequenceCollisions()
      }
      .store(in: &cancellables)
  }

  /// Start the game session
  func startGame() {
    gameStarted = true
    gameState.reset()
    sequenceCircles.removeAll()
    cameraManager.startSession()
    startSequenceSpawning()
    startCleanupTimer()
  }

  /// Stop the game session
  func stopGame() {
    gameStarted = false
    cameraManager.stopSession()
    stopSpawning()
    sequenceCircles.removeAll()
  }

  /// Restart the game
  func restartGame() {
    // Immediately reset game state to hide overlay
    gameState.reset()
    sequenceCircles.removeAll()

    stopGame()
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
      self.startGame()
    }
  }

  /// Update view size when geometry changes
  func updateViewSize(_ size: CGSize) {
    viewSize = size
  }

  /// Switch collision detection method
  /// - Parameter type: The collision detection type to use
  func setCollisionDetection(to type: CollisionDetectionType) {
    collisionDetectionType = type
  }

  // MARK: - Sequence Game Logic

  /// Start spawning sequence circles
  private func startSequenceSpawning() {
    scheduleNextSequenceSpawn()
  }

  /// Stop all spawning timers
  private func stopSpawning() {
    spawnTimer?.invalidate()
    spawnTimer = nil
    cleanupTimer?.invalidate()
    cleanupTimer = nil
  }

  /// Schedule the next sequence circle spawn
  private func scheduleNextSequenceSpawn() {
    guard gameStarted && !gameState.isGameOver && !gameState.isGameWon else { return }

    let randomDelay = Double.random(in: minSpawnDelay...maxSpawnDelay)

    spawnTimer?.invalidate()
    spawnTimer = Timer.scheduledTimer(withTimeInterval: randomDelay, repeats: false) {
      [weak self] _ in
      self?.spawnSequenceCircle()
    }
  }

  /// Spawn a new sequence circle
  private func spawnSequenceCircle() {
    guard gameStarted && viewSize != .zero && sequenceCircles.count < maxActiveCircles else {
      scheduleNextSequenceSpawn()
      return
    }

    // Generate random position
    let safeMargin = shapeSize / 2 + 20
    let randomX = Double.random(in: safeMargin...(viewSize.width - safeMargin))
    let randomY = Double.random(in: safeMargin...(viewSize.height - safeMargin))
    let position = CGPoint(x: randomX, y: randomY)

    // Generate color based on sequence number
    let colors: [Color] = [.blue, .red, .green, .orange, .purple]
    let colorIndex = (gameState.nextSequenceToSpawn - 1) % colors.count
    let color = colors[colorIndex]

    // Create new sequence circle
    let circle = SequenceCircle(
      sequenceNumber: gameState.nextSequenceToSpawn,
      position: position,
      size: shapeSize,
      color: color
    )

    withAnimation(.spring(response: 0.6, dampingFraction: 0.8)) {
      sequenceCircles.append(circle)
    }

    // Update next sequence number to spawn
    gameState.nextSequenceToSpawn += 1
    if gameState.nextSequenceToSpawn > gameState.maxSequenceNumbers {
      gameState.nextSequenceToSpawn = 1
    }

    // Schedule next spawn
    scheduleNextSequenceSpawn()
  }

  /// Start cleanup timer to remove expired circles
  private func startCleanupTimer() {
    cleanupTimer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
      self?.cleanupExpiredCircles()
    }
  }

  /// Remove expired circles and handle damage
  private func cleanupExpiredCircles() {
    let currentTime = Date()
    let expiredCircles = sequenceCircles.filter { circle in
      currentTime.timeIntervalSince(circle.spawnTime) > gameState.circleLifetime
    }

    for expiredCircle in expiredCircles {
      if !expiredCircle.isHit && expiredCircle.sequenceNumber == gameState.currentSequence {
        // Player missed the correct sequence - take damage
        gameState.takeDamage()
        provideMissedSequenceFeedback()
      }
    }

    withAnimation(.easeOut(duration: 0.3)) {
      sequenceCircles.removeAll { circle in
        currentTime.timeIntervalSince(circle.spawnTime) > gameState.circleLifetime
      }
    }
  }

  /// Check for collisions with sequence circles
  private func checkSequenceCollisions() {
    guard gameStarted && handDetectionService.handDetectionData.isDetected && viewSize != .zero
    else { return }

    for (index, circle) in sequenceCircles.enumerated() {
      guard !circle.isHit else { continue }

      let circleFrame = CGRect(
        x: circle.position.x - circle.size / 2,
        y: circle.position.y - circle.size / 2,
        width: circle.size,
        height: circle.size
      )

      let collision = collisionStrategy.checkCollision(
        hands: handDetectionService.handDetectionData.hands,
        shapeFrame: circleFrame,
        viewSize: viewSize
      )

      if collision.hasCollision {
        handleSequenceTouch(at: index)
        break  // Only handle one collision per frame
      }
    }
  }

  /// Handle touch on a sequence circle
  private func handleSequenceTouch(at index: Int) {
    guard index < sequenceCircles.count else { return }

    let touchedCircle = sequenceCircles[index]

    // Mark circle as hit
    sequenceCircles[index].isHit = true

    if touchedCircle.sequenceNumber == gameState.currentSequence {
      // Correct sequence - award points
      handleCorrectSequence(at: index)
    } else {
      // Wrong sequence - take damage
      handleWrongSequence(at: index)
    }
  }

  /// Handle correct sequence touch
  private func handleCorrectSequence(at index: Int) {
    withAnimation(.easeOut(duration: 0.3)) {
      sequenceCircles.remove(at: index)
    }

    gameState.scorePoint()
    provideCorrectSequenceFeedback()

    // Check for win condition
    if gameState.isGameWon {
      provideWinFeedback()
      stopSpawning()
    }
  }

  /// Handle wrong sequence touch
  private func handleWrongSequence(at index: Int) {
    let wrongCircle = sequenceCircles[index]

    // Visual feedback for wrong tap
    withAnimation(.easeOut(duration: 0.3)) {
      sequenceCircles.remove(at: index)
    }

    gameState.takeDamage()
    provideWrongSequenceFeedback()

    // Check for game over
    if gameState.isGameOver {
      provideGameOverFeedback()
      stopSpawning()
    }
  }

  // MARK: - Haptic & Audio Feedback

  /// Provide feedback for correct sequence
  private func provideCorrectSequenceFeedback() {
    let feedback = UINotificationFeedbackGenerator()
    feedback.notificationOccurred(.success)
  }

  /// Provide feedback for wrong sequence
  private func provideWrongSequenceFeedback() {
    let feedback = UINotificationFeedbackGenerator()
    feedback.notificationOccurred(.error)
  }

  /// Provide feedback for missed sequence
  private func provideMissedSequenceFeedback() {
    let feedback = UIImpactFeedbackGenerator(style: .heavy)
    feedback.impactOccurred()
  }

  /// Provide feedback for game win
  private func provideWinFeedback() {
    let feedback = UINotificationFeedbackGenerator()
    feedback.notificationOccurred(.success)
  }

  /// Provide feedback for game over
  private func provideGameOverFeedback() {
    let feedback = UINotificationFeedbackGenerator()
    feedback.notificationOccurred(.error)
  }

  // MARK: - Legacy Support

  /// Legacy method for backward compatibility
  private func handleCollision() {
    // This method is kept for compatibility but not used in sequence game
  }
}
