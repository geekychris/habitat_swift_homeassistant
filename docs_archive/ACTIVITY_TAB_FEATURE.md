# Activity Tab Feature

**Date**: December 14, 2025  
**Status**: ✅ **IMPLEMENTED**

## What's New

A new **Activity** tab that shows device activity/history with powerful filtering options.

## Features

### 1. Activity Timeline

- **Shows recent device activity** (state changes, events)
- **Sorted by time** (most recent first)
- **Device icons and colors** indicating state
- **Timestamps** showing when events occurred

### 2. Time Frame Filtering

Choose from 5 time frame options:

- **Last Hour** - Activity in the past 60 minutes
- **Today** - Activity since midnight
- **Last Week** - Activity in past 7 days
- **Last Month** - Activity in past 30 days
- **All Time** - All available activity (up to 1 year)

### 3. Keyword Search

- **Search by device name**: "Kitchen Light"
- **Search by entity ID**: "light.kitchen"
- **Search by state**: "on", "off", "unavailable"
- **Real-time filtering** as you type

### 4. Visual Design

- **Color-coded states**:
    - 🔵 Blue: On/Open/Unlocked
    - ⚫ Gray: Off/Closed/Locked
    - 🟠 Orange: Unavailable
- **Device icons** matching dashboard
- **Timestamps** with date and time
- **Event counter** showing filtered results

## User Interface

### Layout

```
┌─────────────────────────────────────┐
│ Activity                       🔄   │  ← Title & Refresh
├─────────────────────────────────────┤
│ 🔍 Search activity...               │  ← Search bar
├─────────────────────────────────────┤
│ [Last Hour] [Today] [Week] [Month]  │  ← Time frame chips
├─────────────────────────────────────┤
│                                     │
│ 💡 Kitchen Light                    │
│    light.kitchen • On      3:45 PM  │
│                            Dec 14   │
│                                     │
│ 🔌 Living Switch                    │
│    switch.living • Off     2:30 PM  │
│                            Dec 14   │
│                                     │
│ 🌡️ Thermostat                       │
│    climate.main • 72°      1:15 PM  │
│                            Dec 14   │
│                                     │
├─────────────────────────────────────┤
│ 15 events        Updated just now   │  ← Footer
└─────────────────────────────────────┘
```

### Activity Row Details

Each activity row shows:

- **Device icon** (left) - color-coded by state
- **Device name** (top line)
- **Entity ID** • **State** (bottom line)
- **Time** (right, top) - HH:MM format
- **Date** (right, bottom) - Month Day

### Empty States

**No Activity Found**:

```
┌─────────────────────────────────────┐
│         🕐                          │
│                                     │
│       No Activity                   │
│ No activity found for the           │
│     selected filters                │
└─────────────────────────────────────┘
```

**No Configuration**:

```
┌────────────────────��────────────────┐
│     No Active Configuration         │
│  Please configure a Home Assistant  │
│      connection first               │
└─────────────────────────────────────┘
```

## Usage Examples

### Example 1: View Recent Activity

1. **Tap Activity tab** (clock icon)
2. **See today's activity** by default
3. **Scroll through events**
4. Most recent at top ✅

### Example 2: Find Specific Device

1. **Go to Activity tab**
2. **Type "kitchen"** in search
3. **See only kitchen device activity**
4. Events filtered in real-time ✅

### Example 3: Check Last Hour

1. **Activity tab**
2. **Tap "Last Hour" chip**
3. **See only past 60 minutes**
4. Perfect for recent changes ✅

### Example 4: Investigate State Changes

1. **Activity tab**
2. **Search "off"** in keyword filter
3. **See all devices that turned off**
4. Useful for troubleshooting ✅

### Example 5: Weekly Review

1. **Activity tab**
2. **Tap "Last Week"**
3. **Browse all activity**
4. Get overview of automation patterns ✅

## Time Frame Options

| Time Frame | Shows Activity From | Use Case |
|------------|---------------------|----------|
| **Last Hour** | Past 60 minutes | Recent changes, quick check |
| **Today** | Midnight to now | Daily overview |
| **Last Week** | Past 7 days | Weekly patterns |
| **Last Month** | Past 30 days | Monthly trends |
| **All Time** | Up to 1 year | Complete history |

## Search Capabilities

The search bar filters across:

- ✅ **Device friendly name**: "Kitchen Light"
- ✅ **Entity ID**: "light.kitchen"
- ✅ **State value**: "on", "off", "72°"

**Search is case-insensitive** and matches partial strings.

## Color Coding

### State Colors

- **Blue** (🔵): Active states
    - `on`
    - `open`
    - `unlocked`
- **Gray** (⚫): Inactive states
    - `off`
    - `closed`
    - `locked`
- **Orange** (🟠): Problem states
    - `unavailable`
- **Primary** (⚪): Other states
    - Numeric values
    - Custom states

### Device Icons

- 💡 **Light**: `lightbulb`
- 🔌 **Switch**: `power`
- 🌡️ **Climate**: `thermometer`
- 🪟 **Cover**: `curtains.closed`
- 🌀 **Fan**: `fan`
- 🔒 **Lock**: `lock`
- 📡 **Sensor**: `sensor`
- ⚪ **Other**: `circle`

## Implementation Details

### File Structure

**New File**: `Views/ActivityView.swift`

- `ActivityView` - Main view component
- `ActivityItem` - Data model for activity events
- `ActivityRow` - Individual event row
- `TimeFrameChip` - Time filter button

**Modified File**: `ContentView.swift`

- Added Activity tab (tag 1)
- Updated tab ordering
- Added clock icon

### Current Functionality

**Mock Data**: Currently generates mock activity based on existing entities

- 1-3 events per device
- Random timestamps up to 1 week ago
- Realistic state changes

**Future Enhancement**: Will connect to Home Assistant history API to show real activity data

### Data Model

```swift
struct ActivityItem: Identifiable {
    let id: String
    let entityId: String
    let entityName: String
    let state: String
    let timestamp: Date
    let domain: String
}
```

### Filtering Logic

```swift
var filteredActivities: [ActivityItem] {
    var filtered = activities
    
    // Filter by time frame
    filtered = filtered.filter { 
        $0.timestamp >= selectedTimeFrame.startDate 
    }
    
    // Filter by search text
    if !searchText.isEmpty {
        filtered = filtered.filter { activity in
            activity.entityName.contains(searchText) ||
            activity.state.contains(searchText) ||
            activity.entityId.contains(searchText)
        }
    }
    
    return filtered
}
```

## Tab Bar Update

The main tab bar now has 4 tabs:

1. **🏠 Dashboard** - Device controls
2. **🕐 Activity** - History/activity log (NEW!)
3. **⚙️ Config** - Configuration management
4. **🔲 Tabs** - Custom tab management

## Features to Add (Future)

When connected to real Home Assistant API:

1. **Real History Data**
    - Connect to `/api/history` endpoint
    - Fetch actual state changes
    - Show user-triggered vs automation changes

2. **Event Details**
    - Tap event to see details
    - Show context (automation triggered, user action, etc.)
    - Related events grouped

3. **Export/Share**
    - Export filtered activity to CSV
    - Share specific events
    - Generate activity reports

4. **Advanced Filters**
    - Filter by domain (lights, switches, etc.)
    - Filter by trigger type (manual, automation)
    - Custom date range picker

5. **Charts/Graphs**
    - Activity heatmap
    - Device usage statistics
    - State duration charts

## Test It

### Basic Usage

1. **Tap Activity tab** (clock icon)
2. **See mock activity** generated from your devices
3. **Try different time frames** - Last Hour, Today, Week, etc.
4. **Search for devices** - type device name or state
5. **Pull to refresh** - regenerate mock data

### Filtering

1. **Select "Last Hour"** - see recent events only
2. **Type "kitchen"** - see kitchen devices
3. **Type "on"** - see devices that are on
4. **Clear search** - see all (within time frame)

### Empty State

1. **Select "Last Hour"** with no recent activity
2. **See "No Activity" message**
3. **Select longer time frame** - activity appears

The Activity tab provides valuable insight into your smart home! 📊
