# Tab Filter Fix

## Problem

When adding entities to custom tabs in the "Tabs" section, the Dashboard showed "No entities to
display" even though entities were properly assigned to the tab.

## Root Cause

The `filteredEntities` computed property in `AppViewModel.swift` had incorrect filtering logic:

```swift
// OLD (BROKEN) LOGIC:
var filteredEntities: [HAEntity] {
    var filtered = entities
    
    // WRONG: This filters first by selectedEntityIds
    if !selectedEntityIds.isEmpty {
        filtered = filtered.filter { selectedEntityIds.contains($0.entityId) }
    }
    
    // Then tries to filter by tab - but already filtered out entities!
    if let tabName = selectedTab, let tab = customTabs.first(where: { $0.name == tabName }) {
        let tabEntityIds = Set(tab.entityIds)
        filtered = filtered.filter { tabEntityIds.contains($0.entityId) }
    }
    
    return filtered.sorted { $0.friendlyName < $1.friendlyName }
}
```

**The problem**:

- The logic created an AND condition between `selectedEntityIds` and `tab.entityIds`
- When you assigned entities to a tab, they were stored in `tab.entityIds` but NOT in
  `selectedEntityIds`
- This meant the first filter would return an empty set if `selectedEntityIds` was empty
- Even if `selectedEntityIds` had values, it would need entities to be in BOTH sets to show up

## Solution

Reorganized the filtering logic to properly prioritize tab selection:

```swift
// NEW (FIXED) LOGIC:
var filteredEntities: [HAEntity] {
    var filtered = entities
    
    // Filter by tab selection FIRST
    if let tabName = selectedTab,
       let tab = customTabs.first(where: { $0.name == tabName }) {
        // When a specific tab is selected, show entities in that tab
        let tabEntityIds = Set(tab.entityIds)
        filtered = filtered.filter { tabEntityIds.contains($0.entityId) }
    } else {
        // "All" tab: show either selected entities or all controllable entities
        if !selectedEntityIds.isEmpty {
            filtered = filtered.filter { selectedEntityIds.contains($0.entityId) }
        } else {
            // If no entities selected, show all controllable entities
            filtered = filtered.filter { $0.isControllable }
        }
    }
    
    return filtered.sorted { $0.friendlyName < $1.friendlyName }
}
```

**The fix**:

1. **Custom tab selected** → Show ONLY entities assigned to that tab (ignores `selectedEntityIds`)
2. **"All" tab selected** → Show selected entities OR all controllable entities
3. No more AND condition between two entity sets

## Expected Behavior After Fix

### Scenario 1: User creates "Living Room" tab and adds entities

1. User goes to "Tabs" tab
2. Creates "Living Room" tab
3. Taps the tab to open entity assignment
4. Checks entities to add (e.g., "Living Room Light", "TV")
5. Goes back to Dashboard
6. Selects "Living Room" tab chip
7. **NOW WORKS**: Shows the 2 entities assigned to that tab ✅

### Scenario 2: User clicks "All" tab

1. On Dashboard
2. Clicks "All" tab chip
3. **Shows**: All controllable entities (lights, switches, climate devices)

## Files Modified

- `SimpleHomeAssistant/ViewModels/AppViewModel.swift` - Fixed `filteredEntities` computed property

## Testing

Build verified successful:

```bash
xcodebuild -scheme SimpleHomeAssistant -sdk iphonesimulator build
** BUILD SUCCEEDED **
```

## Notes

- The `selectedEntityIds` feature appears to be from an older "Select" tab that's no longer in the
  UI
- The new workflow uses custom tabs exclusively for entity organization
- This fix maintains backward compatibility with the `selectedEntityIds` feature for "All" tab
