# App Transport Security Configuration Required

**Status**: ⚠️ **ACTION NEEDED**

## The Problem

Your app is in a loop because the **external URL authentication is failing** due to App Transport
Security (ATS) blocking HTTP connections.

From the console log:

```
❌ Authentication failed for http://geekychris.com:8123: 
The resource could not be loaded because the App Transport Security policy 
requires the use of a secure connection.
```

## Root Cause

1. ✅ **Internal auth succeeds**: `http://homeassistant.local:8123` (local domains bypass ATS)
2. ❌ **External auth fails**: `http://geekychris.com:8123` (ATS blocks HTTP to non-local domains)
3. **Failure triggers `onCancel()`** → Returns to form → Loop!

## Solution 1: Configure ATS in Xcode (Recommended)

You must manually configure App Transport Security in Xcode:

### Steps:

1. **Open project in Xcode**
2. **Select the project** in the navigator (top item)
3. **Select the "SimpleHomeAssistant" target**
4. **Go to "Info" tab**
5. **Add a new key**:
    - Right-click in the Custom iOS Target Properties list
    - Click "Add Row"
    - Add key: `App Transport Security Settings` (type: Dictionary)
6. **Expand the dictionary**, add a Boolean key:
    - Key: `Allow Arbitrary Loads`
    - Type: Boolean
    - Value: YES

### Alternative (More Secure):

Instead of allowing all HTTP, allow only specific domains:

```
App Transport Security Settings (Dictionary)
  └─ Exception Domains (Dictionary)
       └─ geekychris.com (Dictionary)
            ├─ NSExceptionAllowsInsecureHTTPLoads (Boolean): YES
            └─ NSIncludesSubdomains (Boolean): YES
       └─ homeassistant.local (Dictionary)
            ├─ NSExceptionAllowsInsecureHTTPLoads (Boolean): YES
            └─ NSIncludesSubdomains (Boolean): YES
```

## Solution 2: Use HTTPS for External URL

**Best practice**: Configure your external Home Assistant with HTTPS:

1. Set up Let's Encrypt SSL certificate
2. Use HTTPS URL: `https://geekychris.com:8123`
3. No ATS configuration needed!

## Solution 3: Code Workaround (Temporary)

I can modify the code to:

- If external auth fails with ATS error, automatically use the internal token for both
- Show a warning message to the user

Would you like me to implement this workaround?

## Why This Matters

- **Security**: ATS protects users by requiring secure HTTPS connections
- **Your case**: Home Assistant typically uses HTTP by default (insecure)
- **The fix**: Either allow HTTP in ATS settings OR configure Home Assistant with HTTPS

## Quick Test

After configuring ATS, the flow will be:

```
Internal auth → ✅ Success
External auth → ✅ Success (no more ATS error)
Both tokens saved → Form closes → Done! ✅
```

## Next Steps

1. **Option A**: Configure ATS in Xcode (see steps above)
2. **Option B**: Set up HTTPS on your Home Assistant
3. **Option C**: Let me implement a code workaround

Let me know which approach you prefer!
