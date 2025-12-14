# Dashboard Swipe-to-Delete Fix

**Date**: December 14, 2025  
**Status**: ✅ **FIXED**

## The Problem

Swipe-to-delete on dashboard wasn't actually removing devices. The swipe action appeared but devices
remained visible.

## Root Cause

The dashboard has **two different filtering modes**:

1. **"All" Tab**: Shows entities based on `selectedEntityIds`
2. **Custom Tab** (e.g., "Kitchen"): Shows entities based on `tab.entityIds`

The original code called `toggleEntitySelection()` which only modified `selectedEntityIds`. This
worked for "All" tab but **didn't work for custom tabs** because custom tabs filter by
`tab.entityIds`, not `selectedEntityIds`.

### Example Issue

**Viewing "Kitchen" tab on dashboard**:

- Dashboard shows entities where `entityId` is in `kitchen_tab.entityIds`
- Swipe → calls `toggleEntitySelection()` → removes from `selectedEntityIds`
- But dashboard filter uses `tab.entityIds` (not `selectedEntityIds`)
- **Result**: Entity stays visible! ❌

## The Fix

Created a new function `removeFromDashboard()` that **handles both cases**:

```swift
func removeFromDashboard(_ entityId: String) {
    if let tabName = selectedTab,
       let tabIndex = customTabs.firstIndex(where: { $0.name == tabName }) {
        // Viewing custom tab → Remove from tab.entityIds
        var updatedTab = customTabs[tabIndex]
        updatedTab.entityIds.removeAll { $0 == entityId }
        customTabs[tabIndex] = updatedTab
        persistence.saveTabs(customTabs, configId: config.id)
    } else {
        // Viewing "All" tab → Remove from selectedEntityIds
        selectedEntityIds.remove(entityId)
        persistence.saveSelectedEntities(Array(selectedEntityIds), configId: config.id)
    }
}
```

### How It Works Now

**Viewing "All" Tab**:

```
Swipe device → removeFromDashboard()
    ↓
Remove from selectedEntityIds
    ↓
Dashboard re-filters
    ↓
Device disappears! ✅
```

**Viewing Custom Tab** (e.g., "Kitchen"):

```
Swipe device → removeFromDashboard()
    ↓
Remove from kitchen_tab.entityIds
    ↓
Dashboard re-filters
    ↓
Device disappears! ✅
```

## Before vs After

### Before (Broken)

**All Tab**:

- Swipe → Remove from `selectedEntityIds` → Works ✅

**Custom Tab** (Kitchen):

- Swipe → Remove from `selectedEntityIds` → Doesn't work ❌
- Dashboard still shows entity because it filters by `tab.entityIds`

### After (Fixed)

**All Tab**:

- Swipe → Remove from `selectedEntityIds` → Works ✅

**Custom Tab** (Kitchen):

- Swipe → Remove from `tab.entityIds` → Works ✅
- Dashboard immediately updates, entity disappears

## Testing Scenarios

### Test 1: Remove from "All" Tab

1. **Dashboard** → Ensure "All" chip is selected
2. **Swipe left** on a device
3. **Tap "Remove from Dashboard"**
4. **Device disappears immediately** ✅
5. **Go to Entities tab** → Device still has checkmark removed
6. **Back to Dashboard** → Device still gone ✅

### Test 2: Remove from Custom Tab

1. **Dashboard** → Tap "Kitchen" tab chip
2. **Swipe left** on a kitchen device
3. **Tap "Remove from Dashboard"**
4. **Device disappears immediately** ✅
5. **Go to Tabs** → Select Kitchen tab
6. **Device unchecked** in Kitchen tab ✅
7. **Back to Dashboard** → Kitchen tab → Device still gone ✅

### Test 3: Persistent Changes

1. **Remove device** from dashboard (either "All" or custom tab)
2. **Close app**
3. **Reopen app**
4. **Device still removed** ✅

## Technical Details

### Changes Made

**File**: `ViewModels/AppViewModel.swift`

**Added Function**:

```swift
func removeFromDashboard(_ entityId: String) {
    guard let config = activeConfiguration else { return }
    
    if let tabName = selectedTab,
       let tabIndex = customTabs.firstIndex(where: { $0.name == tabName }) {
        // Custom tab: remove from tab
        var updatedTab = customTabs[tabIndex]
        updatedTab.entityIds.removeAll { $0 == entityId }
        customTabs[tabIndex] = updatedTab
        persistence.saveTabs(customTabs, configId: config.id)
    } else {
        // "All" tab: remove from selected entities
        selectedEntityIds.remove(entityId)
        persistence.saveSelectedEntities(Array(selectedEntityIds), configId: config.id)
    }
}
```

**File**: `Views/DashboardView.swift`

**Changed**:

```swift
// Before
.swipeActions {
    Button(role: .destructive) {
        viewModel.toggleEntitySelection(entity.entityId)  // ❌ Didn't work for tabs
    }
}

// After
.swipeActions {
    Button(role: .destructive) {
        viewModel.removeFromDashboard(entity.entityId)  // ✅ Works everywhere!
    }
}
```

### Why This Works

1. **Context-aware**: Function checks which tab you're viewing
2. **Modifies correct data**:
    - "All" tab → modifies `selectedEntityIds`
    - Custom tab → modifies `tab.entityIds`
3. **Triggers UI update**: Both `selectedEntityIds` and `customTabs` are `@Published`
4. **Persists changes**: Saves to correct persistence location
5. **Immediate feedback**: SwiftUI reactively updates `filteredEntities`

## Dashboard Filtering Logic

Understanding how the dashboard decides what to show:

```swift
var filteredEntities: [HAEntity] {
    var filtered = entities
    
    if let tabName = selectedTab,
       let tab = customTabs.first(where: { $0.name == tabName }) {
        // Custom tab selected
        filtered = filtered.filter { tab.entityIds.contains($0.entityId) }
    } else {
        // "All" tab selected
        if !selectedEntityIds.isEmpty {
            filtered = filtered.filter { selectedEntityIds.contains($0.entityId) }
        } else {
            filtered = filtered.filter { $0.isControllable }
        }
    }
    
    return filtered.sorted { $0.friendlyName < $1.friendlyName }
}
```

**Key Point**: Different tabs use different sources for filtering!

## Re-adding Removed Devices

### From "All" Tab

If you removed from "All" tab:

1. **Go to Entities tab**
2. **Find device** and tap checkbox
3. **Device reappears** on "All" dashboard

### From Custom Tab

If you removed from "Kitchen" tab:

1. **Go to Tabs → Kitchen**
2. **Find device** and check it
3. **Device reappears** on Kitchen dashboard

## Example Workflow

**Cleaning up Kitchen tab**:

1. Dashboard → Tap "Kitchen" chip
2. See all kitchen devices
3. Swipe left on "Old Kitchen Sensor"
4. Tap "Remove from Dashboard"
5. **Sensor disappears immediately** ✅
6. Go to Tabs → Kitchen
7. **Sensor is unchecked** ✅
8. Kitchen tab now only shows active devices

The swipe-to-delete now works correctly in all contexts! 🎉
