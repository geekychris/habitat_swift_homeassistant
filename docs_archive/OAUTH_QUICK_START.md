# OAuth Authentication - Quick Start Guide

## What Changed?

Your iOS Home Assistant app now supports **web-based login** (OAuth2) just like the Android version!

## Two Ways to Authenticate

### Option 1: API Token (Traditional)

- Manually copy/paste token from Home Assistant
- Good for: Power users, automation
- Steps: Copy token → Paste in app → Done

### Option 2: Web Login (New! ✨)

- Log in through browser with username/password
- Good for: Everyone, easier setup
- Steps: Tap Save → Log in via browser → Done

## Why Separate Tokens?

Your configuration can now have **different tokens for internal and external URLs**:

- **Internal URL**: `http://192.168.1.100:8123` (local network)
- **External URL**: `https://my-home.duckdns.org` (internet)

Use case: You have two different Home Assistant instances, or different security requirements.

## Quick Setup - Web Login Method

1. **Open Configuration Tab**
2. **Tap +**
3. **Enter Details**:
   ```
   Name: Home
   Internal URL: http://192.168.1.100:8123
   External URL: https://my-home.duckdns.org
   ```
4. **Select "Web Login (OAuth)"**
5. **Tap Save**
6. **Browser Opens** → Log in with username/password
7. **If URLs Differ** → Browser opens again for external URL
8. **Done!** ✅

## Quick Setup - API Token Method

1. **Open Configuration Tab**
2. **Tap +**
3. **Enter Details**:
   ```
   Name: Home
   Internal URL: http://192.168.1.100:8123
   External URL: https://my-home.duckdns.org
   ```
4. **Keep "API Token" Selected**
5. **Enter Token** (from HA: Profile → Security → Long-Lived Tokens)
6. **Optional**: Turn off "Use same token for both URLs" if you have different tokens
7. **Tap Save**
8. **Done!** ✅

## Troubleshooting

### "Authentication cancelled"

- You tapped Cancel in the browser
- Solution: Try again, complete the login

### "Invalid token"

- Token expired or incorrect
- Solution: Re-authenticate or check token

### "401 Unauthorized"

- Wrong credentials or expired token
- Solution: Delete configuration and add again with new authentication

### Browser doesn't open

- URL might be invalid
- Solution: Check URL format (http:// or https://)

### URLs are the same, why authenticate twice?

- You entered the same URL twice
- Solution: Leave external URL empty if they're the same

## Tips

💡 **Same Instance**: Leave external URL empty if internal/external point to same server  
💡 **Different Servers**: Use separate URLs and authenticate to each  
💡 **Security**: Web login is more secure - no manual token copying  
💡 **Switching**: Can switch between URL types in app header (Internal/External toggle)

## Technical Notes

- Uses OAuth2 Authorization Code Flow with PKCE
- Matches official Home Assistant companion app authentication
- Tokens stored locally (no cloud sync)
- Works with Home Assistant 2021.1 or later

## Still Have Questions?

See `OAUTH_AUTHENTICATION_IMPLEMENTATION.md` for complete technical details.
