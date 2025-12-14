# Active Configuration Indicator

**Date**: December 14, 2025  
**Status**: ✅ **IMPLEMENTED**

## What's New

The app header now displays **which configuration is currently active**, making it easy to see at a
glance which Home Assistant instance you're connected to.

## Visual Design

### Before

```
┌─────────────────────────────────────┐
│ 🏠 HA-bitat           [Dashboard]   │  ← Just app name and page
└─────────────────────────────────────┘
```

### After

```
┌─────────────────────────────────────┐
│ 🏠 HA-bitat           [Dashboard]   │
│ 🟢 Home • Internal                  │  ← Active config indicator!
└─────────────────────────────────────┘
```

## What It Shows

The indicator displays:

- **🟢 Green dot** - Indicates active connection
- **Configuration name** - e.g., "Home", "Office", "Vacation Home"
- **Connection type** - "Internal" or "External"

### Examples

**Using Internal URL**:

```
🟢 Home • Internal
```

**Using External URL**:

```
🟢 Office • External
```

**Multiple Configurations**:

```
🟢 Vacation Home • Internal
```

## Location

The indicator appears:

- **Below the main header** (app name and page name)
- **Above the main content** area
- **On all screens** (Dashboard, History, Events, Config, Tabs)
- **Left-aligned** for consistency

## Benefits

### 1. Always Know Your Context

No more confusion about which Home Assistant instance you're controlling!

### 2. See Connection Type

Quickly identify if you're on internal or external connection.

### 3. Multi-Config Management

Essential when managing multiple homes or locations.

### 4. Visual Confirmation

Green dot provides instant visual feedback that you're connected.

## Complete Header Layout

```
┌─────────────────────────────────────┐
│ 🏠 HA-bitat           [Dashboard]   │  ← App branding & page name
│ 🟢 Home • Internal                  │  ← Active config indicator
├─────────────────────────────────────┤
│                                     │
│ [Main Content Area]                 │
│                                     │
└─────────────────────────────────────┘
```

## Scenarios

### Single Configuration User

```
🟢 Home • Internal
```

- See your home name
- Know you're on local network

### Multiple Configuration User - Switching

```
Before: 🟢 Home • Internal
  ↓ (Switch to Office config)
After:  🟢 Office • External
```

- Clear visual feedback of switch
- No confusion about which system

### Remote Access

```
🟢 Home • External
```

- Know you're connecting remotely
- Aware of using external URL

### Network Switching

```
At home:  🟢 Home • Internal   (on local WiFi)
Away:     🟢 Home • External   (on cellular/other WiFi)
```

- Can toggle between internal/external
- Always see which connection type

## When It Appears

**Shows When**:

- ✅ An active configuration exists
- ✅ Successfully connected to Home Assistant
- ✅ On all tabs/screens

**Hidden When**:

- ❌ No configuration set up yet
- ❌ On configuration setup screen (would be redundant)

## Typography & Styling

**Green Dot**:

- Size: 8pt circle
- Color: System green (indicates active/connected)
- Always present when config is active

**Configuration Name**:

- Font: Caption (small, non-intrusive)
- Color: Secondary (gray, doesn't compete with main content)
- Weight: Regular

**Separator**:

- Character: `•` (bullet)
- Color: Secondary
- Purpose: Visual separation

**Connection Type**:

- Text: "Internal" or "External"
- Font: Caption
- Color: Secondary
- Dynamic: Updates when toggled

## User Experience

### Clarity

Users always know:

- Which system they're controlling
- Whether they're on internal or external connection
- Visual confirmation via green dot

### Space Efficient

- Compact design (single line)
- Doesn't take much vertical space
- Non-intrusive placement

### Informative

- Configuration name (custom user label)
- Connection type (technical detail)
- Status indicator (visual confirmation)

## Real-World Usage

### Example 1: Home User

```
Header shows: 🟢 Home • Internal

User knows:
- Connected to "Home" instance
- On local network (faster, more reliable)
- Can control all devices locally
```

### Example 2: Managing Multiple Locations

```
Configuration 1: 🟢 Main House • Internal
Configuration 2: 🟢 Vacation Home • External
Configuration 3: 🟢 Parents House • External

User benefits:
- Never confused about which home
- Clear indication of connection type
- Easy to verify before controlling devices
```

### Example 3: Troubleshooting

```
User: "Why is my response slow?"
Header: 🟢 Home • External

User realizes: "Ah, I'm on external - let me switch to internal"
[Taps Dashboard → Toggles to Internal]
Header: 🟢 Home • Internal

User: "Much faster now!"
```

## Technical Details

**File**: `ContentView.swift`

**Implementation**:

```swift
if let activeConfig = viewModel.activeConfiguration {
    HStack(spacing: 6) {
        Image(systemName: "circle.fill")
            .font(.system(size: 8))
            .foregroundColor(.green)
        Text(activeConfig.name)
            .font(.caption)
            .foregroundColor(.secondary)
        Text("•")
            .font(.caption)
            .foregroundColor(.secondary)
        Text(activeConfig.useInternalUrl ? "Internal" : "External")
            .font(.caption)
            .foregroundColor(.secondary)
    }
}
```

**Dynamic Updates**:

- Automatically updates when configuration changes
- Updates when toggling internal/external
- Reactively bound to `viewModel.activeConfiguration`

## Comparison: Header Evolution

### Version 1 (Original)

```
🏠 HA-bitat           [Dashboard]
```

Simple but no context

### Version 2 (Current)

```
🏠 HA-bitat           [Dashboard]
🟢 Home • Internal
```

Context-aware and informative!

## Future Enhancements

Possible additions:

1. **Connection status** - Red dot if disconnected
2. **Last sync time** - "Updated 2m ago"
3. **Device count** - "15 devices"
4. **Tap to switch** - Quick config switcher
5. **Signal strength** - Internal: ••••, External: ••

## Test It

1. **Open the app** with an active configuration
2. **Look at the header** - see configuration name
3. **Note the green dot** - indicates active
4. **See connection type** - "Internal" or "External"
5. **Switch configurations** - watch it update
6. **Toggle internal/external** on Dashboard - watch it change
7. **Navigate between tabs** - always visible

You'll always know exactly which Home Assistant you're controlling! 🏠✨
