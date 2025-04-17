import SwiftUI
import OrthoTimeTrackerCore
import AppKit

struct DeviceDetailView: View {
    let device: OTTDevice
    @EnvironmentObject private var deviceManager: OTTDeviceManager
    @State private var deviceName: String
    @State private var isEditingName = false
    
    init(device: OTTDevice) {
        self.device = device
        self._deviceName = State(initialValue: device.name)
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    if isEditingName {
                        // Using our custom text field with title font
                        CustomTextField(
                            text: $deviceName,
                            onCommit: {
                                updateDeviceName()
                            },
                            font: NSFont.systemFont(ofSize: 18) // Larger title-like font size
                        )
                        .frame(height: 40)
                        
                        Button("Save") {
                            updateDeviceName()
                        }
                    } else {
                        Text(device.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Button(action: {
                            // Reset to current device name before entering edit mode
                            deviceName = device.name
                            isEditingName = true
                        }) {
                            Image(systemName: "pencil")
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                }
                
                // Stopwatch - using the current device manager timestamp for live updates
                VStack(alignment: .center, spacing: 10) {
                    // This view observes both the timestamp and the objectWillChange publisher
                    let _ = deviceManager.currentTimestamp
                    
                    // Add a timer for redundant UI refresh
                    Text("")
                        .hidden()
                        .onReceive(Timer.publish(every: 0.5, on: .main, in: .common).autoconnect()) { _ in
                            // This creates a separate refresh cycle as a backup
                        }
                    
                    // Get the current device from the manager to ensure we have the latest data
                    let currentDevice = deviceManager.devices.first(where: { $0.id == device.id }) ?? device
                    
                    Text(TimeUtils.formattedTime(currentDevice.totalTime()))
                        .font(.system(size: 60, weight: .bold, design: .monospaced))
                        .foregroundColor(currentDevice.isRunning ? Color(red: 0.0, green: 0.3, blue: 0.7) : .primary)
                    
                    Button(action: {
                        // Always use the latest device reference
                        if let freshDevice = deviceManager.devices.first(where: { $0.id == device.id }) {
                            deviceManager.toggleTimer(for: freshDevice)
                        } else {
                            deviceManager.toggleTimer(for: device)
                        }
                    }) {
                        Text(currentDevice.isRunning ? "Stop" : "Start")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 10)
                            .background(currentDevice.isRunning ? Color.red : Color(red: 0.0, green: 0.3, blue: 0.7))
                            .cornerRadius(10)
                    }
                    .buttonStyle(BorderlessButtonStyle())
                }
                .frame(maxWidth: .infinity)
                .padding()
                
                // Statistics
                StatisticsView(device: device)
            }
            .padding()
        }
    }
    
    private func updateDeviceName() {
        if !deviceName.isEmpty && deviceName != device.name {
            var updatedDevice = device
            updatedDevice.name = deviceName
            deviceManager.updateDevice(updatedDevice)
        }
        isEditingName = false
    }
}

struct StatisticsView: View {
    let device: OTTDevice
    @EnvironmentObject private var deviceManager: OTTDeviceManager
    
    var body: some View {
        // Observe the timestamp to keep stats current
        let _ = deviceManager.currentTimestamp
        
        // Get the latest device data
        let currentDevice = deviceManager.devices.first(where: { $0.id == device.id }) ?? device
        
        return GroupBox(label: Text("Statistics").font(.headline)) {
            VStack(alignment: .leading, spacing: 15) {
                StatRow(title: "Today", value: TimeUtils.formattedTime(currentDevice.totalTime()))
                
                Divider()
                
                StatRow(title: "This Week", value: TimeUtils.formattedTime(currentDevice.totalTime(timeFrame: .week)))
                StatRow(title: "This Month", value: TimeUtils.formattedTime(currentDevice.totalTime(timeFrame: .month)))
                
                Divider()
                
                StatRow(title: "Daily Average (Week)", value: TimeUtils.formattedTime(currentDevice.averageTimePerDay(timeFrame: .week)))
                StatRow(title: "Daily Average (Month)", value: TimeUtils.formattedTime(currentDevice.averageTimePerDay(timeFrame: .month)))
            }
            .padding()
        }
    }
}

struct StatRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.medium)
        }
    }
}

