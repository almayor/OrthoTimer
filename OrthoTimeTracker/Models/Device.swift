import Foundation
import CloudKit

struct Device: Identifiable, Equatable {
    var id: UUID
    var name: String
    var totalTimeToday: TimeInterval
    var sessionStartTime: Date?
    var weeklyStats: [Date: TimeInterval]
    var monthlyStats: [Date: TimeInterval]
    
    var isRunning: Bool {
        sessionStartTime != nil
    }
    
    init(id: UUID = UUID(), name: String, totalTimeToday: TimeInterval = 0, sessionStartTime: Date? = nil) {
        self.id = id
        self.name = name
        self.totalTimeToday = totalTimeToday
        self.sessionStartTime = sessionStartTime
        self.weeklyStats = [:]
        self.monthlyStats = [:]
    }
    
    func currentSessionTime() -> TimeInterval {
        guard let startTime = sessionStartTime else { return 0 }
        return Date().timeIntervalSince(startTime)
    }
    
    func totalTime() -> TimeInterval {
        totalTimeToday + (isRunning ? currentSessionTime() : 0)
    }
    
    func averageTimePerDay(timeFrame: TimeFrame) -> TimeInterval {
        switch timeFrame {
        case .week:
            let totalWeekTime = weeklyStats.values.reduce(0, +)
            return totalWeekTime / TimeInterval(max(1, weeklyStats.count))
        case .month:
            let totalMonthTime = monthlyStats.values.reduce(0, +)
            return totalMonthTime / TimeInterval(max(1, monthlyStats.count))
        }
    }
    
    func totalTime(timeFrame: TimeFrame) -> TimeInterval {
        switch timeFrame {
        case .week:
            return weeklyStats.values.reduce(0, +)
        case .month:
            return monthlyStats.values.reduce(0, +)
        }
    }
    
    enum TimeFrame {
        case week
        case month
    }
}

extension Device {
    func toCKRecord() -> CKRecord {
        let record = CKRecord(recordType: "Device", recordID: CKRecord.ID(recordName: id.uuidString))
        record["name"] = name
        record["totalTimeToday"] = totalTimeToday
        record["sessionStartTime"] = sessionStartTime
        
        // Encode stats dictionaries to Data
        if let weeklyData = try? JSONEncoder().encode(weeklyStats) {
            record["weeklyStats"] = weeklyData
        }
        
        if let monthlyData = try? JSONEncoder().encode(monthlyStats) {
            record["monthlyStats"] = monthlyData
        }
        
        return record
    }
    
    static func fromCKRecord(_ record: CKRecord) -> Device? {
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
