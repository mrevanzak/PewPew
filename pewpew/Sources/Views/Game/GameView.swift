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
  @State private var showMenu = false

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        if showMenu {
          MenuView()
        } else {
          // Camera background
          CameraBackgroundView(viewModel: viewModel)

          // Game scene
          SpriteView(viewModel: viewModel)

          // Character at center bottom
          CharacterView(
            character: viewModel.selectedCharacter,
            screenSize: geometry.size,
          )

          // Game over overlay
          if viewModel.isGameOver {
            GameOverOverlayView(score: viewModel.score, onReplay: {
              viewModel.replayGame()
            }, onMenu: {
              showMenu = true
            })
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
      .onChange(of: geometry.size) { _, newSize in
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

#Preview(traits: .landscapeRight) {
  GameOverOverlayView(score: 123, onReplay: { }, onMenu: { })
}
