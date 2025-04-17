import SwiftUI
import AppKit
import OrthoTimeTrackerCore

@main
struct OrthoTimeTrackerMacApp: App {
    // Initialize with the core package's managers
    @StateObject private var deviceManager = OTTDeviceManager()
    @StateObject private var menuBarManager = OTTMenuBarManager()
    
    // Configure app with defaults
    init() {
        // Initialize core framework
        OrthoTimeTrackerCore.configure()
        
        // Set the accent color
        NSApplication.shared.appearance = NSAppearance(named: .aqua)
    }
    
    var body: some Scene {
        WindowGroup(id: "main", content: {
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
            // Always show the timer text in the menu bar
            if let device = menuBarManager.selectedDevice {
                // Show timer with device name and icon
                HStack(spacing: 4) {
                    Image(systemName: device.isRunning ? "timer.circle.fill" : "timer.circle")
                        .foregroundColor(device.isRunning ? OrthoTimeTrackerCore.accentColor : nil)
                    Text(device.name + ": " + menuBarManager.timerText)
                        .font(.system(.body, design: .monospaced))
                        .foregroundColor(device.isRunning ? OrthoTimeTrackerCore.accentColor : nil)
                }
            } else {
                // No device selected
                Label("OrthoTimer", systemImage: "timer.circle")
            }
        }
        .menuBarExtraStyle(.window)
    }
}