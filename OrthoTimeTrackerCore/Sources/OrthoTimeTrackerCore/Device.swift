import Foundation
import CloudKit

public struct Device: Identifiable, Equatable {
    public var id: UUID
    public var name: String
    public var totalTimeToday: TimeInterval
    public var sessionStartTime: Date?
    public var weeklyStats: [Date: TimeInterval]
    public var monthlyStats: [Date: TimeInterval]
    public var lastStopTime: Date? // When the device was last removed
    public var notifiedForNotWearing: Bool = false // Whether we've sent a notification for not wearing
    public var notifiedForLongWearing: Bool = false // Whether we've sent a notification for wearing too long
    
    public var isRunning: Bool {
        sessionStartTime != nil
    }
    
    public init(id: UUID = UUID(), name: String, totalTimeToday: TimeInterval = 0, sessionStartTime: Date? = nil, lastStopTime: Date? = nil) {
        self.id = id
        self.name = name
        self.totalTimeToday = totalTimeToday
        self.sessionStartTime = sessionStartTime
        self.lastStopTime = lastStopTime
        self.weeklyStats = [:]
        self.monthlyStats = [:]
    }
    
    public func currentSessionTime() -> TimeInterval {
        guard let startTime = sessionStartTime else { return 0 }
        return Date().timeIntervalSince(startTime)
    }
    
    public func totalTime() -> TimeInterval {
        totalTimeToday + (isRunning ? currentSessionTime() : 0)
    }
    
    public func averageTimePerDay(timeFrame: TimeFrame) -> TimeInterval {
        switch timeFrame {
        case .week:
            let totalWeekTime = weeklyStats.values.reduce(0, +)
            return totalWeekTime / TimeInterval(max(1, weeklyStats.count))
        case .month:
            let totalMonthTime = monthlyStats.values.reduce(0, +)
            return totalMonthTime / TimeInterval(max(1, monthlyStats.count))
        }
    }
    
    public func totalTime(timeFrame: TimeFrame) -> TimeInterval {
        switch timeFrame {
        case .week:
            return weeklyStats.values.reduce(0, +)
        case .month:
            return monthlyStats.values.reduce(0, +)
        }
    }
    
    public enum TimeFrame {
        case week
        case month
    }
}

// MARK: - CloudKit Extension
extension Device {
    public func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: "Device", recordID: CKRecord.ID(recordName: id.uuidString))
        record["name"] = name
        record["totalTimeToday"] = totalTimeToday
        record["sessionStartTime"] = sessionStartTime
        record["lastStopTime"] = lastStopTime
        record["notifiedForNotWearing"] = notifiedForNotWearing
        record["notifiedForLongWearing"] = notifiedForLongWearing
        
        // Encode stats dictionaries to Data
        if let weeklyData = try? JSONEncoder().encode(weeklyStats) {
            record["weeklyStats"] = weeklyData
        }
        
        if let monthlyData = try? JSONEncoder().encode(monthlyStats) {
            record["monthlyStats"] = monthlyData
        }
        
        return record
    }
    
    public static func fromCKRecord(_ record: CKRecord) -> Device? {
        let idString = record.recordID.recordName
        guard 
            let id = UUID(uuidString: idString),
            let name = record["name"] as? String
        else { return nil }
        
        var device = Device(id: id, name: name)
        
        if let totalTimeToday = record["totalTimeToday"] as? TimeInterval {
            device.totalTimeToday = totalTimeToday
        }
        
        if let sessionStartTime = record["sessionStartTime"] as? Date {
            device.sessionStartTime = sessionStartTime
        }
        
        if let lastStopTime = record["lastStopTime"] as? Date {
            device.lastStopTime = lastStopTime
        }
        
        if let notifiedForNotWearing = record["notifiedForNotWearing"] as? Bool {
            device.notifiedForNotWearing = notifiedForNotWearing
        }
        
        if let notifiedForLongWearing = record["notifiedForLongWearing"] as? Bool {
            device.notifiedForLongWearing = notifiedForLongWearing
        }
        
        if let weeklyData = record["weeklyStats"] as? Data,
           let weeklyStats = try? JSONDecoder().decode([Date: TimeInterval].self, from: weeklyData) {
            device.weeklyStats = weeklyStats
        }
        
        if let monthlyData = record["monthlyStats"] as? Data,
           let monthlyStats = try? JSONDecoder().decode([Date: TimeInterval].self, from: monthlyData) {
            device.monthlyStats = monthlyStats
        }
        
        return device
    }
}