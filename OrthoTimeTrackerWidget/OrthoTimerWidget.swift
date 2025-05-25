import WidgetKit
import SwiftUI
import CloudKit
import OrthoTimeTrackerCore

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), devices: [sampleDevice()])
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), devices: [sampleDevice()])
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        // Use CloudKit for real devices
        fetchDevices { fetchedDevices in
            let currentDate = Date()
            
            let devices = fetchedDevices.isEmpty ? [self.sampleDevice()] : fetchedDevices
            
            // Create a timeline with updates every minute
            let entries = self.createTimelineEntries(startDate: currentDate, devices: devices)
            let timeline = Timeline(entries: entries, policy: .atEnd)
            
            completion(timeline)
        }
    }
    
    // Sample device for previews and placeholders
    private func sampleDevice() -> OTTDevice {
        var device = OTTDevice(name: "Retainer")
        device.totalTimeToday = 3600 * 2 + 35 * 60 // 2h 35m
        device.sessionStartTime = Date() // Active
        return device
    }
    
    // Create entries for the next hour, updating every minute
    private func createTimelineEntries(startDate: Date, devices: [OTTDevice]) -> [SimpleEntry] {
        var entries: [SimpleEntry] = []
        let calendar = Calendar.current
        
        // Create entries for the next hour, one per minute
        for minuteOffset in 0..<60 {
            let entryDate = calendar.date(byAdding: .minute, value: minuteOffset, to: startDate)!
            var updatedDevices: [OTTDevice] = []
            
            // Update time calculations for each future entry if timer is running
            for device in devices {
                var updatedDevice = device
                if device.isRunning {
                    let futureTimeInterval = entryDate.timeIntervalSince(startDate)
                    updatedDevice.totalTimeToday += futureTimeInterval
                }
                updatedDevices.append(updatedDevice)
            }
            
            entries.append(SimpleEntry(date: entryDate, devices: updatedDevices))
        }
        
        return entries
    }
    
    // Fetch devices from CloudKit
    private func fetchDevices(completion: @escaping ([OTTDevice]) -> Void) {
        let container = CKContainer.default()
        let privateDB = container.privateCloudDatabase
        let query = CKQuery(recordType: "Device", predicate: NSPredicate(value: true))
        
        privateDB.perform(query, inZoneWith: nil) { results, error in
            if let error = error {
                print("Error fetching widget data: \(error.localizedDescription)")
                completion([])
                return
            }
            
            let devices = results?.compactMap { OTTDevice.fromCKRecord($0) } ?? []
            completion(devices)
        }
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let devices: [OTTDevice]
}

struct OrthoTimeTrackerWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var widgetFamily
    
    var body: some View {
        switch widgetFamily {
        case .systemSmall:
            if let device = entry.devices.first {
                SingleDeviceWidgetView(device: device)
            } else {
                EmptyDeviceView()
            }
        case .systemMedium, .systemLarge:
            MultipleDevicesWidgetView(devices: entry.devices)
        default:
            if let device = entry.devices.first {
                SingleDeviceWidgetView(device: device)
            } else {
                EmptyDeviceView()
            }
        }
    }
}

struct SingleDeviceWidgetView: View {
    var device: OTTDevice
    
    var body: some View {
        ZStack {
            Color.accentColor.opacity(0.1)
            
            VStack(spacing: 10) {
                Text(device.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(TimeUtils.formattedTime(device.totalTime()))
                    .font(.system(.title2, design: .monospaced))
                    .foregroundColor(device.isRunning ? .accentColor : .primary)
                
                // Button to toggle timer state
                Link(destination: URL(string: "orthotimer://toggle/\(device.id.uuidString)")!) {
                    Text(device.isRunning ? "Stop" : "Start")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(device.isRunning ? Color.red : Color.accentColor)
                        .foregroundColor(.white)
                        .cornerRadius(12)
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
}

struct MultipleDevicesWidgetView: View {
    var devices: [OTTDevice]
    
    var body: some View {
        ZStack {
            Color.accentColor.opacity(0.1)
            
            if devices.isEmpty {
                EmptyDeviceView()
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
                                DeviceRowWidgetView(device: device)
                                
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
}

struct DeviceRowWidgetView: View {
    var device: OTTDevice
    
    var body: some View {
        HStack(spacing: 12) {
            VStack(alignment: .leading, spacing: 4) {
                Text(device.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(TimeUtils.formattedTime(device.totalTime()))
                    .font(.system(.body, design: .monospaced))
                    .foregroundColor(device.isRunning ? .accentColor : .primary)
            }
            
            Spacer()
            
            if device.isRunning {
                Image(systemName: "timer.circle.fill")
                    .foregroundColor(.accentColor)
            }
            
            // Button to toggle timer state
            Link(destination: URL(string: "orthotimer://toggle/\(device.id.uuidString)")!) {
                Text(device.isRunning ? "Stop" : "Start")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(device.isRunning ? Color.red : Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
            }
        }
        .padding(.horizontal)
        .padding(.vertical, 8)
    }
}

struct EmptyDeviceView: View {
    var body: some View {
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
}

struct OrthoTimerWidget: Widget {
    let kind: String = "OrthoTimerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            if #available(iOS 17.0, *) {
                OrthoTimeTrackerWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                OrthoTimeTrackerWidgetEntryView(entry: entry)
                    .padding()
                    .background()
            }
        }
        .configurationDisplayName("OrthoTimer")
        .description("Track your orthodontic device wear time.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// Using OTTDevice from OrthoTimeTrackerCore instead of local Device model
