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

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        // Camera background
        CameraBackgroundView(viewModel: viewModel)

        // Game overlays
        SpriteView(viewModel: viewModel)
        //        GameOverlaysView(viewModel: viewModel, viewSize: geometry.size)

        // Status overlay in safe area
        StatusOverlayView(viewModel: viewModel)
      }
      .onAppear {
        viewModel.updateViewSize(geometry.size)
        viewModel.startGame()
      }
      .onDisappear {
        viewModel.stopGame()
      }
      .onChange(of: geometry.size) { newSize in
        viewModel.updateViewSize(newSize)
      }
    }
    .ignoresSafeArea()
    .persistentSystemOverlays(.hidden)
  }
}

// MARK: - Camera Background View
struct CameraBackgroundView: View {
  @ObservedObject var viewModel: GameViewModel

  var body: some View {
    Group {
      if viewModel.cameraManager.permissionGranted {
        CameraView(cameraManager: viewModel.cameraManager)
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

// MARK: - Game Overlays View
struct GameOverlaysView: View {
  @ObservedObject var viewModel: GameViewModel
  let viewSize: CGSize

  var body: some View {
    ZStack {
      // Real-time finger tracking points - always visible and optimized
      // FingerPointsOverlay(
      //   handDetectionService: viewModel.handDetectionService,
      //   viewSize: viewSize
      // )

      // Target image following palm
      TargetImageOverlay(
        handDetectionService: viewModel.handDetectionService,
        viewSize: viewSize
      )

      // Sequence circles
      ForEach(viewModel.sequenceCircles) { circle in
        SequenceCircleView(circle: circle)
      }

      // Game over/win overlay
      if viewModel.gameState.isGameOver || viewModel.gameState.isGameWon {
        GameEndOverlay(viewModel: viewModel, viewSize: viewSize)
      }

      // Image("foreground")
      //   .resizable()
      //   .frame(width: viewSize.width, height: viewSize.height)
      //   .position(CGPoint(x: viewSize.width / 2, y: viewSize.height / 2))
    }
  }
}

// MARK: - Sequence Circle View
struct SequenceCircleView: View {
  let circle: SequenceCircle

  var body: some View {
    ZStack {
      Circle()
        .fill(circle.color.opacity(0.8))
        .frame(width: circle.size, height: circle.size)
        .overlay(
          Circle()
            .stroke(Color.white, lineWidth: 3)
        )
        .shadow(color: circle.color.opacity(0.6), radius: 10, x: 0, y: 5)

      Text("\(circle.sequenceNumber)")
        .font(.title)
        .fontWeight(.bold)
        .foregroundColor(.white)
        .shadow(color: .black.opacity(0.5), radius: 2, x: 1, y: 1)
    }
    .position(circle.position)
    .scaleEffect(circle.isHit ? 1.2 : 1.0)
    .opacity(circle.isHit ? 0.5 : 1.0)
    .animation(.easeInOut(duration: 0.3), value: circle.isHit)
  }
}

// MARK: - Game End Overlay
struct GameEndOverlay: View {
  @ObservedObject var viewModel: GameViewModel
  let viewSize: CGSize

  var body: some View {
    ZStack {
      // Background overlay
      Rectangle()
        .fill(.black.opacity(0.8))
        .ignoresSafeArea()

      VStack(spacing: 24) {
        // Game result icon
        Image(
          systemName: viewModel.gameState.isGameWon ? "checkmark.circle.fill" : "xmark.circle.fill"
        )
        .font(.system(size: 80))
        .foregroundColor(viewModel.gameState.isGameWon ? .green : .red)

        // Game result text
        Text(viewModel.gameState.isGameWon ? "You Won!" : "Game Over")
          .font(.largeTitle)
          .fontWeight(.bold)
          .foregroundColor(.white)

        // Score display
        Text("Final Score: \(viewModel.gameState.score)")
          .font(.title2)
          .foregroundColor(.gray)

        // Restart button
        Button(action: {
          viewModel.restartGame()
        }) {
          HStack {
            Image(systemName: "arrow.clockwise")
            Text("Play Again")
          }
          .font(.title2)
          .fontWeight(.semibold)
          .foregroundColor(.white)
          .padding()
          .background(.blue)
          .cornerRadius(12)
        }
      }
      .padding(32)
      .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 20))
    }
  }
}

// MARK: - Target Image Overlay
struct TargetImageOverlay: View {
  @ObservedObject var handDetectionService: HandDetectionService
  let viewSize: CGSize

  var body: some View {
    ZStack {
      ForEach(handDetectionService.handDetectionData.hands.indices, id: \.self) { handIndex in
        let hand = handDetectionService.handDetectionData.hands[handIndex]
        let palmPosition = TargetImageCalculations.calculatePalmPosition(for: hand)
        let dynamicSize = TargetImageCalculations.calculateTargetSize(for: hand, baseSize: 60)

        Image("target")
          .resizable()
          .frame(width: dynamicSize, height: dynamicSize)
          .position(palmPosition)
          .scaleEffect(1.0)
          .animation(.easeOut(duration: 0.2), value: dynamicSize)
          .opacity(handDetectionService.handDetectionData.isDetected ? 0.6 : 0.0)
      }
    }
  }

}

// MARK: - Interactive Shape
struct InteractiveShape: View {
  let size: CGFloat
  let color: Color
  let position: CGPoint

  var body: some View {
    Circle()
      .fill(color)
      .frame(width: size, height: size)
      .position(position)
      .shadow(color: color.opacity(0.4), radius: 15, x: 0, y: 5)
      .scaleEffect(1.0)
      .animation(.easeInOut(duration: 1.5).repeatForever(autoreverses: true), value: UUID())
  }
}
