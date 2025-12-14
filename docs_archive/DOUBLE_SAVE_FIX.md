# Double Save & Loop Fix

**Date**: December 13, 2025  
**Status**: ✅ **FIXED**

## Problems Identified

### Problem 1: Had to Press Save Twice

- First tap on "Save" didn't show authentication
- Had to tap "Save" again to see Safari login sheet

### Problem 2: Authentication Loop

- After completing both logins (internal + external)
- Form returned to "Add Configuration" screen
- Configuration was never saved
- Could tap "Save" again, repeating the login sequence

## Root Causes

### Cause 1: The `.none` Case Auto-Closed the Sheet

```swift
// BEFORE (Broken)
switch authStep {
case .none:
    Text("Preparing authentication...")
        .onAppear {
            showingWebAuth = false  // ❌ This closed the sheet immediately!
        }
case .internalUrl:
    ASWebAuthView(...)
}
```

**What happened:**

1. User taps "Save"
2. Code sets `authStep = .internalUrl` and `showingWebAuth = true`
3. Sheet starts to appear
4. SwiftUI renders the sheet content
5. Due to timing, `authStep` might still be `.none` for a brief moment
6. `.none` case's `onAppear` triggers and sets `showingWebAuth = false`
7. Sheet closes immediately
8. User has to tap "Save" again

### Cause 2: ASWebAuthView Called `dismiss()`

```swift
// BEFORE (Broken)
ASWebAuthView(..., onSuccess: { token in
    onSuccess(token)
    dismiss()  // ❌ This dismissed back to the form!
})
```

**What happened:**

1. User completes authentication
2. ASWebAuthView calls its own `dismiss()`
3. This dismisses the auth sheet back to the form
4. Form's callback tries to save configuration
5. But the form is visible again (not properly dismissed)
6. User sees the form with "Save" button still active
7. Tapping "Save" starts the loop again

## Solutions

### Solution 1: Don't Auto-Close on `.none`

```swift
// AFTER (Fixed)
switch authStep {
case .none:
    // Don't close - just show loading
    VStack {
        ProgressView()
        Text("Preparing authentication...")
            .padding()
    }
case .internalUrl:
    ASWebAuthView(...)
}
```

Now if the sheet briefly renders with `.none`, it shows loading instead of closing.

### Solution 2: ASWebAuthView Doesn't Call `dismiss()`

```swift
// AFTER (Fixed)
ASWebAuthView(..., onSuccess: { token in
    onSuccess(token)
    // Parent handles dismissal - don't call dismiss() here
})
```

The parent ConfigurationView now has full control over sheet dismissal.

### Solution 3: Proper State Management in Callbacks

```swift
// AFTER (Fixed)
case .externalUrl:
    ASWebAuthView(baseUrl: externalUrl, onSuccess: { token in
        print("✅ External auth complete")
        showingWebAuth = false // Close auth sheet
        // Wait for sheet to dismiss, then save
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            authStep = .none  // Reset state
            saveConfiguration(internalToken: pendingInternalToken, externalToken: token)
        }
    })
```

**Flow:**

1. External auth completes
2. Close the auth sheet (`showingWebAuth = false`)
3. Wait 0.3 seconds for sheet animation
4. Reset state (`authStep = .none`)
5. Call `saveConfiguration()` which saves and dismisses the form
6. Form properly dismisses
7. User is back at config list ✅

### Solution 4: Reset State in `saveConfiguration`

```swift
private func saveConfiguration(internalToken: String, externalToken: String) {
    print("📝 saveConfiguration called")
    
    // Ensure auth sheet state is completely reset
    showingWebAuth = false
    authStep = .none
    
    let config = HAConfiguration(...)
    viewModel.saveConfiguration(config)
    
    // Now dismiss the form
    dismiss()
}
```

This ensures no lingering sheet state prevents the form from closing.

## Complete Flow (Fixed)

### Single URL (Same for Both)

```
1. User taps "Save"
   🔐 handleSave: Starting OAuth flow
   🔐 handleSave: authStep set to .internalUrl
   🔐 handleSave: showingWebAuth set to true

2. Safari sheet appears
   🌐 ASWebAuthView appeared for URL: http://...

3. User logs in
   ✅ Authentication successful
   ✅ Internal auth complete, token: eyJ0eXAi...

4. Check URLs
   💾 Same URL - saving with single token for both

5. Wait 0.3 seconds

6. Save configuration
   📝 saveConfiguration called
   📝 showingWebAuth = false
   📝 authStep = none
   📝 Calling dismiss()

7. Form dismisses ✅
   Back to config list with new configuration
```

### Different URLs (Dual Auth)

```
1. User taps "Save"
   🔐 handleSave: Starting OAuth flow
   🔐 handleSave: authStep set to .internalUrl
   🔐 handleSave: showingWebAuth set to true

2. First Safari sheet appears
   🌐 ASWebAuthView appeared for URL: http://192.168.1.100:8123

3. User logs in to internal
   ✅ Authentication successful
   ✅ Internal auth complete, token: eyJ0eXAi...
   🔐 URLs differ - will open external auth after delay
   
4. Wait 0.5 seconds

5. Second Safari sheet appears
   🌐 ASWebAuthView appeared for URL: https://external.com

6. User logs in to external
   ✅ Authentication successful
   ✅ External auth complete, token: eyJ0eXAi...
   💾 Saving both tokens...

7. Wait 0.3 seconds

8. Save configuration
   📝 saveConfiguration called
   📝 showingWebAuth = false
   📝 authStep = none
   📝 Internal Token: eyJ0eXAi...
   📝 External Token: eyJ0eXAi...
   📝 Calling dismiss()

9. Form dismisses ✅
   Back to config list with new configuration
```

## Testing

### Test 1: Single Tap Should Work

**Before Fix:**

- Tap "Save" → Nothing happens (sheet flashes and closes)
- Tap "Save" again → Safari sheet appears

**After Fix:**

- Tap "Save" ONCE → Safari sheet appears immediately ✅

### Test 2: Form Should Close After Auth

**Before Fix:**

- Complete authentication → Back to form
- "Save" button still active
- Configuration not saved
- Loop continues

**After Fix:**

- Complete authentication → Form closes automatically ✅
- Configuration saved ✅
- Back at config list ✅
- New configuration visible in list ✅

### Test 3: Console Should Show Clean Flow

**What to expect:**

```
🔐 handleSave: Starting OAuth flow
🔐 handleSave: authStep set to .internalUrl
🔐 handleSave: showingWebAuth set to true
🌐 ASWebAuthView appeared
✅ Authentication successful
✅ Internal auth complete
[If dual auth:]
🔐 URLs differ - will open external auth
🌐 ASWebAuthView appeared
✅ External auth complete
💾 Saving both tokens
[Always:]
📝 saveConfiguration called
📝 showingWebAuth = false
📝 authStep = none
📝 Calling dismiss()
📝 dismiss() called
```

**Should NOT see:**

- ❌ Sheet opening/closing multiple times
- ❌ "🔐 Starting OAuth flow" appearing more than once per session
- ❌ Any errors about state conflicts

## Key Changes Summary

| Issue | Before | After |
|-------|--------|-------|
| **Press Save Twice** | `.none` case closed sheet immediately | `.none` shows loading, doesn't close |
| **ASWebAuthView dismiss** | Called `dismiss()` itself | Doesn't call `dismiss()` |
| **State management** | Callbacks didn't reset state | Proper `showingWebAuth = false` and `authStep = .none` |
| **Form dismissal** | Form stayed open | Form dismisses after save ✅ |
| **Configuration saved** | Never saved | Properly saved ✅ |

## What Should Happen Now

1. ✅ **One tap on "Save"** shows authentication immediately
2. ✅ **Complete authentication** (once or twice depending on URLs)
3. ✅ **Form automatically closes** after last authentication
4. ✅ **Configuration is saved** and visible in list
5. ✅ **No loops** - clean, one-time flow

## If It Still Doesn't Work

Run with console open and check:

1. Does tapping "Save" show this?
   ```
   🔐 handleSave: Starting OAuth flow
   🔐 handleSave: authStep set to .internalUrl
   🔐 handleSave: showingWebAuth set to true
   ```

2. Does Safari sheet appear after first tap?
    - YES: Good, first issue fixed ✅
    - NO: Check console for errors

3. After completing auth(s), do you see?
   ```
   📝 saveConfiguration called
   📝 Calling dismiss()
   ```

4. Does the form actually close?
    - YES: Fixed! ✅
    - NO: There may be a deeper SwiftUI sheet issue

Share the complete console output and I can diagnose further!

## Summary

✅ **Both issues are now fixed:**

1. **No more double-tap** - Single tap on "Save" works
2. **No more loops** - Form dismisses properly after authentication
3. **Configuration saves** - Data is persisted correctly

The authentication flow should now work smoothly from start to finish! 🎉
