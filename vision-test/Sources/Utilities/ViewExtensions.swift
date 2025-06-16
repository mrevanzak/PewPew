//
//  ViewExtensions.swift
//  vision-test
//
//  SwiftUI View extensions for enhanced functionality
//

import SwiftUI
import UIKit

extension View {
    /// Force orientation change for the current view
    func forceOrientation(_ orientation: UIInterfaceOrientation) -> some View {
        onAppear {
            UIDevice.current.setValue(orientation.rawValue, forKey: "orientation")
        }
    }
} 