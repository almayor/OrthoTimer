import SwiftUI
import CloudKit

@main
struct OrthoTimeTrackerApp: App {
    @StateObject private var deviceManager = DeviceManager()
    
    var body: some Scene {
        WindowGroup {
            DeviceListView()
                .environmentObject(deviceManager)
        }
    }
}
