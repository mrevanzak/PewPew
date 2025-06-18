//
//  CameraView.swift
//  vision-test
//
//  Camera view that displays live video feed from device camera with hand detection overlay
//

import AVFoundation
import SwiftUI
import UIKit

/// UIViewRepresentable wrapper for camera preview with hand detection overlay
/// Provides live camera feed display and hand tracking visualization for iOS
struct CameraView: UIViewRepresentable {
  let cameraManager: CameraManager

  func makeUIView(context: Context) -> CameraPreviewView {
    let view = CameraPreviewView()

    // Get preview layer from camera manager
    let previewLayer = cameraManager.getPreviewLayer()
    view.setPreviewLayer(previewLayer)

    return view
  }

  func updateUIView(_ uiView: CameraPreviewView, context: Context) {
  }
}

/// Custom UIView that combines camera preview with hand detection overlay
class CameraPreviewView: UIView {
  private var previewLayer: AVCaptureVideoPreviewLayer?
  private var overlayLayer = CAShapeLayer()

  override init(frame: CGRect) {
    super.init(frame: frame)
    setupOverlay()
    setupOrientationObserver()
  }

  required init?(coder: NSCoder) {
    super.init(coder: coder)
    setupOverlay()
    setupOrientationObserver()
  }

  deinit {
    NotificationCenter.default.removeObserver(self)
  }

  func setPreviewLayer(_ layer: AVCaptureVideoPreviewLayer) {
    previewLayer = layer
    layer.frame = bounds
    self.layer.addSublayer(layer)

    // Add overlay on top of preview layer
    layer.addSublayer(overlayLayer)
  }

  override func layoutSubviews() {
    super.layoutSubviews()
    previewLayer?.frame = bounds
    overlayLayer.frame = bounds
  }

  private func setupOverlay() {
    overlayLayer.strokeColor = UIColor.red.cgColor
    overlayLayer.fillColor = UIColor.blue.cgColor
    overlayLayer.lineWidth = 8
    overlayLayer.lineJoin = .round
  }

  private func setupOrientationObserver() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(orientationChanged),
      name: UIDevice.orientationDidChangeNotification,
      object: nil
    )
  }

  @objc private func orientationChanged() {
    // Force layout update when orientation changes
    DispatchQueue.main.async {
      self.setNeedsLayout()
      self.layoutIfNeeded()
    }
  }

}
