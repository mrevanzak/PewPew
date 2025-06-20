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

/// ViewModel managing game state and camera
class GameViewModel: ObservableObject {
  // Hand detection and camera services
  @Published var handDetectionService = HandDetectionService()
  @Published var cameraManager: CameraManager

  // Basic game state
  @Published var viewSize: CGSize = .zero
  @Published var gameStarted = false

  private var cancellables = Set<AnyCancellable>()

  init() {
    let handService = HandDetectionService()
    self.handDetectionService = handService
    self.cameraManager = CameraManager(handDetectionService: handService)
  }

  /// Start the game session
  func startGame() {
    gameStarted = true
    cameraManager.startSession()
  }

  /// Stop the game session
  func stopGame() {
    gameStarted = false
    cameraManager.stopSession()
  }

  /// Restart the game
  func restartGame() {
    stopGame()
    DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
      self.startGame()
    }
  }

  /// Update view size when geometry changes
  func updateViewSize(_ size: CGSize) {
    viewSize = size
  }
}
