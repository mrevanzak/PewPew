import Foundation

/// Represents a playable character in the game
enum Character: String, CaseIterable, Identifiable {
  case sheriffBeq = "sherrifBeq"
  case deputyBur = "deputyBur"

  var id: String { rawValue }

  /// Display name for the character
  var displayName: String {
    switch self {
    case .sheriffBeq:
      return "SHERIFF BEQ"
    case .deputyBur:
      return "DEPUTY BUR"
    }
  }

  /// Asset name for character image
  var imageName: String {
    return rawValue
  }

  /// Character description
  var description: String {
    switch self {
    case .sheriffBeq:
      return "A sly gun that is by his side at all"
    case .deputyBur:
      return "A clumsy bear a work but he faster gun shoot"
    }
  }
}
