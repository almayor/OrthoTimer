import SwiftUI
import OrthoTimeTrackerCore
import AppKit
import Combine

// View model to handle device detail state
class DeviceDetailViewModel: ObservableObject {
    @Published var isEditingName: Bool = false
    @Published var deviceName: String = ""
    private var originalDeviceName: String = "" // Keep track of original name
    private var cancellables = Set<AnyCancellable>()
    
    init() {
        // Subscribe to changes from EditModeManager
        EditModeManager.shared.editModeSubject
            .receive(on: RunLoop.main)
            .sink { [weak self] isEditing in
                // When selection changes, this will receive 'false'
                if !isEditing {
                    // Cancel editing without saving when switching devices
                    self?.cancelEditing()
                }
            }
            .store(in: &cancellables)
    }
    
    func resetEditState() {
        isEditingName = false
    }
    
    func startEditing(device: OTTDevice) {
        print("Starting edit for device: \(device.name)")
        deviceName = device.name
        originalDeviceName = device.name // Save original name
        isEditingName = true
    }
    
    func cancelEditing() {
        // Revert to original name without saving
        deviceName = originalDeviceName
        isEditingName = false
    }
    
    deinit {
        cancellables.forEach { $0.cancel() }
    }
}

struct DeviceDetailView: View {
    let device: OTTDevice
    @EnvironmentObject private var deviceManager: OTTDeviceManager
    @StateObject private var viewModel = DeviceDetailViewModel()
    
    // Create an ID for this view instance based on the device ID
    // This ensures the view is recreated when the device changes
    private var deviceId: String {
        return device.id.uuidString
    }
    
    // Debug helper to track changes
    private func debug(_ message: String) {
        print("DeviceDetailView: \(message)")
    }
    
    var body: some View {
        ScrollView {
            VStack(alignment: .leading, spacing: 20) {
                // Header
                HStack {
                    if viewModel.isEditingName {
                        // Using our custom text field with title font
                        CustomTextField(
                            text: $viewModel.deviceName,
                            onCommit: {
                                // Do nothing on commit, only save with button
                            },
                            font: NSFont.systemFont(ofSize: 18) // Larger title-like font size
                        )
                        .frame(height: 40)
                        
                        HStack(spacing: 8) {
                            Button("Cancel") {
                                viewModel.cancelEditing()
                            }
                            .keyboardShortcut(.escape, modifiers: [])
                            
                            Button("Save") {
                                updateDeviceName()
                            }
                            .keyboardShortcut(.return, modifiers: [])
                        }
                    } else {
                        Text(device.name)
                            .font(.largeTitle)
                            .fontWeight(.bold)
                        
                        Spacer()
                        
                        Button(action: {
                            // Start editing with the current device name
                            viewModel.startEditing(device: device)
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
        // This is the key part - use the ID to force view reset when device changes
        .id(deviceId)
        // When this view appears, reset the editing state
        .onAppear {
            viewModel.resetEditState()
        }
    }
    
    private func updateDeviceName() {
        debug("Saving name change: \(device.name) -> \(viewModel.deviceName)")
        
        if !viewModel.deviceName.isEmpty && viewModel.deviceName != device.name {
            // Create a copy of the device with the updated name
            var updatedDevice = device
            updatedDevice.name = viewModel.deviceName
            
            // Update the device in the manager
            debug("Updating device name in manager")
            deviceManager.updateDevice(updatedDevice)
        } else {
            debug("No update needed: name unchanged or empty")
        }
        
        // End editing mode
        viewModel.isEditingName = false
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