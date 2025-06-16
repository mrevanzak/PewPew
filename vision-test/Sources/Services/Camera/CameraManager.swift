//
//  CameraManager.swift
//  vision-test
//
//  Manages camera session and video output for hand detection
//

import AVFoundation
import Combine
import Foundation
import Vision
import UIKit

/// Manager class for camera session and video processing
/// Handles camera setup, permissions, and delegates video output for hand detection
class CameraManager: NSObject, ObservableObject {
  // Camera session for video capture
  let session = AVCaptureSession()

  // Video output for processing frames
  private let videoOutput = AVCaptureVideoDataOutput()

  // Queue for video processing
  private let videoQueue = DispatchQueue(label: "video.queue", qos: .userInteractive)

  // Hand detection service
  private let handDetectionService: HandDetectionService

  // Published properties for UI updates
  @Published var isSessionRunning = false
  @Published var permissionGranted = false
  
  // Preview layer for coordinate conversion
  private var previewLayer: AVCaptureVideoPreviewLayer?
  
  // Video connection for orientation handling
  private var videoConnection: AVCaptureConnection?

  init(handDetectionService: HandDetectionService) {
    self.handDetectionService = handDetectionService
    super.init()

    // Check camera permission
    checkPermission()

    // Setup camera session
    setupSession()
    
    // Setup orientation observers
    setupOrientationObservers()
  }
  
  deinit {
    NotificationCenter.default.removeObserver(self)
  }
  
  /// Get the preview layer for camera display
  func getPreviewLayer() -> AVCaptureVideoPreviewLayer {
    if previewLayer == nil {
      previewLayer = AVCaptureVideoPreviewLayer(session: session)
      previewLayer?.videoGravity = .resizeAspectFill
      // Provide preview layer to hand detection service for coordinate conversion
      handDetectionService.setPreviewLayer(previewLayer!)
    }
    return previewLayer!
  }

  /// Check and request camera permission
  private func checkPermission() {
    switch AVCaptureDevice.authorizationStatus(for: .video) {
    case .authorized:
      permissionGranted = true
    case .notDetermined:
      requestPermission()
    default:
      permissionGranted = false
    }
  }

  /// Request camera permission from user
  private func requestPermission() {
    AVCaptureDevice.requestAccess(for: .video) { [weak self] granted in
      DispatchQueue.main.async {
        self?.permissionGranted = granted
        if granted {
          self?.setupSession()
        }
      }
    }
  }

  /// Setup camera capture session
  private func setupSession() {
    guard permissionGranted else { return }

    session.beginConfiguration()

    // Add camera input (prefer front camera for hand detection)
    guard
      let device = AVCaptureDevice.default(.builtInWideAngleCamera, for: .video, position: .front),
      let input = try? AVCaptureDeviceInput(device: device)
    else {
      print("Failed to create camera input")
      session.commitConfiguration()
      return
    }

    if session.canAddInput(input) {
      session.addInput(input)
    }

    // Configure video output for hand detection
    videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
    videoOutput.alwaysDiscardsLateVideoFrames = true
    videoOutput.videoSettings = [
      kCVPixelBufferPixelFormatTypeKey as String: Int(kCVPixelFormatType_420YpCbCr8BiPlanarFullRange)
    ]

    if session.canAddOutput(videoOutput) {
      session.addOutput(videoOutput)
    }

    // Store video connection for orientation handling
    videoConnection = videoOutput.connection(with: .video)
    
    // Set initial orientation
    updateVideoOrientation()

    // Set session quality for better hand detection
    session.sessionPreset = .high

    session.commitConfiguration()
  }
  
  /// Setup device orientation observers
  private func setupOrientationObservers() {
    NotificationCenter.default.addObserver(
      self,
      selector: #selector(orientationChanged),
      name: UIDevice.orientationDidChangeNotification,
      object: nil
    )
  }
  
  /// Handle device orientation change
  @objc private func orientationChanged() {
    updateVideoOrientation()
  }
  
  /// Update video connection orientation based on device orientation
  private func updateVideoOrientation() {
    guard let videoConnection = videoConnection,
          videoConnection.isVideoOrientationSupported else { return }
    
    DispatchQueue.main.async {
      let deviceOrientation = UIDevice.current.orientation
      let videoOrientation: AVCaptureVideoOrientation
      
      // Only handle landscape orientations as per Info.plist configuration
      switch deviceOrientation {
      case .landscapeLeft:
        videoOrientation = .landscapeRight // Camera is mirrored for front camera
      case .landscapeRight:
        videoOrientation = .landscapeLeft // Camera is mirrored for front camera
      case .portrait, .portraitUpsideDown:
        // Device shouldn't rotate to portrait due to Info.plist, but handle gracefully
        // Default to current orientation or landscape right
        videoOrientation = self.videoConnection?.videoOrientation ?? .landscapeRight
      default:
        // Handle unknown/face up/face down orientations
        videoOrientation = .landscapeRight // Default to landscape right
      }
      
      videoConnection.videoOrientation = videoOrientation
      
      // Also update preview layer orientation
      if let previewLayer = self.previewLayer {
        previewLayer.connection?.videoOrientation = videoOrientation
      }
      
      // Notify hand detection service of orientation change
      self.handDetectionService.updateOrientation(videoOrientation)
    }
  }

  /// Start camera session
  func startSession() {
    guard permissionGranted && !session.isRunning else { return }

    videoQueue.async { [weak self] in
      self?.session.startRunning()

      DispatchQueue.main.async {
        self?.isSessionRunning = true
      }
    }
  }

  /// Stop camera session
  func stopSession() {
    guard session.isRunning else { return }

    videoQueue.async { [weak self] in
      self?.session.stopRunning()

      DispatchQueue.main.async {
        self?.isSessionRunning = false
      }
    }
  }
}

// MARK: - AVCaptureVideoDataOutputSampleBufferDelegate
extension CameraManager: AVCaptureVideoDataOutputSampleBufferDelegate {
  func captureOutput(
    _ output: AVCaptureOutput, didOutput sampleBuffer: CMSampleBuffer,
    from connection: AVCaptureConnection
  ) {
    // Process each frame for hand detection
    handDetectionService.processFrame(sampleBuffer)
  }
}
