import SwiftUI
import CloudKit
import OrthoTimeTrackerCore

@main
struct OrthoTimeTrackerApp: App {
    @StateObject private var deviceManager = OTTDeviceManager()
    
    init() {
        // Initialize core framework
        OrthoTimeTrackerCore.configure()
    }
    
    var body: some Scene {
        WindowGroup {
            DeviceListView()
                .environmentObject(deviceManager)
                .onOpenURL { url in
                    handleDeepLink(url: url)
                }
        }
    }
    
    private func handleDeepLink(url: URL) {
        guard url.scheme == "orthotimer" || url.scheme == "orthotimetracker" else { return }
        
        if url.host == "toggle" {
            let pathComponents = url.pathComponents
            if pathComponents.count >= 2 {
                let deviceID = pathComponents[1]
                if let uuid = UUID(uuidString: deviceID),
                   let device = deviceManager.devices.first(where: { $0.id == uuid }) {
                    deviceManager.toggleTimer(for: device)
                }
            }
        } else if url.host == "detail" {
            // The detail URL just toggles the device's timer
            // This is a simplified approach since we don't have access to the expandedDeviceId state
            let pathComponents = url.pathComponents
            if pathComponents.count >= 2 {
                let deviceID = pathComponents[1]
                if let uuid = UUID(uuidString: deviceID),
                   let device = deviceManager.devices.first(where: { $0.id == uuid }) {
                    // Just toggle the timer as a fallback
                    deviceManager.toggleTimer(for: device)
                }
            }
        }
    }
}
