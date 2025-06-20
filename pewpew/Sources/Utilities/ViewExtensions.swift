//
//  ViewExtensions.swift
//  pewpew
//
//  SwiftUI View extensions for enhanced functionality
//

import SwiftUI
import UIKit

extension View {
  /// Force orientation change for the current view
  func forceOrientation(_ orientation: UIInterfaceOrientation) -> some View {
    onAppear {
      UIDevice.current.setValue(orientation.rawValue, forKey: "orientation")
    }
  }
}

// MARK: - View Extensions

extension View {
  /// Adds a blur effect with the specified radius
  /// - Parameter radius: The blur radius to apply
  /// - Returns: A view with blur effect applied
  func blur(_ radius: CGFloat) -> some View {
    self.blur(radius: radius)
  }

  /// Applies a glow effect with specified color and radius
  /// - Parameters:
  ///   - color: The glow color
  ///   - radius: The glow radius
  /// - Returns: A view with glow effect applied
  func glow(color: Color = .white, radius: CGFloat = 20) -> some View {
    self
      .shadow(color: color, radius: radius / 3)
      .shadow(color: color, radius: radius / 3)
      .shadow(color: color, radius: radius / 3)
  }
}
