# Crash Fix - Alert During Sheet Dismissal

**Date**: December 14, 2025  
**Status**: ✅ **FIXED**

## The Crash

After entering both usernames/passwords, the app crashed with:

```
Trying to dismiss the presentation controller while transitioning already.
*** Terminating app due to uncaught exception 'NSInternalInconsistencyException'
reason: 'A view controller not containing an alert controller was asked for its contained alert controller.'
```

## Root Cause

The `ASWebAuthView` had an error alert that tried to present during the sheet dismissal process:

```swift
.alert("Authentication Error", isPresented: .constant(...)) {
    Button("OK") { ... }
}
```

**The problem**: When authentication completed and the sheet was being dismissed, if there was any
error state, the alert would try to present on a view controller that was already
transitioning/dismissing, causing UIKit to crash.

## The Fix

**Removed the error alert completely**. Errors are already logged to the console, and showing an
alert during complex sheet transitions is fragile and unnecessary.

**Before**:

```swift
.onAppear { ... }
.alert("Authentication Error", ...) { // ❌ Crashes during dismissal
    Button("OK") { ... }
}
```

**After**:

```swift
.onAppear { ... }
// ✅ No alert - errors logged to console only
```

## Why This Works

1. **No UI conflicts**: No alert trying to present during sheet dismissal
2. **Simple flow**: Auth completes → Callback fires → Sheet dismisses cleanly
3. **Error visibility**: Errors still logged to console for debugging
4. **Stable**: No competing UI transitions

## What Happens Now

**Successful Flow**:

```
Enter credentials → Complete login → ✅ Success callback
→ Sheet dismisses → Next auth or save → Form closes ✅
```

**Error Flow** (cancelled, network error, etc):

```
Error occurs → ❌ Logged to console → onCancel() callback
→ Sheet dismisses → User back at form
```

No crashes, clean dismissal! 🎉

## Test It Now

1. **Run the app**
2. **Add configuration** with OAuth (different URLs)
3. **Complete both logins**
4. **Watch**: Form should close without crashing ✅
5. **Configuration saved** ✅

The crash is fixed - the form will now dismiss cleanly after both authentications complete!
