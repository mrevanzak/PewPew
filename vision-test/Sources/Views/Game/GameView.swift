//
//  GameView.swift
//  vision-test
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
        // Game overlays
        //                GameOverlaysView(viewModel: viewModel, viewSize: geometry.size)
        
        // Status overlay in safe area
//        StatusOverlayView(viewModel: viewModel)
      }
      .onAppear {
        viewModel.updateViewSize(geometry.size)
        viewModel.startGame()
        //                handDetectionService.startDetection() // Start hand detection
      }
      .onDisappear {
        viewModel.stopGame()
        //                handDetectionService.stopDetection() // Stop hand detection
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

// MARK: - Game Overlays View
struct GameOverlaysView: View {
  @ObservedObject var viewModel: GameViewModel
  let viewSize: CGSize
  
  var body: some View {
    ZStack {
      // Real-time finger tracking points - always visible and optimized
      FingerPointsOverlay(
        handDetectionService: viewModel.handDetectionService,
        viewSize: viewSize
      )
      
      // Interactive shape (if visible)
      if viewModel.isShapeVisible {
        InteractiveShape(
          size: viewModel.shapeSize,
          color: viewModel.currentShapeColor,
          position: viewModel.shapePosition
        )
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

// MARK: - Status Info Card
struct StatusInfoCard: View {
  @ObservedObject var handDetectionService: HandDetectionService
  
  var body: some View {
    VStack(alignment: .leading, spacing: 6) {
      HStack {
        Circle()
          .fill(handDetectionService.handDetectionData.isDetected ? .green : .red)
          .frame(width: 8, height: 8)
        Text("Hand Detected")
          .font(.caption)
          .fontWeight(.medium)
      }
      
      Text("Hands: \(handDetectionService.handDetectionData.fingerPointsPerHand.count)")
        .font(.caption2)
        .foregroundColor(.secondary)
      
      Text(
        "Confidence: \(String(format: "%.2f", handDetectionService.handDetectionData.confidence))"
      )
      .font(.caption2)
      .foregroundColor(.secondary)
      
    }
    .padding(12)
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
  }
}

// MARK: - Score Card
struct ScoreCard: View {
  let score: Int
  
  var body: some View {
    VStack(spacing: 4) {
      Text("SCORE")
        .font(.caption2)
        .fontWeight(.semibold)
        .foregroundColor(.secondary)
      
      Text("\(score)")
        .font(.title)
        .fontWeight(.bold)
        .foregroundColor(.primary)
    }
    .padding(16)
    .background(.ultraThinMaterial, in: RoundedRectangle(cornerRadius: 12))
  }
}
