# OrthoTimeTracker Project Structure

## Overview

This project contains three main components:
1. iOS app for tracking orthodontic device wear time
2. macOS companion app with menu bar integration
3. Shared Swift Package for common code

This architecture ensures consistent data representation and logic across platforms while allowing platform-specific UI optimizations.

## Directory Structure

```
OrthoTimeTracker/
├── OrthoTimeTracker/               # iOS App
│   ├── Assets.xcassets/           # Contains app icon and other images
│   │   └── AppIcon.appiconset/    # App icon in various required sizes
│   ├── Info.plist
│   ├── OrthoTimeTrackerApp.swift   # iOS app entry point
│   ├── Views/                      # iOS-specific views
│   │   ├── DeviceDetailView.swift
│   │   ├── DeviceListView.swift
│   │   └── WidgetPreviewView.swift
│   └── Widgets/                    # iOS widget preview
│
├── OrthoTimeTrackerMac/            # macOS App
│   ├── Assets.xcassets/           # Contains app icon and other images
│   │   └── AppIcon.appiconset/    # App icon in various required sizes
│   ├── ContentView.swift           # Main window view
│   ├── DeviceDetailView.swift      # Device detail for macOS
│   ├── Info.plist
│   ├── MenuBarView.swift           # Menu bar UI
│   ├── OrthoTimeTrackerMacApp.swift # macOS app entry point
│   └── OrthoTimeTrackerMac.entitlements
│
├── OrthoTimeTrackerCore/           # Shared Swift Package
│   ├── Package.swift
│   ├── Sources/OrthoTimeTrackerCore
│   │   ├── Device.swift            # Core data model
│   │   ├── DeviceManager.swift     # Shared device management
│   │   ├── MenuBarManager.swift    # Menu bar state management
│   │   ├── OrthoTimeTrackerCore.swift # Package entry point
│   │   └── TimeUtils.swift         # Shared time utilities
│   └── Tests/OrthoTimeTrackerCoreTests
│
└── OrthoTimeTrackerWidget/         # iOS Widget Extension
    ├── Assets.xcassets/
    ├── Info.plist
    ├── OrthoTimeTrackerWidget.entitlements
    ├── OrthoTimeTrackerWidget.swift
    └── OrthoTimeTrackerWidgetBundle.swift
```

## File Responsibilities

### Shared Swift Package

- **Device.swift**: Core data model representing orthodontic devices with timing and statistics functionality
- **DeviceManager.swift**: Manages device data, timers, and CloudKit synchronization with platform-specific conditional compilation
- **TimeUtils.swift**: Time formatting and calculation utilities
- **MenuBarManager.swift**: Manages menu bar display state for macOS
- **OrthoTimeTrackerCore.swift**: Package entry point and common configuration

### iOS App

- **OrthoTimeTrackerApp.swift**: iOS app entry point
- **DeviceListView.swift**: Main list of all devices
- **DeviceDetailView.swift**: Detail view with timer and statistics for a specific device
- **WidgetPreviewView.swift**: Widget preview within the app

### macOS App

- **OrthoTimeTrackerMacApp.swift**: macOS app entry point with menu bar configuration
- **ContentView.swift**: Main window with device list and navigation
- **MenuBarView.swift**: Menu bar interface for quick device control
- **DeviceDetailView.swift**: macOS-specific detail view for devices

### iOS Widget

- **OrthoTimeTrackerWidget.swift**: Home screen widget implementation
- **OrthoTimeTrackerWidgetBundle.swift**: Widget bundle configuration

## Platform Specifics

### iOS-specific Features
- Push notifications for wear time reminders
- Widget support
- Deep linking for toggling timers from widgets

### macOS-specific Features
- Menu bar extras integration
- Menu-based device selection
- Optimized windowing for desktop use