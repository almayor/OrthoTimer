# OrthoTimeTracker

A simple iOS app for tracking the time you wear your orthodontic devices.

## Features

- Track multiple devices with individual timers
- Real-time stopwatch display
- Daily, weekly, and monthly statistics
- CloudKit integration for data persistence across devices
- Automatic timer reset at midnight
- Clean, intuitive interface

## Future Enhancements

- Home screen and lock screen widgets showing current timer status
- Notifications for wear time reminders
- More detailed statistics and charts
- Wear time goals and achievements

## Requirements

- iOS 15.0+
- Xcode 13.0+
- Apple Developer account for CloudKit functionality

## Setup

1. Clone the repository
2. Open the project in Xcode
3. Update the bundle identifier and team in project settings
4. Update the CloudKit container identifier in the entitlements file
5. Build and run on your device

## Usage

- Add new devices from the device list screen
- Tap a device to view details and control its timer
- Long press a device in the list to delete it
- Edit device names by tapping the pencil icon in the device detail screen
