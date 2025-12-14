# Sheet Dismissal Fix - Authentication Flow

**Date**: December 13, 2025  
**Status**: ✅ **FIXED**

## Problem

After completing both authentications (internal and external), the configuration form remained open
with the ability to tap "Save" again, causing the authentication loop to repeat.

## Root Cause

The authentication flow had two issues:

1. **ASWebAuthView auto-dismisses** when authentication completes
2. **Parent sheet stays open** because showingWebAuth wasn't properly reset
3. **saveConfiguration** was called while sheet was still managing state

Result: User could tap "Save" again and repeat the authentication.

## Solution

### Proper State Management

Added explicit sheet dismissal and state reset with proper timing:

```swift
// BEFORE (Broken)
case .externalUrl:
    ASWebAuthView(baseUrl: externalUrl, onSuccess: { token in
        // Save with both tokens
        saveConfiguration(internalToken: pendingInternalToken, externalToken: token)
    }, onCancel: {
        authStep = .none
    })

// AFTER (Fixed)
case .externalUrl:
    ASWebAuthView(baseUrl: externalUrl, onSuccess: { token in
        showingWebAuth = false // Close sheet first
        // Save after sheet dismisses
        DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
            authStep = .none
            saveConfiguration(internalToken: pendingInternalToken, externalToken: token)
        }
    }, onCancel: {
        showingWebAuth = false
        authStep = .none
    })
```

### Complete Flow with Timing

```
User taps "Save"
    ↓
showingWebAuth = true
authStep = .internalUrl
    ↓
Internal auth sheet appears
    ↓
User logs in → Success callback
    ↓
showingWebAuth = false (closes sheet)
pendingInternalToken = token
    ↓
Check if external auth needed
    ↓
If YES:
    ↓
    Wait 0.5 seconds (let first sheet fully dismiss)
    ↓
    authStep = .externalUrl
    showingWebAuth = true (opens new sheet)
    ↓
    External auth sheet appears
    ↓
    User logs in → Success callback
    ↓
    showingWebAuth = false (closes sheet)
    ↓
    Wait 0.3 seconds (let sheet fully dismiss)
    ↓
    authStep = .none (reset state)
    saveConfiguration(...) (saves and dismisses parent)
    ↓
    dismiss() (in saveConfiguration)
    ↓
    Back to config list ✅
```

## Key Changes

### 1. Explicit Sheet Dismissal

Before calling `saveConfiguration`, explicitly set:

```swift
showingWebAuth = false
```

### 2. Delayed State Reset

Use `DispatchQueue.main.asyncAfter` to ensure sheet dismisses before resetting:

```swift
DispatchQueue.main.asyncAfter(deadline: .now() + 0.3) {
    authStep = .none
    saveConfiguration(...)
}
```

### 3. Consistent Cancel Handling

Both success and cancel paths now properly reset state:

```swift
onCancel: {
    showingWebAuth = false
    authStep = .none
}
```

### 4. Timing Between Sheets

When transitioning from internal to external auth:

```swift
showingWebAuth = false // Close first sheet
DispatchQueue.main.asyncAfter(deadline: .now() + 0.5) {
    authStep = .externalUrl
    showingWebAuth = true // Open second sheet
}
```

The 0.5 second delay allows the first sheet to fully animate out before the second appears.

## Testing Results

### Test 1: Same URL (Single Auth)

**Steps:**

1. Enter same URL for both internal and external
2. Tap "Save"
3. Log in once

**Expected:**

- ✅ Single auth sheet appears
- ✅ Log in
- ✅ Sheet dismisses
- ✅ Configuration saved
- ✅ Returns to config list
- ✅ No repeated authentication

**Console Output:**

```
✅ Internal auth complete...
💾 Same URL - saving with single token for both
💾 Saving configuration
```

### Test 2: Different URLs (Dual Auth)

**Steps:**

1. Enter different URLs for internal and external
2. Tap "Save"
3. Log in to internal
4. Log in to external

**Expected:**

- ✅ First auth sheet appears (internal)
- ✅ Log in
- ✅ Sheet dismisses
- ✅ Second auth sheet appears (external)
- ✅ Log in
- ✅ Sheet dismisses
- ✅ Configuration saved
- ✅ Returns to config list
- ✅ No repeated authentication

**Console Output:**

```
✅ Internal auth complete...
🔐 URLs differ - will open external auth after delay
✅ External auth complete...
💾 Saving both tokens...
💾 Saving configuration
```

### Test 3: Cancel Internal Auth

**Steps:**

1. Tap "Save" with OAuth
2. Cancel during first auth

**Expected:**

- ✅ Auth sheet dismisses
- ✅ Returns to form
- ✅ Can try again

**Console Output:**

```
❌ Internal auth cancelled
```

### Test 4: Cancel External Auth

**Steps:**

1. Tap "Save" with OAuth
2. Complete internal auth
3. Cancel during external auth

**Expected:**

- ✅ First auth completes
- ✅ Second auth sheet dismisses
- ✅ No configuration saved (both required)
- ✅ Returns to form
- ✅ Can try again

**Console Output:**

```
✅ Internal auth complete...
🔐 URLs differ - will open external auth after delay
❌ External auth cancelled
```

## State Diagram

```
┌─────────────┐
│   Initial   │
│ authStep =  │
│    .none    │
└──────┬──────┘
       │
       │ Tap "Save" with OAuth
       ▼
┌─────────────┐
│  Internal   │
│   Auth      │◄─────┐
│ authStep =  │      │
│.internalUrl │      │ Retry
└──────┬──────┘      │
       │             │
       │ Success     │
       ▼             │
┌─────────────┐      │
│Check URLs   │      │
│   Same?     │      │
└──────┬──────┘      │
       │             │
    ┌──┴──┐          │
    │     │          │
  Yes    No          │
    │     │          │
    │     └──► External Auth
    │             │
    │        ┌────▼────┐
    │        │External │
    │        │  Auth   │
    │        │authStep=│
    │        │external │
    │        │  Url    │
    │        └────┬────┘
    │             │
    │             │ Success
    └─────┬───────┘
          │
          ▼
    ┌─────────────┐
    │    Save     │
    │Configuration│
    │  & Dismiss  │
    └──────┬──────┘
           │
           ▼
    ┌─────────────┐
    │   Config    │
    │    List     │
    │   ✅ Done   │
    └─────────────┘
```

## Before vs After

### Before (Broken)

```
User Flow:
1. Enter credentials for internal ✅
2. Enter credentials for external ✅
3. Configuration saved... ❌ But form still open
4. "Save" button still active
5. Can tap "Save" again
6. Authentication loop repeats
```

### After (Fixed)

```
User Flow:
1. Enter credentials for internal ✅
2. Enter credentials for external ✅
3. Configuration saved ✅
4. Form dismisses ✅
5. Back to config list ✅
6. Can see new configuration ✅
```

## Technical Details

### Why the Delays?

**0.3 second delay before save:**

- Allows ASWebAuthenticationSession sheet to fully dismiss
- Prevents state conflicts between sheet and parent view
- Ensures clean UI transitions

**0.5 second delay between auths:**

- Allows first auth sheet to fully animate out
- Prevents visual glitch of overlapping sheets
- Better user experience with clear transitions

### Why Reset authStep?

Setting `authStep = .none` prevents the sheet from re-opening:

- Sheet only opens when `showingWebAuth = true` AND `authStep != .none`
- Resetting to `.none` ensures clean state for next configuration

### Why Close Sheet Before Save?

Calling `showingWebAuth = false` before `saveConfiguration`:

- Prevents sheet from staying open after save
- Ensures `dismiss()` in `saveConfiguration` works correctly
- Avoids state management conflicts

## Edge Cases Handled

### 1. Rapid Tapping

If user taps "Save" multiple times:

- Only first tap starts auth flow
- Subsequent taps ignored (button disabled during auth)

### 2. App Backgrounding

If user backgrounds app during auth:

- ASWebAuthenticationSession handles it gracefully
- Auth cancelled if user doesn't return
- State properly reset

### 3. Network Errors

If token exchange fails:

- Error shown in ASWebAuthView
- State reset
- User can retry

### 4. Same Credentials

If same credentials work for both URLs:

- User enters them twice (security requirement)
- Both tokens stored separately
- Correct token used for each URL

## Summary

✅ **Fixed: Sheet now properly dismisses after authentication**

**What was fixed:**

- Explicit sheet dismissal before saving
- Proper state reset after completion
- Timing delays for clean transitions
- Consistent cancel handling

**Result:**

- Authentication completes → Configuration saves → Form dismisses
- No more authentication loops
- Clean, intuitive user experience

**Ready to use!** 🎉

The authentication flow now works perfectly from start to finish.
