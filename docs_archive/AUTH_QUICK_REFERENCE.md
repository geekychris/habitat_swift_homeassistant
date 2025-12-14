# Authentication Quick Reference

## 🔐 Two Ways to Authenticate

### Method 1: API Token (Recommended)

**Best for:** Security, multiple devices, automation

**Setup:**

```
Home Assistant → Profile → Long-Lived Access Tokens → Create Token
     ↓
HAbitat → Config → + → API Token → Paste Token → Save
```

**Pros:**

- ✅ More secure (revocable)
- ✅ Never expires
- ✅ Per-device control

**Cons:**

- ❌ Extra setup step

---

### Method 2: Username & Password

**Best for:** Quick setup, simplicity

**Setup:**

```
HAbitat → Config → + → Username & Password → Enter Credentials → Save
```

**Pros:**

- ✅ Simple setup
- ✅ Use existing credentials

**Cons:**

- ❌ Less secure
- ❌ Password stored locally
- ❌ Requires HA 2021.1+

---

## 📱 In-App Setup

### Adding Configuration

1. **Config Tab** → **+** button
2. **Fill Details:**
    - Name: "Home"
    - Internal URL: `http://192.168.1.100:8123`
    - External URL: `https://home.example.com:8123`

3. **Choose Auth Method** (toggle switch):

   **Option A: API Token**
    - Select "API Token"
    - Paste your token from Home Assistant
    - Save

   **Option B: Username & Password**
    - Select "Username & Password"
    - Enter username (e.g., `admin`)
    - Enter password
    - Save

4. **Test Connection** → "✅ Connection successful!"

---

## 🔄 Switching Between Methods

### Token → Credentials

1. Edit configuration
2. Switch to "Username & Password"
3. Enter credentials
4. Save (token auto-cleared)

### Credentials → Token

1. Edit configuration
2. Switch to "API Token"
3. Paste token
4. Save (credentials auto-cleared)

---

## 🆘 Troubleshooting

### Token Auth Issues

**"401 Unauthorized"**

- Token expired or revoked
- Solution: Generate new token in HA, update config

**"Invalid API token"**

- Token incomplete or incorrect
- Solution: Copy full token (no spaces), paste again

### Credentials Auth Issues

**"Invalid username or password"**

- Wrong credentials
- Solution: Verify credentials work in HA web UI

**"Invalid credentials"**

- Auth endpoint unavailable
- Solution: Check HA version (need 2021.1+)

### General Issues

**"Missing authentication credentials"**

- Fields not filled
- Solution: Complete all required fields

**"No configuration set"**

- No active configuration
- Solution: Add and activate a configuration

---

## 🎯 Quick Comparison

| Feature | API Token | Username/Password |
|---------|-----------|-------------------|
| **Security** | ⭐⭐⭐⭐⭐ | ⭐⭐⭐ |
| **Setup Time** | 2 minutes | 30 seconds |
| **Revocable** | ✅ Yes | ❌ No (must change password) |
| **Expiration** | Never | Session-based |
| **Multiple Devices** | ✅ One token per device | ❌ Same password everywhere |
| **HA Version** | All versions | 2021.1+ |
| **Recommendation** | ✅ Recommended | Use if needed |

---

## 💡 Best Practices

### Security

1. **Use API tokens** for production
2. **Use HTTPS** for external connections
3. **Different tokens** for different devices
4. **Revoke unused** tokens regularly

### Password Safety (if using credentials)

1. **Strong passwords** only
2. **Don't share** credentials
3. **Change regularly**
4. **Enable 2FA** in Home Assistant (if supported)

---

## 📚 More Information

- **Full Guide**: `USERNAME_PASSWORD_AUTH.md`
- **Troubleshooting**: See "Troubleshooting" section in full guide
- **Migration**: See "Migration Guide" in full guide
- **Technical Details**: See "Technical Details" in full guide

---

🏠 **HAbitat** - Choose the auth method that works for you!
