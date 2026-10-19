<p align="center">
  <img src="assets/logo.png" alt="Habitat Swift Homeassistant logo" width="180">
</p>

# HAbitat - iOS Home Assistant Client

<div align="center">

**A modern, native iOS client for Home Assistant**

![iOS](https://img.shields.io/badge/iOS-16.0+-blue.svg)
![Swift](https://img.shields.io/badge/Swift-5.9+-orange.svg)
![SwiftUI](https://img.shields.io/badge/SwiftUI-3.0+-green.svg)
![License](https://img.shields.io/badge/License-MIT-lightgrey.svg)

[Features](#features) • [Screenshots](#screenshots) • [Architecture](#architecture) • [Installation](#installation) • [Usage](#usage)

</div>

---

## 📱 Overview

HAbitat (HA-bitat) is a native iOS application that provides a clean, intuitive interface for
controlling your Home Assistant smart home devices. Built entirely with SwiftUI, it offers a
responsive, modern UI that works seamlessly across iPhone and iPad.

### ✨ Key Features

- 🏠 **Multi-Configuration Support** - Manage multiple Home Assistant instances
- 🔄 **Network Switching** - Toggle between internal and external URLs
- 📱 **Universal App** - Optimized for both iPhone and iPad
- 🎨 **Custom Tabs** - Organize entities by room or category
- ⚡ **Real-time Control** - Toggle lights, adjust thermostats, control switches
- 🔐 **Flexible Authentication** - API tokens OR OAuth2 web login (matches Android app)
- 🔑 **Dual Authentication** - Separate tokens for internal and external URLs
- 🔒 **Secure** - OAuth2 with PKCE, HTTP support for local networks
- 💾 **Persistent** - Configurations and selections saved locally
- 🎯 **Debounced Actions** - Smooth, flicker-free UI with loading states

---

## 📸 Screenshots

### iPhone

```
┌─────────────────────┐
│ 🏠 HA-bitat  Dashboard │  ← Header with branding
├─────────────────────┤
│ 🏠 Internal  🔄     │  ← URL toggle & refresh
├─────────────────────┤
│ All | Kitchen       │  ← Tab filters
├─────────────────────┤
│ ┌─────────────────┐ │
│ │ 💡 Living Light │ │  ← Entity card
│ │ light.living    │ │
│ │        [Toggle] │ │
│ │ ▬▬▬▬▬▬▬▬○─ 75%  │ │  ← Brightness slider
│ └─────────────────┘ │
│ ┌─────────────────┐ │
│ │ 🌡️ Thermostat   │ │
│ │ climate.main    │ │
│ │        [Toggle] │ │  ← On/Off control
│ │ Temp: ➖ 72° ➕  │ │  ← Temperature
│ │ Mode: [Heat ▼]  │ │  ← HVAC mode
│ └─────────────────┘ │
└─────────────────────┘
 🏠  ⚙️  ▦             ← 3-tab navigation
```

### iPad

Same vertical layout but with larger spacing and fonts for tablet-optimized viewing.

---

## 🏗️ Architecture

HAbitat follows the **MVVM (Model-View-ViewModel)** architecture pattern with SwiftUI's reactive
framework.

### Architecture Diagram

```
┌─────────────────────────────────────────────────────────┐
│                        Views Layer                       │
│  ┌──────────────┐  ┌──────────────┐  ┌──────────────┐  │
│  │ Dashboard    │  │ Config       │  │ Tabs         │  │
│  │ View         │  │ View         │  │ Management   │  │
│  └──────┬───────┘  └──────┬───────┘  └──────┬───────┘  │
│         │                  │                  │          │
│         └──────────────────┼──────────────────┘          │
│                            │                             │
└────────────────────────────┼─────────────────────────────┘
                             │
                    @EnvironmentObject
                             │
┌────────────────────────────┼─────────────────────────────┐
│                    ViewModel Layer                        │
│              ┌──────────────────────┐                     │
│              │   AppViewModel       │                     │
│              │  @MainActor          │                     │
│              │  @Published State    │                     │
│              │  - configurations    │                     │
│              │  - entities          │                     │
│              │  - selectedEntityIds │                     │
│              │  - customTabs        │                     │
│              └──────────┬───────────┘                     │
│                         │                                 │
└─────────────────────────┼─────────────────────────────────┘
                          │
                  Uses (async/await)
                          │
┌─────────────────────────┼─────────────────────────────────┐
│                   Services Layer                          │
│   ┌────────────────┐           ┌──────────────────┐      │
│   │ HomeAssistant  │           │ Persistence      │      │
│   │ API            │           │ Controller       │      │
│   │ - fetch()      │           │ - save()         │      │
│   │ - toggle()     │           │ - load()         │      │
│   │ - control()    │           │                  │      │
│   └────────┬───────┘           └────────┬─────────┘      │
│            │                             │                │
└────────────┼─────────────────────────────┼────────────────┘
             │                             │
    REST API │                             │ UserDefaults
             │                             │
┌────────────▼─────────────────────────────▼────────────────┐
│                      Data Layer                            │
│   ┌────────────────┐         ┌──────────────────┐         │
│   │ Home Assistant │         │ UserDefaults     │         │
│   │ Server         │         │ Storage          │         │
│   │ (REST API)     │         │ - Configs        │         │
│   └────────────────┘         │ - Selections     │         │
│                              │ - Tabs           │         │
│                              └──────────────────┘         │
└────────────────────────────────────────────────────────────┘
```

### Data Flow Example

**User toggles a light:**

```
1. User taps toggle in EntityCardView
        ↓
2. handleToggle() sets isProcessing = true
        ↓
3. Calls viewModel.toggleEntity(entity)
        ↓
4. AppViewModel.toggleEntity()
        ↓
5. HomeAssistantAPI.toggleEntity()
        ↓
6. POST /api/services/light/toggle
        ↓
7. Wait 500ms (debounce)
        ↓
8. Fetch fresh entity states
        ↓
9. Update @Published entities array
        ↓
10. SwiftUI rerenders EntityCardView
        ↓
11. isProcessing = false
```

### Key Design Patterns

#### 1. **MVVM Pattern**

- **Views**: SwiftUI views (declarative UI)
- **ViewModel**: `AppViewModel` (business logic, state management)
- **Model**: Data structures (`HAEntity`, `HAConfiguration`, `CustomTab`)

#### 2. **Repository Pattern**

- `HomeAssistantAPI`: Network layer abstraction
- `PersistenceController`: Storage layer abstraction
- Views don't directly access data sources

#### 3. **Reactive Programming**

- `@Published` properties in ViewModel
- `@EnvironmentObject` for dependency injection
- Automatic UI updates via Combine framework

#### 4. **Async/Await**

- Modern Swift concurrency
- Clean asynchronous code
- Proper error handling

---

## 📁 Project Structure

```
SimpleHomeAssistant/
├── SimpleHomeAssistant/
│   ├── Models/
│   │   ├── Configuration.swift       # Home Assistant config model
│   │   ├── HAEntity.swift            # Entity model with domain logic
│   │   └── CustomTab.swift           # Custom tab model
│   │
│   ├── ViewModels/
│   │   └── AppViewModel.swift        # Main ViewModel (state & logic)
│   │
│   ├── Views/
│   │   ├── ContentView.swift         # Root view with tab navigation
│   │   ├── DashboardView.swift       # Entity control dashboard
│   │   ├── EntityCardView.swift      # Individual entity card
│   │   ├── ConfigurationView.swift   # Configuration management
│   │   └── TabManagementView.swift   # Custom tab editor
│   │
│   ├── Services/
│   │   ├── HomeAssistantAPI.swift    # REST API client
│   │   └── Persistence.swift         # UserDefaults storage
│   │
│   ├── Assets/
│   │   ├── default_config.json       # Default config (NOT in git)
│   │   └── default_config.json.template
│   │
│   ├── Assets.xcassets/
│   │   └── AppIcon.appiconset/       # App icon assets
│   │
│   ├── Info.plist                    # App configuration
│   ├── SimpleHomeAssistantApp.swift  # App entry point
│   └── ContentView.swift             # Main navigation
│
├── SimpleHomeAssistantTests/          # Unit tests
└── SimpleHomeAssistantUITests/        # UI tests

Generated Documentation:
├── README.md                          # This file
├─��� FIXES_APPLIED.md                   # Bug fixes documentation
├── HABITAT_BRANDING.md                # Branding guide
└── HOW_TO_OPEN_IN_XCODE.md           # Quick start guide
```

---

## 🔧 Technical Stack

| Component | Technology |
|-----------|------------|
| **Language** | Swift 5.9+ |
| **UI Framework** | SwiftUI 3.0+ |
| **Min iOS Version** | iOS 16.0 |
| **Architecture** | MVVM |
| **Networking** | URLSession + async/await |
| **Persistence** | UserDefaults (JSON encoding) |
| **Concurrency** | Swift Concurrency (async/await) |
| **State Management** | Combine + @Published |
| **Dependency Injection** | @EnvironmentObject |

---

## 📦 Installation

### Prerequisites

- **macOS** 13.0 (Ventura) or later
- **Xcode** 15.0 or later
- **iOS Simulator** or physical iOS device
- **Home Assistant** instance (local or remote)

### Setup Steps

#### 1. Clone or Open Project

```bash
cd /path/to/SimpleHomeAssistant/iossimplehomeassistant/SimpleHomeAssistant
```

#### 2. Open in Xcode

```bash
open SimpleHomeAssistant.xcodeproj
```

**Or** double-click `SimpleHomeAssistant.xcodeproj` in Finder.

#### 3. Configure Default Settings (Optional)

Create a default configuration file:

```bash
cd SimpleHomeAssistant/Assets
cp default_config.json.template default_config.json
```

Edit `default_config.json`:

```json
{
  "name": "My Home",
  "internalUrl": "http://192.168.1.100:8123",
  "externalUrl": "https://your-domain.duckdns.org:8123",
  "apiToken": "your-long-lived-access-token-here",
  "isActive": true
}
```

**⚠️ Important**: This file is excluded from git via `.gitignore`.

#### 4. Select Target Device

In Xcode:

1. Click the device selector (top toolbar)
2. Choose:
    - **iPhone simulator** (e.g., iPhone 15 Pro)
    - **iPad simulator** (e.g., iPad Pro)
    - **Physical device** (requires Apple Developer account)

#### 5. Build and Run

Press **⌘R** or click the **Play** button.

The app will:

1. Build successfully
2. Install on simulator/device
3. Launch automatically
4. Load default config (if exists)

---

## 🚀 Usage Guide

### First Launch

#### Step 1: Add Configuration

1. Tap **Config** tab (gear icon)
2. Tap **+** button (floating blue circle, bottom-right)
3. Fill in the form:
    - **Name**: Friendly name (e.g., "Home", "Office")
    - **Internal URL**: Local network URL (e.g., `http://192.168.1.100:8123`)
    - **External URL**: Remote URL (e.g., `https://yourdomain.duckdns.org:8123`)
    - **Authentication Method**: Choose "API Token" or "Username & Password"
        - **API Token**: Long-lived access token from Home Assistant (recommended)
        - **Username & Password**: Your Home Assistant login credentials
4. Tap **Save**

**Note**: See `USERNAME_PASSWORD_AUTH.md` for detailed authentication guide.

#### Step 2: Test Connection

1. Tap **Show More** on your configuration
2. Tap **Test Connection**
3. Verify: ✅ "Connection successful!"

#### Step 3: Load Entities

Entities load automatically after successful connection.

Go to **Dashboard** tab - entities should appear.

### Managing Entities

#### Create Custom Tabs

1. Go to **Tabs** tab (grid icon)
2. Tap **+** button
3. Enter tab name (e.g., "Living Room", "Bedroom")
4. Tap **Create**
5. Tap the newly created tab to open entity assignment
6. Check entities to include in this tab
7. Use search to filter entities
8. Go back to Dashboard
9. Select the tab chip to see your entities

**Note**: Entities are assigned per tab. Each tab can have its own set of entities.

#### Filter Dashboard

On Dashboard:

- **All**: Shows all controllable entities (lights, switches, climate devices)
- **Tab chips**: Shows only entities assigned to that specific tab

### Controlling Entities

#### Lights

- **Toggle**: Turn on/off
- **Brightness**: Drag slider (0-100%)
- **Loading**: Spinner shows during action

#### Switches

- **Toggle**: Turn on/off

#### Thermostats

- **Toggle**: Turn HVAC on/off
- **Temperature**: ➖ / ➕ buttons
- **Mode**: Dropdown (Heat, Cool, Auto, etc.)

#### Sensors

- **Display**: Read-only value + unit

### Network Switching

Toggle between internal/external URLs:

1. Tap **Internal** / **External** badge (top-left)
2. Switch network
3. All subsequent API calls use selected URL

---

## 🎨 Customization

### Changing App Icon

1. **Prepare icon**: 1024×1024 PNG, no transparency
2. **Run script**:
   ```bash
   cd iossimplehomeassistant
   ./generate_icons.sh YourIcon.png
   ```
3. **Rebuild**: ⌘⇧K (Clean) → ⌘R (Run)

### Changing App Name

Edit the Xcode project build settings:

1. Open `SimpleHomeAssistant.xcodeproj` in Xcode
2. Select the project in the navigator
3. Select the "SimpleHomeAssistant" target
4. Go to "Build Settings" tab
5. Search for "Bundle Display Name"
6. Change `INFOPLIST_KEY_CFBundleDisplayName` value to your desired app name

Or edit `project.pbxproj` directly and change:

```
INFOPLIST_KEY_CFBundleDisplayName = YourAppName;
```

---

## 🐛 Troubleshooting

### Build Issues

#### Error: "Multiple commands produce Info.plist"

**Fixed**: This issue has been resolved. The project now uses auto-generated Info.plist with build
settings.

If you encounter this error:

- Ensure `SimpleHomeAssistant/Info.plist` is renamed to `Info.plist.backup`
- The project uses `GENERATE_INFOPLIST_FILE = YES` in build settings
- Custom Info.plist values are defined as `INFOPLIST_KEY_*` build settings

See `BUILD_FIX.md` for details.

#### Error: "No such module 'SwiftUI'"

**Solution**: Ensure iOS Deployment Target is 16.0+

- Select project → Build Settings → iOS Deployment Target → 16.0

#### Error: "Command PhaseScriptExecution failed"

**Solution**: Clean build folder

```bash
# In Xcode
⌘⇧K (Cmd+Shift+K)
```

Or delete derived data:

```bash
rm -rf ~/Library/Developer/Xcode/DerivedData/SimpleHomeAssistant-*
```

### Runtime Issues

#### 401 Unauthorized Error

**Cause**: Invalid or expired API token

**Solution**:

1. Go to Home Assistant
2. Profile → Security → Long-Lived Access Tokens
3. Create new token
4. Edit configuration in app
5. Paste new token

#### Can't Connect to Home Assistant

**Cause**: Network or URL issue

**Solution**:

1. Verify URL in browser first
2. Check internal URL works on same network
3. Check external URL works on cellular
4. Verify port `:8123` is included
5. Check ATS exceptions in `Info.plist`

#### Entities Not Loading

**Cause**: Configuration not active or API error

**Solution**:

1. Verify configuration is active (green checkmark)
2. Test connection
3. Check Home Assistant logs
4. Restart app

### Network Issues

#### HTTP Not Allowed

Already configured! `Info.plist` has ATS exceptions for:

- Local networks (192.168.x.x)
- Your external domain
- Localhost

---

## 🔐 Security

### API Token Storage

- Tokens stored in **UserDefaults** (not Keychain)
- Auto-trimmed to remove whitespace
- Never logged in release builds

### Network Security

- **HTTP allowed** for local networks via ATS exceptions
- **HTTPS preferred** for external access
- Configure in `Info.plist` → `NSAppTransportSecurity`

### Git Safety

**Never commit**:

- ✅ `Assets/default_config.json` (in `.gitignore`)

**Safe to commit**:

- ✅ `Assets/default_config.json.template`
- ✅ All source code

---

## 🧪 Testing

### Unit Tests

```bash
# Run all tests
⌘U in Xcode
```

Or via command line:

```bash
xcodebuild test -scheme SimpleHomeAssistant \
  -destination 'platform=iOS Simulator,name=iPhone 15 Pro'
```

### Manual Testing Checklist

- [ ] Add configuration
- [ ] Test connection (internal)
- [ ] Test connection (external)
- [ ] Switch network URLs
- [ ] Load entities
- [ ] Create custom tab
- [ ] Select entities in tab
- [ ] Filter dashboard by tab
- [ ] Toggle light
- [ ] Adjust brightness
- [ ] Toggle thermostat
- [ ] Change temperature
- [ ] Change HVAC mode
- [ ] Pull to refresh
- [ ] Edit configuration
- [ ] Delete configuration

---

## 📈 Performance

### Optimization Strategies

1. **Debouncing**
    - Brightness slider: 300ms debounce
    - All controls: 500ms cooldown
    - Prevents API spam

2. **Lazy Loading**
    - `LazyVStack` for entity list
    - Only render visible entities
    - Smooth scrolling

3. **State Management**
    - `@Published` for reactive updates
    - Minimal redraws
    - Efficient diffing

4. **Network**
    - Async/await for non-blocking calls
    - 30s timeout
    - Error handling

---

## 🔄 Continuous Integration

### GitHub Actions Workflows

This project includes three automated workflows:

#### 1. **CI Build** (`build.yml`)

- Triggers on push/PR to `main` or `develop`
- Builds for iOS Simulator
- Runs unit tests
- Perfect for development workflow

#### 2. **Release Build** (`release.yml`)

- Triggers on version tags (`v1.0.0`)
- Creates unsigned IPA for testing
- Uploads to GitHub Releases
- Can be triggered manually

#### 3. **Signed Release** (`release-signed.yml`)

- Triggers on signed tags (`v1.0.0-signed`)
- Creates signed IPA with your certificates
- Ready for TestFlight or ad-hoc distribution
- Requires Apple Developer secrets setup

### Quick Start

**For testing builds:**

```bash
git tag v1.0.0
git push origin v1.0.0
# Download IPA from GitHub Releases
```

**For signed distribution:**

```bash
# First, add secrets to GitHub (see .github/workflows/README.md)
git tag v1.0.0-signed
git push origin v1.0.0-signed
# Download signed IPA from GitHub Releases
```

**See full documentation:** `.github/workflows/README.md`

---

## 📝 Development Notes

### Adding New Entity Types

1. **Update `HAEntity.swift`**:
   ```swift
   var isControllable: Bool {
       ["light", "switch", "climate", "your_new_type"].contains(domain)
   }
   ```

2. **Add control UI in `EntityCardView.swift`**:
   ```swift
   else if entity.domain == "your_new_type" {
       // Add your custom control UI
   }
   ```

3. **Add API methods in `HomeAssistantAPI.swift`**:
   ```swift
   func controlYourNewType(_ entityId: String, ...) async throws {
       try await callService(domain: "your_domain", service: "your_service", ...)
   }
   ```

### Adding New Features

1. **Model**: Add data structure in `Models/`
2. **ViewModel**: Add logic to `AppViewModel.swift`
3. **View**: Create new view in `Views/`
4. **Navigation**: Update `ContentView.swift`

---

## 🤝 Contributing

### Code Style

- **SwiftLint**: Follow Swift style guide
- **Naming**: Descriptive, clear variable names
- **Comments**: Explain why, not what
- **Structure**: MVVM pattern strictly

### Pull Request Process

1. Create feature branch
2. Make changes
3. Test thoroughly
4. Update documentation
5. Submit PR with clear description

---

## 📄 License

This project is licensed under the MIT License.

---

## 🙏 Acknowledgments

- **Home Assistant**: Amazing open-source home automation platform
- **SwiftUI**: Apple's declarative UI framework
- **Community**: Home Assistant community for inspiration

---

## 📞 Support

### Getting Help

- **Home Assistant Forums**: https://community.home-assistant.io/
- **iOS Issues**: Check troubleshooting section above
- **Feature Requests**: Open an issue

### Useful Links

- [Home Assistant API Documentation](https://developers.home-assistant.io/docs/api/rest/)
- [SwiftUI Documentation](https://developer.apple.com/documentation/swiftui/)
- [Swift Concurrency](https://docs.swift.org/swift-book/LanguageGuide/Concurrency.html)

---

## 🗺️ Roadmap

### Completed ✅

- ✅ Multi-configuration management
- ✅ Entity control (lights, switches, climate)
- ✅ Custom tabs
- ✅ Network URL switching
- ✅ Debouncing and loading states
- ✅ HAbitat branding
- ✅ Persistent storage

### Planned 🔜

- 🔜 Widgets for home screen
- 🔜 Shortcuts integration
- 🔜 Push notifications
- 🔜 Automations management
- 🔜 Dark mode support
- 🔜 Localization (i18n)
- 🔜 Apple Watch companion app

---

<div align="center">

**Made with ❤️ for Home Assistant**

🏠 **HAbitat** - Your home, in your pocket

</div>
