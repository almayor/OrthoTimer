import SwiftUI

struct DeviceDetailView: View {
    let device: Device
    @EnvironmentObject private var deviceManager: DeviceManager
    @State private var deviceName: String
    @State private var showingRenameAlert = false
    
    init(device: Device) {
        self.device = device
        _deviceName = State(initialValue: device.name)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Stopwatch
                VStack {
                    Text(TimeUtils.formattedTime(device.totalTime()))
                        .font(.system(size: 60, weight: .bold, design: .monospaced))
                        .foregroundColor(device.isRunning ? .accentColor : .primary)
                    
                    Button(action: {
                        deviceManager.toggleTimer(for: device)
                    }) {
                        Text(device.isRunning ? "Stop" : "Start")
                            .frame(width: 100, height: 44)
                            .background(device.isRunning ? Color.red : Color.accentColor)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding()
                }
                
                // Statistics
                StatisticsView(device: device)
            }
        }
        .navigationTitle(device.name)
        .toolbar {
            ToolbarItem(placement: .navigationBarTrailing) {
                Button(action: {
                    showingRenameAlert = true
                }) {
                    Image(systemName: "pencil")
                }
            }
        }
        .alert("Rename Device", isPresented: $showingRenameAlert) {
            TextField("Device Name", text: $deviceName)
            Button("Cancel", role: .cancel) {
                deviceName = device.name
            }
            Button("Save") {
                updateDeviceName()
            }
        }
    }
    
    private func updateDeviceName() {
        if !deviceName.isEmpty && deviceName != device.name {
            var updatedDevice = device
            updatedDevice.name = deviceName
            deviceManager.updateDevice(updatedDevice)
        }
    }
    
}

struct StatisticsView: View {
    let device: Device
    @EnvironmentObject private var deviceManager: DeviceManager
    
    var body: some View {
        VStack(alignment: .leading, spacing: 15) {
            Text("Statistics")
                .font(.headline)
                .foregroundColor(.secondary)
            
            Divider()
                
            Group {
                StatRow(title: "Today", value: TimeUtils.formattedTime(device.totalTime()))
                StatRow(title: "This Week", value: TimeUtils.formattedTime(device.totalTime(timeFrame: .week)))
                StatRow(title: "This Month", value: TimeUtils.formattedTime(device.totalTime(timeFrame: .month)))
                Divider()
                StatRow(title: "Daily Average (Week)", value: TimeUtils.formattedTime(device.averageTimePerDay(timeFrame: .week)))
                StatRow(title: "Daily Average (Month)", value: TimeUtils.formattedTime(device.averageTimePerDay(timeFrame: .month)))
            }
        }
        .padding()
        .background(Color(.systemBackground))
        .cornerRadius(10)
        .shadow(color: Color.black.opacity(0.05), radius: 5, x: 0, y: 2)
        .padding()
    }
}

struct StatRow: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
                .font(.system(.body, design: .rounded))
            Spacer()
            Text(value)
                .font(.system(.body, design: .monospaced))
                .fontWeight(.medium)
        }
        .padding(.vertical, 4)
    }
}

struct DeviceDetailView_Previews: PreviewProvider {
    static var previews: some View {
        NavigationView {
            DeviceDetailView(device: Device(name: "Retainer"))
                .environmentObject(DeviceManager())
        }
    }
}
