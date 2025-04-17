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
    @State private var currentTime: TimeInterval = 0
    
    var body: some View {
        HStack {
            VStack(alignment: .leading) {
                Text(device.name)
                    .font(.headline)
                Text(formattedTime(device.totalTime()))
                    .font(.subheadline)
                    .foregroundColor(device.isRunning ? .green : .secondary)
            }
            
            Spacer()
            
            if device.isRunning {
                Image(systemName: "timer")
                    .foregroundColor(.green)
            }
        }
    }
    
    private func formattedTime(_ timeInterval: TimeInterval) -> String {
        let hours = Int(timeInterval) / 3600
        let minutes = Int(timeInterval) / 60 % 60
        let seconds = Int(timeInterval) % 60
        return String(format: "%02d:%02d:%02d", hours, minutes, seconds)
    }
}

struct DeviceListView_Previews: PreviewProvider {
    static var previews: some View {
        DeviceListView()
            .environmentObject(DeviceManager())
    }
}
