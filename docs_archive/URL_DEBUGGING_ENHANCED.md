# Enhanced URL Debugging

**Date**: December 14, 2025  
**Status**: ✅ **IMPLEMENTED**

## What Changed

Added **detailed logging** to show exactly which URL is being used for API calls, making it easy to
verify that external/internal switching is working correctly.

## New Console Output

### When Fetching Entities

```
🔗 Fetching entities from: http://geekychris.com:8123
🔑 Auth type: oauth
🔑 Using external URL
📍 Internal URL: http://homeassistant.local:8123
📍 External URL: http://geekychris.com:8123
🎯 Actually using: http://geekychris.com:8123
📡 Response status: 200
```

### When Controlling Devices

```
🎬 Calling service light.toggle via: http://geekychris.com:8123
🔑 Using external URL
```

## How to Verify URL Switching

### In the App UI

1. **Look at the dashboard header**
    - Shows **"🏠 Internal"** (blue button) when using internal URL
    - Shows **"🌐 External"** (green button) when using external URL

2. **Tap the button to switch**
    - Button toggles between Internal ↔ External
    - Immediately reloads entities with new URL

### In the Console (Xcode)

1. **Open Console** (Cmd+Shift+Y in Xcode)
2. **Watch for logs** when:
    - Opening the dashboard
    - Refreshing entities
    - Toggling devices
    - Switching between Internal/External

3. **Verify the URLs**:
   ```
   📍 Internal URL: http://homeassistant.local:8123  ← Your internal
   📍 External URL: http://geekychris.com:8123       ← Your external
   🎯 Actually using: http://geekychris.com:8123     ← Which one is active
   ```

## What to Check

### Test Internal URL

1. **Tap the URL button** to ensure it shows **"🏠 Internal"** (blue)
2. **Pull to refresh** or wait for auto-refresh
3. **Check console** - should see:
   ```
   🔑 Using internal URL
   🎯 Actually using: http://homeassistant.local:8123
   ```

### Test External URL

1. **Tap the URL button** to switch to **"🌐 External"** (green)
2. **Pull to refresh** or wait for auto-refresh
3. **Check console** - should see:
   ```
   🔑 Using external URL
   🎯 Actually using: http://geekychris.com:8123
   ```

### Test Device Control

1. **Toggle a light or device**
2. **Check console** - should see which URL was used:
   ```
   🎬 Calling service light.toggle via: http://geekychris.com:8123
   🔑 Using external URL
   ```

## Troubleshooting

### If It Always Shows Internal URL

**Check**:

1. Is the button actually toggling? (Blue ↔ Green)
2. Are you refreshing/reloading after switching?
3. Check console for `📍 External URL:` - is it set correctly?

### If Both URLs Are The Same

**Check Configuration**:

1. Go to Configuration tab
2. Edit your configuration
3. Verify Internal URL and External URL are **different**

### If External URL Returns Errors

**Check**:

1. Is App Transport Security configured in Xcode? (if using HTTP)
2. Can you reach the external URL from your device/simulator?
3. Is the external token valid?

## Files Modified

- **`HomeAssistantAPI.swift`**
    - Added detailed URL logging in `fetchAllEntities()`
    - Added URL logging in `callService()`

## Example Debug Session

```
User opens app:
🔗 Fetching entities from: http://homeassistant.local:8123
🔑 Using internal URL
📍 Internal URL: http://homeassistant.local:8123
📍 External URL: http://geekychris.com:8123
🎯 Actually using: http://homeassistant.local:8123  ✅ Correct!

User taps URL button to switch:
🔗 Fetching entities from: http://geekychris.com:8123
🔑 Using external URL
📍 Internal URL: http://homeassistant.local:8123
📍 External URL: http://geekychris.com:8123
🎯 Actually using: http://geekychris.com:8123  ✅ Switched!

User toggles a light:
🎬 Calling service light.toggle via: http://geekychris.com:8123
🔑 Using external URL  ✅ Still using external!
```

The logging makes it crystal clear which URL is being used! 🔍
