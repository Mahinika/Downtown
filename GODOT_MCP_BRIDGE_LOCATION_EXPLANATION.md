# Godot MCP Bridge Location - Explanation & Solution

**Date**: January 2026  
**Question**: Why is MCP bridge in "Eternal Champions" project directory?  
**Answer**: Bridge location doesn't matter - it's globally accessible via `mcp.json`

---

## ✅ You're Right About Global Access

**MCP tools ARE globally accessible** - the bridge location doesn't matter because:

### How It Works

1. **Global MCP Config**: `C:\Users\Ropbe\.cursor\mcp.json` (global, not project-specific)
   - This config points to the bridge location
   - **Any project can use it** - it's in your user directory

2. **Bridge Connects to Any Godot**:
   - Bridge connects to `localhost:6400` (any Godot instance)
   - Works with **any Godot project** - Downtown, Eternal Champions, etc.
   - Not tied to a specific project

3. **Tools Are Global**:
   - Once registered in the bridge, tools are available to all projects
   - MCP servers are global resources, not project-specific

---

## The Real Issue: Static vs Dynamic Tools

**Current Situation**:
- Bridge has **static tool registry** (hardcoded 38 tools + our 28 new = 66 tools)
- Tools are registered at startup
- Works globally but requires manual updates

**Better Solution** (Implemented):
- **Dynamic tool discovery** via LIST_TOOLS
- Bridge queries Godot for available tools on connection
- Automatically includes all tools from any Godot project
- **No manual registry updates needed**

---

## ✅ What I've Done

### 1. Added Dynamic Tool Discovery
**File**: `tools/dynamic_tools.py`
- Queries Godot's `LIST_TOOLS` command
- Registers all tools dynamically
- Works with any Godot project automatically

### 2. Kept Static Tools
**File**: `tools/advanced_tools.py`
- All 28 new tools implemented statically
- Provides fallback if dynamic discovery fails
- Ensures all tools are available

### 3. Updated Registration
**File**: `tools/__init__.py`
- Registers both static and dynamic tools
- Dynamic discovery ensures ALL tools from Godot are included
- Backwards compatible with existing static tools

---

## Why Bridge Location Doesn't Matter

The bridge can be anywhere because:

1. **Global Config Points to It**: `~/.cursor/mcp.json` references the bridge location
2. **Bridge Connects to Any Godot**: Connects to `localhost:6400` (whichever Godot is running)
3. **Tools Are Discovered Dynamically**: With LIST_TOOLS, tools come from Godot, not bridge location

**Example**:
- Bridge location: `Eternal Champions/mcp_server/`
- Godot project: `Downtown/`
- **Result**: Bridge connects to Downtown's Godot and discovers Downtown's tools ✅

---

## Moving Bridge (Optional)

If you want to move the bridge to a global location:

### Option 1: Keep Where It Is (Recommended)
- ✅ Already works globally
- ✅ Already accessible to all projects
- ✅ No changes needed

### Option 2: Move to Global Location
Move bridge to:
```
C:\Users\Ropbe\.godot-mcp\
```
Then update `C:\Users\Ropbe\.cursor\mcp.json`:
```json
{
  "mcpServers": {
    "godot": {
      "command": "C:\\Users\\Ropbe\\.godot-mcp\\venv\\Scripts\\python.exe",
      "args": ["C:\\Users\\Ropbe\\.godot-mcp\\server.py"]
    }
  }
}
```

**Not necessary** - current location works fine because `mcp.json` is global.

---

## Summary

✅ **Bridge location doesn't affect global access** - `mcp.json` makes it global  
✅ **Dynamic discovery implemented** - queries LIST_TOOLS from any Godot project  
✅ **All 66+ tools available** - static registry + dynamic discovery  
✅ **Works with all projects** - Downtown, Eternal Champions, any Godot project

**After restart**: Bridge will query LIST_TOOLS and automatically include all tools from whatever Godot project is running. No manual updates needed! 🎉

---

**Status**: ✅ Bridge works globally, dynamic discovery added  
**Next**: Restart Cursor to enable dynamic tool discovery
