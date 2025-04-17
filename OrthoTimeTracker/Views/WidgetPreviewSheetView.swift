import SwiftUI

// This sheet view wraps the widget preview content to avoid import issues
struct WidgetPreviewSheetView: View {
    let deviceManager: DeviceManager
    @Environment(\.presentationMode) var presentationMode
    
    var body: some View {
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    Text("Widget Previews")
                        .font(.title)
                        .padding(.top)
                    
                    Text("Small Widget Preview")
                        .font(.headline)
                    
                    // Small widget preview
                    if let device = deviceManager.devices.first {
                        singleDevicePreview(device: device)
                            .frame(width: 170, height: 170)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(radius: 2)
                    } else {
                        emptyDevicePreview()
                            .frame(width: 170, height: 170)
                            .clipShape(RoundedRectangle(cornerRadius: 20))
                            .shadow(radius: 2)
                    }
                    
                    Divider()
                        .padding(.vertical)
                    
                    Text("Medium Widget Preview")
                        .font(.headline)
                    
                    // Medium widget preview
                    multipleDevicesPreview(devices: deviceManager.devices)
                        .frame(width: 360, height: 170)
                        .clipShape(RoundedRectangle(cornerRadius: 20))
                        .shadow(radius: 2)
                    
                    Spacer()
                    
                    Text("Note: This is just a preview of how the widgets would look. Widget functionality requires iOS Developer Program membership.")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .multilineTextAlignment(.center)
                        .padding()
                }
                .padding()
            }
            .navigationTitle("Widget Preview")
            .navigationBarItems(trailing: Button("Done") {
                presentationMode.wrappedValue.dismiss()
            })
        }
    }
    
    // Single device preview (small widget)
    private func singleDevicePreview(device: Device) -> some View {
        ZStack {
            Color.accentColor.opacity(0.1)
            
            VStack(spacing: 8) {
                Text(device.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(formattedTime(device.totalTime()))
                    .font(.system(.title3, design: .monospaced))
                    .foregroundColor(device.isRunning ? .accentColor : .primary)
                
                Button(action: {
                    // Create a copy of the device to avoid directy mutation
                    var updatedDevice = device
                    deviceManager.toggleTimer(for: updatedDevice)
                }) {
                    Text(device.isRunning ? "Stop" : "Start")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 4)
                        .background(device.isRunning ? Color.red : Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(8)
                }
                
                if device.isRunning {
                    HStack(spacing: 4) {
                        Image(systemName: "timer.circle.fill")
                        Text("Active")
                    }
                    .font(.caption2)
                    .foregroundColor(.accentColor)
                }
            }
            .padding()
        }
    }
    
    // Multiple devices preview (medium/large widget)
    private func multipleDevicesPreview(devices: [Device]) -> some View {
        ZStack {
            Color.accentColor.opacity(0.1)
            
            if devices.isEmpty {
                emptyDevicePreview()
            } else {
                VStack(alignment: .leading, spacing:.zero) {
                    Text("OrthoTimeTracker")
                        .font(.caption)
                        .foregroundColor(.secondary)
                        .padding(.horizontal)
                        .padding(.top, 8)
                        .padding(.bottom, 4)
                    
                    Divider()
                    
                    ScrollView {
                        VStack(spacing: 0) {
                            ForEach(devices) { device in
                                deviceRowPreview(device: device)
                                
                                if device.id != devices.last?.id {
                                    Divider()
                                        .padding(.leading)
                                }
                            }
                        }
                    }
                }
            }
        }
    }
    
    // Device row for multiple devices preview
    private func deviceRowPreview(device: Device) -> some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(device.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(formattedTime(device.totalTime()))
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(device.isRunning ? .accentColor : .primary)
            }
            
            Spacer()
            
            if device.isRunning {
                Image(systemName: "timer.circle.fill")
                    .foregroundColor(.accentColor)
            }
            
            Button(action: {
                deviceManager.toggleTimer(for: device)
            }) {
                Text(device.isRunning ? "Stop" : "Start")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 8)
                    .padding(.vertical, 4)
                    .background(device.isRunning ? Color.red : Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(8)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
    
    // Empty state for when no devices exist
    private func emptyDevicePreview() -> some View {
        VStack(spacing: 8) {
            Image(systemName: "timer.circle")
                .font(.system(size: 28))
                .foregroundColor(Color.accentColor.opacity(0.5))
            
            Text("No Devices")
                .font(.headline)
            
            Text("Add devices in the app")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
    
    // Time formatting helper
    private func formattedTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) / 60 % 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}