import WidgetKit
import SwiftUI
import CloudKit

// This is a placeholder for future widget implementation
struct TimeTrackerWidgetEntryView: View {
    var entry: SimpleEntry

    var body: some View {
        VStack {
            Text(entry.device?.name ?? "No Device")
                .font(.headline)
            
            if let device = entry.device {
                Text(TimeUtils.formattedTime(device.totalTime()))
                    .font(.system(.title2, design: .monospaced))
                    .foregroundColor(device.isRunning ? .green : .primary)
                
                if device.isRunning {
                    HStack {
                        Image(systemName: "timer")
                        Text("Active")
                    }
                    .foregroundColor(.green)
                }
            } else {
                Text("00:00:00")
                    .font(.system(.title2, design: .monospaced))
            }
        }
        .padding()
    }
}

struct SimpleEntry: TimelineEntry {
    let date: Date
    let device: Device?
}

// Note: Actual widget implementation will be added in the future
