# OrthoTimeTracker: Future Enhancements

This file tracks planned features and improvements for the OrthoTimeTracker app. These can be implemented while waiting for Apple Developer Program enrollment or as future updates.

## Widget Improvements

- [x] Fix widget installation error by removing NSExtensionPrincipalClass from Info.plist
- [x] Improve widget appearance with proper corner radius and styling
- [x] Add responsive font sizing for better readability on all widget sizes
- [x] Fix URL scheme handling for widget interactions
- [ ] Implement widget configuration for selecting specific devices
- [ ] Create different widget designs for different information displays
- [ ] Add widget family support for accessory circular and inline widgets
- [ ] Support Lock Screen widgets for iOS 16+

## UI/UX Enhancements

- [ ] Add animations and transitions for a more polished feel
- [ ] Improve layout adaptivity for different screen sizes (iPhone/iPad)
- [ ] Implement dark mode with custom color schemes
- [ ] Add haptic feedback for important actions
- [ ] Create custom tab bar or navigation styling
- [ ] Design loading states and empty states
- [ ] Improve accessibility support (VoiceOver, Dynamic Type)

## Core Functionality

- [ ] Add settings screen for app customization
  - [ ] Notification preferences (timing, types)
  - [ ] App appearance options
  - [ ] Reset data options
- [ ] Implement device categories (retainers, aligners, elastics, etc.)
- [ ] Add statistics visualization with charts/graphs
- [ ] Create weekly/monthly goals for device wear time
- [ ] Add reminders with custom schedules
- [x] Implement data export/backup functionality (currently CSV export for device data)
- [ ] Allow photo attachments for each device

## macOS Improvements

- [x] Fix menu bar timer updates in real-time
- [x] Increase default window size for better statistics visibility
- [x] Improve color scheme for better readability
- [x] Fix the device name editing issues
- [x] Ensure a device is auto-selected in the menu bar when there's only one device
- [ ] Make app run exclusively in the menu bar (no dock icon)
- [ ] Convert SVG icon to SF Symbol for better system integration
- [ ] Add keyboard shortcuts for common actions
- [ ] Create a more comprehensive statistics view
- [ ] Implement Spotlight search integration
- [ ] Add contextual menu support
- [ ] Improve menubar widget with customizable information
- [ ] Add Handoff support between iOS and macOS
- [ ] Implement Share extension

## Pre-Release Preparation

- [ ] Create onboarding screens for first-time users
- [ ] Expand test coverage with UI tests
- [ ] Prepare App Store screenshots for all device sizes
- [ ] Write compelling App Store description
- [ ] Create privacy policy
- [ ] Add app usage analytics (privacy-focused)
- [ ] Conduct beta testing with real users

## CloudKit Integration

- [ ] **HIGH PRIORITY**: Re-enable CloudKit after Apple Developer Program enrollment is approved
- [ ] Update conditional compilation to enable CloudKit on both iOS and macOS
- [ ] Configure CloudKit containers and entitlements properly
- [ ] Implement proper error handling for CloudKit operations
- [ ] Add conflict resolution for simultaneous edits
- [ ] Create sync status indicators
- [ ] Add offline mode with automatic syncing when connection returns
- [ ] Implement CloudKit sharing features (share with orthodontist)

## Long-term Vision

- [ ] Create a companion Apple Watch app
- [ ] Add reminders via Siri Shortcuts
- [ ] Implement a journal feature for orthodontic treatment notes
- [ ] Add appointment tracking with calendar integration
- [ ] Add support for multiple user profiles (family sharing)

---

## Development Process

1. Prioritize features based on user impact
2. Create feature branches for each enhancement
3. Write tests before implementing new features
4. Document changes in the CHANGELOG.md
5. Keep the README.md updated with new functionality