//
//  StatusOverlay.swift
//  vision-test
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
        // Hand detection status
        DebugCard(handDetectionService: viewModel.handDetectionService)

        Spacer()

        // Game state info
        HStack(spacing: 12) {
          HealthCard(
            health: viewModel.gameState.health,
            maxHealth: viewModel.gameState.maxHealth
          )

          ScoreCard(score: viewModel.gameState.score)
        }
      }
      .padding()

      Spacer()
    }.safeAreaPadding(.top)
  }
}

// MARK: - Status Info Card
struct DebugCard: View {
  @ObservedObject var handDetectionService: HandDetectionService

  var body: some View {
    Card(alignment: .leading) {
      HStack {
        Circle()
          .fill(handDetectionService.handDetectionData.isDetected ? .green : .red)
          .frame(width: 8, height: 8)
        Text("Hand Detected")
          .font(.caption)
          .fontWeight(.medium)
      }

      Text("Hands: \(handDetectionService.handDetectionData.hands.count)")
        .font(.caption2)
        .foregroundColor(.secondary)

      Text(
        "Confidence: \(String(format: "%.2f", handDetectionService.handDetectionData.confidence))"
      )
      .font(.caption2)
      .foregroundColor(.secondary)
    }
  }
}

// MARK: - Score Card
struct ScoreCard: View {
  let score: Int

  var body: some View {
    Card {
      Text("SCORE")
        .font(.caption2)
        .fontWeight(.semibold)
        .foregroundColor(.secondary)

      Text("\(score)")
        .font(.title)
        .fontWeight(.bold)
        .foregroundColor(.primary)
    }
  }
}

// MARK: - Health Card
struct HealthCard: View {
  let health: Int
  let maxHealth: Int

  var body: some View {
    Card {
      Text("HEALTH")
        .font(.caption2)
        .fontWeight(.semibold)
        .foregroundColor(.secondary)

      HStack(spacing: 4) {
        ForEach(0..<maxHealth, id: \.self) { index in
          Image(systemName: index < health ? "heart.fill" : "heart")
            .foregroundColor(index < health ? .red : .gray)
            .font(.title2)
        }
      }
    }
  }
}
