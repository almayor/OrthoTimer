import SwiftUI
import OrthoTimeTrackerCore
import AppKit
import Combine

// Global state manager for edit mode
final class EditModeManager {
    static let shared = EditModeManager()
    
    // Publisher for edit mode changes
    let editModeSubject = PassthroughSubject<Bool, Never>()
    
    // Called when device selection changes
    func deviceSelectionChanged() {
        // Cancel any active editing
        editModeSubject.send(false)
    }
}

struct ContentView: View {
    @EnvironmentObject private var deviceManager: OTTDeviceManager
    @State private var selectedDeviceID: UUID?
    @State private var previousDeviceID: UUID? // To track device selection changes
    @State private var showingAddDevice = false
    @State private var newDeviceName = ""
    
    var body: some View {
        NavigationSplitView {
            VStack {
                // When selection changes, notify the edit mode manager
                List(selection: Binding(
                    get: { self.selectedDeviceID },
                    set: { newValue in
                        // Check if selection actually changed
                        if newValue != self.selectedDeviceID {
                            // Cancel edit mode when selection changes
                            EditModeManager.shared.deviceSelectionChanged()
                        }
                        self.selectedDeviceID = newValue
                    }
                )) {
                    ForEach(deviceManager.devices) { device in
                        DeviceRow(device: device, selection: $selectedDeviceID)
                            .tag(device.id)
                    }
                    .onDelete(perform: deleteDevices)
                }
                
                // Add Device button at the bottom of the left pane
                Button(action: { showingAddDevice = true }) {
                    HStack {
                        Image(systemName: "plus.circle.fill")
                        Text("Add Device")
                    }
                    .frame(maxWidth: .infinity)
                    .padding(.vertical, 8)
                }
                .buttonStyle(.borderedProminent)
                .padding([.horizontal, .bottom], 12)
            }
            .navigationTitle("Orthodontic Devices")
            // Removed from toolbar since we now have a dedicated button
            .sheet(isPresented: $showingAddDevice) {
                VStack(spacing: 20) {
                    Text("Add New Device")
                        .font(.headline)
                    
                    // Use our custom text field component
                    CustomTextField(text: $newDeviceName)
                        .frame(width: 250, height: 30)
                        .padding(.vertical, 4)
                    
                    HStack {
                        Button("Cancel") {
                            showingAddDevice = false
                            newDeviceName = ""
                        }
                        
                        Button("Add") {
                            if !newDeviceName.isEmpty {
                                deviceManager.addDevice(name: newDeviceName)
                                newDeviceName = ""
                                showingAddDevice = false
                            }
                        }
                        .disabled(newDeviceName.isEmpty)
                    }
                    .padding(.top)
                }
                .padding()
                .frame(width: 300, height: 220) // Increased height to provide more space
            }
        } detail: {
            if let selectedDeviceID = selectedDeviceID,
               let device = deviceManager.devices.first(where: { $0.id == selectedDeviceID }) {
                DeviceDetailView(device: device)
            } else {
                Text("Select a device")
                    .font(.title)
                    .foregroundColor(.secondary)
            }
        }
    }
    
    private func deleteDevices(at offsets: IndexSet) {
        deviceManager.deleteDevice(at: offsets)
    }
}

struct DeviceRow: View {
    let device: OTTDevice
    @EnvironmentObject private var deviceManager: OTTDeviceManager
    
    // Get the current selection from list
    @Binding var selection: UUID?
    
    var body: some View {
        // Observe timestamp changes
        let _ = deviceManager.currentTimestamp
        
        // Get the latest device data
        let currentDevice = deviceManager.devices.first(where: { $0.id == device.id }) ?? device
        
        // Check if this row is selected
        let isSelected = selection == currentDevice.id
        
        return HStack {
            VStack(alignment: .leading) {
                Text(currentDevice.name)
                    .font(.headline)
                
                Text(TimeUtils.formattedTime(currentDevice.totalTime()))
                    .font(.subheadline)
                    .fontWeight(currentDevice.isRunning ? .bold : .regular) 
                    // Use different color based on selection state
                    .foregroundColor(isSelected 
                        ? (currentDevice.isRunning ? .white : .primary) // Selected: white when active
                        : (currentDevice.isRunning ? Color(red: 0.0, green: 0.3, blue: 0.7) : .secondary)) // Not selected: dark blue when active
            }
            
            Spacer()
            
            if currentDevice.isRunning {
                Image(systemName: "timer.circle.fill")
                    .foregroundColor(isSelected ? .white : Color(red: 0.0, green: 0.3, blue: 0.7))
            }
        }
        .padding(.vertical, 4)
    }
}

