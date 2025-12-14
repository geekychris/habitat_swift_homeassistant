# Workflow Status Badges

Add these badges to your README.md to show build status:

## Usage

Replace `YOUR_USERNAME` and `YOUR_REPO` with your actual GitHub username and repository name.

## Badges

### CI Build Status

```markdown
![CI Build](https://github.com/YOUR_USERNAME/YOUR_REPO/actions/workflows/build.yml/badge.svg)
```

**Example:**

```markdown
![CI Build](https://github.com/johndoe/SimpleHomeAssistant/actions/workflows/build.yml/badge.svg)
```

**Result:
** ![CI Build](https://github.com/YOUR_USERNAME/YOUR_REPO/actions/workflows/build.yml/badge.svg)

---

### Release Build Status

```markdown
![Release](https://github.com/YOUR_USERNAME/YOUR_REPO/actions/workflows/release.yml/badge.svg)
```

**Example:**

```markdown
![Release](https://github.com/johndoe/SimpleHomeAssistant/actions/workflows/release.yml/badge.svg)
```

**Result:
** ![Release](https://github.com/YOUR_USERNAME/YOUR_REPO/actions/workflows/release.yml/badge.svg)

---

### Signed Release Status

```markdown
![Signed Release](https://github.com/YOUR_USERNAME/YOUR_REPO/actions/workflows/release-signed.yml/badge.svg)
```

**Example:**

```markdown
![Signed Release](https://github.com/johndoe/SimpleHomeAssistant/actions/workflows/release-signed.yml/badge.svg)
```

**Result:
** ![Signed Release](https://github.com/YOUR_USERNAME/YOUR_REPO/actions/workflows/release-signed.yml/badge.svg)

---

## All Badges Together

```markdown
![CI Build](https://github.com/YOUR_USERNAME/YOUR_REPO/actions/workflows/build.yml/badge.svg)
![Release](https://github.com/YOUR_USERNAME/YOUR_REPO/actions/workflows/release.yml/badge.svg)
![Signed Release](https://github.com/YOUR_USERNAME/YOUR_REPO/actions/workflows/release-signed.yml/badge.svg)
```

---

## Badge with Branch

To show status for a specific branch:

```markdown
![CI Build](https://github.com/YOUR_USERNAME/YOUR_REPO/actions/workflows/build.yml/badge.svg?branch=main)
```

---

## Custom Badge Colors

GitHub automatically colors badges:

- 🟢 Green = Passing
- 🔴 Red = Failing
- 🟡 Yellow = Running
- ⚪ Gray = No runs

---

## Placement in README

Add badges at the top of your README.md:

```markdown
# HAbitat - iOS Home Assistant Client

<div align="center">

![CI Build](https://github.com/YOUR_USERNAME/YOUR_REPO/actions/workflows/build.yml/badge.svg)
![Release](https://github.com/YOUR_USERNAME/YOUR_REPO/actions/workflows/release.yml/badge.svg)

**A modern, native iOS client for Home Assistant**

![iOS](https://img.shields.io/badge/iOS-16.0+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)
![SwiftUI](https://img.shields.io/badge/SwiftUI-3.0+-green.svg)

</div>
```

---

## Additional Badges

You can also add these badges:

### Latest Release

```markdown
![GitHub release](https://img.shields.io/github/v/release/YOUR_USERNAME/YOUR_REPO)
```

### License

```markdown
![License](https://img.shields.io/badge/License-MIT-lightgrey.svg)
```

### Platform

```markdown
![Platform](https://img.shields.io/badge/platform-iOS-lightgrey.svg)
```

### Swift Version

```markdown
![Swift](https://img.shields.io/badge/Swift-5.9-orange.svg)
```

### iOS Version

```markdown
![iOS](https://img.shields.io/badge/iOS-16.0+-blue.svg)
```

---

🏠 **HAbitat** - Show off your build status!
