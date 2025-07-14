import SwiftUI

/// Main menu view with cowboy-themed design matching the provided image
struct MenuView: View {
  @State private var showCharacterSelection = false

  var body: some View {
    Image("menu")
      .resizable()
      .aspectRatio(contentMode: .fill)
      .ignoresSafeArea()
      .overlay(
        ZStack {
          Image("menuBoard")
            .resizable()
            .aspectRatio(contentMode: .fit)
            .frame(height: 360)

          Button(action: {
            withAnimation(.easeInOut(duration: 0.1)) {
              showCharacterSelection = true
            }
          }) {
            // START text overlay
            Text("START")
              .font(.custom("Worktalk", size: 80))
              .foregroundColor(Color(red: 1.001, green: 0.846, blue: 0.613))  // Cream color
              .shadow(color: .brown.opacity(0.5), radius: 1, x: 1, y: 1)
              .offset(x: 0, y: 40)
          }
        }
        .frame(maxWidth: .infinity, maxHeight: .infinity, alignment: .bottom)
        .padding(.bottom, 64)
      )
      .fullScreenCover(isPresented: $showCharacterSelection) {
        CharacterSelectionView(dismissToRoot: {
          showCharacterSelection = false
        })
      }
  }
}

#Preview(traits: .landscapeRight) {
  MenuView()
}
