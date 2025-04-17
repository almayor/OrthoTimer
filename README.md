# OrthoTimeTracker

A suite of applications for tracking orthodontic device wear time.

## Features

- Track multiple orthodontic devices (retainers, invisalign, etc.)
- Real-time wear time tracking
- Daily wear statistics with automatic midnight reset
- Weekly and monthly historical data
- Notifications for wear time reminders
- iOS and macOS apps with data syncing via CloudKit
- iOS home screen widgets
- macOS menu bar integration
- Custom orthodontist-themed app icon (tooth with braces and timer)

## Project Structure

- **OrthoTimeTracker/** - iOS app
  - Views/ - iOS app views
  - Widgets/ - iOS widget implementation
 
- **OrthoTimeTrackerMac/** - macOS app
  - Menu bar integration
  - macOS-specific views

- **OrthoTimeTrackerCore/** - Shared Swift Package
  - Models/ - Core data models (Device)
  - ViewModels/ - Shared view models (DeviceManager, MenuBarManager)
  - Utils/ - Utility functions and time formatting

- **OrthoTimeTrackerWidget/** - iOS widget extension

## Requirements

- iOS 16.0+ / macOS 13.0+
- Xcode 14.0+
- Swift 5.0+
- Apple Developer Account for CloudKit access

## Setup

1. Clone the repository
2. Open OrthoTimeTracker.xcodeproj in Xcode
3. Update the bundle identifier and team in project settings
4. Build both the iOS and macOS targets

## Usage

### iOS App
- Add new devices from the device list screen
- Tap a device to view details and control its timer
- Long press a device in the list to delete it
- Edit device names by tapping the pencil icon in the device detail screen

### macOS App
- Control device timers from the menu bar
- Open the main window for a full view of all devices and statistics
- Sync data seamlessly with the iOS app via CloudKit

## Data Persistence

The app uses CloudKit for data persistence, allowing seamless syncing between iOS and macOS apps. In the simulator, sample data is used instead.

## Troubleshooting

If you encounter build issues:
1. Make sure the OrthoTimeTrackerCore package is properly added as a dependency to both targets
2. Clean the build folder (Shift+Cmd+K) and rebuild
3. Verify that the Swift Package Manager dependencies are properly resolved

If app icons don't appear immediately:
1. Delete the app from the simulator/device first
2. Clean the build folder (Shift+Cmd+K)
3. Rebuild the app - icons may take a couple of simulator launches to appear due to caching

## Menu Bar Integration

The macOS app includes a menu bar integration that allows you to:
- See the currently active timer at a glance
- Start and stop device timers
- Quickly open the main window
- Access all your devices without keeping the main window open

The menu bar displays the timer with color coding:
- Blue: Device timer is active
- White/Default: Device timer is inactive