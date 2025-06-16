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
    @ObservedObject var handDetectionService: HandDetectionService

    func makeUIView(context: Context) -> CameraPreviewView {
        let view = CameraPreviewView()
        
        // Get preview layer from camera manager
        let previewLayer = cameraManager.getPreviewLayer()
        view.setPreviewLayer(previewLayer)
        
        return view
    }

    func updateUIView(_ uiView: CameraPreviewView, context: Context) {
        // Update hand detection overlay
        uiView.updateHandPoints(handDetectionService.handDetectionData.hands)
    }
}

/// Custom UIView that combines camera preview with hand detection overlay
class CameraPreviewView: UIView {
    private var previewLayer: AVCaptureVideoPreviewLayer?
    private var overlayLayer = CAShapeLayer()
    private var pointsPath = UIBezierPath()

    override init(frame: CGRect) {
        super.init(frame: frame)
        setupOverlay()
    }
    
    required init?(coder: NSCoder) {
        super.init(coder: coder)
        setupOverlay()
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
    
    /// Update hand points overlay with enhanced visualization
    func updateHandPoints(_ hands: [HandPoints]) {
        pointsPath.removeAllPoints()
        
        for hand in hands {
            // Draw wrist
            pointsPath.move(to: hand.wrist)
            pointsPath.addArc(withCenter: hand.wrist, radius: 5, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
            
            // Draw thumb with connections
            pointsPath.move(to: hand.wrist)
            hand.thumb.forEach { point in
                pointsPath.addLine(to: point)
                pointsPath.addArc(withCenter: point, radius: 5, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
                pointsPath.move(to: point)
            }
            
            // Draw index finger with connections
            pointsPath.move(to: hand.wrist)
            hand.index.forEach { point in
                pointsPath.addLine(to: point)
                pointsPath.addArc(withCenter: point, radius: 5, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
                pointsPath.move(to: point)
            }
            
            // Draw middle finger with connections
            pointsPath.move(to: hand.wrist)
            hand.middle.forEach { point in
                pointsPath.addLine(to: point)
                pointsPath.addArc(withCenter: point, radius: 5, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
                pointsPath.move(to: point)
            }
            
            // Draw ring finger with connections
            pointsPath.move(to: hand.wrist)
            hand.ring.forEach { point in
                pointsPath.addLine(to: point)
                pointsPath.addArc(withCenter: point, radius: 5, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
                pointsPath.move(to: point)
            }
            
            // Draw little finger with connections
            pointsPath.move(to: hand.wrist)
            hand.little.forEach { point in
                pointsPath.addLine(to: point)
                pointsPath.addArc(withCenter: point, radius: 5, startAngle: 0, endAngle: 2 * .pi, clockwise: true)
                pointsPath.move(to: point)
            }
        }
        
        // Update overlay layer with smooth animation
        CATransaction.begin()
        CATransaction.setDisableActions(true)
        overlayLayer.path = pointsPath.cgPath
        CATransaction.commit()
    }
}
