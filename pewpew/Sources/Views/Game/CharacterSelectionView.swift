import SwiftUI

/// Character selection view with western-themed design
struct CharacterSelectionView: View {
  @StateObject private var gameViewModel = GameViewModel()
  @State private var selectedCharacter: Character?
  @State private var showGame = false

  let dismissToRoot: () -> Void

  let screenWidth = UIScreen.main.bounds.size.width
  let screenHeight = UIScreen.main.bounds.size.height

  var body: some View {
    Image("bg")
      .resizable()
      .aspectRatio(contentMode: .fill)
      .ignoresSafeArea()
      .overlay(
        VStack {
          Image("logo")
            .resizable()
            .aspectRatio(contentMode: .fit)

          Text("Choose character")
            .font(.custom("Worktalk", size: 48))
            .foregroundColor(Color(red: 0.517, green: 0.333, blue: 0.191))
            .shadow(color: .brown.opacity(0.6), radius: 2, x: 2, y: 2)

          // Character Selection Buttons
          HStack(spacing: 60) {
            CharacterButton(
              character: .sheriffBeq,
              isSelected: selectedCharacter == .sheriffBeq
            ) {
              selectCharacter(.sheriffBeq)
            }

            CharacterButton(
              character: .deputyBur,
              isSelected: selectedCharacter == .deputyBur
            ) {
              selectCharacter(.deputyBur)
            }
          }

          // Start Button
          Button(action: startGame) {
            Image(systemName: "play.fill")
              .padding(.all, 28.0)
              .font(.system(size: 72))
              .foregroundColor(.white)
              .shadow(color: .brown.opacity(0.6), radius: 2, x: 2, y: 2)
              .background(
                Ellipse()
                  .fill(
                    selectedCharacter == nil
                      ? Color(red: 1.0, green: 0.846, blue: 0.613)
                      : Color(red: 0.517, green: 0.333, blue: 0.191)
                  )
                  .shadow(color: .black.opacity(0.3), radius: 3, x: 2, y: 2)
              )
          }
          .disabled(selectedCharacter == nil)
          .transition(.scale.combined(with: .opacity))
          .animation(.easeInOut(duration: 0.3), value: selectedCharacter)

          Spacer()
        }
        .frame(maxWidth: .infinity, maxHeight: screenHeight * 0.9)
      )
      .fullScreenCover(isPresented: $showGame) {
        GameView(dismissToRoot: dismissToRoot)
          .environmentObject(gameViewModel)
      }
  }

  private func selectCharacter(_ character: Character) {
    withAnimation(.easeInOut(duration: 0.2)) {
      selectedCharacter = character
      gameViewModel.selectCharacter(character)
    }
  }

  private func startGame() {
    withAnimation(.easeInOut(duration: 0.1)) {
      showGame = true
    }
  }
}

/// Individual character selection button
struct CharacterButton: View {
  let character: Character
  let isSelected: Bool
  let action: () -> Void

  var height = UIScreen.main.bounds.size.height * 0.45

  var body: some View {
    Button(action: action) {
      VStack(spacing: 8) {
        // Character Image
        Image(character.imageName)
          .resizable()
          .aspectRatio(contentMode: .fit)
          .frame(height: height)
          .overlay(
            RoundedRectangle(cornerRadius: 0.15 * height)
              .stroke(
                isSelected ? Color.yellow : Color(red: 0.545, green: 0.271, blue: 0.075),
                lineWidth: isSelected ? 4 : 2
              )
          )
          .scaleEffect(isSelected ? 1.05 : 1.0)
      }
    }
    .animation(.easeInOut(duration: 0.2), value: isSelected)
  }
}

#Preview(traits: .landscapeRight) {
  CharacterSelectionView(dismissToRoot: {})
}
