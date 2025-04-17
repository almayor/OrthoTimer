import SwiftUI
import OrthoTimeTrackerCore

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
                        TextField("Device Name", text: $deviceName, onCommit: {
                            updateDeviceName()
                        })
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.title)
                        
                        Button("Save") {
                            updateDeviceName()
                        }
                    } else {
                        Text(device.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Button(action: {
                            isEditingName = true
                        }) {
                            Image(systemName: "pencil")
                        }
                        .buttonStyle(BorderlessButtonStyle())
                    }
                }
                
                // Stopwatch
                VStack(alignment: .center, spacing: 10) {
                    Text(TimeUtils.formattedTime(device.totalTime()))
                        .font(.system(size: 60, weight: .bold, design: .monospaced))
                        .foregroundColor(device.isRunning ? .accentColor : .primary)
                    
                    Button(action: {
                        deviceManager.toggleTimer(for: device)
                    }) {
                        Text(device.isRunning ? "Stop" : "Start")
                            .font(.headline)
                            .foregroundColor(.white)
                            .padding(.horizontal, 30)
                            .padding(.vertical, 10)
                            .background(device.isRunning ? Color.red : OrthoTimeTrackerCore.accentColor)
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
        GroupBox(label: Text("Statistics").font(.headline)) {
            VStack(alignment: .leading, spacing: 15) {
                StatRow(title: "Today", value: TimeUtils.formattedTime(device.totalTime()))
                
                Divider()
                
                StatRow(title: "This Week", value: TimeUtils.formattedTime(device.totalTime(timeFrame: .week)))
                StatRow(title: "This Month", value: TimeUtils.formattedTime(device.totalTime(timeFrame: .month)))
                
                Divider()
                
                StatRow(title: "Daily Average (Week)", value: TimeUtils.formattedTime(device.averageTimePerDay(timeFrame: .week)))
                StatRow(title: "Daily Average (Month)", value: TimeUtils.formattedTime(device.averageTimePerDay(timeFrame: .month)))
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