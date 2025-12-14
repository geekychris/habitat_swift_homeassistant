# Hide Unavailable & Dashboard Swipe-to-Delete

**Date**: December 14, 2025  
**Status**: ✅ **IMPLEMENTED**

## What's New

Two new features to improve device management:

1. **Hide Unavailable Checkbox** - Filter out offline devices when managing tabs
2. **Dashboard Swipe-to-Delete** - Remove devices from dashboard with swipe gesture

## Feature 1: Hide Unavailable Devices

### What It Does

In the **Tab Detail View** (Tabs → Select tab), you can now **hide unavailable devices** with a
checkbox, making it easier to focus on working devices when adding to tabs.

### Location

**Tabs → Select a tab → See checkbox below search bar**

```
┌─────────────────────────────────┐
│ 🔍 Search...                    │
├─────────────────────────────────┤
│ ☑ Hide Unavailable              │  ← New checkbox!
├─────────────────────────────────┤
│ Devices list...                 │
└─────────────────────────────────┘
```

### How It Works

**Unchecked (default)**:

- Shows **all devices** (available + unavailable)
- Unavailable devices marked with orange "• Unavailable"

**Checked**:

- Shows **only available devices**
- Unavailable devices filtered out
- Cleaner list when adding devices to tab

### Usage

1. **Go to Tabs** → Tap a tab name
2. **See the checkbox** below the search bar: "Hide Unavailable"
3. **Tap checkbox** to toggle
4. **Unchecked**: All devices shown (with unavailable marked)
5. **Checked**: Only available devices shown ✅

### Benefits

- **Focus on working devices**: Don't clutter your tab with offline devices
- **Faster selection**: Less scrolling through unavailable devices
- **Still visible when needed**: Uncheck to see all devices including offline
- **Combines with search**: Search + hide unavailable = powerful filtering

### Example Scenario

**Adding devices to "Living Room" tab**:

**Before (checkbox unchecked)**:

```
☐ Living Room Light
☐ Living Room Switch
☐ Old Sensor • Unavailable     ← Shows offline
☐ Broken Plug • Unavailable    ← Shows offline
☐ Living Room Fan
```

😩 Lots of unavailable devices to skip

**After (checkbox checked)**:

```
☐ Living Room Light
☐ Living Room Switch
☐ Living Room Fan
```

✅ Only working devices shown!

## Feature 2: Dashboard Swipe-to-Delete

### What It Does

On the **Dashboard**, you can now **swipe left** on device cards to remove them from the dashboard.

### How It Works

**Swipe Actions**:

- Swipe left on any device card
- Red "Remove from Dashboard" button appears
- Tap to remove device from visible devices

**Context Menu** (Alternative):

- Long-press on any device card
- Menu appears with "Remove from Dashboard"
- Tap to remove

### Usage Methods

#### Method 1: Swipe

1. **On Dashboard** → Find a device card
2. **Swipe left** on the card
3. **Red "Remove from Dashboard" button** appears
4. **Tap button** → Device removed from dashboard ✅

#### Method 2: Long Press

1. **On Dashboard** → Find a device card
2. **Long-press** the card
3. **Menu appears** with "Remove from Dashboard"
4. **Tap menu item** → Device removed from dashboard ✅

### Visual Flow

**Swipe Action**:

```
┌─────────────────────────────┐
│ 🏠 Kitchen Light            │  ← Swipe left
│ ☑ On                        │
│ Brightness: 75%             │
└─────────────────────────────┘
              ↓
┌─────────────────────────────┐
│ Kitchen Light  [Remove from │  ← Tap button
│ On             Dashboard 🗑️]│
└─────────────────────────────┘
              ↓
Device removed from dashboard! ✅
```

**Long Press**:

```
Long press card
    ↓
Menu appears:
┌─────────────────────────────┐
│ Remove from Dashboard 🗑️    │
└─────────────────────────────┘
    ↓
Tap → Device removed! ✅
```

### What Happens When Removed

- Device **removed from selectedEntityIds**
- Dashboard **immediately updates** - card disappears
- Device **still exists** in Home Assistant
- Can **re-add** from Entities tab or Tab management
- **Persisted** - stays removed after app restart

### Re-adding Removed Devices

**Option 1**: Via Entities Tab

1. Go to **Entities** tab
2. Find the device
3. Tap checkbox to select
4. Device appears on dashboard again

**Option 2**: Via Tab Management

1. Go to **Tabs** → Select tab containing device
2. Check the device
3. Device appears on dashboard again

## Implementation Details

### Hide Unavailable Checkbox

**File**: `Views/TabManagementView.swift`

**State Variable**:

```swift
@State private var hideUnavailable = false
```

**Filter Logic**:

```swift
var filteredEntities: [HAEntity] {
    var entities = viewModel.entities
    
    // Filter out unavailable if checkbox is checked
    if hideUnavailable {
        entities = entities.filter { $0.state.lowercased() != "unavailable" }
    }
    
    // Then apply search filter
    // ...
}
```

**UI**:

```swift
Button(action: { hideUnavailable.toggle() }) {
    HStack(spacing: 8) {
        Image(systemName: hideUnavailable ? "checkmark.square.fill" : "square")
        Text("Hide Unavailable")
    }
}
```

### Dashboard Swipe Actions

**File**: `Views/DashboardView.swift`

**Changed From**: `ScrollView` with `LazyVStack`
**Changed To**: `List` with swipe actions

**Swipe Action**:

```swift
.swipeActions(edge: .trailing, allowsFullSwipe: false) {
    Button(role: .destructive) {
        viewModel.toggleEntitySelection(entity.entityId)
    } label: {
        Label("Remove from Dashboard", systemImage: "trash")
    }
}
```

**Context Menu**:

```swift
.contextMenu {
    Button(role: .destructive) {
        viewModel.toggleEntitySelection(entity.entityId)
    } label: {
        Label("Remove from Dashboard", systemImage: "trash")
    }
}
```

**Key Settings**:

- `allowsFullSwipe: false` - Prevents accidental full-swipe deletion
- `role: .destructive` - Red color indicates removal action
- `listRowSeparator(.hidden)` - Maintains card appearance
- `listRowInsets` - Proper padding for cards

## Example Workflows

### Workflow 1: Clean Tab Setup

1. Creating "Bedroom" tab
2. Check "Hide Unavailable"
3. Browse only working devices
4. Select devices to add
5. Tab has only functional devices ✅

### Workflow 2: Dashboard Cleanup

1. Dashboard has too many devices
2. Swipe left on unused devices
3. Tap "Remove from Dashboard"
4. Cleaner, more focused dashboard ✅

### Workflow 3: Combine Features

1. Go to tab management
2. Check "Hide Unavailable"
3. Search for "kitchen"
4. See only available kitchen devices
5. Quick and precise selection ✅

## UI Updates

### Tab Detail View

**Before**:

```
┌─────────────────────────────┐
│ 🔍 Search...                │
├─────────────────────────────┤
│ All devices including       │
│ unavailable ones            │
└─────────────────────────────┘
```

**After**:

```
┌─────────────────────────────┐
│ 🔍 Search...                │
│ ☑ Hide Unavailable          │  ← New!
├─────────────────────────────┤
│ Filtered devices            │
└─────────────────────────────┘
```

### Dashboard

**Before**:

```
Device cards - no removal option
```

**After**:

```
Device cards:
- Swipe left → Remove button
- Long press → Context menu
```

## Test It

### Test Hide Unavailable

1. **Turn off some devices** or unplug them
2. **Go to Tabs** → Select a tab
3. **See unavailable devices** with orange indicator
4. **Check "Hide Unavailable"** checkbox
5. **Unavailable devices disappear** ✅
6. **Uncheck** → They reappear ✅

### Test Dashboard Swipe

1. **Go to Dashboard** with some devices
2. **Swipe left** on a device card
3. **Red "Remove" button appears** ✅
4. **Tap button** → Device removed ✅
5. **Or try long-press** → Menu appears → Remove ✅

### Test Dashboard Context Menu

1. **Long-press** a device card
2. **Menu appears** with "Remove from Dashboard"
3. **Tap menu item** → Device removed ✅

Both features work together to give you precise control over your device management! 🎯
