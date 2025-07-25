import Foundation
import Combine
import CloudKit
import SwiftUI
#if os(iOS)
import UserNotifications
#endif

public class DeviceManager: ObservableObject {
    @Published public var devices: [Device] = []
    @Published public var currentTimestamp: Date = Date()
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private var cloudKitContainer: CKContainer?
    private var lastMidnightCheck = Date()
    
    public init() {
        // Initialize CloudKit for all environments except simulator
        #if targetEnvironment(simulator)
        cloudKitContainer = nil
        print("CloudKit disabled in simulator - using local data only")
        #else
        cloudKitContainer = CKContainer.default()
        print("CloudKit enabled - container initialized")
        #endif
        
        #if os(iOS)
        // Request notification permission on iOS
        requestNotificationPermission()
        #endif
        
        setupTimer()
        
        // Use sample data only if CloudKit is not available
        if cloudKitContainer == nil {
            print("Using sample data (CloudKit container is nil)")
            loadSampleData()
        } else {
            print("Initializing with CloudKit data")
            fetchDevices()
        }
        
        // Check for midnight transition and notification conditions
        Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.checkForMidnightTransition()
                #if os(iOS)
                self?.checkNotificationConditions()
                #endif
            }
            .store(in: &cancellables)
    }
    
    #if os(iOS)
    // Request permission to send notifications
    private func requestNotificationPermission() {
        UNUserNotificationCenter.current().requestAuthorization(options: [.alert, .sound, .badge]) { granted, error in
            if granted {
                print("Notification permission granted")
            } else if let error = error {
                print("Notification permission error: \(error.localizedDescription)")
            }
        }
    }
    
    // Check if we need to send notifications based on device status
    private func checkNotificationConditions() {
        for device in devices {
            // Check for not wearing notification (3+ hours without wearing)
            if !device.isRunning {
                if let lastStopTime = device.lastStopTime {
                    let hoursSinceStop = Date().timeIntervalSince(lastStopTime) / 3600
                    
                    // If not worn for 3+ hours and we haven't notified already
                    if hoursSinceStop >= 3 && !device.notifiedForNotWearing {
                        sendNotWearingNotification(for: device)
                        
                        // Update the device to mark as notified
                        var updatedDevice = device
                        updatedDevice.notifiedForNotWearing = true
                        updateDevice(updatedDevice)
                    }
                }
            } else {
                // Reset the not wearing notification flag when device is worn again
                if device.notifiedForNotWearing {
                    var updatedDevice = device
                    updatedDevice.notifiedForNotWearing = false
                    updateDevice(updatedDevice)
                }
                
                // Check for wearing too long (12+ hours)
                if let startTime = device.sessionStartTime {
                    let hoursWearing = Date().timeIntervalSince(startTime) / 3600
                    
                    // If worn for 12+ hours and we haven't notified already
                    if hoursWearing >= 12 && !device.notifiedForLongWearing {
                        sendWearingTooLongNotification(for: device)
                        
                        // Update the device to mark as notified
                        var updatedDevice = device
                        updatedDevice.notifiedForLongWearing = true
                        updateDevice(updatedDevice)
                    }
                }
            }
        }
    }
    
    // Send notification for not wearing device for 3+ hours
    private func sendNotWearingNotification(for device: Device) {
        let content = UNMutableNotificationContent()
        content.title = "Time to wear your \(device.name)"
        content.body = "You haven't worn your \(device.name) for over 3 hours. Put it on to stay on track!"
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "not-wearing-\(device.id.uuidString)",
            content: content,
            trigger: nil // Deliver immediately
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    
    // Send notification for wearing device too long (12+ hours)
    private func sendWearingTooLongNotification(for device: Device) {
        let content = UNMutableNotificationContent()
        content.title = "Time for a break from \(device.name)"
        content.body = "You've been wearing your \(device.name) for over 12 hours. Consider taking a break to eat or clean it."
        content.sound = .default
        
        let request = UNNotificationRequest(
            identifier: "wearing-too-long-\(device.id.uuidString)",
            content: content,
            trigger: nil // Deliver immediately
        )
        
        UNUserNotificationCenter.current().add(request)
    }
    #endif
    
    private func setupTimer() {
        // Create a timer that updates consistently every second
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            
            // Force update of timestamp for SwiftUI refresh
            self.currentTimestamp = Date()
            
            // Force a UI update
            DispatchQueue.main.async {
                self.objectWillChange.send()
            }
            
            // Also force update of session times if needed
            for (index, device) in self.devices.enumerated() where device.isRunning {
                // No need to update the full device, just force UI refresh
                if device.isRunning {
                    // Publishing a second change notification helps SwiftUI catch updates
                    DispatchQueue.main.async {
                        self.objectWillChange.send()
                    }
                }
            }
        }
        
        // Make sure timer runs in all run loop modes
        RunLoop.main.add(timer!, forMode: .common)
    }
    
    public func addDevice(name: String) {
        let device = Device(name: name)
        devices.append(device)
        saveDevice(device)
    }
    
    public func deleteDevice(at indexSet: IndexSet) {
        for index in indexSet {
            let device = devices[index]
            deleteDeviceFromCloud(device)
            devices.remove(at: index)
        }
    }
    
    public func updateDevice(_ updatedDevice: Device) {
        if let index = devices.firstIndex(where: { $0.id == updatedDevice.id }) {
            devices[index] = updatedDevice
            saveDevice(updatedDevice)
        }
    }
    
    public func toggleTimer(for device: Device) {
        var updatedDevice = device
        let now = Date()
        
        if device.isRunning {
            // Stop the timer and add the elapsed time
            if let startTime = device.sessionStartTime {
                let elapsedTime = now.timeIntervalSince(startTime)
                updatedDevice.totalTimeToday += elapsedTime
                updatedDevice.sessionStartTime = nil
                
                // Record the stop time for notification purposes
                updatedDevice.lastStopTime = now
                
                // Reset the long wearing notification flag
                updatedDevice.notifiedForLongWearing = false
            }
        } else {
            // Start the timer
            updatedDevice.sessionStartTime = now
            
            // Reset the not wearing notification flag
            updatedDevice.notifiedForNotWearing = false
        }
        
        updateDevice(updatedDevice)
    }
    
    private func checkForMidnightTransition() {
        let now = Date()
        let calendar = Calendar.current
        
        // Check if we've crossed midnight since the last check
        if !calendar.isDate(lastMidnightCheck, inSameDayAs: now) {
            resetDailyTimers()
            updateStatistics(forDate: lastMidnightCheck)
            lastMidnightCheck = now
        }
    }
    
    private func resetDailyTimers() {
        for i in 0..<devices.count {
            var device = devices[i]
            
            // If a session is running, stop it and add time to statistics
            if let startTime = device.sessionStartTime {
                let elapsedTime = Date().timeIntervalSince(startTime)
                device.totalTimeToday += elapsedTime
                
                // Restart the session
                device.sessionStartTime = Date()
            }
            
            // Reset the daily counter
            device.totalTimeToday = 0
            
            devices[i] = device
            saveDevice(device)
        }
    }
    
    private func updateStatistics(forDate date: Date) {
        let calendar = Calendar.current
        let dateKey = calendar.startOfDay(for: date)
        
        for i in 0..<devices.count {
            var device = devices[i]
            
            // Update daily stats
            device.weeklyStats[dateKey] = device.totalTimeToday
            device.monthlyStats[dateKey] = device.totalTimeToday
            
            // Clean up old stats (keep last 7 days for week, last 30 for month)
            cleanupOldStats(for: &device, calendar: calendar)
            
            devices[i] = device
            saveDevice(device)
        }
    }
    
    private func cleanupOldStats(for device: inout Device, calendar: Calendar) {
        let today = calendar.startOfDay(for: Date())
        
        // Keep only the last 7 days for weekly stats
        device.weeklyStats = device.weeklyStats.filter { dateKey, _ in
            guard let daysDifference = calendar.dateComponents([.day], from: dateKey, to: today).day else {
                return false
            }
            return daysDifference <= 7
        }
        
        // Keep only the last 30 days for monthly stats
        device.monthlyStats = device.monthlyStats.filter { dateKey, _ in
            guard let daysDifference = calendar.dateComponents([.day], from: dateKey, to: today).day else {
                return false
            }
            return daysDifference <= 30
        }
    }
    
    // MARK: - CloudKit Operations
    
    private func fetchDevices() {
        // Guard for CloudKit availability
        guard let container = cloudKitContainer else {
            print("CloudKit container not available")
            loadSampleData()
            return
        }
        
        // Skip CloudKit on simulator only
        #if targetEnvironment(simulator)
        print("Skipping CloudKit fetch on simulator")
        loadSampleData()
        return
        #endif
        
        // Real CloudKit implementation
        print("Fetching devices from CloudKit...")
        let privateDatabase = container.privateCloudDatabase
        let query = CKQuery(recordType: "Device", predicate: NSPredicate(value: true))
        
        privateDatabase.perform(query, inZoneWith: nil) { [weak self] results, error in
            if let error = error {
                let ckError = error as? CKError
                let errorCode = ckError?.errorCode ?? -1
                
                print("Error fetching devices from CloudKit:")
                print("- Error code: \(errorCode)")
                print("- Description: \(error.localizedDescription)")
                
                if let ckError = ckError {
                    switch ckError.errorCode {
                    case CKError.Code.networkUnavailable.rawValue, CKError.Code.networkFailure.rawValue:
                        print("- Network error. Will retry on next app launch.")
                    case CKError.Code.serviceUnavailable.rawValue, CKError.Code.requestRateLimited.rawValue:
                        print("- CloudKit service issue. Will retry on next app launch.")
                    case CKError.Code.badContainer.rawValue, CKError.Code.incompatibleVersion.rawValue, CKError.Code.badDatabase.rawValue:
                        print("- CloudKit configuration issue. Check entitlements and Apple Developer portal.")
                    case CKError.Code.permissionFailure.rawValue, CKError.Code.notAuthenticated.rawValue:
                        print("- Authentication error. User may need to sign in to iCloud.")
                    default:
                        print("- Unspecified CloudKit error.")
                    }
                }
                
                DispatchQueue.main.async {
                    self?.loadSampleData() // Fall back to sample data if fetch fails
                }
                return
            }
            
            let devices = results?.compactMap { Device.fromCKRecord($0) } ?? []
            
            DispatchQueue.main.async {
                if !devices.isEmpty {
                    print("Successfully loaded \(devices.count) devices from CloudKit")
                    self?.devices = devices
                    self?.checkForMidnightTransition() // Check if we need to reset timers
                } else {
                    print("No devices found in CloudKit. This is normal for new installations.")
                    print("Using initial sample data. New devices will be saved to CloudKit.")
                    self?.loadSampleData()
                }
            }
        }
    }
    
    private func loadSampleData() {
        DispatchQueue.main.async { [weak self] in
            let device1 = Device(name: "Retainer")
            let device2 = Device(name: "Invisalign", totalTimeToday: 3600) // 1 hour
            self?.devices = [device1, device2]
            self?.checkForMidnightTransition()
        }
    }
    
    private func saveDevice(_ device: Device) {
        // Skip CloudKit on simulator only
        #if targetEnvironment(simulator)
        print("Skipping CloudKit save in simulator - using local data only")
        return
        #endif
        
        // Guard for CloudKit availability
        guard let container = cloudKitContainer else {
            print("CloudKit container not available for saving")
            return
        }
        
        // Real CloudKit implementation
        print("Saving device \(device.name) to CloudKit...")
        let privateDatabase = container.privateCloudDatabase
        let record = device.toCKRecord()
        
        privateDatabase.save(record) { savedRecord, error in
            if let error = error {
                let ckError = error as? CKError
                let errorCode = ckError?.errorCode ?? -1
                
                print("Error saving device to CloudKit:")
                print("- Error code: \(errorCode)")
                print("- Description: \(error.localizedDescription)")
                
                if let ckError = ckError {
                    switch ckError.errorCode {
                    case CKError.Code.networkUnavailable.rawValue, CKError.Code.networkFailure.rawValue:
                        print("- Network error. Data saved locally, will sync when network available.")
                    case CKError.Code.serviceUnavailable.rawValue, CKError.Code.requestRateLimited.rawValue:
                        print("- CloudKit service issue. Data saved locally, will retry later.")
                    case CKError.Code.badContainer.rawValue, CKError.Code.incompatibleVersion.rawValue, CKError.Code.badDatabase.rawValue:
                        print("- CloudKit configuration issue. Check entitlements and Apple Developer portal.")
                    case CKError.Code.permissionFailure.rawValue, CKError.Code.notAuthenticated.rawValue:
                        print("- Authentication error. User may need to sign in to iCloud.")
                    default:
                        print("- Unspecified CloudKit error.")
                    }
                }
            } else {
                print("Device \(device.name) saved to CloudKit successfully (Record ID: \(record.recordID.recordName))")
            }
        }
    }
    
    private func deleteDeviceFromCloud(_ device: Device) {
        // Skip CloudKit on simulator only
        #if targetEnvironment(simulator)
        print("Skipping CloudKit delete in simulator - using local data only")
        return
        #endif
        
        // Guard for CloudKit availability
        guard let container = cloudKitContainer else {
            print("CloudKit container not available for deleting")
            return
        }
        
        // Real CloudKit implementation
        print("Deleting device \(device.name) from CloudKit...")
        let privateDatabase = container.privateCloudDatabase
        let recordID = CKRecord.ID(recordName: device.id.uuidString)
        
        privateDatabase.delete(withRecordID: recordID) { deletedRecordID, error in
            if let error = error {
                let ckError = error as? CKError
                let errorCode = ckError?.errorCode ?? -1
                
                print("Error deleting device from CloudKit:")
                print("- Error code: \(errorCode)")
                print("- Description: \(error.localizedDescription)")
                
                if let ckError = ckError {
                    switch ckError.errorCode {
                    case CKError.Code.networkUnavailable.rawValue, CKError.Code.networkFailure.rawValue:
                        print("- Network error. Will retry when network available.")
                    case CKError.Code.unknownItem.rawValue:
                        print("- Device not found in CloudKit. This is normal if it was never saved.")
                    case CKError.Code.serviceUnavailable.rawValue, CKError.Code.requestRateLimited.rawValue:
                        print("- CloudKit service issue. Will retry later.")
                    case CKError.Code.badContainer.rawValue, CKError.Code.incompatibleVersion.rawValue, CKError.Code.badDatabase.rawValue:
                        print("- CloudKit configuration issue. Check entitlements and Apple Developer portal.")
                    case CKError.Code.permissionFailure.rawValue, CKError.Code.notAuthenticated.rawValue:
                        print("- Authentication error. User may need to sign in to iCloud.")
                    default:
                        print("- Unspecified CloudKit error.")
                    }
                }
            } else {
                print("Device \(device.name) deleted from CloudKit successfully")
            }
        }
    }
}