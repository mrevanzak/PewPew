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

  // Game state
  @Published var isShapeVisible = true
  @Published var viewSize: CGSize = .zero
  @Published var score = 0
  @Published var gameStarted = false

  // Game configuration
  let shapeSize: CGFloat = 100
  let shapeColor = Color.blue.opacity(0.7)

  private var cancellables = Set<AnyCancellable>()

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
  }

  /// Stop the game session
  func stopGame() {
    gameStarted = false
    cameraManager.stopSession()
  }

  /// Update view size when geometry changes
  func updateViewSize(_ size: CGSize) {
    viewSize = size
  }

  /// Check for collision between finger points and shapes
  private func checkCollision() {
    guard isShapeVisible && handDetectionService.handDetectionData.isDetected && viewSize != .zero
    else { return }

    // Calculate shape frame (circle in center)
    let shapeFrame = CGRect(
      x: viewSize.width / 2 - shapeSize / 2,
      y: viewSize.height / 2 - shapeSize / 2,
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
    withAnimation(.easeOut(duration: 0.5)) {
      isShapeVisible = false
    }

    // Increment score
    score += 1

    // Reset shape after 2 seconds
    DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
      withAnimation(.easeIn(duration: 0.3)) {
        self.isShapeVisible = true
      }
    }

    // Add haptic feedback
    let impactFeedback = UIImpactFeedbackGenerator(style: .medium)
    impactFeedback.impactOccurred()
  }
}
