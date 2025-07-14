//
//  CameraManager.swift
//  pewpew
//
//  Manages camera session and video output for hand detection
//

import AVFoundation
import Combine
import Foundation
import UIKit
import Vision

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

  // Orientation manager for handling device rotation
  private let orientationManager = OrientationManager.shared

  // Published properties for UI updates
  @Published var isSessionRunning = false
  @Published var permissionGranted = false

  init(handDetectionService: HandDetectionService) {
    self.handDetectionService = handDetectionService
    super.init()

    // Check camera permission
    checkPermission()

    // Setup camera session
    setupSession()
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

    // Add camera input
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

    // Configure video output
    videoOutput.setSampleBufferDelegate(self, queue: videoQueue)
    videoOutput.videoSettings = [
      kCVPixelBufferPixelFormatTypeKey as String: kCVPixelFormatType_32BGRA
    ]

    if session.canAddOutput(videoOutput) {
      session.addOutput(videoOutput)
    }

    // Set initial video orientation based on current device orientation
    applyCurrentOrientation()

    // Set session quality
    session.sessionPreset = .high

    session.commitConfiguration()
  }

  /// Apply current orientation to video output connection
  private func applyCurrentOrientation() {
    guard let connection = videoOutput.connection(with: .video) else { return }
    orientationManager.applyRotation(to: connection)
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

  deinit {
    // Orientation management is handled by OrientationManager.shared
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
