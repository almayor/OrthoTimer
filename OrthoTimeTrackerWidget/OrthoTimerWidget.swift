import WidgetKit
import SwiftUI
import CloudKit
import OrthoTimeTrackerCore

struct Provider: TimelineProvider {
    func placeholder(in context: Context) -> SimpleEntry {
        SimpleEntry(date: Date(), devices: [sampleDevice()], relevance: nil)
    }

    func getSnapshot(in context: Context, completion: @escaping (SimpleEntry) -> ()) {
        let entry = SimpleEntry(date: Date(), devices: [sampleDevice()], relevance: nil)
        completion(entry)
    }

    func getTimeline(in context: Context, completion: @escaping (Timeline<Entry>) -> ()) {
        #if targetEnvironment(simulator)
        // For simulator testing, use sample data
        let devices = [sampleDevice()]
        let currentDate = Date()
        let entries = createTimelineEntries(
            startDate: currentDate,
            devices: devices
        )
        let timeline = Timeline(entries: entries, policy: .atEnd)
        completion(timeline)
        #else
        // Use CloudKit for real devices
        fetchDevices { fetchedDevices in
            let currentDate = Date()
            
            let devices = fetchedDevices.isEmpty ? [self.sampleDevice()] : fetchedDevices
            
            // Create a timeline with updates every minute
            let entries = self.createTimelineEntries(
                startDate: currentDate,
                devices: devices
            )
            let timeline = Timeline(entries: entries, policy: .after(Date().addingTimeInterval(5 * 60))) // Update every 5 minutes
            
            completion(timeline)
        }
        #endif
    }
    
    // Sample device for previews and placeholders
    private func sampleDevice() -> OTTDevice {
        var device = OTTDevice(name: "Retainer")
        device.totalTimeToday = 3600 * 2 + 35 * 60 // 2h 35m
        device.sessionStartTime = Date() // Active
        return device
    }
    
    // Create entries for the next hour, updating every minute
    private func createTimelineEntries(
        startDate: Date,
        devices: [OTTDevice]
    ) -> [SimpleEntry] {
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
            
            // Create widget relevance score based on active device
            var relevance: TimelineEntryRelevance? = nil
            if let activeDevice = updatedDevices.first(where: { $0.isRunning }) {
                relevance = TimelineEntryRelevance(score: 100)
            }
            
            entries.append(SimpleEntry(
                date: entryDate, 
                devices: updatedDevices,
                relevance: relevance
            ))
        }
        
        return entries
    }
    
    // Fetch devices from CloudKit
    private func fetchDevices(completion: @escaping ([OTTDevice]) -> Void) {
        let container = CKContainer.default()
        let privateDB = container.privateCloudDatabase
        let query = CKQuery(recordType: "Device", predicate: NSPredicate(value: true))
        
        // Add an operation timeout to ensure widget doesn't hang
        let operation = CKQueryOperation(query: query)
        operation.qualityOfService = .userInteractive  // High priority for widget
        operation.resultsLimit = 10  // Limit for performance
        
        var fetchedDevices: [OTTDevice] = []
        
        operation.recordFetchedBlock = { record in
            if let device = OTTDevice.fromCKRecord(record) {
                fetchedDevices.append(device)
            }
        }
        
        operation.queryCompletionBlock = { cursor, error in
            if let error = error {
                let ckError = error as? CKError
                let errorCode = ckError?.errorCode ?? -1
                
                print("Widget error fetching devices from CloudKit:")
                print("- Error code: \(errorCode)")
                print("- Description: \(error.localizedDescription)")
                
                // For widgets, always fall back gracefully to avoid blank widgets
                completion([])
                return
            }
            
            if fetchedDevices.isEmpty {
                print("Widget found no devices in CloudKit")
                // Return a sample device for better user experience
                completion([self.sampleDevice()])
            } else {
                print("Widget successfully loaded \(fetchedDevices.count) devices from CloudKit")
                completion(fetchedDevices)
            }
        }
        
        // Use a 5-second timeout for widget operations
        DispatchQueue.global().asyncAfter(deadline: .now() + 5) {
            operation.cancel()
            if fetchedDevices.isEmpty {
                print("Widget CloudKit operation timed out, using sample data")
                DispatchQueue.main.async {
                    completion([self.sampleDevice()])
                }
            }
        }
        
        privateDB.add(operation)
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let devices: [OTTDevice]
    let relevance: TimelineEntryRelevance?
}

struct OrthoTimeTrackerWidgetEntryView: View {
    var entry: Provider.Entry
    @Environment(\.widgetFamily) var widgetFamily
    
    var body: some View {
        let cornerRadius: CGFloat = 15
        
        ZStack {
            // Proper background with corner radius
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color(UIColor.systemBackground))
                .shadow(color: Color.accentColor.opacity(0.1), radius: 2)
            
            RoundedRectangle(cornerRadius: cornerRadius)
                .fill(Color.accentColor.opacity(0.1))
            
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
}

struct SingleDeviceWidgetView: View {
    var device: OTTDevice
    
    var body: some View {
        VStack(spacing: 6) {
            Text(device.name)
                .font(.headline)
                .lineLimit(1)
                .padding(.horizontal, 4)
            
            Text(TimeUtils.formattedTime(device.totalTime()))
                .font(.system(
                    size: UIScreen.main.bounds.width <= 155 ? 18 : 22,
                    weight: .medium,
                    design: .monospaced
                ))
                .minimumScaleFactor(0.7)
                .foregroundColor(device.isRunning ? .accentColor : .primary)
                .padding(.vertical, 2)
            
            // Button to toggle timer state
            Link(destination: URL(string: "orthotimer://toggle/\(device.id.uuidString)")!) {
                Text(device.isRunning ? "Stop" : "Start")
                    .font(.caption)
                    .fontWeight(.medium)
                    .padding(.horizontal, 14)
                    .padding(.vertical, 4)
                    .background(device.isRunning ? Color.red : Color.accentColor)
                    .foregroundColor(.white)
                    .cornerRadius(10)
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
        .padding(.horizontal, 8)
        .padding(.vertical, 10)
    }
}

struct MultipleDevicesWidgetView: View {
    var devices: [OTTDevice]
    
    var body: some View {
        if devices.isEmpty {
            EmptyDeviceView()
        } else {
            VStack(alignment: .leading, spacing: 0) {
                Text("OrthoTimer")
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
                    .minimumScaleFactor(0.8)
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

@main
struct OrthoTimerWidget: Widget {
    let kind: String = "OrthoTimerWidget"

    var body: some WidgetConfiguration {
        StaticConfiguration(
            kind: kind,
            provider: Provider()
        ) { entry in
            if #available(iOS 17.0, *) {
                OrthoTimeTrackerWidgetEntryView(entry: entry)
                    .containerBackground(.fill.tertiary, for: .widget)
            } else {
                OrthoTimeTrackerWidgetEntryView(entry: entry)
                    .padding(0)
            }
        }
        .configurationDisplayName("OrthoTimer")
        .description("Track your orthodontic device wear time.")
        .supportedFamilies([.systemSmall, .systemMedium, .systemLarge])
    }
}

// Using OTTDevice from OrthoTimeTrackerCore instead of local Device model
