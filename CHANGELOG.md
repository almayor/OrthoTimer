# Changelog

## 2025-04-17 - macOS App, Project Reorganization & App Icons

### Added
- macOS companion app with:
  - Menu bar integration for quick device control
  - Full application window for detailed statistics
  - Shared codebase with iOS app for consistent experience
- Shared folder for common code between iOS and macOS
- Project structure documentation
- Custom app icon with orthodontist theme (tooth with braces and timer)
- Properly sized app icons for iOS and macOS devices

### Changed
- Refactored device management to work across platforms
- Improved code organization with clear separation of concerns
- Enhanced time utilities to support both platforms
- Conditional compilation for platform-specific features (notifications)

### Fixed
- Code duplication by centralizing shared models and utilities
- File structure organization with proper cross-platform support

## 2025-04-16 - Notification Support & Widget Preview

### Added
- Notification support:
  - Not wearing device for 3+ hours
  - Wearing device for 12+ hours
- Widget preview within the main iOS app

### Changed
- Improved timer tracking accuracy
- Enhanced UI with a darker orthodontist-themed blue accent color

### Fixed
- Timer consistency issues
- Various UI and layout improvements

## 2025-04-15 - Initial Release

### Added
- iOS app for tracking orthodontic device wear time
- Multiple device support
- Real-time stopwatch display
- Daily wear statistics with automatic midnight reset
- Weekly and monthly historical data
- CloudKit integration for data persistence