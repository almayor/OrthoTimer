import Foundation
import Combine
import CloudKit

class DeviceManager: ObservableObject {
    @Published var devices: [Device] = []
    private var timer: Timer?
    private var cancellables = Set<AnyCancellable>()
    private let cloudKitContainer = CKContainer.default()
    private var lastMidnightCheck = Date()
    
    init() {
        setupTimer()
        fetchDevices()
        
        // Check for midnight transition
        Timer.publish(every: 60, on: .main, in: .common)
            .autoconnect()
            .sink { [weak self] _ in
                self?.checkForMidnightTransition()
            }
            .store(in: &cancellables)
    }
    
    private func setupTimer() {
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.objectWillChange.send()
        }
    }
    
    func addDevice(name: String) {
        let device = Device(name: name)
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
    
    func updateDevice(_ updatedDevice: Device) {
        if let index = devices.firstIndex(where: { $0.id == updatedDevice.id }) {
            devices[index] = updatedDevice
            saveDevice(updatedDevice)
        }
    }
    
    func toggleTimer(for device: Device) {
        var updatedDevice = device
        
        if device.isRunning {
            // Stop the timer and add the elapsed time
            if let startTime = device.sessionStartTime {
                let elapsedTime = Date().timeIntervalSince(startTime)
                updatedDevice.totalTimeToday += elapsedTime
                updatedDevice.sessionStartTime = nil
            }
        } else {
            // Start the timer
            updatedDevice.sessionStartTime = Date()
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
        let privateDatabase = cloudKitContainer.privateCloudDatabase
        let query = CKQuery(recordType: "Device", predicate: NSPredicate(value: true))
        
        privateDatabase.perform(query, inZoneWith: nil) { [weak self] results, error in
            if let error = error {
                print("Error fetching devices: \(error.localizedDescription)")
                return
            }
            
            guard let results = results else { return }
            
            let devices = results.compactMap { Device.fromCKRecord($0) }
            
            DispatchQueue.main.async {
                self?.devices = devices
                self?.checkForMidnightTransition() // Check if we need to reset timers
            }
        }
    }
    
    private func saveDevice(_ device: Device) {
        let privateDatabase = cloudKitContainer.privateCloudDatabase
        let record = device.toCKRecord()
        
        privateDatabase.save(record) { _, error in
            if let error = error {
                print("Error saving device: \(error.localizedDescription)")
            }
        }
    }
    
    private func deleteDeviceFromCloud(_ device: Device) {
        let privateDatabase = cloudKitContainer.privateCloudDatabase
        let recordID = CKRecord.ID(recordName: device.id.uuidString)
        
        privateDatabase.delete(withRecordID: recordID) { _, error in
            if let error = error {
                print("Error deleting device: \(error.localizedDescription)")
            }
        }
    }
}
