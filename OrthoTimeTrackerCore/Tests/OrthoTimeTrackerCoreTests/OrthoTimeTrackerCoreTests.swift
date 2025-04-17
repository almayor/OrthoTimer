import XCTest
@testable import OrthoTimeTrackerCore

final class OrthoTimeTrackerCoreTests: XCTestCase {
    func testDeviceCreation() {
        let device = Device(name: "Test Device")
        XCTAssertEqual(device.name, "Test Device")
        XCTAssertEqual(device.totalTimeToday, 0)
        XCTAssertFalse(device.isRunning)
    }
    
    func testDeviceTimer() {
        var device = Device(name: "Timer Test")
        let now = Date()
        
        // Start timer
        device.sessionStartTime = now
        XCTAssertTrue(device.isRunning)
        
        // Total time includes current session
        let startTimeTotal = device.totalTime()
        XCTAssertGreaterThanOrEqual(startTimeTotal, 0)
    }
    
    func testTimeUtils() {
        // Test formatting
        let oneHour = 3600.0
        XCTAssertEqual(TimeUtils.formattedTime(oneHour), "01:00:00")
        
        // Test hours minutes formatting
        XCTAssertEqual(TimeUtils.formattedHoursMinutes(3600 + 120), "1 hr 2 min")
    }
}