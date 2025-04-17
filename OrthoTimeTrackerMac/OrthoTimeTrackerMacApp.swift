import SwiftUI
import AppKit
import OrthoTimeTrackerCore

@main
struct OrthoTimeTrackerMacApp: App {
    @StateObject private var deviceManager = OTTDeviceManager()
    @StateObject private var menuBarManager = OTTMenuBarManager()
    
    init() {
        // Set the accent color
        NSApplication.shared.appearance = NSAppearance(named: .aqua)
    }
    
    var body: some Scene {
        WindowGroup("OrthoTimeTracker") {
            ContentView()
                .environmentObject(deviceManager)
                .environmentObject(menuBarManager)
                .frame(minWidth: 600, minHeight: 400)
                .accentColor(OrthoTimeTrackerCore.accentColor)
        }
        .windowStyle(HiddenTitleBarWindowStyle())
        .commands {
            SidebarCommands()
        }
        
        // Add a menu bar extra for the app
        MenuBarExtra {
            MenuBarView()
                .environmentObject(deviceManager)
                .environmentObject(menuBarManager)
                .accentColor(OrthoTimeTrackerCore.accentColor)
        } label: {
            if let device = menuBarManager.selectedDevice, device.isRunning {
                Label(menuBarManager.timerText, systemImage: "timer.circle.fill")
            } else {
                Label("OrthoTimer", systemImage: "timer.circle")
            }
        }
        .menuBarExtraStyle(.window)
    }
}