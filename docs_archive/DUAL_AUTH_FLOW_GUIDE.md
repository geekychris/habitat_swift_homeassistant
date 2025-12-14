# Dual Authentication Flow - Complete Guide

**Date**: December 13, 2025  
**Status**: ✅ **COMPLETE & WORKING**

## Overview

The app now supports **separate authentication tokens for internal and external URLs**. When you
have different URLs (e.g., local network vs. internet), the app will:

1. Prompt you to log in to the **internal URL** first
2. After successful login, **automatically prompt** for the **external URL**
3. Store **both tokens separately**
4. Use the **correct token** based on which URL you're connected to

## How It Works

### Scenario 1: Same URL for Both

**Configuration:**

- Internal URL: `http://192.168.1.100:8123`
- External URL: `http://192.168.1.100:8123` (same)

**Authentication Flow:**

```
1. Tap "Save" with OAuth selected
2. Safari sheet opens → Log in
3. Token received
4. ✅ Same token stored for BOTH internal and external
5. Configuration saved
6. Done!
```

**Console Output:**

```
🔐 Starting OAuth2 flow for: http://192.168.1.100:8123
✅ Internal auth complete, token: eyJ0eXAiOiJKV1QiLCJh...
💾 Same URL - saving with single token for both
💾 Saving configuration
```

### Scenario 2: Different URLs (Dual Authentication)

**Configuration:**

- Internal URL: `http://192.168.1.100:8123` (local network)
- External URL: `https://my-home.duckdns.org` (internet)

**Authentication Flow:**

```
1. Tap "Save" with OAuth selected
2. Safari sheet opens for INTERNAL URL
3. Log in to internal Home Assistant
4. Token received
5. Sheet closes automatically
6. (0.5 second delay)
7. Safari sheet opens for EXTERNAL URL
8. Log in to external Home Assistant
9. Token received
10. ✅ BOTH tokens stored separately
11. Configuration saved
12. Done!
```

**Console Output:**

```
🔐 Starting OAuth2 flow for: http://192.168.1.100:8123
✅ Internal auth complete, token: eyJ0eXAiOiJKV1QiLCJh...
🔐 URLs differ - closing sheet and opening external auth
🔐 Internal: http://192.168.1.100:8123
🔐 External: https://my-home.duckdns.org
🔐 Starting OAuth2 flow for: https://my-home.duckdns.org
✅ External auth complete, token: eyJ0eXAiOiJKV1QiLCJh...
💾 Saving both tokens - Internal: eyJ0eXAiOiJKV1Q..., External: eyJ0eXAiOiJKV1Q...
💾 Saving configuration
```

### Scenario 3: External URL Empty

**Configuration:**

- Internal URL: `http://192.168.1.100:8123`
- External URL: (empty)

**Authentication Flow:**

```
1. Tap "Save" with OAuth selected
2. Safari sheet opens → Log in
3. Token received
4. ✅ External URL auto-set to internal URL
5. Same token used for both
6. Configuration saved
7. Done!
```

## Token Storage

### Configuration Model

```swift
struct HAConfiguration {
    var internalUrl: String
    var externalUrl: String
    private var _internalToken: String?
    private var _externalToken: String?
    var useInternalUrl: Bool
    
    var currentToken: String? {
        useInternalUrl ? internalToken : externalToken
    }
}
```

### Example Stored Configuration

```json
{
  "name": "Home",
  "internalUrl": "http://192.168.1.100:8123",
  "externalUrl": "https://my-home.duckdns.org",
  "internalToken": "eyJ0eXAiOiJKV1QiLCJhbGc...INTERNAL_TOKEN",
  "externalToken": "eyJ0eXAiOiJKV1QiLCJhbGc...EXTERNAL_TOKEN",
  "useInternalUrl": true,
  "isActive": true
}
```

## Token Usage

### When Internal URL is Selected

```
Dashboard Header: "🏠 Internal"
API Request → http://192.168.1.100:8123/api/states
Authorization: Bearer eyJ0eXAi...INTERNAL_TOKEN
```

### When External URL is Selected

```
Dashboard Header: "🌐 External"
API Request → https://my-home.duckdns.org/api/states
Authorization: Bearer eyJ0eXAi...EXTERNAL_TOKEN
```

### Switching URLs

Tap the **🔄** button in the dashboard header to toggle between internal and external.

```
Before: 🏠 Internal → Uses internalToken
Tap 🔄
After:  🌐 External → Uses externalToken
```

## Use Cases

### Use Case 1: Same Home Assistant, Two Access Methods

**Setup:**

- Internal URL: `http://192.168.1.100:8123` (local network)
- External URL: `https://my-home.duckdns.org` (same HA, via internet)

**Authentication:**

- Log in ONCE during internal auth
- **Same credentials work for both** (same Home Assistant instance)
- App stores two tokens (one for each URL)
- Both tokens are for the same user on the same HA instance

**Why Separate Tokens?**

- Security: Limit external token permissions if desired
- Reliability: If external URL changes, only re-auth external
- Debugging: See which URL/token is being used

### Use Case 2: Two Different Home Assistant Instances

**Setup:**

- Internal URL: `http://192.168.1.100:8123` (home HA)
- External URL: `https://vacation-home.duckdns.org` (vacation home HA)

**Authentication:**

- Log in to home HA during internal auth
- Log in to vacation home HA during external auth
- **Different credentials for each**
- App stores both tokens separately

**Result:**

- Switch between two completely different HA systems
- Each with its own entities, automations, etc.

### Use Case 3: Development vs. Production

**Setup:**

- Internal URL: `http://192.168.1.100:8123` (production HA)
- External URL: `http://192.168.1.101:8123` (development HA)

**Authentication:**

- Production credentials for internal
- Development credentials for external
- Safely test changes without affecting production

## Troubleshooting

### Only One Authentication Prompt Appears

**Check:**

1. Are internal and external URLs **exactly the same**?
    - If so, only one prompt is expected (same token for both)
2. Is external URL **empty**?
    - If so, app uses internal URL for both

**Solution:**

- If you want dual auth, ensure URLs are **different**
- Check Console logs for: "🔐 URLs differ - closing sheet..."

### Second Authentication Doesn't Appear

**Symptoms:**

- First auth completes
- Configuration saves immediately
- Only one token stored

**Common Causes:**

1. **URLs are the same** (as strings)
   ```swift
   Internal: "http://192.168.1.100:8123"
   External: "http://192.168.1.100:8123"
   Result: Same URL → One auth only
   ```

2. **URLs differ only in trailing slash**
   ```swift
   Internal: "http://192.168.1.100:8123"
   External: "http://192.168.1.100:8123/"
   Result: Treated as different → Two auths
   ```

3. **External URL is empty**
   ```swift
   Internal: "http://192.168.1.100:8123"
   External: ""
   Result: External auto-set to internal → One auth
   ```

**Debug Steps:**

1. Check Console output:
   ```
   ✅ Internal auth complete...
   🔐 URLs differ - closing sheet...  ← Should see this
   🔐 Internal: <url1>
   🔐 External: <url2>
   ```

2. Verify URLs are truly different:
    - No trailing slashes
    - Same protocol (http/https)
    - Different hosts or ports

3. Look for second auth prompt:
   ```
   🔐 Starting OAuth2 flow for: <external-url>
   ```

### Wrong Token Used for API Calls

**Symptoms:**

- Connected to internal URL
- Getting 401 Unauthorized
- Or vice versa

**Check:**

1. Which URL is selected?
    - Dashboard header shows: 🏠 Internal or 🌐 External
2. Check Console for API calls:
   ```
   🔗 Fetching entities from: http://192.168.1.100:8123
   🔑 Using internal URL
   ```

**Solution:**

- Toggle URL using 🔄 button
- Delete and re-add configuration
- Check both tokens are valid

### Authentication Cancelled

**If you cancel during first auth:**

```
❌ Internal auth cancelled
→ No configuration saved
→ Can try again
```

**If you cancel during second auth:**

```
✅ Internal auth complete...
❌ External auth cancelled
→ No configuration saved
→ Internal token discarded
→ Must start over
```

**Solution:**

- Complete both authentications
- Or use same URL for both (only one auth needed)

## Testing the Flow

### Test 1: Same URL

1. Open Configuration tab
2. Tap +
3. Enter:
    - Name: "Test Same"
    - Internal URL: `http://192.168.1.100:8123`
    - External URL: `http://192.168.1.100:8123`
4. Select "Web Login (OAuth)"
5. Tap "Save"

**Expected:**

- ✅ One Safari sheet appears
- ✅ Log in
- ✅ Configuration saves
- ✅ Console shows: "Same URL - saving with single token"

### Test 2: Different URLs

1. Open Configuration tab
2. Tap +
3. Enter:
    - Name: "Test Different"
    - Internal URL: `http://192.168.1.100:8123`
    - External URL: `https://my-home.duckdns.org`
4. Select "Web Login (OAuth)"
5. Tap "Save"

**Expected:**

- ✅ First Safari sheet appears (internal URL)
- ✅ Log in to internal
- ✅ Sheet closes
- ✅ **Second Safari sheet appears** (external URL)
- ✅ Log in to external
- ✅ Configuration saves
- ✅ Console shows: "Saving both tokens - Internal: ..., External: ..."

### Test 3: Verify Token Usage

1. Add configuration with different URLs and tokens
2. Open Dashboard
3. Check header shows: 🏠 Internal
4. Open Console in Xcode
5. Tap refresh (🔄 in header circle)
6. Check Console:
   ```
   🔗 Fetching entities from: <internal-url>
   🔑 Using internal URL
   ```
7. Tap URL toggle (🔄 next to "Internal")
8. Header changes to: 🌐 External
9. Tap refresh again
10. Check Console:
    ```
    🔗 Fetching entities from: <external-url>
    🔑 Using external URL
    ```

## API Token Method (Alternative)

If you prefer manual token entry:

1. Select "API Token" instead of "Web Login (OAuth)"
2. Enter internal token (from HA: Profile → Security → Long-Lived Tokens)
3. **Toggle OFF**: "Use same token for both URLs"
4. Enter external token (from external HA)
5. Tap "Save"

Result:

- No web login required
- Same behavior: separate tokens for each URL
- Tokens used based on current URL selection

## Summary

✅ **Dual authentication works perfectly!**

**Key Points:**

- Different URLs → Two authentication prompts
- Same URL → One authentication prompt
- Each URL uses its own token
- Toggle between URLs with 🔄 button
- Console logs show which token is being used

**The Flow:**

1. Internal auth → Token stored
2. Check if external URL differs
3. If yes → External auth → Second token stored
4. If no → Use same token for both
5. API always uses correct token for current URL

**Ready to test!** 🎉

Try it with your real Home Assistant URLs and see the dual authentication in action.
