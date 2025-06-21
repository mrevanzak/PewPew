//
//  GameViewModel.swift
//  pewpew
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

  // Game state
  @Published var isShapeVisible = false
  @Published var viewSize: CGSize = .zero
  @Published var score = 0
  @Published var gameStarted = false
  @Published var isGameOver: Bool = false
  
  // Random spawn properties
  @Published var shapePosition: CGPoint = .zero
  @Published var currentShapeColor: Color = .blue

  // Game configuration
  let shapeSize: CGFloat = 100
  let shapeColor = Color.blue.opacity(0.7)
  
  // Spawn timing configuration
  private let minSpawnDelay: Double = 1.0
  private let maxSpawnDelay: Double = 4.0
  private let shapeVisibleDuration: Double = 3.0

  // Bullet system state for SpriteKit
  @Published var bullets: Int = 10
  let maxBullets = 100

  private var cancellables = Set<AnyCancellable>()
  private var spawnTimer: Timer?

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
        self?.checkCollision()
      }
      .store(in: &cancellables)
  }

  /// Start the game session
  func startGame() {
    gameStarted = true
    score = 0
    cameraManager.startSession()
    startRandomSpawning()
  }

  /// Stop the game session
  func stopGame() {
    gameStarted = false
    cameraManager.stopSession()
    stopRandomSpawning()
  }

  /// Update view size when geometry changes
  func updateViewSize(_ size: CGSize) {
    viewSize = size
  }
  
  /// Start random spawning timer
  private func startRandomSpawning() {
    // Schedule first spawn
    scheduleNextSpawn()
  }
  
  /// Stop random spawning timer
  private func stopRandomSpawning() {
    spawnTimer?.invalidate()
    spawnTimer = nil
    isShapeVisible = false
  }
  
  /// Schedule the next random spawn
  private func scheduleNextSpawn() {
    let randomDelay = Double.random(in: minSpawnDelay...maxSpawnDelay)
    
    spawnTimer?.invalidate()
    spawnTimer = Timer.scheduledTimer(withTimeInterval: randomDelay, repeats: false) { [weak self] _ in
      self?.spawnShape()
    }
  }
  
  /// Spawn shape at random position with random color
  private func spawnShape() {
    guard gameStarted && viewSize != .zero else { return }
    
    // Generate random position (ensuring shape stays within bounds)
    let safeMargin = shapeSize / 2 + 20
    let randomX = Double.random(in: safeMargin...(viewSize.width - safeMargin))
    let randomY = Double.random(in: safeMargin...(viewSize.height - safeMargin))
    
    shapePosition = CGPoint(x: randomX, y: randomY)
    
    // Generate random color
    let colors: [Color] = [.blue, .red, .green, .orange, .purple, .pink]
    currentShapeColor = colors.randomElement()?.opacity(0.7) ?? .blue.opacity(0.7)
    
    // Show shape with animation
    withAnimation(.easeIn(duration: 0.3)) {
      isShapeVisible = true
    }
    
    // Hide shape after duration
    DispatchQueue.main.asyncAfter(deadline: .now() + shapeVisibleDuration) {
      if self.isShapeVisible {
        self.hideShape()
      }
    }
  }
  
  /// Hide shape and schedule next spawn
  private func hideShape() {
    withAnimation(.easeOut(duration: 0.3)) {
      isShapeVisible = false
    }
    
    // Schedule next spawn
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
      self.scheduleNextSpawn()
    }
  }

  /// Check for collision between finger points and shapes
  private func checkCollision() {
    guard isShapeVisible && handDetectionService.handDetectionData.isDetected && viewSize != .zero
    else { return }

    // Calculate shape frame using dynamic position
    let shapeFrame = CGRect(
      x: shapePosition.x - shapeSize / 2,
      y: shapePosition.y - shapeSize / 2,
      width: shapeSize,
      height: shapeSize
    )

    // Use the improved collision detection from utilities
    let collision = CollisionDetection.checkFingerCollision(
      fingerPoints: handDetectionService.handDetectionData.fingerPointsPerHand,
      shapeFrame: shapeFrame,
      viewSize: viewSize
    )

    if collision.hasCollision {
      handleCollision()
    }
  }

  /// Handle collision detected event
  private func handleCollision() {
    // Hide the shape when collision is detected
    withAnimation(.easeOut(duration: 0.3)) {
      isShapeVisible = false
    }

    // Increment score
    score += 1

    // Schedule next spawn after short delay
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
      self.scheduleNextSpawn()
    }

    // Add haptic feedback
    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    impactFeedback.impactOccurred()
  }

  /// Called by GameScene when bullets reach zero
  func gameOver(finalScore: Int? = nil) {
    isGameOver = true
    gameStarted = false
    stopGame()
    if let score = finalScore {
      self.score = score
    }
  }

  /// Replay the game (reset state)
  func replayGame() {
    score = 0
    bullets = maxBullets
    isGameOver = false
    gameStarted = false
    startGame()
  }
}
