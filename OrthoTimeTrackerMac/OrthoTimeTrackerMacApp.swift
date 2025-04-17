import SwiftUI
import AppKit
import OrthoTimeTrackerCore
import Combine

// Utility function to check if window is a status bar window
private func isStatusBarWindow(_ window: NSWindow) -> Bool {
    let windowClass = String(describing: type(of: window))
    return windowClass.contains("StatusBar") || windowClass.contains("Popover")
}

// Application state shared between main app and menu bar
final class AppDelegate: NSObject, NSApplicationDelegate {
    // Create shared managers that are accessible from everywhere
    let deviceManager = OTTDeviceManager()
    let menuBarManager = OTTMenuBarManager()
    private var timer: Timer?
    
    // Store a reference to the main window controller
    var mainWindowController: NSWindowController?
    
    override init() {
        super.init()
        
        // Initialize core framework
        OrthoTimeTrackerCore.configure()
        
        // Connect the managers
        menuBarManager.setDeviceManager(deviceManager)
        
        // Create an extra global timer to ensure UI updates
        // This helps keep everything in sync
        Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.deviceManager.objectWillChange.send()
                self?.menuBarManager.objectWillChange.send()
            }
        }
    }
    
    func applicationDidFinishLaunching(_ notification: Notification) {
        // Setup a timer to force updates (menu bar sometimes doesn't update otherwise)
        timer = Timer.scheduledTimer(withTimeInterval: 0.5, repeats: true) { [weak self] _ in
            DispatchQueue.main.async {
                self?.menuBarManager.updateTimerText()
            }
        }
        
        if let timer = timer {
            RunLoop.main.add(timer, forMode: .common)
        }
        
        // Listen for menu bar actions
        NotificationCenter.default.addObserver(
            self,
            selector: #selector(openMainWindow),
            name: NSNotification.Name("OpenMainWindow"),
            object: nil
        )
    }
    
    @objc func openMainWindow() {
        // First activate the app
        NSApp.activate(ignoringOtherApps: true)
        
        // If we have a stored window controller, use it directly
        if let controller = mainWindowController {
            controller.showWindow(nil)
            if let window = controller.window {
                window.makeKeyAndOrderFront(nil)
                return
            }
        }
        
        // Otherwise try to find an existing window
        let regularWindows = NSApp.windows.filter { !isStatusBarWindow($0) }
        
        if let window = regularWindows.first(where: { $0.isVisible }) {
            // Bring visible window to front
            window.makeKeyAndOrderFront(nil)
        } else if let window = regularWindows.first(where: { $0.isMiniaturized }) {
            // Restore minimized window
            window.deminiaturize(nil)
        } else {
            // Create a new window by opening a URL scheme
            if let url = URL(string: "orthotimetracker://openMainWindow") {
                NSWorkspace.shared.open(url)
            } else {
                // Fallback to opening the app bundle
                NSWorkspace.shared.open(Bundle.main.bundleURL)
            }
        }
    }
    
    func applicationWillTerminate(_ notification: Notification) {
        timer?.invalidate()
    }
}

// Menu bar label that shows the timer
struct MenuBarLabel: View {
    @ObservedObject var deviceManager: OTTDeviceManager
    @ObservedObject var menuBarManager: OTTMenuBarManager
    
    var body: some View {
        // Create a view that observes the device manager's timestamp
        // This ensures the menu bar label updates in sync with the main app
        let _ = deviceManager.currentTimestamp
        
        if let device = menuBarManager.selectedDevice {
            HStack(spacing: 4) {
                Image(systemName: "timer.circle")
                    .foregroundColor(device.isRunning ? Color.green : nil)
                
                // Always get the freshest time
                Text(menuBarManager.currentTimeForSelectedDevice())
                    .font(.system(.body, design: .monospaced))
                    .fontWeight(device.isRunning ? .bold : .regular)
                    .foregroundColor(device.isRunning ? Color.green : nil)
            }
            .onAppear {
                // Force an update on appear
                menuBarManager.updateTimerText()
            }
        } else {
            Label("OrthoTimer", systemImage: "timer.circle")
        }
    }
}

@main
struct OrthoTimeTrackerMacApp: App {
    @NSApplicationDelegateAdaptor(AppDelegate.self) var appDelegate
    @State private var showMainWindow = false
    
    var body: some Scene {
        WindowGroup("OrthoTimeTracker") {
            ContentView()
                .environmentObject(appDelegate.deviceManager)
                .environmentObject(appDelegate.menuBarManager)
                .frame(minWidth: 600, minHeight: 400)
                .accentColor(OrthoTimeTrackerCore.accentColor)
                .onAppear {
                    // On first appearance, store a reference to the window
                    DispatchQueue.main.async {
                        if let window = NSApp.windows.first(where: { !isStatusBarWindow($0) }),
                            let controller = window.windowController {
                            appDelegate.mainWindowController = controller
                        }
                    }
                }
        }
        .handlesExternalEvents(matching: Set(arrayLiteral: "openMainWindow"))
        .commands {
            SidebarCommands()
            
            // Add a New Window command
            CommandGroup(after: .newItem) {
                Button("New OrthoTimeTracker Window") {
                    appDelegate.openMainWindow()
                }
                .keyboardShortcut("n", modifiers: .command)
            }
        }
        
        // Add a menu bar extra for the app
        MenuBarExtra {
            MenuBarView()
                .environmentObject(appDelegate.deviceManager)
                .environmentObject(appDelegate.menuBarManager)
        } label: {
            MenuBarLabel(
                deviceManager: appDelegate.deviceManager,
                menuBarManager: appDelegate.menuBarManager
            )
        }
        .menuBarExtraStyle(.window)
    }
}