// MARK: - Game Configuration

import SwiftUI

enum GameConfiguration {

  // MARK: - UI Constants
  enum UI {
    static let handCircleSize: CGFloat = 70
    static let projectileRadius: CGFloat = 12
    static let screenMargin: CGFloat = 30
    static let labelPadding: CGFloat = 24
    static let labelFontSize: CGFloat = 24
    static let effectFontSize: CGFloat = 16
  }

  // MARK: - Physics Constants
  enum Physics {
    enum Category {
      static let player: UInt32 = 0x1 << 0
      static let target: UInt32 = 0x1 << 1
      static let projectile: UInt32 = 0x1 << 2
    }
  }

  // MARK: - Game Constants
  enum Game {
    static let maxBullets = 100
    static let initialBullets = 10
    static let targetScoreValue = 10
    static let bulletReward = 10
    static let projectileSpeed: CGFloat = 900.0
    static let handDetectionConfidenceThreshold: Float = 0.5
    static let handOpenThreshold: CGFloat = 0.10
  }

  // MARK: - Timing Constants
  enum Timing {
    static let minSpawnDelay: Double = 1.0
    static let maxSpawnDelay: Double = 4.0
    static let shapeVisibleDuration: Double = 3.0
    static let spawningInterval: Double = 1.0
    static let handAnimationDuration: Double = 0.1
    static let hideAnimationDuration: Double = 0.3
    static let showAnimationDuration: Double = 0.3
    static let effectAnimationDuration: Double = 1.0
    static let nextSpawnDelay: Double = 0.5
  }

  // MARK: - Target Configuration
  enum Target {
    static let minSize: CGFloat = 50
    static let maxSize: CGFloat = 70
    static let bulletTargetSpawnChance: Double = 0.2
    static let alienColors: [Color] = [.blue, .red, .green, .orange, .purple, .pink]
    static let minYPosition: CGFloat = 0.2  // 20% from bottom
    static let targetSpeed: ClosedRange<CGFloat> = 100...250
  }
}

// MARK: - Asset Names
enum AssetName {
  static let alien = "alien"
  static let alienCrash = "alienCrash"
  static let shootMark = "shootMark"
  static let crosshair = "crosshair"
}

// MARK: - Animation Configurations
enum AnimationConfig {
  static let scaleUpFactor: CGFloat = 1.2
  static let scaleUpDuration: Double = 0.1
  static let scaleDownDuration: Double = 0.1
  static let effectScaleFactor: CGFloat = 1.5
  static let effectScaleDuration: Double = 0.2
  static let effectFadeOutDuration: Double = 0.8
  static let effectMoveUpDistance: CGFloat = 50
}
