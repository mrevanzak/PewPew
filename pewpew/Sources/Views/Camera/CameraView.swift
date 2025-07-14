//
//  CameraView.swift
//  pewpew
//
//  Camera view that displays live video feed from device camera
//

import AVFoundation
import SwiftUI
import UIKit

/// UIViewRepresentable wrapper for AVCaptureVideoPreviewLayer
/// Provides live camera feed display in SwiftUI for iOS
struct CameraView: UIViewRepresentable {
  let session: AVCaptureSession

  func makeUIView(context: Context) -> UIView {
    let view = CameraPreviewView()
    view.setupPreviewLayer(session: session)
    return view
  }

  func updateUIView(_ uiView: UIView, context: Context) {
    // Update preview layer frame if view bounds change
    if let cameraView = uiView as? CameraPreviewView {
      cameraView.updateFrame()
    }
  }
}

/// Custom UIView that manages AVCaptureVideoPreviewLayer with orientation support
class CameraPreviewView: UIView {
  private var previewLayer: AVCaptureVideoPreviewLayer?
  private let orientationManager = OrientationManager.shared

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupOrientationObserver()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupOrientationObserver()
  }

  func setupPreviewLayer(session: AVCaptureSession) {
    // Create preview layer for camera feed
    let previewLayer = AVCaptureVideoPreviewLayer(session: session)
    previewLayer.videoGravity = .resizeAspect
    layer.addSublayer(previewLayer)
    self.previewLayer = previewLayer

    // Set initial orientation
    applyCurrentOrientation()
  }

  func updateFrame() {
    DispatchQueue.main.async { [weak self] in
      guard let self = self, let previewLayer = self.previewLayer else { return }
      previewLayer.frame = self.bounds
    }
  }

  private func setupOrientationObserver() {
    // Observe orientation changes from OrientationManager
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(orientationChanged),
      name: UIDevice.orientationDidChangeNotification,
      object: nil
    )
  }

  @objc private func orientationChanged() {
    applyCurrentOrientation()
  }

  private func applyCurrentOrientation() {
    guard let connection = previewLayer?.connection else { return }
    orientationManager.applyRotation(to: connection)
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    updateFrame()
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
    // OrientationManager handles its own lifecycle management
  }
}
