import Foundation
import SwiftUI

public class TimeUtils {
    public static func formattedTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) / 60 % 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
    
    public static func formattedHoursMinutes(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) / 60 % 60
        return String(format: "%d hr %d min", hours, minutes)
    }
    
    public static func startOfDay(for date: Date) -> Date {
        return Calendar.current.startOfDay(for: date)
    }
    
    public static func startOfWeek(for date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.yearForWeekOfYear, .weekOfYear], from: date)
        return calendar.date(from: components) ?? date
    }
    
    public static func startOfMonth(for date: Date) -> Date {
        let calendar = Calendar.current
        let components = calendar.dateComponents([.year, .month], from: date)
        return calendar.date(from: components) ?? date
    }
    
    public static let timerColor = Color(red: 0.302, green: 0.533, blue: 0.725) // #4d88b9 - darker orthodontist-y blue
}