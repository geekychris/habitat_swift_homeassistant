# Configuration Import/Export Feature ✅

**Date**: December 14, 2025  
**Status**: ✅ **FULLY IMPLEMENTED**

## Overview

The app now supports **importing and exporting configurations** as JSON files, enabling easy backup,
sharing, and cloud storage.

## Features

### 1. Export Configurations 📤

**Export All Configurations**:

- Tap the **⋯** menu button (above the + button)
- Select **"Export All"**
- iOS share sheet appears
- Choose destination:
    - **iCloud Drive** ✅
    - **Files app** ✅
    - **AirDrop** ✅
    - **Email** ✅
    - **Other apps** ✅

**Export Format**:

```json
{
  "version": "1.0",
  "exportDate": "2025-12-14T12:00:00Z",
  "configurations": [
    {
      "id": "...",
      "name": "Home",
      "internalUrl": "http://homeassistant.local:8123",
      "externalUrl": "http://geekychris.com:8123",
      "internalToken": "...",
      "externalToken": "...",
      "authMethod": "token",
      "useInternalUrl": true,
      "isActive": true
    }
  ]
}
```

**File Naming**:

- All configs: `ha_configs_2025-12-14.json`
- Single config: `Home_config.json`

### 2. Import Configurations 📥

**Import Process**:

1. Tap **⋯** menu button
2. Select **"Import"**
3. iOS file picker appears
4. Select JSON file from:
    - **iCloud Drive** ✅
    - **Files app** ✅
    - **Downloads** ✅
    - **Other locations** ✅
5. Configurations automatically imported
6. Success/error alert shows

**Smart Import**:

- Supports **batch files** (multiple configs)
- Supports **single config files**
- Validates file format
- Checks version compatibility
- Prevents duplicates (generates new IDs)

### 3. Cloud Storage Integration ☁️

**Works with all iOS storage**:

- **iCloud Drive**: Full sync across devices
- **Files app**: Any connected storage
- **Third-party apps**: Dropbox, Google Drive, etc.

**Workflow Example**:

1. **Export** → Save to iCloud Drive
2. **Open on another device**
3. **Import** → Instant configuration sync! ✅

## User Interface

### Configuration Screen

```
┌─────────────────────────────────────┐
│ Configurations                      │
├─────────────────────────────────────┤
│ 🟢 Home                             │
│    homeassistant.local:8123         │
│                                     │
│ ⚪ Office                           │
│    office.example.com:8123          │
└─────────────────────────────────────┘
                                    
                               [⋯]  ← Menu button
                                    ↓
                            ┌───────────────┐
                            │ Export All    │
                            │ Import        │
                            └───────────────┘
                               [+]  ← Add button
```

### Export Flow

```
Tap ⋯ → Select "Export All" → Share Sheet Appears
                                    ↓
                        ┌──────────────────────┐
                        │  Save to Files       │
                        │  AirDrop             │
                        │  Save to iCloud      │
                        │  Copy                │
                        │  More...             │
                        └──────────────────────┘
```

### Import Flow

```
Tap ⋯ → Select "Import" → File Picker Opens
                                ↓
                    ┌─────────────────────┐
                    │  iCloud Drive       │
                    │  On My iPhone       │
                    │  Downloads          │
                    │  Browse...          │
                    └─────────────────────┘
                                ↓
                    Select JSON file → Import
                                ↓
                    "Successfully imported 2 configuration(s)"
```

## Use Cases

### 1. Backup Configurations 💾

**Before changes**:

1. Export all configurations
2. Save to iCloud Drive
3. Make changes
4. If something breaks → Import backup! ✅

### 2. Share Configurations 🤝

**Help a friend**:

1. Export your configuration
2. AirDrop to friend
3. They import it
4. Instant setup! ✅

### 3. Multi-Device Sync 📱

**Same config on all devices**:

1. Export from iPhone → Save to iCloud
2. Open iPad → Import from iCloud
3. Configurations synced! ✅

### 4. Configuration Templates 📋

**Create templates**:

1. Set up perfect configuration
2. Export it
3. Use as template for new locations
4. Import and modify! ✅

## Technical Details

### File Format

**Version**: 1.0  
**Format**: JSON (pretty-printed, sorted keys)  
**Encoding**: UTF-8  
**Date Format**: ISO 8601

### Security

**Tokens Included**: ⚠️ Export files contain authentication tokens  
**Recommendation**: Store securely (encrypted cloud storage)  
**Best Practice**: Don't share exports publicly

### Validation

Import validates:

- ✅ JSON structure
- ✅ Required fields
- ✅ Version compatibility
- ✅ Data types

### Error Handling

Clear error messages for:

- Invalid file format
- Unsupported version
- File read errors
- Missing required fields

## Files Added

### New Files

1. **`ConfigurationImportExport.swift`**
    - Export/import logic
    - File operations
    - Validation
    - Error handling

2. **`ShareSheet.swift`**
    - iOS share sheet wrapper
    - UIActivityViewController
    - URL identifiable extension

### Modified Files

1. **`ConfigurationView.swift`**
    - Added menu button
    - Import/export UI
    - File picker integration
    - Alert handling

## Testing

### Test Export

1. **Go to Config tab**
2. **Tap ⋯ menu**
3. **Select "Export All"**
4. **Choose "Save to Files"**
5. **Navigate to saved location**
6. **Verify JSON file created** ✅

### Test Import

1. **Delete a configuration** (for testing)
2. **Tap ⋯ menu**
3. **Select "Import"**
4. **Choose exported file**
5. **Verify configuration restored** ✅
6. **Check all settings preserved** ✅

### Test Cloud Storage

1. **Export → Save to iCloud Drive**
2. **Open Files app → Verify file in iCloud**
3. **Open on another device**
4. **Import from iCloud**
5. **Verify configurations match** ✅

## Future Enhancements

Potential additions:

- Export individual configurations (not just all)
- Automatic backups before changes
- Import/export tabs and entity selections
- Encrypted exports with password
- QR code sharing for quick setup

## Summary

The configuration import/export feature is **fully functional** and provides:

✅ **Export all configurations** to JSON  
✅ **Import configurations** from JSON  
✅ **Cloud storage integration** (iCloud, Files, etc.)  
✅ **Share via AirDrop, email, etc.**  
✅ **Smart validation and error handling**  
✅ **Preserves all settings and tokens**  
✅ **Clean, intuitive UI**

**Ready to use!** You can now backup, share, and sync your Home Assistant configurations across
devices. 🎉
