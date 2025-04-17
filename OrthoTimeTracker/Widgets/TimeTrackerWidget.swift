import WidgetKit
import SwiftUI
import CloudKit
import OrthoTimeTrackerCore

// MARK: - Widget Configuration

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), devices: [sampleDevice()])
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), devices: [sampleDevice()])
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        fetchDevices { fetchedDevices in
            let currentDate = Date()
            
            // Create a timeline with updates every minute
            let entries = createTimelineEntries(startDate: currentDate, devices: fetchedDevices)
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

// MARK: - Widget Views

struct TimeTrackerWidgetEntryView: View {
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
            Color("AccentColor").opacity(0.1)
            
            VStack(spacing: 10) {
                Text(device.name)
                    .font(.headline)
                    .lineLimit(1)
                
                Text(TimeUtils.formattedTime(device.totalTime()))
                    .font(.system(.title2, design: .monospaced))
                    .foregroundColor(device.isRunning ? Color("AccentColor") : .primary)
                
                // Button to toggle timer state
                Link(destination: URL(string: "orthotimetracker://toggle/\(device.id.uuidString)")!) {
                    Text(device.isRunning ? "Stop" : "Start")
                        .font(.caption)
                        .fontWeight(.medium)
                        .padding(.horizontal, 16)
                        .padding(.vertical, 6)
                        .background(device.isRunning ? Color.red : Color("AccentColor"))
                        .foregroundColor(.white)
                        .cornerRadius(12)
                }
                
                if device.isRunning {
                    HStack(spacing: 4) {
                        Image(systemName: "timer.circle.fill")
                        Text("Active")
                    }
                    .font(.caption2)
                    .foregroundColor(Color("AccentColor"))
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
            Color("AccentColor").opacity(0.1)
            
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
                    .foregroundColor(device.isRunning ? Color("AccentColor") : .primary)
            }
            
            Spacer()
            
            if device.isRunning {
                Image(systemName: "timer.circle.fill")
                    .foregroundColor(Color("AccentColor"))
            }
            
            // Button to toggle timer state
            Link(destination: URL(string: "orthotimetracker://toggle/\(device.id.uuidString)")!) {
                Text(device.isRunning ? "Stop" : "Start")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 12)
                    .padding(.vertical, 4)
                    .background(device.isRunning ? Color.red : Color("AccentColor"))
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
                .foregroundColor(Color("AccentColor").opacity(0.5))
            
            Text("No Devices")
                .font(.headline)
            
            Text("Add devices in the app")
                .font(.caption)
                .foregroundColor(.secondary)
        }
        .padding()
    }
}

// MARK: - Widget Definition

struct TimeTrackerWidget: Widget {
    let kind: String = "TimeTrackerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(kind: kind, provider: Provider()) { entry in
            TimeTrackerWidgetEntryView(entry: entry)
        }
        .configurationDisplayName("Device Tracker")
        .description("Track your orthodontic device wear time.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// MARK: - Widget Previews

struct TimeTrackerWidget_Previews: PreviewProvider {
    static var previews: some View {
        let sampleDevices = [
            OTTDevice(name: "Retainer", totalTimeToday: 7200, sessionStartTime: Date()),
            OTTDevice(name: "Invisalign", totalTimeToday: 14400),
            OTTDevice(name: "Nightguard", totalTimeToday: 3600, sessionStartTime: Date())
        ]
        let entry = SimpleEntry(date: Date(), devices: sampleDevices)
        
        Group {
            TimeTrackerWidgetEntryView(entry: SimpleEntry(date: Date(), devices: [sampleDevices[0]]))
                .previewContext(WidgetPreviewContext(family: .systemSmall))
                .previewDisplayName("Small - Single Device")
            
            TimeTrackerWidgetEntryView(entry: entry)
                .previewContext(WidgetPreviewContext(family: .systemMedium))
                .previewDisplayName("Medium - Multiple Devices")
        }
    }
}
