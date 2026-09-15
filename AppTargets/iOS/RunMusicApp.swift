import SwiftUI
import RunMusicAppUI

@main
struct RunMusicApp: App {
    @UIApplicationDelegateAdaptor(RunMusicAppDelegate.self) private var appDelegate

    var body: some Scene {
        WindowGroup {
            RunMusicRootView()
        }
    }
}
