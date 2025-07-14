//
//  OrientationManager.swift
//  pewpew
//
//  Utility class for handling device orientation changes and video rotation
//

import AVFoundation
import Combine
import Foundation
import UIKit

/// Manages device orientation changes and provides rotation angles for video connections
class OrientationManager: ObservableObject {

  /// Current rotation angle based on device orientation
  @Published private(set) var currentRotationAngle: CGFloat = 0

  /// Shared instance for app-wide orientation management
  static let shared = OrientationManager()

  private init() {
    setupOrientationMonitoring()
    updateRotationAngle()
  }

  /// Setup device orientation monitoring
  private func setupOrientationMonitoring() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(orientationChanged),
      name: UIDevice.orientationDidChangeNotification,
      object: nil
    )

    // Start device orientation monitoring
    UIDevice.current.beginGeneratingDeviceOrientationNotifications()
  }

  /// Handle orientation change notification
  @objc private func orientationChanged() {
    updateRotationAngle()
  }

  /// Update rotation angle based on current device orientation
  private func updateRotationAngle() {
    let deviceOrientation = UIDevice.current.orientation

    switch deviceOrientation {
    case .landscapeLeft:
      currentRotationAngle = 180
    case .landscapeRight:
      currentRotationAngle = 0
    default:
      currentRotationAngle = 0  // Default rotation for other orientations
    }
  }

  /// Apply rotation angle to video connection if supported
  /// - Parameter connection: AVCaptureConnection to update
  func applyRotation(to connection: AVCaptureConnection) {
    if connection.isVideoRotationAngleSupported(currentRotationAngle) {
      connection.videoRotationAngle = currentRotationAngle
    }
  }

  /// Get current rotation angle for manual application
  /// - Returns: Current rotation angle in degrees
  func getCurrentRotationAngle() -> CGFloat {
    return currentRotationAngle
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
    UIDevice.current.endGeneratingDeviceOrientationNotifications()
  }
}
