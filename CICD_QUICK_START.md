# CI/CD Quick Start Guide

## 🎯 Quick Reference

### Automatic CI Build (Every Push)

```bash
git add .
git commit -m "Your changes"
git push origin main
```

✅ GitHub automatically builds and tests your code

---

## 📦 Creating Releases

### Option 1: Unsigned Release (For Testing)

**Use Case:** Sideloading with AltStore, Xcode, or testing

```bash
# Create and push a version tag
git tag v1.0.0
git push origin v1.0.0
```

**What happens:**

1. GitHub Actions builds the app
2. Creates an IPA file (unsigned)
3. Uploads to GitHub Releases (draft)
4. You can download and sideload it

**Download:** Go to Releases page → Download IPA

---

### Option 2: Signed Release (For Distribution)

**Use Case:** TestFlight, Ad-hoc distribution, Enterprise distribution

**First-time setup (ONE TIME):**

1. **Get your Apple Developer certificate:**

```bash
# Export from Keychain as .p12 with password
# Convert to base64:
base64 -i YourCert.p12 | pbcopy
```

2. **Get your provisioning profile:**

```bash
# Download from developer.apple.com
# Convert to base64:
base64 -i YourProfile.mobileprovision | pbcopy
```

3. **Add secrets to GitHub:**

- Go to: Repository → Settings → Secrets and variables → Actions
- Add these secrets:
    - `APPLE_CERTIFICATE_BASE64` (paste base64 cert)
    - `APPLE_CERTIFICATE_PASSWORD` (your .p12 password)
    - `APPLE_PROVISIONING_PROFILE_BASE64` (paste base64 profile)
    - `APPLE_TEAM_ID` (from App Store Connect)

**After setup, create releases:**

```bash
# Create and push a signed version tag
git tag v1.0.0-signed
git push origin v1.0.0-signed
```

**What happens:**

1. GitHub Actions builds with signing
2. Creates signed IPA
3. Uploads to GitHub Releases
4. Ready for TestFlight or distribution

**Download:** Go to Releases page → Download signed IPA

---

## 🔧 Manual Workflow Trigger

Instead of tags, you can trigger builds manually:

1. Go to GitHub → Actions tab
2. Select workflow (CI Build, Release Build, or Signed Release)
3. Click "Run workflow"
4. Enter version number if needed
5. Click "Run workflow" button

---

## 📊 Checking Build Status

**View all builds:**

- Go to: Repository → Actions tab
- See status of all workflows
- Click on any run to see logs

**Download artifacts:**

- Open a successful workflow run
- Scroll to "Artifacts" section
- Download IPA files (available for 90 days)

---

## 🏷️ Version Naming

Follow semantic versioning:

```bash
# Major.Minor.Patch
v1.0.0      # First release
v1.0.1      # Bug fix
v1.1.0      # New feature
v2.0.0      # Breaking changes

# Add -signed for signed builds
v1.0.0-signed

# Pre-release versions
v1.0.0-beta.1
v1.0.0-rc.1
```

---

## 🚀 Complete Release Workflow

### Step-by-Step: From Code to Release

```bash
# 1. Make your changes
git checkout -b feature/new-feature
# ... make changes ...
git add .
git commit -m "Add awesome feature"

# 2. Push and create PR
git push origin feature/new-feature
# Create PR on GitHub, wait for CI to pass

# 3. Merge to main
# Merge PR on GitHub

# 4. Create release tag
git checkout main
git pull
git tag v1.0.0
git push origin v1.0.0

# 5. Wait for GitHub Actions
# Go to Actions tab and watch the build

# 6. Download from Releases
# Go to Releases page
# Download IPA
# Install on device or upload to TestFlight
```

---

## 📱 Installing Built IPAs

### Unsigned IPA (from release.yml):

**Option A: AltStore**

1. Install [AltStore](https://altstore.io/)
2. Add IPA to AltStore
3. Install on device

**Option B: Xcode**

1. Open Xcode
2. Window → Devices and Simulators
3. Select your device
4. Drag IPA to device

### Signed IPA (from release-signed.yml):

**Option A: TestFlight**

1. Upload IPA to App Store Connect
2. Add to TestFlight
3. Invite testers

**Option B: Direct Install**

1. Upload IPA to a server
2. Create manifest.plist
3. Install via itms-services:// URL

**Option C: Xcode/Configurator**

1. Connect device
2. Use Apple Configurator or Xcode
3. Install directly

---

## 🐛 Common Issues

### "Workflow not running"

- Check you pushed the tag: `git push origin v1.0.0`
- Verify workflows are in `.github/workflows/`
- Check Actions are enabled in repository settings

### "Build failed: No matching simulator"

- Update simulator name in workflow YAML
- Check GitHub's available simulators

### "Signing failed"

- Verify all 4 secrets are set correctly
- Check certificate hasn't expired
- Ensure provisioning profile matches bundle ID

### "Can't download IPA"

- Check workflow completed successfully
- Artifacts expire after 90 days
- Re-run workflow if needed

---

## 💡 Pro Tips

1. **Use draft releases** for testing before making public
2. **Add release notes** when creating tags
3. **Test unsigned builds** before creating signed builds
4. **Keep certificates updated** (check expiration annually)
5. **Use different tags** for different build types

---

## 📚 Learn More

- Full documentation: `.github/workflows/README.md`
- GitHub Actions: https://docs.github.com/actions
- Apple Code Signing: https://developer.apple.com/support/code-signing/

---

## 🆘 Need Help?

1. Check workflow logs in Actions tab
2. Read `.github/workflows/README.md`
3. Review troubleshooting section above
4. Check GitHub Actions documentation

---

🏠 **HAbitat** - Automated builds make releases easy!
