//
//  ViewExtensions.swift
//  vision-test
//
//  SwiftUI View extensions for enhanced functionality
//

import SwiftUI
import UIKit

extension View {
    /// Configures supported interface orientations for the view
    func supportedOrientations(_ orientations: UIInterfaceOrientationMask) -> some View {
        onAppear {
            OrientationManager.shared.setOrientationLock(orientations)
        }
    }
    
    /// Force orientation change for the current view
    func forceOrientation(_ orientation: UIInterfaceOrientation) -> some View {
        onAppear {
            UIDevice.current.setValue(orientation.rawValue, forKey: "orientation")
        }
    }
}

/// Orientation management singleton
class OrientationManager: ObservableObject {
    static let shared = OrientationManager()
    
    @Published var orientationLock: UIInterfaceOrientationMask = .all
    
    private init() {}
    
    func setOrientationLock(_ mask: UIInterfaceOrientationMask) {
        orientationLock = mask
    }
}

/// App delegate for orientation handling
class AppDelegate: NSObject, UIApplicationDelegate {
    func application(_ application: UIApplication, supportedInterfaceOrientationsFor window: UIWindow?) -> UIInterfaceOrientationMask {
        return OrientationManager.shared.orientationLock
    }
} 