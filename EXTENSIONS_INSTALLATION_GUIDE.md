# Extensions Installation Guide - Downtown City Management Game

## Overview
This guide covers installation of recommended extensions for the Downtown project, prioritized by impact and development needs.

---

## ✅ Priority 1: Mobile UX Plugin (IMMEDIATE)

### Extension: godot-4-mobile-plugin
**Author**: Sabinayo  
**Purpose**: Enhanced mobile UI/UX with tooltips and help bars  
**License**: MIT  
**Compatibility**: Godot 4.0+ (works with 4.5)

### Installation Steps:

1. **Download**:
   - **itch.io**: https://sabinayo.itch.io/godot-4-mobile-plugin
   - **GitHub**: https://github.com/sabinayo/godot-4-mobile-plugin
   - **Asset Library**: Search "godot-4-mobile-plugin" in Godot's AssetLib tab

2. **Install**:
   - Extract the downloaded ZIP
   - Copy the `addons/mobile` folder to `downtown/addons/mobile`
   - Ensure structure: `downtown/addons/mobile/plugin.cfg` exists

3. **Enable**:
   - Open Godot → Project → Project Settings → Plugins
   - Find "Mobile" plugin
   - Check the "Enable" checkbox

4. **Usage**:
   - Add `HelpBar` to LineEdit/SpinBox nodes for mobile keyboard assistance
   - Add `Tooltip` to Control nodes for mobile-friendly tooltips
   - Configure in Inspector: "Display on Mobile" option

### Benefits:
- ✅ Better mobile UX for touch interactions
- ✅ Dynamic tooltips for UI elements
- ✅ Help bar for text input on mobile devices
- ✅ Low integration effort, high impact

---

## ✅ Priority 2: Enhanced Save System (SHORT-TERM)

### Extension: Save System Pro
**Author**: EpicToaster  
**Purpose**: Professional save system with encryption and multiple slots  
**License**: Paid (check pricing)  
**Compatibility**: Godot 4.5 tested

### Installation Steps:

1. **Download**:
   - **itch.io**: https://epictoaster.itch.io/save-system-pro-encrypted-profile-based-save-system-for-godot
   - Purchase/download the plugin

2. **Install**:
   - Extract the downloaded package
   - Copy the `addons/save_system_pro` folder to `downtown/addons/save_system_pro`
   - Ensure structure: `downtown/addons/save_system_pro/plugin.cfg` exists

3. **Enable**:
   - Open Godot → Project → Project Settings → Plugins
   - Find "Save System Pro" plugin
   - Check the "Enable" checkbox

4. **Integration**:
   - Review existing `SaveManager.gd` in `downtown/scripts/`
   - Consider migrating to Save System Pro API or using it alongside
   - Features: Multiple save slots, AES encryption, autosave, editor tools

### Alternative: Addon Save (4.x)
**Free alternative** with similar features:
- **Asset Library**: https://godotassetlibrary.com/asset/U5mEq6/addon-save-%284.x%29
- Features: JSON/binary saves, AES-256-CBC encryption, compression, backups, cloud-ready

### Benefits:
- ✅ Multiple save slots (currently single save)
- ✅ AES encryption for save file security
- ✅ Autosave functionality
- ✅ Editor tools for save management
- ✅ Cloud sync ready (Addon Save)

---

## ⏳ Priority 3: Analytics & Backend (PRE-RELEASE)

### Extension: GodotX Firebase
**Author**: godot-x team  
**Purpose**: Firebase integration for analytics, crash reporting, cloud saves  
**License**: MIT  
**Compatibility**: Godot 4.5, Android SDK 33.5.1

### Installation Steps:

1. **Download**:
   - **GitHub**: https://github.com/godot-x/firebase
   - Follow installation guide in repository

2. **Install**:
   - Clone or download repository
   - Copy Firebase modules to `downtown/addons/firebase`
   - Configure Android export settings (Gradle required)

3. **Setup**:
   - Requires Firebase project setup
   - Android SDK configuration
   - Google Services JSON file

4. **Enable**:
   - Project → Project Settings → Plugins
   - Enable Firebase modules you need (Analytics, Crashlytics, etc.)

### Benefits:
- ✅ Analytics for player behavior tracking
- ✅ Crash reporting and error tracking
- ✅ Push notifications
- ✅ Cloud save integration
- ✅ Essential for production release

---

## 📊 Priority 4: Analytics Visualization (OPTIONAL)

### Extension: DataViz UI
**Author**: Emergent Realms  
**Purpose**: Charts, gauges, dashboards for city management UI  
**License**: Check license on itch.io  
**Compatibility**: Godot 4.5+

### Installation Steps:

1. **Download**:
   - **itch.io**: https://emergent-realms.itch.io/godot-dataviz-ui

2. **Install**:
   - Extract and copy to `downtown/addons/dataviz_ui`

3. **Enable**:
   - Project → Project Settings → Plugins → Enable "DataViz UI"

### Benefits:
- ✅ Resource trend graphs
- ✅ Population growth charts
- ✅ Production analytics dashboards
- ✅ Visual data representation for city stats

---

## 🔧 Installation Verification

After installing any extension:

1. **Check Plugin Status**:
   - Project → Project Settings → Plugins
   - Verify plugin shows as "Enabled" with green checkmark

2. **Verify Files**:
   - Check `downtown/addons/[plugin_name]/plugin.cfg` exists
   - Verify `plugin.cfg` has correct `[plugin]` section

3. **Test Integration**:
   - Run project (F5)
   - Check for errors in Output panel
   - Verify plugin features work as expected

4. **Update Documentation**:
   - Update `memory-bank/Downtown/techContext.md` with new extensions
   - Document any integration patterns or usage

---

## 📝 Current Project State

### Existing Extensions:
- ✅ **godot_mcp**: Custom MCP plugin for AI-assisted development (active)

### Recommended Extensions (To Install):
1. ⏳ **godot-4-mobile-plugin**: Mobile UX enhancements
2. ⏳ **Save System Pro** or **Addon Save**: Enhanced save system
3. ⏳ **GodotX Firebase**: Analytics and backend (pre-release)
4. ⏳ **DataViz UI**: Analytics visualization (optional)

---

## 🚫 Extensions NOT Recommended

These extensions were evaluated but **not recommended** for this project:

- **GridBuilding v5.0**: Custom building system already implemented
- **Terrain3D**: 2D game, not needed
- **Dialogue Manager**: No narrative/dialogue system planned
- **Inventory Systems**: Custom ResourceManager already implemented
- **Pathfinding Extensions**: Built-in AStar2D sufficient

---

## 📚 Additional Resources

- **Godot Asset Library**: https://godotengine.org/asset-library/asset
- **Godot Plugin Documentation**: https://docs.godotengine.org/en/4.5/tutorials/plugins/editor/making_plugins.html
- **Android Plugin Guide**: https://docs.godotengine.org/en/4.5/tutorials/platform/android/android_plugin.html

---

## ⚠️ Important Notes

1. **Compatibility**: Always verify Godot 4.5 compatibility before installing
2. **Testing**: Test extensions in development before production
3. **Performance**: Monitor impact on 60 FPS target for mobile
4. **Integration**: Follow existing Manager Pattern and signal-based architecture
5. **Documentation**: Update techContext.md after installing new extensions

---

**Last Updated**: January 2026  
**Godot Version**: 4.5.1  
**Project**: Downtown City Management Game
