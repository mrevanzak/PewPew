//
//  GameView.swift
//  pewpew
//
//  Main game view combining camera, hand detection, and game elements
//

import SpriteKit
import SwiftUI

/// Clean main game view that orchestrates all components
struct GameView: View {
  @EnvironmentObject var viewModel: GameViewModel
  @Environment(\.dismiss) private var dismiss

  let dismissToRoot: () -> Void

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        // Camera background
        CameraBackgroundView(viewModel: viewModel)

        // Frame to hide the black bar
        BlackBarHider(screenSize: geometry.size)

        // Game scene
        SpriteView(viewModel: viewModel)

        // Character at center bottom
        CharacterView(
          character: viewModel.selectedCharacter,
          screenSize: geometry.size,
        )

        // Pause button (top-right)
        VStack {
          HStack {
            Spacer()
            Button(action: {
              viewModel.pauseGame()
            }) {
              Image("pause")
                .resizable()
                .frame(width: 60, height: 60)
                .foregroundColor(.white)
                .shadow(radius: 4)
            }
            .padding(.top, 24)
            .padding(.trailing, 24)
          }
          Spacer()
        }
        .opacity(viewModel.isGameOver || viewModel.isPaused ? 0 : 1)

        // Timer display (top center)
        VStack {
          HStack {
            Spacer()
            Text(timeString(from: viewModel.timeRemaining))
              .font(.custom("Worktalk", size: 48))
              .foregroundColor(.white)
              .padding(.top, 24)
              .shadow(radius: 4)
            Spacer()
          }
          Spacer()
        }
        .opacity(viewModel.isGameOver || viewModel.isPaused ? 0 : 1)

        // Game over overlay
        if viewModel.isGameOver {
          GameOverOverlayView(
            score: viewModel.score,
            onReplay: {
              viewModel.replayGame()
            },
            onMenu: {
              dismissToRoot()
            })
        }

        // Pause overlay
        if viewModel.isPaused && !viewModel.isGameOver {
          PauseOverlayView(
            onResume: {
              viewModel.resumeGame()
            },
            onMenu: {
              viewModel.stopGame()
              dismissToRoot()
            })
        }
      }
      .onAppear {
        viewModel.updateViewSize(geometry.size)
        viewModel.startGame()
      }
      .onDisappear {
        viewModel.stopGame()
      }
      .onChange(of: geometry.size) { _, newSize in
        viewModel.updateViewSize(newSize)
      }
    }
    .ignoresSafeArea()
  }
}

// MARK: - Black Bar Hider View
struct BlackBarHider: View {
  let screenSize: CGSize

  // Standard camera aspect ratio (most mobile cameras use 16:9 or 4:3)
  private let cameraAspectRatio: CGFloat = 16.0 / 9.0

  private var blackBarHeight: CGFloat {
    let screenAspectRatio = screenSize.width / screenSize.height

    // If camera aspect ratio is wider than screen, we get top/bottom black bars
    if cameraAspectRatio > screenAspectRatio {
      let cameraHeightOnScreen = screenSize.width / cameraAspectRatio
      return (screenSize.height - cameraHeightOnScreen) / 2
    }
    return 0
  }

  var body: some View {
    VStack(spacing: 0) {
      // Top black bar frame
      if blackBarHeight > 0 {
        Image("frame")
          .resizable()
          .aspectRatio(contentMode: .fill)
          .frame(width: screenSize.width, height: blackBarHeight)
          .clipped()
      }

      Spacer()

      // Bottom black bar frame
      if blackBarHeight > 0 {
        Image("frame")
          .resizable()
          .aspectRatio(contentMode: .fill)
          .frame(width: screenSize.width, height: blackBarHeight)
          .clipped()
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

// MARK: - Character View
struct CharacterView: View {
  let character: Character
  let screenSize: CGSize

  var characterHeight: CGFloat {
    screenSize.height * 0.15
  }

  var body: some View {
    VStack {
      Spacer()

      // Character body
      ZStack {
        Image("\(character.imageName)LeftHand")
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(height: characterHeight * 0.6)
          .offset(x: -characterHeight * 0.35, y: -characterHeight * 0.18)

        Image("\(character.imageName)RightHand")
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(height: characterHeight * 0.6)
          .offset(x: characterHeight * 0.35, y: -characterHeight * 0.18)

        Image("\(character.imageName)Back")
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(height: characterHeight)  // Character size relative to screen
          .padding(.bottom, 20)  // Small margin from bottom
      }
    }
  }
}

// MARK: - Game Over Overlay View
struct GameOverOverlayView: View {
  let score: Int
  let onReplay: () -> Void
  let onMenu: () -> Void
  var body: some View {
    ZStack {
      Image("gameoverOverlay")
        .resizable()
        .aspectRatio(contentMode: .fill)
        .ignoresSafeArea()

      VStack(spacing: 24) {
        ZStack {
          Image("scoreBoard")
          VStack(spacing: 12) {
            Text("Game Over")
              .font(.custom("Worktalk", size: 48))
              .fontWeight(.bold)
              .foregroundColor(.red)
            Text("Score: \(score)")
              .font(.custom("Worktalk", size: 48))
              .foregroundColor(.white)
          }
        }
        Button(action: onReplay) {
          Text("Replay")
            .font(.custom("Worktalk", size: 48))
            .fontWeight(.semibold)
            .padding(.horizontal, 32)
            .padding(.vertical, 12)
            .foregroundColor(.white)
            .cornerRadius(10)
        }

        Button(action: onMenu) {
          Text("Menu")
            .font(.custom("Worktalk", size: 48))
            .fontWeight(.semibold)
            .padding(.horizontal, 32)
            .padding(.vertical, 12)
            .foregroundColor(.white)
            .cornerRadius(10)
        }
      }
      .padding(40)
      .shadow(radius: 20)
      .frame(maxWidth: .infinity, maxHeight: .infinity)
    }
  }
}

// MARK: - Pause Overlay View
struct PauseOverlayView: View {
  let onResume: () -> Void
  let onMenu: () -> Void
  var body: some View {
    ZStack {
      Color.black.opacity(0.6).ignoresSafeArea()
      VStack(spacing: 32) {
        Text("Paused")
          .font(.custom("Worktalk", size: 48))
          .foregroundColor(.white)
          .padding(.bottom, 16)
        Button(action: onResume) {
          Text("Resume")
            .font(.custom("Worktalk", size: 36))
            .foregroundColor(.white)
            .padding(.horizontal, 40)
            .padding(.vertical, 12)
            .background(Color.green.opacity(0.8))
            .cornerRadius(12)
        }
        Button(action: onMenu) {
          Text("Menu")
            .font(.custom("Worktalk", size: 36))
            .foregroundColor(.white)
            .padding(.horizontal, 40)
            .padding(.vertical, 12)
            .background(Color.red.opacity(0.8))
            .cornerRadius(12)
        }
      }
    }
  }
}

// Helper for formatting time
private func timeString(from seconds: Int) -> String {
  let minutes = seconds / 60
  let secs = seconds % 60
  return String(format: "%02d:%02d", minutes, secs)
}

#Preview(traits: .landscapeRight) {
  GameView(dismissToRoot: {}).environmentObject(GameViewModel())
}
