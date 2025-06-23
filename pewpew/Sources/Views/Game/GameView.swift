//
//  GameView.swift
//  pewpew
//
//  Main game view combining camera, hand detection, and game elements
//

import SpriteKit
import SwiftUI

/// Main game view that orchestrates all components
struct GameView: View {
  @StateObject private var viewModel = GameViewModel()
  @StateObject private var handDetectionService = HandDetectionService()
  
  var body: some View {
    GeometryReader { geometry in
      ZStack {
        // Camera background
        CameraBackgroundView(viewModel: viewModel)
        SpriteView(viewModel: viewModel)
        
        if viewModel.isGameOver {
          GameOverOverlayView(score: viewModel.score) {
            viewModel.replayGame()
          }
        }
      }
      .onAppear {
        viewModel.updateViewSize(geometry.size)
        viewModel.startGame()
      }
      .onDisappear {
        viewModel.stopGame()
      }
      .onChange(of: geometry.size) { oldSize, newSize in
        viewModel.updateViewSize(newSize)
      }
    }
    .ignoresSafeArea()
  }
}

// MARK: - Camera Background View
struct CameraBackgroundView: View {
  @ObservedObject var viewModel: GameViewModel
  
  var body: some View {
    Group {
      if viewModel.cameraManager.permissionGranted {
        CameraView(session: viewModel.cameraManager.session)
      } else {
        CameraPermissionView()
      }
    }
  }
}

// MARK: - Camera Permission View
struct CameraPermissionView: View {
  var body: some View {
    VStack(spacing: 16) {
      Image(systemName: "camera.fill")
        .font(.system(size: 60))
        .foregroundColor(.white.opacity(0.6))
      
      Text("Camera Permission Required")
        .font(.title2)
        .fontWeight(.semibold)
        .foregroundColor(.white)
      
      Text("Please enable camera access in System Preferences to play the game")
        .font(.body)
        .foregroundColor(.gray)
        .multilineTextAlignment(.center)
        .padding(.horizontal, 32)
    }
    .frame(maxWidth: .infinity, maxHeight: .infinity)
    .background(Color.black)
  }
}

// MARK: - Game Over Overlay View
struct GameOverOverlayView: View {
  let score: Int
  let onReplay: () -> Void
  var body: some View {
    VStack(spacing: 24) {
      Text("Game Over")
        .font(.largeTitle)
        .fontWeight(.bold)
        .foregroundColor(.red)
      Text("Score: \(score)")
        .font(.title2)
        .foregroundColor(.primary)
      Button(action: onReplay) {
        Text("Replay")
          .font(.title3)
          .fontWeight(.semibold)
          .padding(.horizontal, 32)
          .padding(.vertical, 12)
          .background(Color.blue)
          .foregroundColor(.white)
          .cornerRadius(10)
      }
    }
    .padding(40)
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 24))
    .shadow(radius: 20)
    .frame(maxWidth: .infinity, maxHeight: .infinity)
  }
}
