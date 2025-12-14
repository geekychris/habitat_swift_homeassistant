# WebView Not Appearing - Troubleshooting Guide

## Issue

When selecting "Web Login (OAuth)" and tapping "Save", the browser/WebView does not appear.

## Potential Causes & Solutions

### 1. URL Scheme Not Registered ⚠️

**Problem**: The `homeassistant://` URL scheme may not be properly registered in the Xcode project.

**Solution**: Add URL scheme to project

#### Method A: Via Xcode UI (Recommended)

1. Open `SimpleHomeAssistant.xcodeproj` in Xcode
2. Select the **SimpleHomeAssistant** target
3. Go to the **Info** tab
4. Find "URL Types" section (may need to scroll down)
5. Click the **+** button to add a new URL Type
6. Fill in:
    - **Identifier**: `com.homeassistant.auth`
    - **URL Schemes**: `homeassistant`
    - **Role**: Editor
7. Build and run

#### Method B: Via Project File (Advanced)

Edit `SimpleHomeAssistant.xcodeproj/project.pbxproj` and add to the target's build settings:

```
INFOPLIST_KEY_CFBundleURLTypes = (
    {
        CFBundleTypeRole = Editor;
        CFBundleURLName = "com.homeassistant.auth";
        CFBundleURLSchemes = (homeassistant);
    },
);
```

### 2. Sheet Animation Issue

**Problem**: The sheet might be trying to show before `authStep` is set correctly.

**Status**: ✅ Fixed in latest code with switch statement

The code now uses:

```swift
.sheet(isPresented: $showingWebAuth) {
    Group {
        switch authStep {
        case .none:
            Text("Preparing authentication...")
        case .internalUrl:
            WebViewAuthView(...)
        case .externalUrl:
            WebViewAuthView(...)
        }
    }
}
```

### 3. Invalid URL Format

**Problem**: The URL might be malformed or empty.

**Test**: Add debug logging to see what URL is being used:

```swift
private func handleSave() {
    if authType == .oauth {
        print("🔐 OAuth selected")
        print("🔐 Internal URL: '\(internalUrl)'")
        print("🔐 External URL: '\(externalUrl)'")
        authStep = .internalUrl
        showingWebAuth = true
        print("🔐 authStep = \(authStep), showingWebAuth = \(showingWebAuth)")
    }
}
```

Check Console output (Cmd+Shift+Y in Xcode) when tapping Save.

### 4. WebView Initialization Error

**Problem**: WebViewAuthController might be failing to initialize.

**Test**: Check for errors in WebViewAuthController initialization:

```swift
// In WebViewAuthView.onAppear
.onAppear {
    print("🌐 WebViewAuthView appeared")
    print("🌐 Base URL: \(baseUrl)")
    if let authURL = authController.getAuthorizationURL() {
        print("🌐 Auth URL: \(authURL.absoluteString)")
    } else {
        print("❌ Failed to create auth URL")
    }
}
```

### 5. SwiftUI Navigation Issue

**Problem**: The NavigationView wrapping might be interfering.

**Test**: Try presenting the sheet from a different level in the view hierarchy.

## Debugging Steps

### Step 1: Enable All Debug Logging

Run the app with Xcode debugger attached and watch the Console for:

- "🔐 Starting OAuth flow"
- "🔐 showingWebAuth set to true"
- "🌐 WebViewAuthView appeared"

### Step 2: Verify URL Scheme

Run this command to check if URL scheme is in the built app:

```bash
# After building, check the Info.plist in the built app
plutil -p ~/Library/Developer/Xcode/DerivedData/SimpleHomeAssistant-*/Build/Products/Debug-iphonesimulator/SimpleHomeAssistant.app/Info.plist | grep -A 10 CFBundleURLTypes
```

Expected output:

```
"CFBundleURLTypes" => [
    0 => {
        "CFBundleTypeRole" => "Editor"
        "CFBundleURLName" => "com.homeassistant.auth"
        "CFBundleURLSchemes" => [
            0 => "homeassistant"
        ]
    }
]
```

### Step 3: Test WebView Directly

Create a simple test view to verify WebView works:

```swift
struct TestWebView: View {
    var body: some View {
        WebViewAuthView(
            baseUrl: "http://192.168.1.100:8123",
            onSuccess: { token in
                print("Token: \(token)")
            },
            onCancel: {
                print("Cancelled")
            }
        )
    }
}
```

Present this view directly from a button to isolate the issue.

### Step 4: Check Sheet State

Add this to AddConfigurationView:

```swift
var body: some View {
    NavigationView {
        Form {
            // ... existing form content ...
            
            // Debug section
            Section("Debug") {
                Text("Auth Type: \(authType == .token ? "Token" : "OAuth")")
                Text("Auth Step: \(String(describing: authStep))")
                Text("Showing Web Auth: \(showingWebAuth ? "Yes" : "No")")
            }
        }
        // ... rest of body ...
    }
}
```

This will show you the exact state before and after tapping Save.

## Quick Fix Test

Try this minimal working example:

```swift
struct SimpleOAuthTest: View {
    @State private var showSheet = false
    
    var body: some View {
        NavigationView {
            VStack {
                Button("Test OAuth") {
                    print("Button tapped")
                    showSheet = true
                    print("showSheet = \(showSheet)")
                }
                .padding()
            }
            .sheet(isPresented: $showSheet) {
                Text("Sheet is showing!")
                    .padding()
                    .onAppear {
                        print("Sheet appeared")
                    }
            }
        }
    }
}
```

If this works, the issue is with the OAuth-specific code. If it doesn't, the issue is with the sheet
presentation itself.

## Expected Behavior

When working correctly:

1. User taps "Save" with OAuth selected
2. Console shows: "🔐 Starting OAuth flow for internal URL: http://..."
3. Console shows: "🔐 showingWebAuth set to true, authStep = internalUrl"
4. Sheet animates up from bottom
5. WebView loads with Home Assistant login page
6. User can see username/password fields

## Current Status

- ✅ Build succeeds with no errors
- ✅ Code structure is correct
- ⚠️ URL scheme may not be registered (needs manual setup)
- ⚠️ Need to verify sheet is actually presenting

## Next Steps

1. **Add URL scheme via Xcode** (see Method A above)
2. **Run app with debugger** and check console output
3. **Test with simple button** to verify sheet works
4. **Check Console logs** for any WebView errors

## Alternative Approach

If WebView continues to fail, consider using ASWebAuthenticationSession instead:

```swift
import AuthenticationServices

class ASAuthController {
    func authenticate(url: URL, completion: @escaping (Result<String, Error>) -> Void) {
        let session = ASWebAuthenticationSession(
            url: url,
            callbackURLScheme: "homeassistant"
        ) { callbackURL, error in
            // Handle result
        }
        session.presentationContextProvider = self
        session.start()
    }
}
```

This is Apple's recommended way for OAuth and handles URL schemes automatically.
