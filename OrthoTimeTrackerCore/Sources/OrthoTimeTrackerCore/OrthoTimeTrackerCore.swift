import Foundation
import SwiftUI

public struct OrthoTimeTrackerCore {
    public static let version = "1.0.0"
    
    public static func configure() {
        // IMPORTANT: Re-enable CloudKit after Apple Developer Program enrollment is approved
        // TODO: Update this configuration method once Developer Program is active
        
        #if os(macOS)
        print("OrthoTimeTrackerCore configured for macOS - CloudKit disabled")
        print("NOTE: CloudKit will be enabled on macOS after Developer Program approval")
        #elseif targetEnvironment(simulator)
        print("OrthoTimeTrackerCore configured for iOS simulator - CloudKit disabled")
        #elseif DEBUG
        print("OrthoTimeTrackerCore configured for iOS DEBUG - CloudKit disabled")
        #else
        print("OrthoTimeTrackerCore configured for iOS - CloudKit disabled until Developer Program approval")
        print("NOTE: CloudKit will be enabled once Developer Program is approved")
        #endif
    }
    
    // Common accent color for both platforms
    public static let accentColor = Color(red: 0.302, green: 0.533, blue: 0.725) // #4d88b9 - darker orthodontist-y blue
}

// Export the main components
public typealias OTTDevice = Device
public typealias OTTDeviceManager = DeviceManager
public typealias OTTMenuBarManager = MenuBarManager