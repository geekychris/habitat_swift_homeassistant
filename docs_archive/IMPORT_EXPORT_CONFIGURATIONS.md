# Configuration Import/Export Feature

**Date**: December 14, 2025  
**Status**: ✅ **IMPLEMENTED**

## What's New

You can now **import and export** Home Assistant configurations as JSON files, with support for
cloud storage via iOS share sheet.

## Features

### 1. Export Configurations

- Export **all configurations** to a single JSON file
- Export **individual configurations** (future enhancement)
- Files include version information and export date
- Pretty-printed JSON for readability

### 2. Import Configurations

- Import configurations from JSON files
- Supports importing multiple configurations at once
- Version validation for compatibility
- Error handling with clear messages

### 3. Cloud Storage Integration

- Use iOS **Share Sheet** to save to:
    - iCloud Drive
    - Google Drive
    - Dropbox
    - Files app
    - AirDrop to other devices
    - Email, Messages, etc.

## User Interface

### Configuration Screen

```
┌─────────────────────────────────────┐
│ Configurations                      │
├─────────────────────────────────────┤
│                                     │
│ Configuration 1                     │
│ Configuration 2                     │
│                                     │
│                            [···]    │  ← Menu button
│                            [+]      │  ← Add button
└─────────────────────────────────────┘
```

**Floating Buttons** (bottom-right):

- **[···] Menu** - Import/Export options
- **[+] Add** - Create new configuration

### Menu Options

Tap the **[···]** menu button to see:

```
┌──────────────────────┐
│ 📤 Export All        │
│ 📥 Import            │
└──────────────────────┘
```

## How to Use

### Export All Configurations

1. **Go to Config tab**
2. **Tap [···] button** (bottom-right)
3. **Tap "Export All"**
4. **Share sheet appears**
5. **Choose destination**:
    - Save to Files → iCloud Drive
    - Share to Dropbox
    - AirDrop to another device
    - Email to yourself
    - etc.

**Result**: JSON file `ha_configs_2025-12-14.json` created

### Import Configurations

1. **Go to Config tab**
2. **Tap [···] button** (bottom-right)
3. **Tap "Import"**
4. **File picker appears**
5. **Navigate to your JSON file**:
    - iCloud Drive
    - Dropbox
    - Local files
    - etc.
6. **Select file**
7. **Confirmation message** shows number imported

**Result**: Configurations added to your list

## Export File Format

### Single Configuration Export

```json
{
  "version": "1.0",
  "exportDate": "2025-12-14T10:30:00Z",
  "configuration": {
    "id": "uuid-here",
    "name": "Home",
    "internalUrl": "http://192.168.1.100:8123",
    "externalUrl": "https://myhome.duckdns.org",
    "internalToken": "eyJhbGciOiJIUzI1NiIs...",
    "externalToken": "eyJhbGciOiJIUzI1NiIs...",
    "authType": "oauth",
    "isActive": true,
    "useInternalUrl": true
  }
}
```

### Multiple Configurations Export

```json
{
  "version": "1.0",
  "exportDate": "2025-12-14T10:30:00Z",
  "configurations": [
    {
      "id": "uuid-1",
      "name": "Home",
      ...
    },
    {
      "id": "uuid-2",
      "name": "Office",
      ...
    }
  ]
}
```

## Use Cases

### Backup Your Configurations

```
Export All → Save to iCloud Drive
→ Safe backup of all settings
```

### Transfer Between Devices

```
iPhone: Export All → AirDrop
iPad: Import → All configs copied
```

### Share with Family

```
Export All → Email JSON file
Family member: Import → Same setup
```

### Multiple Phones

```
Primary phone: Export → iCloud Drive
Secondary phone: Import from iCloud
→ Synchronized configs
```

### Disaster Recovery

```
Phone lost/reset
→ Download JSON from cloud
→ Import
→ All configurations restored
```

## Cloud Storage Options

### iCloud Drive

1. Export → Save to Files
2. Choose "iCloud Drive" location
3. Access from any iOS device or Mac

### Dropbox

1. Export → Share to Dropbox app
2. Files sync across devices
3. Import from Dropbox folder

### Google Drive

1. Export → Share to Google Drive app
2. Cloud storage
3. Import from Drive folder

### Email/Messages

1. Export → Share via Email/Messages
2. Send to yourself or others
3. Import from attachment

## File Naming

**Export All**: `ha_configs_YYYY-MM-DD.json`

- Example: `ha_configs_2025-12-14.json`
- Date-stamped for version tracking

**Single Config** (future): `ConfigName_config.json`

- Example: `Home_config.json`
- Named after configuration

## Security Considerations

### What's Included in Export

- ✅ Configuration names
- ✅ URLs (internal/external)
- ✅ **Authentication tokens** (sensitive!)
- ✅ Auth type
- ✅ Active state

### Security Best Practices

**⚠️ Tokens are included!** These files contain your authentication tokens which provide full access
to your Home Assistant.

**Recommendations**:

1. **Store securely** - Use encrypted cloud storage
2. **Don't email unencrypted** - Anyone with the file can access your system
3. **Delete old exports** - Don't leave files lying around
4. **Use iCloud/Dropbox** - These offer encryption
5. **Consider password-protecting** - Zip with password before sharing

### Future Enhancement: Encrypted Export

- Option to export without tokens
- Password-protected exports
- Token encryption

## Error Handling

### Export Errors

```
"Failed to export configurations"
→ Retry export
```

```
"Failed to write export file"
→ Check storage space
→ Check permissions
```

### Import Errors

```
"Invalid configuration file format"
→ File corrupted or wrong format
→ Re-export from source
```

```
"Unsupported configuration version: 2.0"
→ Update app to latest version
```

```
"Failed to read file"
→ Check file exists
→ Check file permissions
```

## Technical Details

### Version Management

- **Current version**: 1.0
- **Future versions**: Will support migration
- **Version check**: Prevents incompatible imports

### File Format

- **Encoding**: UTF-8
- **Format**: JSON
- **Pretty-printed**: Yes (readable)
- **Sorted keys**: Yes (consistent)
- **Date format**: ISO8601

### Import Behavior

- **Duplicate IDs**: Creates new UUID (prevents conflicts)
- **Same name**: Allows (you can have multiple "Home" configs)
- **Tokens**: Imported as-is
- **Active state**: Preserved but only one can be active

## UI Components

### Floating Menu Button

- **Icon**: ··· (ellipsis)
- **Color**: Gray
- **Size**: 48x48pt circle
- **Position**: Above + button

### Share Sheet

- **Native iOS share sheet**
- **All standard destinations**
- **System UI (familiar to users)**

### File Picker

- **Native iOS file picker**
- **Supports all file providers**
- **Filters to JSON files**

## Implementation Files

**New Files**:

1. `Services/ConfigurationImportExport.swift` - Core import/export logic
2. `Views/ShareSheet.swift` - iOS share sheet wrapper

**Modified Files**:

1. `Views/ConfigurationView.swift` - Added import/export UI

### Key Functions

**Export**:

```swift
ConfigurationImportExport.exportConfigurations(_ configs)
→ Returns Data?
→ Pretty-printed JSON
```

**Import**:

```swift
ConfigurationImportExport.importConfigurations(from: data)
→ Returns Result<[HAConfiguration], ImportError>
→ Validates version
```

**File Operations**:

```swift
writeToFile(data: Data, url: URL) → Bool
readFromFile(url: URL) → Data?
```

## Future Enhancements

### Planned Features

1. **Export individual config** - Right-click menu on config row
2. **Encrypted exports** - Password protection
3. **Selective export** - Choose which configs to export
4. **Auto-backup** - Automatic export to iCloud
5. **Import merge** - Merge vs replace options
6. **Version migration** - Support older export formats
7. **Export without tokens** - Share config structure only

### Advanced Options

- **Compression** - Gzip exports
- **Batch operations** - Import/export tabs with configs
- **Cloud sync** - Auto-sync across devices
- **Backup schedule** - Daily/weekly auto-export

## Test It

### Test Export

1. **Create 2-3 configurations**
2. **Tap [···] button** (bottom-right on Config tab)
3. **Tap "Export All"**
4. **Choose "Save to Files"**
5. **Save to "On My iPhone"**
6. **Check Files app** - see JSON file ✅

### Test Import

1. **Delete a configuration** (or use different device)
2. **Tap [···] button**
3. **Tap "Import"**
4. **Select your JSON file**
5. **See success message** ✅
6. **Check configurations list** - restored! ✅

### Test Cloud Sync

1. **Export to iCloud Drive**
2. **Open on iPad/Mac**
3. **See file in iCloud**
4. **Import on iPad**
5. **Same configs on both devices** ✅

Your configurations are now portable and backed up! 🎉📦
