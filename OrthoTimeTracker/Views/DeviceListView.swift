import SwiftUI

struct DeviceListView: View {
    @EnvironmentObject private var deviceManager: DeviceManager
    @State private var showingAddDevice = false
    @State private var newDeviceName = ""
    @State private var deviceToDelete: IndexSet?
    @State private var showingDeleteConfirmation = false
    
    var body: some View {
        NavigationView {
            List {
                ForEach(deviceManager.devices) { device in
                    NavigationLink(destination: DeviceDetailView(device: device)) {
                        DeviceRowView(device: device)
                    }
                }
                .onDelete { indexSet in
                    deviceToDelete = indexSet
                    showingDeleteConfirmation = true
                }
            }
            .navigationTitle("My Devices")
            .toolbar {
                ToolbarItem(placement: .navigationBarTrailing) {
                    Button(action: {
                        showingAddDevice = true
                    }) {
                        Label("Add Device", systemImage: "plus")
                    }
                }
            }
            .alert("Add New Device", isPresented: $showingAddDevice) {
                TextField("Device Name", text: $newDeviceName)
                Button("Cancel", role: .cancel) {
                    newDeviceName = ""
                }
                Button("Add") {
                    if !newDeviceName.isEmpty {
                        deviceManager.addDevice(name: newDeviceName)
                        newDeviceName = ""
                    }
                }
            }
            .confirmationDialog(
                "Are you sure you want to delete this device?",
                isPresented: $showingDeleteConfirmation,
                titleVisibility: .visible
            ) {
                Button("Delete", role: .destructive) {
                    if let indexSet = deviceToDelete {
                        deviceManager.deleteDevice(at: indexSet)
                        deviceToDelete = nil
                    }
                }
                Button("Cancel", role: .cancel) {
                    deviceToDelete = nil
                }
            }
        }
    }
}

struct DeviceRowView: View {
    let device: Device
    @EnvironmentObject private var deviceManager: DeviceManager
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(device.name)
                    .font(.headline)
                
                // Using the currentTimestamp from DeviceManager ensures this updates every second
                Text(TimeUtils.formattedTime(device.totalTime()))
                    .font(.subheadline)
                    .foregroundColor(device.isRunning ? .accentColor : .secondary)
            }
            
            Spacer()
            
            if device.isRunning {
                Image(systemName: "timer")
                    .foregroundColor(.accentColor)
            }
        }
    }
}

struct DeviceListView_Previews: PreviewProvider {
    static var previews: some View {
        DeviceListView()
            .environmentObject(DeviceManager())
    }
}
