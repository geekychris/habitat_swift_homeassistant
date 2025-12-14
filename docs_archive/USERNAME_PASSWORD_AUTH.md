# Username & Password Authentication

## Overview

HAbitat now supports **two authentication methods** for connecting to Home Assistant:

1. **API Token** (Long-Lived Access Token) - Original method
2. **Username & Password** (Credentials) - NEW!

## Why Two Methods?

### API Token (Recommended)

- ✅ More secure (can be revoked without changing password)
- ✅ Granular control (can create multiple tokens)
- ✅ Never expires (until manually revoked)
- ✅ Ideal for automation and apps

### Username & Password

- ✅ Simpler setup (no token generation needed)
- ✅ Uses your regular login credentials
- ✅ Familiar authentication method
- ⚠️ Requires Home Assistant 2021.1 or later
- ⚠️ Session tokens need re-authentication periodically

---

## How It Works

### Token Authentication (Original)

```
App → Home Assistant API
     (Bearer token in header)
```

**Flow:**

1. Configure with long-lived access token
2. Token sent with every API request
3. Home Assistant validates token
4. Access granted if valid

### Username/Password Authentication (New)

```
1. App → Home Assistant /auth/token endpoint
        (username + password)
   
2. Home Assistant → App
        (access token)
   
3. App → Home Assistant API
        (Bearer token in header)
```

**Flow:**

1. Configure with username and password
2. App authenticates and receives temporary access token
3. Token is cached in memory
4. Token sent with every API request
5. If token expires (401), re-authenticate automatically

---

## Usage

### Setting Up Token Authentication

1. **In Home Assistant:**
    - Go to Profile (click your name)
    - Scroll to "Long-Lived Access Tokens"
    - Click "Create Token"
    - Give it a name (e.g., "HAbitat iOS")
    - Copy the token (you won't see it again!)

2. **In HAbitat:**
    - Go to Config tab
    - Tap + to add configuration
    - Select "API Token" auth method
    - Paste your token
    - Save

### Setting Up Username/Password Authentication

1. **Requirements:**
    - Home Assistant 2021.1 or later
    - Local or trusted user account

2. **In HAbitat:**
    - Go to Config tab
    - Tap + to add configuration
    - Select "Username & Password" auth method
    - Enter your Home Assistant username
    - Enter your Home Assistant password
    - Save

3. **Test Connection:**
    - Expand configuration details
    - Tap "Test Connection"
    - Should see "✅ Connection successful!"

---

## Security Considerations

### Token Authentication

- ✅ **Recommended for most users**
- Token can be revoked without changing password
- If token is compromised, create new token and delete old one
- Each device can have its own token

### Username/Password Authentication

- ⚠️ Password is stored in app's local storage (UserDefaults)
- ⚠️ If device is compromised, change your Home Assistant password
- ⚠️ Cannot selectively revoke access (must change password)
- ✅ Access token cached in memory only (not persisted)
- ✅ Tokens expire and are re-issued automatically

### Best Practices

1. **Use API Tokens** when possible
2. **Use strong passwords** if using credentials
3. **Enable HTTPS** for external connections
4. **Keep app updated** for security patches
5. **Review active sessions** regularly in Home Assistant

---

## Technical Details

### Token Caching

- Username/password auth caches access tokens in **memory only**
- Token is **never saved** to disk
- Token cleared when:
    - Configuration changes
    - App restarts
    - 401 Unauthorized received
    - User switches configurations

### Re-authentication

- Automatic on 401 errors
- Seamless for user
- Only one auth request per session

### API Endpoints Used

**Token Auth:**

```
GET /api/states
Headers: Authorization: Bearer {token}
```

**Credentials Auth:**

```
POST /auth/token
Body: grant_type=password&username={user}&password={pass}
Response: { access_token, token_type, expires_in }

Then:
GET /api/states
Headers: Authorization: Bearer {access_token}
```

---

## Troubleshooting

### "Invalid username or password"

- ✅ Check credentials are correct
- ✅ Try logging into Home Assistant web UI
- ✅ Ensure user account is active
- ✅ Check Home Assistant version (needs 2021.1+)

### "401 Unauthorized"

- **Token auth:** Token may be revoked or invalid
    - Generate new token in Home Assistant
    - Update configuration with new token

- **Credentials auth:** Session expired or invalid
    - App will auto re-authenticate
    - If persists, check credentials

### "Missing authentication credentials"

- Configuration not complete
- Fill in all required fields
- Choose correct auth method

### Connection test fails but credentials correct

- Check URL is correct
- Verify network connectivity
- Try internal vs external URL
- Check Home Assistant is running

---

## Migration Guide

### Switching from Token to Credentials

1. Edit configuration
2. Change "Authentication Method" to "Username & Password"
3. Enter username and password
4. Save
5. Test connection

### Switching from Credentials to Token

1. Generate token in Home Assistant (see above)
2. Edit configuration
3. Change "Authentication Method" to "API Token"
4. Paste token
5. Save
6. Test connection

**Note:** Old credentials are automatically cleared when switching methods.

---

## Code Architecture

### Modified Files

**Configuration Model** (`Configuration.swift`):

- Added `AuthType` enum (token/credentials)
- Added optional username/password fields
- Updated initializers for both auth types
- Backward compatible with existing configs

**API Client** (`HomeAssistantAPI.swift`):

- Added `authenticate()` method
- Added `getAuthorizationHeader()` helper
- Updated all API calls to use dynamic auth
- Added token caching logic
- New error types: `invalidCredentials`, `missingCredentials`

**Configuration UI** (`ConfigurationView.swift`):

- Added auth method picker (segmented control)
- Conditional fields based on auth type
- Updated save logic for both methods
- Shows auth type in configuration details

### Error Handling

```swift
enum APIError {
    case noConfiguration
    case invalidResponse
    case unauthorized          // Generic auth failure
    case invalidCredentials    // Wrong username/password
    case missingCredentials    // Config incomplete
    case httpError(Int)
}
```

---

## Compatibility

### Backward Compatibility

- ✅ Existing token-based configurations work unchanged
- ✅ App will migrate old configs automatically
- ✅ No user action required for existing users

### Home Assistant Versions

- **Token auth:** All versions
- **Credentials auth:** 2021.1+ (January 2021)

### iOS Versions

- iOS 16.0+ (no changes)

---

## FAQ

**Q: Which authentication method should I use?**  
A: API Token is recommended for better security and control.

**Q: Can I use both methods for different configurations?**  
A: Yes! Each configuration can use its own auth method.

**Q: Will my password be sent over the network?**  
A: Only during authentication to get the access token. Use HTTPS for external connections.

**Q: How long do access tokens last?**  
A: Depends on Home Assistant configuration, typically several hours to days. App re-authenticates
automatically.

**Q: Can I see my stored password?**  
A: No, passwords are stored but not displayed. Change via edit configuration.

**Q: Does this work with SSO/LDAP?**  
A: If your Home Assistant username/password works in the web UI, it should work in HAbitat.

**Q: What if I change my Home Assistant password?**  
A: Update the password in configuration settings. Token auth is unaffected.

---

## Future Enhancements

Potential future improvements:

- [ ] OAuth2 authentication flow
- [ ] Biometric unlock for credentials
- [ ] Keychain storage for passwords
- [ ] Multi-factor authentication support
- [ ] SSO provider integration

---

## Testing

### Test Scenarios

**Token Auth:**

1. ✅ Add config with valid token → Success
2. ✅ Add config with invalid token → Error
3. ✅ Test connection with valid token → Success
4. ✅ Fetch entities with valid token → Success
5. ✅ Control entities with valid token → Success

**Credentials Auth:**

1. ✅ Add config with valid credentials → Success
2. ✅ Add config with invalid credentials → Error
3. ✅ Test connection with valid credentials → Success
4. ✅ Fetch entities after authentication → Success
5. ✅ Control entities after authentication → Success
6. ✅ Token re-authentication on 401 → Success

**Switching:**

1. ✅ Token → Credentials → Success
2. ✅ Credentials → Token → Success
3. ✅ Edit preserves auth type → Success

---

🏠 **HAbitat** - Now with flexible authentication options!

For questions or issues, please check the troubleshooting section or file an issue on GitHub.
