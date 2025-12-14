# History and Events Tabs

**Date**: December 14, 2025  
**Status**: ✅ **IMPLEMENTED**

## What's New

Two new tabs for tracking your smart home:

1. **History** - Entity state change history (lights turning on/off, temperature changes, etc.)
2. **Events** - General activity and events log

## History Tab (Entity State Changes)

### Purpose

Track **when devices change state** - perfect for understanding automation patterns and device
behavior.

### What It Shows

- **State transitions**: on → off, open → closed, 68° → 72°
- **Device changes**: Which entity changed
- **When it happened**: Precise timestamp
- **What changed**: Old state → New state with visual indicators

### UI Design

```
┌─────────────────────────────────────┐
│ History                        🔄   │
├─────────────────────────────────────┤
│ 🔍 Search history...                │
├─────────────────────────────────────┤
│ [Hour] [6 Hours] [Today] [Yesterday]│  ← Time filters
├─────────────────────────────────────┤
│ 💡 Kitchen Light            3:45 PM │
│    light.kitchen            Dec 14  │
│    [Off] → [On]  brightness: 85%    │
│                                     │
│ 🌡️ Living Thermostat        2:30 PM │
│    climate.living           Dec 14  │
│    [68] → [72]  target: 72°         │
│                                     │
│ 🔌 Bedroom Switch           1:15 PM │
│    switch.bedroom           Dec 14  │
│    [On] → [Off]                     │
└─────────────────────────────────────┘
```

### Features

**Time Frame Filters**:

- **Last Hour** - Changes in past 60 minutes
- **6 Hours** - Recent changes today
- **Today** - All changes since midnight
- **Yesterday** - Previous day's changes
- **Week** - Past 7 days

**State Change Display**:

- **Old state** in gray box
- **Arrow** showing direction of change
- **New state** in colored box (blue=on, gray=off)
- **Attributes** shown when relevant (brightness, temperature, etc.)

**Search**:

- Filter by device name: "kitchen"
- Filter by entity ID: "light.kitchen"
- Filter by state: "on", "off", "72"
- Tokenized search: "kitchen light" matches "Kitchen Under Cabinet Light"

### Example Use Cases

**Troubleshooting**:

```
"Why did my light turn off?"
→ Check History
→ Search "bedroom light"
→ See it turned off at 10:30 PM
→ Check automations
```

**Pattern Analysis**:

```
"How often does my thermostat change?"
→ History → Select "Week"
→ Search "thermostat"
→ See all temperature adjustments
→ Identify patterns
```

**Automation Verification**:

```
"Did my automation run?"
→ History → Select "Today"
→ Search for affected devices
→ Verify state changes at expected times
```

## Events Tab (General Activity)

### Purpose

Track **general system activity** and events (future: automations, updates, notifications).

### What It Shows

- Device activity summary
- System events (currently mock data)
- General activity timeline

### UI Design

```
┌─────────────────────────────────────┐
│ Events                         🔄   │
├─────────────────────────────────────┤
│ 🔍 Search activity...               │
├─────────────────────────────────────┤
│ [Hour] [Today] [Week] [Month] [All] │
├─────────────────────────────────────┤
│ 💡 Kitchen Light            3:45 PM │
│    light.kitchen • On       Dec 14  │
│                                     │
│ 🔌 Living Switch            2:30 PM │
│    switch.living • Off      Dec 14  │
└─────────────────────────────────────┘
```

### Future Enhancements

- Automation triggers and results
- System notifications
- Integration events
- User actions vs automated actions
- Error logs and warnings

## Tab Bar Layout

The app now has **5 tabs**:

1. 🏠 **Dashboard** - Control your devices
2. 🔄 **History** - Entity state changes (NEW!)
3. 🔔 **Events** - General activity (NEW!)
4. ⚙️ **Config** - Configuration management
5. 🔲 **Tabs** - Custom tab management

## Key Differences: History vs Events

| Feature | History | Events |
|---------|---------|--------|
| **Focus** | Entity state changes | General activity |
| **Shows** | Specific transitions (on→off) | Activity summary |
| **Detail** | Old state → New state | Current state only |
| **Use Case** | Troubleshooting, patterns | Overview, monitoring |
| **Attributes** | Shows relevant attributes | Basic info |
| **Time Frames** | Hour, 6H, Today, Yesterday, Week | Hour, Today, Week, Month, All |

## History Tab Details

### State Change Visualization

**Light Example**:

```
💡 Kitchen Light                    3:45 PM
   light.kitchen                    Dec 14
   [Off] → [On]  brightness: 85%
   ^^^^     ^^^  ^^^^^^^^^^^^^^^^^
   Gray     Blue     Attribute
```

**Thermostat Example**:

```
🌡️ Living Thermostat               2:30 PM
   climate.living                  Dec 14
   [68] → [72]  target: 72°
   ^^^^    ^^^^  ^^^^^^^^^^^^
   Gray   Orange   Attribute
```

**Switch Example**:

```
🔌 Bedroom Switch                  1:15 PM
   switch.bedroom                  Dec 14
   [On] → [Off]
   ^^^^    ^^^^
   Blue    Gray
```

### Color Coding

**State Badges**:

- **Blue**: Active states (on, open, unlocked, heat, cool)
- **Gray**: Inactive states (off, closed, locked)
- **Orange**: Temperature values and warnings
- **Primary**: Unknown/custom states

**Device Icons**:

- 💡 Light: `lightbulb.fill`
- 🔌 Switch: `power`
- 🌡️ Climate: `thermometer`
- 🪟 Cover: `curtains.closed`
- 🌀 Fan: `fan.fill`
- 🔒 Lock: `lock.fill`
- 📡 Sensor: `sensor`

### Search Capabilities

Both tabs support **tokenized prefix matching**:

**Examples**:

- `"kit"` → Matches "Kitchen Light"
- `"living therm"` → Matches "Living Room Thermostat"
- `"on"` → Shows all devices that turned on
- `"72"` → Shows temperature changes to 72°

**Search Across**:

- ✅ Device friendly name
- ✅ Entity ID
- ✅ State values (old and new)
- ✅ Partial word matching

## Usage Examples

### Example 1: Find When Light Turned Off

**History Tab**:

1. Tap "History" tab
2. Select "Today" time frame
3. Search "bedroom light"
4. See state changes with timestamps
5. Find: `[On] → [Off]` at 10:30 PM ✅

### Example 2: Monitor Thermostat Changes

**History Tab**:

1. Tap "History"
2. Select "Week"
3. Search "thermostat"
4. See all temperature adjustments
5. Identify pattern: changes every 2-3 hours ✅

### Example 3: Check Automation Success

**History Tab**:

1. Tap "History"
2. Select "Yesterday"
3. Search for automation devices
4. Verify state changes at expected times
5. Confirm automation working ✅

### Example 4: General Activity Overview

**Events Tab**:

1. Tap "Events"
2. Select "Today"
3. Browse general activity
4. Quick overview of smart home activity ✅

## Technical Implementation

### History Tab

**File**: `Views/HistoryView.swift`

**Data Model**:

```swift
struct HistoryItem {
    let entityId: String
    let entityName: String
    let oldState: String?      // Previous state
    let newState: String       // Current state
    let timestamp: Date
    let domain: String
    let attributes: String?    // e.g., "brightness: 85%"
}
```

**Key Features**:

- State transition visualization
- Attribute display for relevant changes
- Color-coded state badges
- Tokenized search

### Events Tab

**File**: `Views/ActivityView.swift`

**Data Model**:

```swift
struct ActivityItem {
    let entityId: String
    let entityName: String
    let state: String          // Current state only
    let timestamp: Date
    let domain: String
}
```

### Mock Data

Both tabs currently use mock data generators:

- Generate realistic state changes
- Based on current entities
- Random timestamps within selected timeframe
- Appropriate for each domain type

### Future: Real Data

Will connect to Home Assistant APIs:

- **History API**: `/api/history/period/<timestamp>`
- **Events API**: `/api/events` (WebSocket)
- Real-time updates for Events tab
- Historical data for History tab

## Empty States

### History Tab - No Changes

```
┌─────────────────────────────────────┐
│         🔄                          │
│                                     │
│       No History                    │
│ No state changes found for          │
│  the selected period                │
└─────────────────────────────────────┘
```

### Events Tab - No Activity

```
┌─────────────────────────────────────┐
│         🕐                          │
│                                     │
│       No Activity                   │
│ No activity found for the           │
│     selected filters                │
└─────────────────────────────────────┘
```

## Test It

### Test History Tab

1. **Tap "History" tab** (double-arrow clock icon)
2. **See entity state changes** with transitions
3. **Try time frames**: Hour, 6 Hours, Today, etc.
4. **Search for a device**: "kitchen"
5. **See state transitions**: `[Off] → [On]`
6. **Pull to refresh**: Regenerate mock data

### Test Events Tab

1. **Tap "Events" tab** (bell icon)
2. **See general activity**
3. **Try different time frames**
4. **Search and filter**
5. **Pull to refresh**

### Compare Both

1. Open **History**: See detailed state transitions
2. Open **Events**: See activity overview
3. Notice different detail levels and use cases

Now you have two powerful tools for monitoring your smart home! 📊🔔
