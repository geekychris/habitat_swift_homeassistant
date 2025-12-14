# Device Management Improvements

**Date**: December 14, 2025  
**Status**: ✅ **IMPLEMENTED**

## What's New

Two major improvements to device management in tabs:

1. **Swipe to Remove** - Remove devices from tabs with a swipe gesture
2. **Unavailable Status** - See which devices are unavailable when adding/managing

## Feature 1: Swipe to Remove Devices

### How It Works

In the **Tab Detail View** (Tabs → Select a tab), assigned devices now support swipe-to-delete.

**Before**: Had to tap checkbox to remove, not intuitive for already-assigned devices

**After**: Swipe left on assigned device → Red "Remove" button appears → Tap to remove

### Usage

1. **Go to Tabs** → Tap on a tab name
2. **See list of all devices** with checkboxes
3. **Find an assigned device** (has blue checkmark)
4. **Swipe left** on the device
5. **"Remove" button appears** (red, with trash icon)
6. **Tap "Remove"** → Device removed from tab ✅

### Visual Flow

```
┌─────────────────────────────────┐
│ ☑ Kitchen Light                 │  ← Swipe left
│   light.kitchen                 │
└─────────────────────────────────┘
                ↓
┌─────────────────────────────────┐
│ ☑ Kitchen Light        [Remove] │  ← Tap Remove
│   light.kitchen           🗑️    │
└─────────────────────────────────┘
                ↓
┌─────────────────────────────────┐
│ ☐ Kitchen Light                 │  ← Removed!
│   light.kitchen                 │
└─────────────────────────────────┘
```

### Code Implementation

**File**: `Views/TabManagementView.swift`

```swift
.swipeActions(edge: .trailing, allowsFullSwipe: true) {
    if assignedEntityIds.contains(entity.entityId) {
        Button(role: .destructive) {
            toggleAssignment(entity.entityId)
        } label: {
            Label("Remove", systemImage: "trash")
        }
    }
}
```

**Key Features**:

- ✅ Only appears on **assigned devices** (with checkmark)
- ✅ **Full swipe** support - swipe all the way to instantly remove
- ✅ **Destructive role** - appears in red to indicate removal
- ✅ **Trash icon** - clear visual indicator

## Feature 2: Unavailable Device Status

### How It Works

Devices that are unavailable (offline, disconnected, etc.) now show an **orange "Unavailable"**
indicator.

**Before**: No way to tell if a device was unavailable when adding to tabs

**After**: Orange "• Unavailable" badge appears next to entity ID

### Where It Appears

1. **Tab Detail View** (Tabs → Select tab)
2. **Entity Selection View** (Entities tab)

### Visual Appearance

```
┌─────────────────────────────────────┐
│ ☐ Kitchen Light                     │
│   light.kitchen • Unavailable       │  ← Orange indicator
│                    ⚠️               │
└─────────────────────────────────────┘
```

### Usage

**When Adding Devices to Tab**:

1. Go to **Tabs** → Select a tab
2. Browse devices
3. **See unavailable devices** marked with orange "• Unavailable"
4. **Decide** whether to add them (maybe they're temporarily offline)

**When Viewing All Entities**:

1. Go to **Entities** tab
2. Browse all devices
3. **Unavailable devices** clearly marked
4. **Know which need attention**

### Code Implementation

**Files**:

- `Views/TabManagementView.swift`
- `Views/EntitySelectionView.swift`

```swift
HStack {
    Text(entity.entityId)
        .font(.caption)
        .foregroundColor(.secondary)
    
    // Show unavailable status
    if entity.state.lowercased() == "unavailable" {
        Text("• Unavailable")
            .font(.caption)
            .foregroundColor(.orange)
    }
}
```

**Detection**:

- Checks if `entity.state.lowercased() == "unavailable"`
- Shows orange text indicator
- Uses bullet point (•) separator for clean visual

## Benefits

### Swipe to Remove

- **Faster workflow**: Quick swipe vs. tapping checkbox
- **Intuitive**: Standard iOS gesture for removal
- **Less mistakes**: Destructive action (red) makes it clear
- **Full swipe**: Can swipe all the way to instantly remove

### Unavailable Status

- **Better decision making**: Know which devices are offline before adding
- **Troubleshooting**: Easily spot offline devices
- **Visual feedback**: Orange color = warning/attention needed
- **Consistent**: Shows in both tab management and entity selection

## Example Scenarios

### Scenario 1: Remove Multiple Devices from Tab

1. Open "Living Room" tab
2. Swipe left on "Old Lamp" → Remove
3. Swipe left on "Broken Switch" → Remove
4. Swipe left on "Unused Sensor" → Remove
   ✅ Cleaned up tab in seconds!

### Scenario 2: Adding Devices with Awareness

1. Creating "Bedroom" tab
2. Browse devices
3. See "Bedroom Light • Unavailable"
4. Skip it (light is offline, will add later)
5. Add working devices only
   ✅ Tab has only functional devices!

### Scenario 3: Troubleshooting

1. Devices not responding
2. Go to Entities tab
3. See several "• Unavailable" indicators
4. Know which devices need attention
   ✅ Quick diagnosis!

## UI Updates

### Tab Detail View - Before

```
☑ Kitchen Light
  light.kitchen

☑ Old Lamp
  light.old_lamp

☑ Offline Sensor
  sensor.offline
```

### Tab Detail View - After

```
☑ Kitchen Light                    ← Swipe to remove
  light.kitchen

☑ Old Lamp                         ← Swipe to remove
  light.old_lamp

☑ Offline Sensor                   ← Swipe to remove
  sensor.offline • Unavailable     ← See it's offline!
```

## Technical Details

### Swipe Actions

- **Edge**: `.trailing` (swipe from right to left)
- **Full Swipe**: Enabled - swipe all the way to instantly trigger
- **Conditional**: Only shows on assigned devices
- **Role**: `.destructive` - red color and careful handling

### Status Detection

- **Check**: `entity.state.lowercased() == "unavailable"`
- **Color**: `.orange` - warning color
- **Placement**: Next to entity ID
- **Font**: `.caption` - consistent with entity ID

## Test It

### Test Swipe to Remove

1. **Go to Tabs** → Select a tab with devices
2. **Find assigned device** (blue checkmark)
3. **Swipe left** on the row
4. **See red "Remove" button** with trash icon
5. **Tap Remove** → Checkmark removed ✅
6. **Try full swipe** → Swipe all the way left → Instantly removes ✅

### Test Unavailable Status

1. **Turn off a device** or unplug it
2. **Wait a moment** for Home Assistant to detect
3. **Refresh entities** (pull down)
4. **Go to Entities tab** or **Tab detail view**
5. **See orange "• Unavailable"** next to offline device ✅

Both features make device management much more intuitive! 🎉
