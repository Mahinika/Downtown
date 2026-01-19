# Godot MCP Bridge Update Required

**Date**: January 2026  
**Issue**: Cursor still shows "38 tools" after implementing 28 new tools  
**Root Cause**: External MCP bridge has hardcoded tool registry

---

## Problem Summary

**Status**: ✅ Tools implemented in Godot  
**Status**: ❌ Tools not visible in Cursor (still shows 38)  
**Root Cause**: External MCP bridge package has hardcoded tool list

---

## Root Cause Analysis

### The MCP Bridge Architecture

Cursor's Godot MCP integration uses an **external MCP bridge/server** (separate package) that:

1. **Sits between Cursor and Godot** - Translates MCP protocol ↔ Godot TCP commands
2. **Has hardcoded tool registry** - Tools are defined in bridge code (ToolRegistry.ts)
3. **Doesn't query LIST_TOOLS** - Bridge doesn't use dynamic discovery

### Where Tools Are Actually Registered

Based on research, the Godot MCP bridge (likely `bradypp/godot-mcp` or similar):

- **Tool definitions**: `src/tools/ToolRegistry.ts`
- **Tool handlers**: `src/tools/<category>/` (scene/, project/, etc.)
- **Server bootstrap**: `GodotMCPServer.ts` (uses ToolRegistry)

**Key Point**: The bridge has a **static tool list** that needs to be updated manually.

---

## Solutions

### Option 1: Update External MCP Bridge Package ⭐ Recommended

If you have access to the MCP bridge source code:

1. **Locate the bridge package**
   - Check Cursor's MCP server directory
   - Look for `godot-mcp` package (Node.js package)
   - Or check if it's installed globally: `npm list -g | grep godot-mcp`

2. **Update ToolRegistry.ts**
   - Add 28 new tool definitions
   - Include tool names, schemas, handlers
   - Match format of existing tools

3. **Rebuild/Reload**
   - Rebuild the bridge package if needed
   - Restart Cursor

### Option 2: Check Bridge Package Location

The bridge might be in:

- **Cursor extensions**: `%APPDATA%\Cursor\extensions\` or `%LOCALAPPDATA%\Cursor\extensions\`
- **Global npm packages**: `%APPDATA%\npm\node_modules\` or similar
- **Cursor's internal storage**: `%APPDATA%\Cursor\` or `%LOCALAPPDATA%\Cursor\`

### Option 3: Use LIST_TOOLS for Manual Registration

If bridge can't be updated automatically:

1. **Query LIST_TOOLS** from Godot to get tool schemas
2. **Manually register tools** in bridge's ToolRegistry
3. **Or submit PR** to bridge repository with new tools

---

## 28 New Tools That Need Registration

### Signal System (4 tools)
- `mcp_godot_connect_signal`
- `mcp_godot_disconnect_signal`
- `mcp_godot_list_signal_connections`
- `mcp_godot_get_signal_list`

### Node Groups (4 tools)
- `mcp_godot_add_node_to_group`
- `mcp_godot_remove_node_from_group`
- `mcp_godot_get_nodes_in_group`
- `mcp_godot_list_all_groups`

### Autoload Management (2 tools)
- `mcp_godot_get_autoloads`
- `mcp_godot_set_autoload`

### Project Settings (2 tools)
- `mcp_godot_get_project_setting`
- `mcp_godot_set_project_setting`

### TileMap Operations (4 tools)
- `mcp_godot_paint_tile`
- `mcp_godot_erase_tile`
- `mcp_godot_get_tile_info`
- `mcp_godot_create_tileset`

### Export Variables (2 tools)
- `mcp_godot_get_export_variables`
- `mcp_godot_set_export_variable`

### Bulk Operations (3 tools)
- `mcp_godot_bulk_create_nodes`
- `mcp_godot_bulk_set_property`
- `mcp_godot_duplicate_subtree`

### UI Layout Helpers (3 tools)
- `mcp_godot_set_anchor`
- `mcp_godot_set_margin`
- `mcp_godot_apply_theme`

---

## How to Find Bridge Package

### Step 1: Check Cursor Logs

The logs show bridge activity:
```
C:\Users\Ropbe\AppData\Roaming\Cursor\logs\<timestamp>\window1\exthost\anysphere.cursor-mcp\MCP user-godot.log
```

### Step 2: Check npm/Node.js Packages

```bash
npm list -g | grep -i godot
npm list -g | grep -i mcp
```

### Step 3: Search for ToolRegistry

```bash
# Search for ToolRegistry.ts or similar files
Get-ChildItem -Path "$env:APPDATA\Cursor" -Recurse -Filter "ToolRegistry*" -ErrorAction SilentlyContinue
Get-ChildItem -Path "$env:LOCALAPPDATA\Cursor" -Recurse -Filter "ToolRegistry*" -ErrorAction SilentlyContinue
```

---

## Next Steps

1. **Locate MCP bridge package** - Find where tool registry is stored
2. **Query LIST_TOOLS** - Use LIST_TOOLS from Godot to get tool schemas
3. **Update ToolRegistry** - Add 28 new tool definitions to bridge
4. **Restart Cursor** - Verify tools appear

---

## Alternative: Bridge Enhancement Request

If bridge doesn't support dynamic discovery:

**Feature Request**: Add LIST_TOOLS query on connection
- Bridge queries Godot's LIST_TOOLS on connection
- Automatically registers tools from response
- No manual registry updates needed

---

## Verification

After updating bridge:

1. **Restart Cursor** - Reload MCP connections
2. **Check tool count** - Should show 66+ tools (38 existing + 28 new)
3. **Test new tools** - Try calling `mcp_godot_get_autoloads` or similar

---

**Status**: ⏳ Waiting for bridge package location/update  
**Godot Side**: ✅ Ready (LIST_TOOLS implemented)  
**Bridge Side**: ❌ Needs tool registry update
