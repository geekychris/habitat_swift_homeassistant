# Build Fix Applied

## Problem

The app was failing to build with the error:

```
Multiple commands produce '.../Info.plist'
```

This error occurred because:

1. The project had `GENERATE_INFOPLIST_FILE = YES` AND
   `INFOPLIST_FILE = SimpleHomeAssistant/Info.plist`
2. The `Info.plist` file was also being automatically included in the Copy Bundle Resources phase by
   Xcode's `PBXFileSystemSynchronizedRootGroup`

## Solution Applied

### Changes Made:

1. **Removed** the conflicting `GENERATE_INFOPLIST_FILE = YES` line initially
2. **Removed** the `INFOPLIST_FILE = SimpleHomeAssistant/Info.plist` reference
3. **Added** `GENERATE_INFOPLIST_FILE = YES` back to let Xcode auto-generate Info.plist
4. **Migrated** custom Info.plist values to build settings:
    - `INFOPLIST_KEY_CFBundleDisplayName = HAbitat`
    - `INFOPLIST_KEY_NSAppTransportSecurity` (for HTTP support)
    - `INFOPLIST_KEY_UIBackgroundModes = "remote-notification"`
5. **Renamed** `SimpleHomeAssistant/Info.plist` to `Info.plist.backup`

### Modified Files:

- `SimpleHomeAssistant.xcodeproj/project.pbxproj`
- `SimpleHomeAssistant/Info.plist` → `SimpleHomeAssistant/Info.plist.backup`

## Verification

Build tested and verified for:

- ✅ Debug configuration (iOS Simulator)
- ✅ Release configuration (iOS Simulator)
- ✅ Physical device build (generic/platform=iOS)

## Notes

The original `Info.plist` settings have been preserved in `Info.plist.backup` for reference. All
custom settings (app name, HTTP transport security, background modes) have been migrated to Xcode
build settings using the `INFOPLIST_KEY_*` format.

This approach is the modern recommended way for iOS projects using Xcode 14+.
