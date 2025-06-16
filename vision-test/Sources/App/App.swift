import SwiftUI

@main
struct VisionTestApp: App {
  @UIApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
  
  var body: some Scene {
    WindowGroup {
      GameView()
    }
  }
}
