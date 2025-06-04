//
//  HandDetectionContentView.swift
//  vision-test
//
//  Complete implementation of hand detection app with collision detection
//

import SwiftUI

struct HandDetectionContentView: View {
  // Hand detection service and camera manager
  @StateObject private var handDetectionService = HandDetectionService()
  @StateObject private var cameraManager: CameraManager

  // Shape visibility state
  @State private var isShapeVisible = true
  @State private var viewSize: CGSize = .zero

  // Shape properties
  private let shapeSize: CGFloat = 100
  private let shapeColor = Color.blue.opacity(0.7)

  // Initialize camera manager with hand detection service
  init() {
    let handService = HandDetectionService()
    _handDetectionService = StateObject(wrappedValue: handService)
    _cameraManager = StateObject(wrappedValue: CameraManager(handDetectionService: handService))
  }

  var body: some View {
    GeometryReader { geometry in
      ZStack {
        // Camera feed background
        if cameraManager.permissionGranted {
          CameraView(session: cameraManager.session)
            .onAppear {
              cameraManager.startSession()
            }
            .onDisappear {
              cameraManager.stopSession()
            }
        } else {
          // Permission denied or not granted
          VStack {
            Text("Camera Permission Required")
              .font(.title2)
              .foregroundColor(.white)
            Text("Please enable camera access in System Preferences")
              .font(.caption)
              .foregroundColor(.gray)
              .multilineTextAlignment(.center)
          }
          .frame(maxWidth: .infinity, maxHeight: .infinity)
          .background(Color.black)
        }

        // Overlay shape (circle in center of screen)
        if isShapeVisible {
          Circle()
            .fill(shapeColor)
            .frame(width: shapeSize, height: shapeSize)
            .position(
              x: geometry.size.width / 2,
              y: geometry.size.height / 2
            )
            .animation(.easeInOut(duration: 0.3), value: isShapeVisible)
        }

        // Debug overlay showing hand bounding boxes (optional)
        if handDetectionService.isHandDetected {
          ForEach(0..<handDetectionService.handBoundingBoxes.count, id: \.self) { index in
            let normalizedBox = handDetectionService.handBoundingBoxes[index]
            let viewBox = handDetectionService.convertToViewCoordinates(
              normalizedBox,
              viewSize: geometry.size
            )

            Rectangle()
              .stroke(Color.red, lineWidth: 2)
              .frame(width: viewBox.width, height: viewBox.height)
              .position(
                x: viewBox.midX,
                y: viewBox.midY
              )
          }
        }
      }
      .onAppear {
        viewSize = geometry.size
      }
      .onChange(of: geometry.size) { newSize in
        viewSize = newSize
      }
    }
    .ignoresSafeArea()
    // Status overlay that respects safe area
    .safeAreaInset(edge: .top, alignment: .leading) {
      HStack {
        VStack(alignment: .leading, spacing: 5) {
          Text("Hand Detected: \(handDetectionService.isHandDetected ? "Yes" : "No")")
          Text("Shape Visible: \(isShapeVisible ? "Yes" : "No")")
          Text("Hands Count: \(handDetectionService.handBoundingBoxes.count)")
        }
        .font(.caption)
        .foregroundColor(.white)
        .padding(8)
        .background(Color.black.opacity(0.6))
        .cornerRadius(8)

        Spacer()
      }
      .padding()
      .background(Color.clear)
    }
    // Monitor hand detection for collision
    .onChange(of: handDetectionService.handBoundingBoxes) { _ in
      checkCollision()
    }
  }

  /// Check for collision between hands and the overlay shape
  private func checkCollision() {
    guard isShapeVisible && handDetectionService.isHandDetected && viewSize != .zero else { return }

    // Convert hand bounding boxes to view coordinates
    let handBoxesInViewCoords = handDetectionService.handBoundingBoxes.map { normalizedBox in
      handDetectionService.convertToViewCoordinates(normalizedBox, viewSize: viewSize)
    }

    // Calculate shape frame (circle in center)
    let shapeFrame = CGRect(
      x: viewSize.width / 2 - shapeSize / 2,
      y: viewSize.height / 2 - shapeSize / 2,
      width: shapeSize,
      height: shapeSize
    )

    // Check for collision
    if CollisionDetection.isHandCollidingWithShape(
      handBoxes: handBoxesInViewCoords,
      shapeFrame: shapeFrame
    ) {
      // Hide the shape when collision is detected
      withAnimation(.easeOut(duration: 0.5)) {
        isShapeVisible = false
      }

      // Reset shape after 2 seconds for testing
      DispatchQueue.main.asyncAfter(deadline: .now() + 2.0) {
        withAnimation(.easeIn(duration: 0.3)) {
          isShapeVisible = true
        }
      }
    }
  }
}

#Preview {
  HandDetectionContentView()
}
