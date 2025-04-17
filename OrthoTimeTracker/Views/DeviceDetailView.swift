import SwiftUI

struct DeviceDetailView: View {
    let device: Device
    @EnvironmentObject private var deviceManager: DeviceManager
    @State private var deviceName: String
    @State private var isEditing = false
    
    init(device: Device) {
        self.device = device
        _deviceName = State(initialValue: device.name)
    }
    
    var body: some View {
        ScrollView {
            VStack(spacing: 20) {
                // Device name with edit button
                HStack {
                    if isEditing {
                        TextField("Device Name", text: $deviceName, onCommit: {
                            updateDeviceName()
                        })
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .font(.title)
                        
                        Button(action: {
                            updateDeviceName()
                        }) {
                            Text("Save")
                        }
                    } else {
                        Text(device.name)
                            .font(.title)
                            .fontWeight(.bold)
                        
                        Button(action: {
                            isEditing = true
                        }) {
                            Image(systemName: "pencil")
                        }
                    }
                }
                .padding()
                
                // Stopwatch
                VStack {
                    Text(formattedTime(device.totalTime()))
                        .font(.system(size: 60, weight: .bold, design: .monospaced))
                        .foregroundColor(device.isRunning ? .green : .primary)
                    
                    Button(action: {
                        deviceManager.toggleTimer(for: device)
                    }) {
                        Text(device.isRunning ? "Stop" : "Start")
                            .frame(width: 100, height: 44)
                            .background(device.isRunning ? Color.red : Color.green)
                            .foregroundColor(.white)
                            .cornerRadius(10)
                    }
                    .padding()
                }
                
                // Statistics
                StatisticsView(device: device)
            }
        }
        .navigationTitle("Device Details")
    }
    
    private func updateDeviceName() {
        if !deviceName.isEmpty && deviceName != device.name {
            var updatedDevice = device
            updatedDevice.name = deviceName
            deviceManager.updateDevice(updatedDevice)
        }
        isEditing = false
    }
    
    private func formattedTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) / 60 % 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

struct StatisticsView: View {
    let device: Device
    
    var body: some View {
        VStack(alignment: .leading, spacing: 20) {
            Text("Statistics")
                .font(.headline)
                .padding(.horizontal)
            
            StatCard(title: "Today", value: formattedTime(device.totalTime()))
            
            StatCard(title: "This Week", value: formattedTime(device.totalTime(timeFrame: .week)))
            
            StatCard(title: "This Month", value: formattedTime(device.totalTime(timeFrame: .month)))
            
            StatCard(title: "Daily Average (Week)", value: formattedTime(device.averageTimePerDay(timeFrame: .week)))
            
            StatCard(title: "Daily Average (Month)", value: formattedTime(device.averageTimePerDay(timeFrame: .month)))
        }
        .padding()
        .background(Color(.systemGray6))
        .cornerRadius(10)
        .padding()
    }
    
    private func formattedTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) / 60 % 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

struct StatCard: View {
    let title: String
    let value: String
    
    var body: some View {
        HStack {
            Text(title)
                .foregroundColor(.secondary)
            Spacer()
            Text(value)
                .fontWeight(.semibold)
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
        .background(Color(.systemBackground))
        .cornerRadius(8)
        .padding(.horizontal)
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
