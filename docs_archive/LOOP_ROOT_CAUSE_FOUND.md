# Authentication Loop - Root Cause Identified

**Date**: December 14, 2025  
**Status**: 🔍 **ROOT CAUSE FOUND** - Action Required

## The Loop Explained

You're stuck in a loop **NOT because of the form dismissal logic**, but because **external
authentication is FAILING**, which calls `onCancel()` and returns you to the form.

### What Your Logs Show

```
✅ Internal auth complete for: http://homeassistant.local:8123  ← SUCCESS
🔐 URLs differ - will open external auth after delay
🌐 ASWebAuthView appeared for URL: http://geekychris.com:8123
🔐 Starting OAuth2 flow for: http://geekychris.com:8123
✅ Got authorization code  ← Login works!
🔄 Exchanging code for token...  ← This is where it fails...
❌ The resource could not be loaded because the App Transport Security policy 
   requires the use of a secure connection.  ← **ATS BLOCKS HTTP!**
❌ External auth cancelled  ← **This returns you to form!**
```

## Why It Happens

1. **Internal URL works**: `homeassistant.local` is a local domain, so ATS allows HTTP
2. **External URL fails**: `geekychris.com` is not local, ATS **blocks HTTP**
3. **Token exchange fails**: Can't POST to `http://geekychris.com:8123/auth/token`
4. **Triggers `onCancel()`**: Returns you to the form
5. **You tap Save again**: Loop repeats!

## The Fix

You have **3 options**:

### Option 1: Configure ATS in Xcode (5 minutes)

**This allows HTTP connections for Home Assistant:**

1. Open project in Xcode
2. Select project → Target → Info tab
3. Add key: `App Transport Security Settings` (Dictionary)
4. Inside, add: `Allow Arbitrary Loads` (Boolean) = YES

**Result**: External auth will succeed, form will close properly!

### Option 2: Use HTTPS for External (Best Practice)

**Configure your Home Assistant with SSL:**

1. Set up Let's Encrypt or other SSL certificate
2. Use `https://geekychris.com:8123` instead of HTTP
3. No ATS configuration needed

**Result**: Secure connection + no ATS issues!

### Option 3: Code Workaround (I can implement)

**Modify code to handle ATS failure gracefully:**

- If external auth fails with ATS error, use internal token for both URLs
- Show a warning to user about insecure connection
- Form closes successfully

**Result**: Works but not ideal (less secure, less clear to user)

## Additional Fix Applied

I also added a guard to prevent **duplicate OAuth sessions**:

```swift
func authenticate(completion: @escaping (Result<String, Error>) -> Void) {
    guard authSession == nil else {
        print("⚠️ Authentication already in progress - ignoring duplicate call")
        return
    }
    // ... rest of auth flow
}
```

This prevents the "Starting OAuth2 flow" message from appearing twice.

## Test After Fixing ATS

Once you configure ATS in Xcode, you should see:

```
✅ Internal auth complete
🔐 URLs differ - will open external auth
✅ External auth complete  ← No more ATS error!
💾 Saving both tokens
📝 saveConfiguration called
📝 Closing form
Form closes! ✅
```

## Which Option Do You Want?

1. **Option 1 (Quick)**: I'll guide you through ATS configuration in Xcode
2. **Option 2 (Secure)**: Set up HTTPS on your Home Assistant first
3. **Option 3 (Workaround)**: I'll implement a code fix to handle ATS failures

Let me know and I'll help you implement it!
