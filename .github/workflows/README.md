# GitHub Actions CI/CD Workflows

This directory contains automated workflows for building, testing, and releasing the HAbitat iOS
app.

## 📋 Available Workflows

### 1. CI Build (`build.yml`)

**Triggers:** Push to `main` or `develop`, Pull Requests

**Purpose:** Continuous integration - validates that code compiles and tests pass

**What it does:**

- ✅ Checks out code
- ✅ Builds app for iOS Simulator (Debug configuration)
- ✅ Runs unit tests
- ✅ Uploads build logs if build fails

**Usage:**

```bash
# Automatically runs on every push/PR to main or develop
git push origin main
```

---

### 2. Release Build (`release.yml`)

**Triggers:** Version tags (`v*.*.*`), Manual workflow dispatch

**Purpose:** Creates unsigned release builds for testing/sideloading

**What it does:**

- 🏗️ Builds app for iOS Device (Release configuration)
- 📦 Creates IPA file (unsigned)
- 📤 Uploads IPA as artifact (90-day retention)
- 🚀 Creates GitHub Release (draft) with IPA attached

**Usage:**

#### Option A: Create a version tag

```bash
# Tag your release
git tag v1.0.0
git push origin v1.0.0

# GitHub Actions will automatically create a release
```

#### Option B: Manual trigger

1. Go to Actions tab in GitHub
2. Select "Release Build" workflow
3. Click "Run workflow"
4. Enter version number (e.g., `1.0.0`)
5. Click "Run workflow"

**Output:**

- IPA file: `SimpleHomeAssistant-{version}.ipa`
- GitHub Release with installation instructions
- Artifact available for 90 days

---

### 3. Signed Release Build (`release-signed.yml`)

**Triggers:** Signed version tags (`v*.*.*-signed`), Manual workflow dispatch

**Purpose:** Creates **signed** release builds for TestFlight or ad-hoc distribution

**What it does:**

- 🔐 Imports Apple signing certificate
- 📋 Imports provisioning profile
- 🏗️ Builds and signs app for iOS Device
- 📦 Exports signed IPA
- 📤 Uploads signed IPA as artifact
- 🚀 Creates GitHub Release with signed IPA

**Setup Required:**

You need to add these secrets to your GitHub repository:

1. Go to your GitHub repo → Settings → Secrets and variables → Actions
2. Add the following secrets:

| Secret Name | Description | How to Get It |
|------------|-------------|---------------|
| `APPLE_CERTIFICATE_BASE64` | Base64 encoded .p12 certificate | See instructions below |
| `APPLE_CERTIFICATE_PASSWORD` | Password for .p12 certificate | Password you set when exporting |
| `APPLE_PROVISIONING_PROFILE_BASE64` | Base64 encoded provisioning profile | See instructions below |
| `APPLE_TEAM_ID` | Your Apple Developer Team ID | Found in App Store Connect |

#### How to Get Certificate and Provisioning Profile

**Step 1: Export Certificate from Keychain**

```bash
# Open Keychain Access
# Find your "Apple Development" or "Apple Distribution" certificate
# Right-click → Export "Certificate Name"
# Save as .p12 with a password
# Convert to base64:
base64 -i YourCertificate.p12 | pbcopy
# Paste into APPLE_CERTIFICATE_BASE64 secret
```

**Step 2: Export Provisioning Profile**

```bash
# Download from Apple Developer Portal
# Or find in: ~/Library/MobileDevice/Provisioning Profiles/
# Convert to base64:
base64 -i YourProfile.mobileprovision | pbcopy
# Paste into APPLE_PROVISIONING_PROFILE_BASE64 secret
```

**Step 3: Get Team ID**

- Log into [App Store Connect](https://appstoreconnect.apple.com/)
- Go to Users and Access → Keys (or Membership)
- Your Team ID is displayed there (10 characters)

**Usage:**

#### Option A: Create a signed version tag

```bash
git tag v1.0.0-signed
git push origin v1.0.0-signed
```

#### Option B: Manual trigger

1. Go to Actions tab
2. Select "Release Build (Signed)"
3. Click "Run workflow"
4. Enter version number
5. Click "Run workflow"

**Output:**

- Signed IPA: `SimpleHomeAssistant-{version}-signed.ipa`
- Ready for TestFlight or ad-hoc distribution

---

## 🚀 Quick Start Guide

### For Development (CI Builds)

No setup needed! Just push your code:

```bash
git add .
git commit -m "Add new feature"
git push origin develop
```

GitHub Actions will automatically build and test.

### For Unsigned Releases (Testing)

Create a version tag:

```bash
git tag v1.0.0
git push origin v1.0.0
```

Download IPA from GitHub Releases or Actions artifacts.

### For Signed Releases (Distribution)

1. Set up secrets (one-time setup, see above)
2. Create signed tag:

```bash
git tag v1.0.0-signed
git push origin v1.0.0-signed
```

3. Download signed IPA and distribute

---

## 📊 Workflow Status

Check workflow status:

- Go to your repository → Actions tab
- See all workflow runs and their status
- Download artifacts from successful runs

### Badges

Add these badges to your README.md:

```markdown
![CI Build](https://github.com/YOUR_USERNAME/YOUR_REPO/actions/workflows/build.yml/badge.svg)
![Release](https://github.com/YOUR_USERNAME/YOUR_REPO/actions/workflows/release.yml/badge.svg)
```

---

## 🔧 Customization

### Change iOS Version Target

Edit the workflows to change simulator/device:

```yaml
# In build.yml or release.yml
-destination 'platform=iOS Simulator,name=iPhone 15 Pro'  # Change to your preferred device
```

### Change Xcode Version

```yaml
# macOS runner version determines Xcode version
runs-on: macos-14  # Xcode 15.x
runs-on: macos-13  # Xcode 14.x
```

### Add TestFlight Upload

Add this step to `release-signed.yml`:

```yaml
- name: Upload to TestFlight
  env:
    APP_STORE_CONNECT_API_KEY: ${{ secrets.APP_STORE_CONNECT_API_KEY }}
  run: |
    xcrun altool --upload-app \
      --type ios \
      --file ${{ runner.temp }}/SimpleHomeAssistant-${{ env.VERSION }}-signed.ipa \
      --apiKey $APP_STORE_CONNECT_API_KEY \
      --apiIssuer ${{ secrets.APP_STORE_CONNECT_ISSUER_ID }}
```

---

## 🐛 Troubleshooting

### Build Fails with "No matching provisioning profiles found"

- Check that `APPLE_PROVISIONING_PROFILE_BASE64` secret is set correctly
- Verify provisioning profile matches your bundle identifier
- Ensure provisioning profile hasn't expired

### Certificate Import Fails

- Verify `APPLE_CERTIFICATE_BASE64` is correctly base64 encoded
- Check `APPLE_CERTIFICATE_PASSWORD` is correct
- Ensure certificate hasn't expired

### IPA Not Created

- Check build logs in Actions tab
- Verify all secrets are set
- Try manual workflow dispatch for more control

### "Simulator not found" Error

- Update simulator name in workflow
- Check available simulators on GitHub runners
- Use `xcrun simctl list devices available` to see options

---

## 📚 Additional Resources

- [GitHub Actions Documentation](https://docs.github.com/en/actions)
- [Xcode Build Settings Reference](https://developer.apple.com/documentation/xcode/build-settings-reference)
- [Apple Code Signing Guide](https://developer.apple.com/support/code-signing/)
- [TestFlight Distribution Guide](https://developer.apple.com/testflight/)

---

## 🔒 Security Best Practices

1. **Never commit certificates or provisioning profiles** to the repository
2. **Use GitHub Secrets** for all sensitive information
3. **Rotate certificates** regularly (at least annually)
4. **Use separate certificates** for development and distribution
5. **Enable branch protection** on main/release branches
6. **Review workflow runs** regularly for suspicious activity

---

## 📝 Version Naming Convention

We use semantic versioning:

- `v1.0.0` - Major.Minor.Patch (unsigned release)
- `v1.0.0-signed` - Signed release for distribution
- `v1.0.0-beta.1` - Pre-release version
- `v1.0.0-rc.1` - Release candidate

**Examples:**

```bash
# First release
git tag v1.0.0
git push origin v1.0.0

# Signed first release
git tag v1.0.0-signed
git push origin v1.0.0-signed

# Bug fix
git tag v1.0.1
git push origin v1.0.1

# New feature
git tag v1.1.0
git push origin v1.1.0

# Breaking changes
git tag v2.0.0
git push origin v2.0.0
```

---

🏠 **HAbitat** - Automated builds for your home automation app!
