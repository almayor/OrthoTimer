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
                    DeviceRow(device: device)
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
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(device.name)
                    .font(.headline)
                
                Text(TimeUtils.formattedTime(device.totalTime()))
                    .font(.subheadline)
                    .foregroundColor(device.isRunning ? .accentColor : .secondary)
            }
            
            Spacer()
            
            if device.isRunning {
                Image(systemName: "timer.circle.fill")
                    .foregroundColor(.accentColor)
            }
        }
        .padding(.vertical, 4)
    }
}