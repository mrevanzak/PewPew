//
//  StatusOverlay.swift
//  pewpew
//
//  Reusable status overlay for displaying hand detection information
//

import SwiftUI

// MARK: - Status Overlay View
struct StatusOverlayView: View {
  @ObservedObject var viewModel: GameViewModel

  var body: some View {
    VStack {
      HStack {
        StatusInfoCard(handDetectionService: viewModel.handDetectionService)
        Spacer()
        ScoreCard(score: viewModel.score)
      }
      .padding()

      Spacer()
    }
  }
}
