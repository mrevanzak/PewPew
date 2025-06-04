//
//  ContentView.swift
//  vision-test
//
//  Main view that combines camera feed, hand detection, and collision detection
//

import SwiftUI

struct ContentView: View {
  var body: some View {
    ZStack {
      // Placeholder background
      Color.black.ignoresSafeArea()

      VStack {
        Text("Hand Detection App")
          .font(.title)
          .foregroundColor(.white)

        Text("Setting up camera and hand detection...")
          .font(.caption)
          .foregroundColor(.gray)
          .padding(.top, 20)
      }
    }
  }
}

#Preview {
  ContentView()
}
