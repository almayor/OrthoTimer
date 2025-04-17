import SwiftUI
import OrthoTimeTrackerCore

struct ContentView: View {
    @EnvironmentObject private var deviceManager: OTTDeviceManager
    @State private var selectedDeviceID: UUID?
    @State private var showingAddDevice = false
    @State private var newDeviceName = ""
    
    var body: some View {
        NavigationSplitView {
            List(selection: $selectedDeviceID) {
                ForEach(deviceManager.devices) { device in
                    DeviceRow(device: device, selection: $selectedDeviceID)
                        .tag(device.id)
                }
                .onDelete(perform: deleteDevices)
            }
            .navigationTitle("Orthodontic Devices")
            .toolbar {
                ToolbarItem(placement: .primaryAction) {
                    Button(action: { showingAddDevice = true }) {
                        Label("Add Device", systemImage: "plus")
                    }
                }
            }
            .sheet(isPresented: $showingAddDevice) {
                VStack(spacing: 20) {
                    Text("Add New Device")
                        .font(.headline)
                    
                    TextField("Device Name", text: $newDeviceName)
                        .textFieldStyle(RoundedBorderTextFieldStyle())
                        .frame(width: 250)
                    
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
                .frame(width: 300, height: 200)
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