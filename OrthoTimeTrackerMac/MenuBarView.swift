import SwiftUI
import AppKit
import OrthoTimeTrackerCore

struct MenuBarView: View {
    @EnvironmentObject private var deviceManager: OTTDeviceManager
    @EnvironmentObject private var menuBarManager: OTTMenuBarManager
    
    // Timer for refreshing the UI
    @State private var refreshTimer = Date()
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("OrthoTimeTracker")
                .font(.headline)
                .padding(.bottom, 5)
            
            // Device selection
            Picker("Device", selection: Binding(
                get: { self.menuBarManager.selectedDevice?.id },
                set: { newValue in
                    if let id = newValue, 
                       let device = self.deviceManager.devices.first(where: { $0.id == id }) {
                        self.menuBarManager.selectedDevice = device
                    } else {
                        self.menuBarManager.selectedDevice = nil
                    }
                }
            )) {
                Text("Select a device").tag(nil as UUID?)
                
                ForEach(deviceManager.devices) { device in
                    Text(device.name).tag(device.id as UUID?)
                }
            }
            .labelsHidden()
            
            // Active timer display
            if let device = menuBarManager.selectedDevice {
                VStack(alignment: .center, spacing: 5) {
                    // Use DeviceManager's timestamp to stay in sync
                    Text("")
                        .hidden()
                        .onReceive(deviceManager.$currentTimestamp) { _ in
                            // This ensures we update exactly when the device manager does
                            menuBarManager.updateTimerText()
                        }
                    
                    // Always get the latest time - with a darker color for better readability
                    Text(menuBarManager.currentTimeForSelectedDevice())
                        .font(.system(.title, design: .monospaced))
                        .foregroundColor(device.isRunning ? Color(red: 0.0, green: 0.3, blue: 0.7) : .primary)
                        .fontWeight(device.isRunning ? .bold : .regular)
                    
                    HStack(spacing: 20) {
                        Button(action: {
                            // Always get the fresh device before toggling
                            if let deviceId = menuBarManager.selectedDevice?.id,
                               let freshDevice = deviceManager.devices.first(where: { $0.id == deviceId }) {
                                deviceManager.toggleTimer(for: freshDevice)
                                menuBarManager.updateTimerText()
                            }
                        }) {
                            Text(device.isRunning ? "Stop" : "Start")
                                .frame(width: 80)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(device.isRunning ? .red : Color(red: 0.0, green: 0.3, blue: 0.7))
                    }
                    .padding(.top, 5)
                }
                .frame(width: 220)
                .padding(.vertical, 10)
            } else {
                Text("No device selected")
                    .foregroundColor(.secondary)
                    .padding(.vertical, 10)
            }
            
            Divider()
            
            // Command buttons side by side
            HStack(spacing: 10) {
                Button("Open Main Window") {
                    // Simply notify the app delegate to handle window opening
                    NotificationCenter.default.post(
                        name: NSNotification.Name("OpenMainWindow"), 
                        object: nil
                    )
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
                
                Spacer()
                
                Button("Quit") {
                    NSApp.terminate(nil)
                }
                .buttonStyle(.bordered)
                .controlSize(.small)
            }
            .padding(.top, 5)
        }
        .padding()
        .frame(width: 250)
        .onAppear {
            // Force an update when the menu appears
            menuBarManager.updateTimerText()
            
            // Auto-select if there's only one device
            if deviceManager.devices.count == 1 && menuBarManager.selectedDevice == nil {
                menuBarManager.selectedDevice = deviceManager.devices[0]
            }
        }
    }
}