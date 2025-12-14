# Auto-Refresh on Configuration Switch

**Date**: December 14, 2025  
**Status**: ✅ **FIXED**

## The Problem

When switching between active configurations, the entities (devices) were not automatically
refreshed. Users had to manually pull-to-refresh to see the devices from the new configuration.

## The Fix

Added automatic entity refresh when switching active configurations in
`AppViewModel.setActiveConfiguration()`.

## What Changed

**File**: `ViewModels/AppViewModel.swift`

**Before**:

```swift
func setActiveConfiguration(_ config: HAConfiguration) {
    // Deactivate all, activate selected
    // ...
    api.setConfiguration(config)
    loadSelectedEntities(configId: config.id)
    loadTabs(configId: config.id)
    // ❌ Entities not loaded - screen shows old data
}
```

**After**:

```swift
func setActiveConfiguration(_ config: HAConfiguration) {
    // Deactivate all, activate selected
    // ...
    api.setConfiguration(config)
    loadSelectedEntities(configId: config.id)
    loadTabs(configId: config.id)
    
    // ✅ Automatically refresh entities from the new configuration
    Task {
        await loadEntities()
    }
}
```

## How It Works Now

### User Flow

1. **Go to Configuration tab**
2. **Tap a different configuration** to make it active
3. **Switch to Dashboard or Entities tab**
4. **Entities automatically load** from the new configuration ✅

### What Happens Behind the Scenes

1. User taps configuration → `setActiveConfiguration()` called
2. Configuration marked as active
3. API client updated with new config
4. Tabs and selected entities loaded
5. **NEW**: `loadEntities()` automatically called
6. UI shows loading spinner
7. Entities fetched from new configuration's URL
8. UI updates with new devices

## Before vs After

### Before (Manual Refresh Required)

```
Switch config → Go to Dashboard
  → See old devices from previous config ❌
  → Pull to refresh manually
  → New devices appear ✅
```

### After (Auto-Refresh)

```
Switch config → Go to Dashboard
  → Loading spinner appears automatically
  → New devices load immediately ✅
```

## Console Output

When you switch configurations, you'll now see:

```
🔍 loadConfigurations() called
✅ Loaded 2 configurations from UserDefaults
🔗 Fetching entities from: http://192.168.1.100:8123
🔑 Auth type: oauth
🔑 Using internal URL
📍 Internal URL: http://192.168.1.100:8123
📍 External URL: http://geekychris.com:8123
🎯 Actually using: http://192.168.1.100:8123
📡 Response status: 200
```

## Benefits

- **Better UX**: No manual refresh needed
- **Intuitive**: Works as users expect
- **Immediate feedback**: Loading spinner shows work is happening
- **Prevents confusion**: No stale data from previous configuration

## Test It

1. **Create/have 2+ configurations** with different devices
2. **Set one as active** from Configuration tab
3. **Go to Dashboard or Entities tab**
4. **See devices loading automatically** ✅
5. **Switch to another configuration**
6. **Go back to Dashboard/Entities**
7. **See new devices loading automatically** ✅

No more manual refresh required! 🎉
