import Foundation
import UIKit

/// Manages game scoring and bullet system
final class ScoreManager: ScoreManaging, ObservableObject {
  @Published private(set) var currentScore: Int = 0
  @Published private(set) var currentBullets: Int = GameConfiguration.Game.initialBullets

  private let maxBullets = GameConfiguration.Game.maxBullets
  private let hapticGenerator = UIImpactFeedbackGenerator(style: .medium)

  init() {
    hapticGenerator.prepare()
  }

  // MARK: - ScoreManaging Implementation

  func addScore(_ points: Int) {
    guard points > 0 else { return }

    currentScore += points
    hapticGenerator.impactOccurred()
  }

  func addBullets(_ count: Int) {
    guard count > 0 else { return }

    currentBullets = min(currentBullets + count, maxBullets)
    hapticGenerator.impactOccurred()
  }

  func useBullet() -> Bool {
    guard currentBullets > 0 else { return false }

    currentBullets -= 1
    return true
  }

  func resetScore() {
    currentScore = 0
    currentBullets = GameConfiguration.Game.initialBullets
  }

  // MARK: - Additional Helpers

  var isOutOfBullets: Bool {
    currentBullets <= 0
  }

  var bulletPercentage: Double {
    Double(currentBullets) / Double(maxBullets)
  }
}
