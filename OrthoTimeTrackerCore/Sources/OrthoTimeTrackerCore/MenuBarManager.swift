import Foundation
import SwiftUI
import Combine

public class MenuBarManager: ObservableObject {
    @Published public var selectedDevice: Device?
    @Published public var timerText: String = "00:00:00"
    
    // Make deviceManager a strong reference to prevent it from being deallocated
    private var deviceManager: DeviceManager?
    
    // Timer for updating the display
    private var timer: AnyCancellable?
    private var cancellables = Set<AnyCancellable>()
    
    public init() {
        // We won't start our own timer - we'll rely on DeviceManager's
        // Timer to keep everything in sync
    }
    
    public func setDeviceManager(_ manager: DeviceManager) {
        self.deviceManager = manager
        
        // Subscribe to changes from device manager - with stronger connection
        manager.objectWillChange
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.updateTimerText()
                    // Send our own change notification to ensure UI updates
                    self?.objectWillChange.send()
                }
            }
            .store(in: &cancellables)
            
        // Also observe the timestamp directly
        manager.$currentTimestamp
            .receive(on: RunLoop.main)
            .sink { [weak self] _ in
                DispatchQueue.main.async {
                    self?.updateTimerText()
                    self?.objectWillChange.send()
                }
            }
            .store(in: &cancellables)
            
        // Initial update
        updateTimerText()
    }
    
    public func updateTimerText() {
        if let deviceId = selectedDevice?.id, let deviceManager = deviceManager {
            // Always get the fresh device from the manager
            if let updatedDevice = deviceManager.devices.first(where: { $0.id == deviceId }) {
                // Update the device reference
                if updatedDevice.id == selectedDevice?.id {
                    selectedDevice = updatedDevice
                }
                
                // Calculate the current time based on real-time data
                let formattedTime = TimeUtils.formattedTime(updatedDevice.totalTime())
                
                // Only update if the text changed to avoid unnecessary UI updates
                if formattedTime != timerText {
                    timerText = formattedTime
                    objectWillChange.send()
                }
            }
        } else {
            if timerText != "00:00:00" {
                timerText = "00:00:00"
                objectWillChange.send()
            }
        }
    }
    
    // Get current time for a device directly (for use in views)
    public func currentTimeForSelectedDevice() -> String {
        if let device = selectedDevice, let manager = deviceManager {
            if let updatedDevice = manager.devices.first(where: { $0.id == device.id }) {
                return TimeUtils.formattedTime(updatedDevice.totalTime())
            }
            return TimeUtils.formattedTime(device.totalTime())
        }
        return "00:00:00"
    }
    
    deinit {
        timer?.cancel()
        cancellables.forEach { $0.cancel() }
    }
}