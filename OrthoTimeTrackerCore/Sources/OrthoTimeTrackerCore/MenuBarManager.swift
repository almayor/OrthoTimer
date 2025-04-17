import Foundation
import SwiftUI

public class MenuBarManager: ObservableObject {
    @Published public var selectedDevice: Device?
    @Published public var timerText: String = "00:00:00"
    private var timer: Timer?
    
    public init() {
        startTimer()
    }
    
    private func startTimer() {
        // Update timer text every second
        timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { [weak self] _ in
            self?.updateTimerText()
        }
        RunLoop.current.add(timer!, forMode: .common)
    }
    
    private func updateTimerText() {
        if let device = selectedDevice {
            timerText = TimeUtils.formattedTime(device.totalTime())
        } else {
            timerText = "00:00:00"
        }
    }
    
    deinit {
        timer?.invalidate()
    }
}