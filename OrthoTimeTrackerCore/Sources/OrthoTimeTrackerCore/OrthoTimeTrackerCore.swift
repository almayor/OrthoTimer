import Foundation
import SwiftUI

public struct OrthoTimeTrackerCore {
    public static let version = "1.0.0"
    
    public static func configure() {
        print("OrthoTimeTrackerCore configured")
    }
    
    // Common accent color for both platforms
    public static let accentColor = Color(red: 0.302, green: 0.533, blue: 0.725) // #4d88b9 - darker orthodontist-y blue
}

// Export the main components
public typealias OTTDevice = Device
public typealias OTTDeviceManager = DeviceManager
public typealias OTTMenuBarManager = MenuBarManager