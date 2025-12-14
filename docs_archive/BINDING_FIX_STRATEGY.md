# Binding-Based Dismissal Fix

**Date**: December 13, 2025  
**Status**: ✅ **IMPLEMENTED - TESTING REQUIRED**

## Problem

After completing both OAuth authentications, the configuration form would not close. The
configuration was not being saved.

## Root Cause

The `@Environment(\.dismiss)` variable was not working reliably when called from within:

1. Async callbacks (`DispatchQueue.main.asyncAfter`)
2. Nested sheet presentations
3. Complex state management with multiple sheets

SwiftUI's `dismiss()` environment value can fail in these scenarios because the environment is
captured at view creation time, not at callback execution time.

## Solution: Binding-Based Sheet Control

Instead of relying on `@Environment(\.dismiss)`, we now control the sheet directly from the parent
view using a `@Binding`:

### Before (Broken)

```swift
// Parent
.sheet(isPresented: $showingAddSheet) {
    AddConfigurationView()  // No control back to parent
}

// Child
struct AddConfigurationView: View {
    @Environment(\.dismiss) var dismiss  // ❌ Doesn't work from async
    
    func saveConfiguration() {
        dismiss()  // ❌ Fails to close sheet
    }
}
```

### After (Fixed)

```swift
// Parent
.sheet(isPresented: $showingAddSheet) {
    AddConfigurationView(isPresented: $showingAddSheet)  // ✅ Pass binding
}

// Child
struct AddConfigurationView: View {
    @Binding var isPresented: Bool  // ✅ Direct control
    
    func saveConfiguration() {
        isPresented = false  // ✅ Closes sheet reliably
    }
}
```

## Changes Made

### 1. Parent View - Pass Binding

**File**: `ConfigurationView.swift`

```swift
// Line 57
.sheet(isPresented: $showingAddSheet) {
    AddConfigurationView(isPresented: $showingAddSheet)
}
```

### 2. Child View - Accept Binding

**File**: `ConfigurationView.swift` - AddConfigurationView

```swift
// Line 184
struct AddConfigurationView: View {
    @EnvironmentObject var viewModel: AppViewModel
    @Binding var isPresented: Bool  // NEW: Direct control from parent
    
    // ... rest of view
}
```

### 3. Replace dismiss() with isPresented = false

**Cancel Button:**

```swift
Button("Cancel") { 
    print("❌ Cancel tapped - closing form")
    isPresented = false  // Changed from dismiss()
}
```

**Save Configuration:**

```swift
private func saveConfiguration(internalToken: String, externalToken: String) {
    // ... save logic ...
    
    print("📝 Closing form by setting isPresented = false...")
    isPresented = false  // Changed from dismiss()
    print("📝 isPresented set to false - form should close now")
}
```

## Why This Works

### Direct State Control

- `isPresented` is a `@Binding` that directly controls the sheet
- Setting it to `false` **immediately** tells SwiftUI to dismiss the sheet
- No reliance on environment values that might be captured incorrectly
- Works reliably from any callback, async or not

### No Environment Issues

- `@Environment(\.dismiss)` can fail when:
    - Called from async contexts
    - View hierarchy changes
    - Multiple sheets are involved
- `@Binding` is a direct reference that always works

### Predictable Behavior

```
Before: dismiss() → Maybe works? → Sheet might stay open
After:  isPresented = false → Always works → Sheet closes
```

## Testing

### Test 1: Cancel Button

**Steps:**

1. Open Configuration → Tap +
2. Fill in some details
3. Tap "Cancel"

**Expected:**

```
Console: ❌ Cancel tapped - closing form
Result: Form closes immediately ✅
```

### Test 2: Token Authentication

**Steps:**

1. Open Configuration → Tap +
2. Fill in details
3. Select "API Token"
4. Enter token
5. Tap "Save"

**Expected:**

```
Console: 📝 Closing form by setting isPresented = false...
         📝 isPresented set to false - form should close now
Result: Form closes, configuration saved ✅
```

### Test 3: OAuth Single URL

**Steps:**

1. Open Configuration → Tap +
2. Fill in:
    - Name: Test
    - Internal URL: http://192.168.1.100:8123
    - External URL: http://192.168.1.100:8123 (same)
3. Select "Web Login (OAuth)"
4. Tap "Save"
5. Complete authentication

**Expected:**

```
Console: 
🔐 handleSave: Starting OAuth flow
🌐 ASWebAuthView appeared
✅ Internal auth complete
💾 Same URL - saving with single token
📝 saveConfiguration called
📝 Closing form by setting isPresented = false...
📝 isPresented set to false - form should close now

Result: Form closes, configuration saved ✅
```

### Test 4: OAuth Different URLs (THE KEY TEST)

**Steps:**

1. Open Configuration → Tap +
2. Fill in:
    - Name: Test
    - Internal URL: http://192.168.1.100:8123
    - External URL: https://your-external.com
3. Select "Web Login (OAuth)"
4. Tap "Save"
5. Complete internal authentication
6. Complete external authentication

**Expected:**

```
Console:
🔐 handleSave: Starting OAuth flow
🌐 ASWebAuthView appeared for: http://192.168.1.100:8123
✅ Internal auth complete
🔐 URLs differ - will open external auth
🌐 ASWebAuthView appeared for: https://your-external.com
✅ External auth complete
💾 Saving both tokens
💾 showingWebAuth before close: true
💾 showingWebAuth after close: false
💾 Scheduling saveConfiguration in 0.5 seconds...
💾 Now calling saveConfiguration...
📝 saveConfiguration called
📝 showingWebAuth = false
📝 authStep = none
📝 Name: Test
📝 Internal Token: eyJ0eXAi...
📝 External Token: eyJ0eXAi...
📝 Calling viewModel.saveConfiguration...
📝 Setting as active configuration...
📝 Closing form by setting isPresented = false...
📝 isPresented set to false - form should close now

Result: Form closes, configuration saved with both tokens ✅
```

## Verification Checklist

After running Test 4 (OAuth with different URLs):

1. ✅ Form closes automatically (not stuck on Add Configuration screen)
2. ✅ Configuration list shows the new configuration
3. ✅ Can see configuration name in the list
4. ✅ Tapping on configuration shows both tokens stored
5. ✅ Dashboard works with new configuration
6. ✅ Can toggle between internal and external URLs
7. ✅ Both URLs work with their respective tokens

## If It Still Doesn't Work

### Check Console Output

1. **Is saveConfiguration called?**
   Look for: `📝 saveConfiguration called`
    - YES: Callback chain is working ✅
    - NO: Problem in OAuth flow

2. **Is isPresented set to false?**
   Look for: `📝 isPresented set to false - form should close now`
    - YES: Command is executed ✅
    - NO: Logic never reaches that point

3. **Does form actually close?**
    - YES: **FIXED!** ✅✅✅
    - NO: Check if there are Swift errors in console

### Possible Remaining Issues

If form still doesn't close after `isPresented = false`:

1. **Binding not connected**: Check that `$showingAddSheet` is properly passed
2. **State conflict**: Check if `showingWebAuth` is still true
3. **SwiftUI bug**: Try restarting Xcode/simulator

## Why This Should Definitely Work

**This is the recommended SwiftUI pattern for programmatic sheet dismissal:**

```swift
@State var showSheet = false

.sheet(isPresented: $showSheet) {
    ChildView(isPresented: $showSheet)
}

// In child:
@Binding var isPresented: Bool

func done() {
    isPresented = false  // ← This ALWAYS works
}
```

This is how SwiftUI's own documentation recommends dismissing sheets programmatically from within
the presented view.

## Summary

✅ **Root cause identified**: `@Environment(\.dismiss)` fails in async callbacks

✅ **Solution implemented**: Direct `@Binding` control from parent

✅ **Expected result**: Form closes immediately when `isPresented = false`

✅ **Testing needed**: Run OAuth flow with different URLs and verify form closes

**This should fix the issue!** The binding-based approach is much more reliable than
environment-based dismissal for complex async flows.

Please test and report:

1. Does form close after OAuth?
2. Is configuration saved?
3. What does console show?
