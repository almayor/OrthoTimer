import Foundation
import SwiftUI

class MenuBarManager: ObservableObject {
    @Published var selectedDevice: Device?
    @Published var timerText: String = "00:00:00"
    private var timer: Timer?
    
    init() {
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