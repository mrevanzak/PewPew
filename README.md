# Hand Detection iOS App

A simple iOS app built with SwiftUI, AVFoundation, and Vision framework that demonstrates real-time hand detection and collision detection with virtual objects.

## Features

- **Live Camera Feed**: Real-time camera preview using AVFoundation
- **Hand Detection**: Uses Vision framework to detect and track hands
- **Collision Detection**: Detects when a hand intersects with a virtual shape
- **Interactive Shape**: Blue circle that disappears when touched by a hand
- **Debug Visualization**: Red bounding boxes show detected hand positions
- **Real-time Status**: Live status display showing detection state

## Architecture

The app follows a modular, clean architecture with the following components:

### Core Components

1. **`CameraView.swift`** - SwiftUI wrapper for camera feed display
2. **`CameraManager.swift`** - Manages camera session, permissions, and video output
3. **`HandDetectionService.swift`** - Vision framework integration for hand detection
4. **`CollisionDetection.swift`** - Utility for detecting shape-hand collisions
5. **`HandDetectionContentView.swift`** - Main UI that integrates all components
6. **`ContentView.swift`** - Basic placeholder view

### Key Features Implementation

#### Camera Feed

- Uses `AVCaptureSession` with front-facing camera
- Handles camera permissions automatically
- Processes video frames at 30 FPS

#### Hand Detection

- Utilizes `VNDetectHumanHandPoseRequest` from Vision framework
- Extracts hand landmarks and calculates bounding boxes
- Supports detection of up to 2 hands simultaneously
- Confidence threshold filtering for accurate detection

#### Collision Detection

- Converts normalized Vision coordinates to view coordinates
- Implements rectangle intersection algorithms
- Provides overlap percentage calculations
- Real-time collision monitoring

## Setup Instructions

### 1. Xcode Project Configuration

1. Open the project in Xcode
2. Add the `Info.plist` file to your project target
3. Ensure all Swift files are added to the project target
4. Set deployment target to iOS 14.0 or later

### 2. Update App Entry Point

Replace the content in `vision_testApp.swift` with:

```swift
import SwiftUI

@main
struct vision_testApp: App {
    var body: some Scene {
        WindowGroup {
            HandDetectionContentView()
        }
    }
}
```

### 3. Build and Run

1. Select a physical iOS device (camera required)
2. Build and run the project
3. Grant camera permissions when prompted

## Usage

1. **Launch the app** - Camera feed should appear automatically
2. **Grant permissions** - Allow camera access when prompted
3. **Show your hand** - Hold your hand in front of the camera
4. **Test collision** - Move your hand to touch the blue circle
5. **Observe behavior** - Circle disappears when touched, reappears after 2 seconds

## Technical Details

### Frameworks Used

- **SwiftUI** - Modern UI framework
- **AVFoundation** - Camera capture and video processing
- **Vision** - Machine learning-based hand detection
- **Combine** - Reactive programming for state management

### Performance Considerations

- Video processing runs on background queue
- UI updates dispatched to main queue
- Efficient coordinate system conversions
- Optimized for real-time performance

### Coordinate System Handling

- Vision framework uses normalized coordinates (0-1)
- App converts to view coordinates for UI positioning
- Proper handling of different screen sizes and orientations

## Troubleshooting

### Common Issues

1. **Camera Permission Denied**

   - Go to System Preferences > Privacy & Security > Camera
   - Enable access for the app

2. **No Hand Detection**

   - Ensure good lighting conditions
   - Hold hand clearly visible to camera
   - Check if hand is within camera frame

3. **Build Errors**
   - Ensure all files are added to project target
   - Check deployment target is iOS 14.0+
   - Clean build folder and rebuild

### Debug Features

- Red rectangles show detected hand bounding boxes
- Status overlay shows detection state and hand count
- Console logging for debugging hand detection

## Future Enhancements

- Multiple shape types (squares, triangles)
- Gesture recognition (pinch, swipe)
- Sound effects for interactions
- Score system and game mechanics
- Multiple collision objects
- 3D object rendering with RealityKit

## Requirements

- Xcode 14.0+
- iOS 14.0+
- Physical device with camera
- macOS 12.0+ (for development)

---

This app serves as a foundation for AR/VR applications, gesture-based interfaces, and interactive media experiences.
