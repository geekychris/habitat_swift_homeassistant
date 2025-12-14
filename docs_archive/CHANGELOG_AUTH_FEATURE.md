# Changelog - Username/Password Authentication

## Version 1.1.0 - Authentication Update

### 🎉 New Features

#### Flexible Authentication

You can now choose between **two authentication methods** when setting up Home Assistant:

1. **API Token** (Recommended)
    - Use long-lived access tokens
    - More secure and manageable
    - Best for long-term use

2. **Username & Password** (New!)
    - Use your regular login credentials
    - Quick and simple setup
    - No token generation needed

### ✨ What's Changed

#### Configuration Setup

- **New authentication picker** when adding/editing configurations
- Switch between token and credentials with a segmented control
- Smart form fields that adapt to your choice
- Clear help text for each method

#### Security

- Credentials authentication uses temporary access tokens
- Tokens cached in memory only (not saved)
- Automatic re-authentication when tokens expire
- Both methods work seamlessly

#### User Experience

- Configuration details now show auth type
- Better error messages for auth failures
- Test connection works with both methods
- Smooth switching between auth methods

### 📱 How to Use

**For New Configurations:**

1. Tap Config → + button
2. Fill in name and URLs
3. Choose authentication method:
    - **API Token**: Paste your token
    - **Username & Password**: Enter credentials
4. Save and test!

**For Existing Configurations:**

- Everything works as before (no action needed)
- Edit to switch to username/password if desired

### 🔧 Technical Details

**What Changed Under the Hood:**

- Enhanced configuration model with auth type support
- New authentication flow for credentials
- Automatic token management and caching
- Updated all API calls to support both methods
- Improved error handling

**Backward Compatibility:**

- ✅ All existing configurations work unchanged
- ✅ No migration required
- ✅ Seamless upgrade

### 📚 Documentation

**New Guides:**

- `USERNAME_PASSWORD_AUTH.md` - Comprehensive guide
- `AUTH_QUICK_REFERENCE.md` - Quick reference card
- `AUTH_IMPLEMENTATION_SUMMARY.md` - Technical details

**Updated:**

- `README.md` - Updated setup instructions

### 🐛 Bug Fixes

None - this is a pure feature addition!

### ⚠️ Requirements

**For Username/Password Auth:**

- Home Assistant 2021.1 or later
- iOS 16.0+ (unchanged)

**For API Token Auth:**

- All Home Assistant versions (unchanged)
- iOS 16.0+ (unchanged)

### 💡 Recommendations

**We recommend API Token authentication** for:

- Better security
- Per-device control
- Production use
- Long-term deployments

**Use Username/Password** for:

- Quick testing
- Temporary access
- Simple setup
- Single device

### 🎯 What's Next

Future improvements we're considering:

- Keychain storage for passwords
- Biometric authentication
- OAuth2 support
- SSO integration

### 📝 Notes

- Passwords are stored locally in app storage
- Access tokens are memory-only (cleared on app restart)
- Both methods work with internal/external URLs
- Network switching works with both methods
- All existing features work with both methods

---

## Upgrade Path

### From Previous Version

1. **Update the app** (via build or TestFlight)
2. **Existing configs** continue working automatically
3. **Optional**: Edit configs to try username/password auth
4. **No data loss** - all settings preserved

### Clean Install

If installing fresh:

1. Choose your preferred auth method during setup
2. Follow the in-app instructions
3. Test connection before proceeding

---

## Support

**Need Help?**

- Read `AUTH_QUICK_REFERENCE.md` for quick tips
- See `USERNAME_PASSWORD_AUTH.md` for detailed guide
- Check troubleshooting sections in documentation

**Found a Bug?**

- File an issue on GitHub
- Include auth method used
- Provide Home Assistant version

---

## Credits

Implemented: December 2024  
Feature: Flexible authentication system  
Status: ✅ Stable and tested

---

🏠 **HAbitat** - Now with even more flexibility!

Thank you for using HAbitat. We hope this update makes your Home Assistant experience even better!
