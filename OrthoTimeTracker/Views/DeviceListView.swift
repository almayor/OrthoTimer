import SwiftUI
import OrthoTimeTrackerCore

// Widget preview content that can be presented in a sheet
// Defined directly in this file to avoid import issues
struct WidgetPreviewContent: View {
    @ObservedObject var deviceManager: OTTDeviceManager // Changed to match the Core package type
    @Environment(\.presentationMode) var presentationMode
    
    // Use a timer to update the view
    @State private var timer: Timer?
    @State private var currentTime = Date()
    
    var body: some View {
        // Setup the timer when view appears, clean up when it disappears
        let _ = VStack {
            Text("").onAppear {
                // Create the timer when view appears
                self.timer = Timer.scheduledTimer(withTimeInterval: 1.0, repeats: true) { _ in
                    self.currentTime = Date()  // Update the time to trigger view refresh
                }
                // Make sure timer runs even when scrolling
                if let timer = self.timer {
                    RunLoop.current.add(timer, forMode: .common)
                }
            }
            .onDisappear {
                // Clean up timer when view disappears
                self.timer?.invalidate()
                self.timer = nil
            }
        }
        
        NavigationView {
            ScrollView {
                VStack(spacing: 20) {
                    // This empty Text view updates with the currentTime to force refresh
                    Text("")
                        .hidden()
                        .id(currentTime.timeIntervalSince1970)
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
    private func singleDevicePreview(device: OTTDevice) -> some View {
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
                    deviceManager.toggleTimer(for: device)
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
    private func multipleDevicesPreview(devices: [OTTDevice]) -> some View {
        ZStack {
            Color.accentColor.opacity(0.1)
            
            if devices.isEmpty {
                emptyDevicePreview()
            } else {
                VStack(alignment: .leading, spacing: 0) {
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
    private func deviceRowPreview(device: OTTDevice) -> some View {
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

struct DeviceListView: View {
    @EnvironmentObject private var deviceManager: OTTDeviceManager
    @State private var showingAddDevice = false
    @State private var newDeviceName = ""
    @State private var deviceToDelete: IndexSet?
    @State private var showingDeleteConfirmation = false
    @State private var showingWidgetPreview = false
    
    // Helper function to create a widget preview
    private func showWidgetPreview() {
        showingWidgetPreview = true
    }
    
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
                
                ToolbarItem(placement: .navigationBarLeading) {
                    Button(action: {
                        showWidgetPreview()
                    }) {
                        Label("Widgets", systemImage: "viewfinder")
                    }
                }
            }
            // Custom sheet presentation for widget preview
            .sheet(isPresented: $showingWidgetPreview) {
                WidgetPreviewContent(deviceManager: deviceManager)
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
    let device: OTTDevice
    @EnvironmentObject private var deviceManager: OTTDeviceManager
    
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
            .environmentObject(OTTDeviceManager())
    }
}
