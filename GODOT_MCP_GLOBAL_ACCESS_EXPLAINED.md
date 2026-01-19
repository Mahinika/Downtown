# Godot MCP Bridge - Global Access Explained

**Date**: January 2026  
**Question**: Why is the bridge in "Eternal Champions" directory? Shouldn't tools be globally accessible?

---

## ✅ Answer: Tools ARE Globally Accessible!

**The bridge location doesn't matter** - tools are globally accessible because:

### How Global Access Works

1. **Global MCP Config** (`C:\Users\Ropbe\.cursor\mcp.json`)
   - This file is in your **user directory**, not a project directory
   - **Global to all projects** - any Cursor workspace can use it
   - Points to bridge location (doesn't matter where bridge is)

2. **Bridge Connects to Any Godot**
   - Bridge connects to `localhost:6400` (whichever Godot is running)
   - **Not tied to a specific project** - works with Downtown, Eternal Champions, any project
   - When you open Downtown in Godot, bridge connects to Downtown's Godot

3. **Tools Registered Globally**
   - Once tools are registered in the bridge, they're available to **all projects**
   - MCP servers are global resources - not project-specific
   - Bridge location is just where the code lives - doesn't affect access

---

## Why Bridge Is In Eternal Champions Directory

The bridge was likely:
1. Created for a specific project initially
2. Then configured in global `mcp.json` 
3. Now works globally for all projects

**This is fine!** The location doesn't affect functionality.

---

## Current Setup (Works Globally) ✅

```
~/.cursor/mcp.json (GLOBAL)
  └─> Points to: Eternal Champions/mcp_server/server.py (just code location)
       └─> Connects to: localhost:6400 (whichever Godot is running)
            └─> Works with: Any Godot project (Downtown, Eternal Champions, etc.)
```

**Result**: Bridge works with **all projects** regardless of its location.

---

## Should We Move Bridge? (Optional)

### Option 1: Keep Where It Is (Recommended) ✅
- ✅ Already works globally
- ✅ Already accessible to all projects
- ✅ No changes needed
- **Location doesn't affect access** - it's just where the code lives

### Option 2: Move to Global Location
If you want cleaner organization, move to:
```
C:\Users\Ropbe\.godot-mcp\
```
Then update `~/.cursor/mcp.json` to point there.

**Not necessary** - current location works fine because `mcp.json` is global.

---

## The Real Solution: All 28 Tools Added ✅

I've added all 28 new tools to the bridge:
- **File**: `tools/advanced_tools.py` (created)
- **Registration**: `tools/__init__.py` (updated)
- **Status**: Ready to use

**Total Tools**: 38 existing + 28 new = **66+ tools** 🎉

---

## Summary

✅ **Tools are globally accessible** - `mcp.json` is global, bridge location doesn't matter  
✅ **Bridge works with all projects** - connects to `localhost:6400` (any Godot)  
✅ **All 28 tools added** - in `tools/advanced_tools.py`  
✅ **No move needed** - current location works fine

**After restart**: Cursor should show 66+ tools (not 38) because all 28 new tools are now registered in the bridge.

---

**The location is fine!** The bridge is globally accessible via the global `mcp.json` configuration. Tools work with all projects. ✅
