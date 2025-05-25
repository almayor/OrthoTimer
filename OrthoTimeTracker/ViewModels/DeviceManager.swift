import Foundation
import Combine
import CloudKit
import SwiftUI
import UserNotifications
import OrthoTimeTrackerCore

class DeviceManager: ObservableObject {
    @Published var devices: [OTTDevice] = []
    @Published var currentTimestamp: Date = Date()
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private let cloudKitContainer = CKContainer.default()
    private var lastMidnightCheck = Date()
    
    init() {
        // Request notification permission
        requestNotificationPermission()
        
        setupTimer()
        fetchDevices()
        
        // Check for midnight transition and notification conditions
        Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.checkForMidnightTransition()
                self?.checkNotificationConditions()
            }
            .store(in: &cancellables)
    }
    
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
    private func sendNotWearingNotification(for device: OTTDevice) {
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
    private func sendWearingTooLongNotification(for device: OTTDevice) {
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
    
    private func setupTimer() {
        // Create a timer that updates a timestamp every second,
        // which forces all observing views to refresh
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            guard let self = self else { return }
            self.currentTimestamp = Date()
            self.objectWillChange.send()
        }
        
        // Make sure timer runs even when scrolling
        RunLoop.current.add(timer!, forMode: .common)
    }
    
    func addDevice(name: String) {
        let device = OTTDevice(name: name)
        devices.append(device)
        saveDevice(device)
    }
    
    func deleteDevice(at indexSet: IndexSet) {
        for index in indexSet {
            let device = devices[index]
            deleteDeviceFromCloud(device)
            devices.remove(at: index)
        }
    }
    
    func updateDevice(_ updatedDevice: OTTDevice) {
        if let index = devices.firstIndex(where: { $0.id == updatedDevice.id }) {
            devices[index] = updatedDevice
            saveDevice(updatedDevice)
        }
    }
    
    func toggleTimer(for device: OTTDevice) {
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
    
    private func cleanupOldStats(for device: inout OTTDevice, calendar: Calendar) {
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
        // For simulator testing, use some sample data instead of CloudKit
        #if targetEnvironment(simulator)
        // Create some sample devices for testing
        let device1 = OTTDevice(name: "Retainer")
        let device2 = OTTDevice(name: "Invisalign", totalTimeToday: 3600) // 1 hour
        devices = [device1, device2]
        checkForMidnightTransition()
        return
        #endif
        
        // Real CloudKit implementation - will work when you have a developer account
        let privateDatabase = cloudKitContainer.privateCloudDatabase
        let query = CKQuery(recordType: "Device", predicate: NSPredicate(value: true))
        
        privateDatabase.perform(query, inZoneWith: nil) { [weak self] results, error in
            if let error = error {
                print("Error fetching devices: \(error.localizedDescription)")
                return
            }
            
            guard let results = results else { return }
            
            let devices = results.compactMap { OTTDevice.fromCKRecord($0) }
            
            DispatchQueue.main.async {
                self?.devices = devices
                self?.checkForMidnightTransition() // Check if we need to reset timers
            }
        }
    }
    
    private func saveDevice(_ device: OTTDevice) {
        // Real CloudKit implementation
        let privateDatabase = cloudKitContainer.privateCloudDatabase
        let record = device.toCKRecord()
        
        privateDatabase.save(record) { _, error in
            if let error = error {
                print("Error saving device: \(error.localizedDescription)")
            }
        }
    }
    
    private func deleteDeviceFromCloud(_ device: OTTDevice) {
        // Real CloudKit implementation
        let privateDatabase = cloudKitContainer.privateCloudDatabase
        let recordID = CKRecord.ID(recordName: device.id.uuidString)
        
        privateDatabase.delete(withRecordID: recordID) { _, error in
            if let error = error {
                print("Error deleting device: \(error.localizedDescription)")
            }
        }
    }
}
