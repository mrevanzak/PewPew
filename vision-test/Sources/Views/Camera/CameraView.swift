//
//  CameraView.swift
//  vision-test
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
    let view = UIView()

    // Create preview layer for camera feed
    let previewLayer = AVCaptureVideoPreviewLayer(session: session)
    previewLayer.videoGravity = .resizeAspectFill
    view.layer.addSublayer(previewLayer)

    if previewLayer.connection?.isVideoRotationAngleSupported(180) ?? false {
      previewLayer.connection?.videoRotationAngle = 180
    }

    return view
  }

  func updateUIView(_ uiView: UIView, context: Context) {
    // Update preview layer frame if view bounds change
    if let previewLayer = uiView.layer.sublayers?.first as? AVCaptureVideoPreviewLayer {
      DispatchQueue.main.async {
        previewLayer.frame = uiView.bounds
      }
    }
  }
}
