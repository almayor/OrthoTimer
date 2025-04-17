import SwiftUI
import AppKit
import OrthoTimeTrackerCore

struct MenuBarView: View {
    @EnvironmentObject private var deviceManager: OTTDeviceManager
    @EnvironmentObject private var menuBarManager: OTTMenuBarManager
    @Environment(\.openWindow) private var openWindow
    
    var body: some View {
        VStack(alignment: .leading, spacing: 12) {
            Text("OrthoTimeTracker")
                .font(.headline)
                .padding(.bottom, 5)
            
            // Device selection
            Picker("Device", selection: Binding(
                get: { self.menuBarManager.selectedDevice?.id },
                set: { newValue in
                    self.menuBarManager.selectedDevice = self.deviceManager.devices.first(where: { $0.id == newValue })
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
                    Text(TimeUtils.formattedTime(device.totalTime()))
                        .font(.system(.title, design: .monospaced))
                        .foregroundColor(device.isRunning ? .accentColor : .primary)
                    
                    HStack(spacing: 20) {
                        Button(action: {
                            deviceManager.toggleTimer(for: device)
                        }) {
                            Text(device.isRunning ? "Stop" : "Start")
                                .frame(width: 80)
                        }
                        .buttonStyle(.borderedProminent)
                        .tint(device.isRunning ? .red : .accentColor)
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
            
            // Command buttons
            Button("Open Main Window") {
                NSApp.activate(ignoringOtherApps: true)
                openWindow(id: "OrthoTimeTracker")
            }
            
            Button("Quit") {
                NSApp.terminate(nil)
            }
        }
        .padding()
        .frame(width: 250)
    }
}