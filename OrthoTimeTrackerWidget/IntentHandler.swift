import Intents
import CloudKit
import OrthoTimeTrackerCore

class IntentHandler: INExtension {
    override func handler(for intent: INIntent) -> Any {
        if intent is SelectDeviceIntent {
            return DeviceSelectionIntentHandler()
        }
        
        return self
    }
}

class DeviceSelectionIntentHandler: NSObject, SelectDeviceIntentHandling {
    func provideDeviceIdOptions(for intent: SelectDeviceIntent, with completion: @escaping ([DeviceIdObject]?, Error?) -> Void) {
        // Fetch devices from CloudKit
        fetchDevices { devices in
            let deviceOptions = devices.map { device -> DeviceIdObject in
                let option = DeviceIdObject(identifier: device.id.uuidString, display: device.name)
                option.deviceName = device.name
                option.deviceId = device.id.uuidString
                return option
            }
            
            completion(deviceOptions, nil)
        }
    }
    
    private func fetchDevices(completion: @escaping ([OTTDevice]) -> Void) {
        let container = CKContainer.default()
        let privateDB = container.privateCloudDatabase
        let query = CKQuery(recordType: "Device", predicate: NSPredicate(value: true))
        
        privateDB.perform(query, inZoneWith: nil) { results, error in
            if let error = error {
                print("Intent handler error fetching devices: \(error.localizedDescription)")
                // Return empty array in case of error
                completion([])
                return
            }
            
            let devices = results?.compactMap { OTTDevice.fromCKRecord($0) } ?? []
            completion(devices)
        }
    }
}