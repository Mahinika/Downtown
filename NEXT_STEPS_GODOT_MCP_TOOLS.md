# Next Steps: Get 28 New Godot MCP Tools Working

**Current Status**: ✅ Godot side complete | ❌ Bridge registry needs update  
**Goal**: Make 28 new tools visible in Cursor (should show 66+ tools instead of 38)

---

## Option 1: Check Cursor MCP Settings (Try This First)

### Step 1: Open Cursor Settings
1. Press `Ctrl+,` (or `Cmd+,` on Mac) to open settings
2. Search for "MCP" or "Model Context Protocol"
3. Look for "Godot" or "godot-mcp" configuration

### Step 2: Check for Bridge Configuration
- Look for tool registry configuration
- Check if there's an option to "query tools dynamically" or "use LIST_TOOLS"
- See if you can add custom tools or extend the registry

### Step 3: Restart Cursor
- If you found settings, save and restart Cursor
- Check if tools count increases from 38 to 66+

---

## Option 2: Check Cursor's Extension/MCP Directory

### Step 1: Find Bridge Package Location
The bridge might be installed here:

**Windows locations to check:**
```
%APPDATA%\Cursor\extensions\
%LOCALAPPDATA%\Cursor\extensions\
%APPDATA%\Cursor\User\globalStorage\
```

### Step 2: Search for Godot MCP Files
Look for:
- `godot-mcp` package folder
- `ToolRegistry.ts` file
- Any files containing "godot" and "mcp"

### Step 3: If Found, Update ToolRegistry.ts
1. Open `ToolRegistry.ts` in the bridge package
2. Add 28 new tool definitions from `tools/godot_mcp_tool_registry_update.md`
3. Restart Cursor

---

## Option 3: Contact Cursor Support (If Bridge Not Accessible)

If the bridge is built into Cursor and you can't access it:

### What to Request
1. **Request LIST_TOOLS support** - Ask bridge to query Godot's LIST_TOOLS on connection
2. **Request tool registry update** - Ask them to add 28 new tools (provide `tools/godot_mcp_tool_registry_update.md`)

### What to Provide
- Link to `tools/godot_mcp_tool_registry_update.md` for tool schemas
- Explain that Godot plugin has LIST_TOOLS implemented
- Show that tools work via TCP but aren't visible in Cursor

---

## Option 4: Check Cursor Logs for Bridge Info

### Step 1: Check Recent Logs
Open: `%APPDATA%\Cursor\logs\<latest-timestamp>\window1\exthost\anysphere.cursor-mcp\MCP user-godot.log`

Look for:
- Bridge package location
- Tool registry initialization
- Any errors about tool discovery

### Step 2: Search for Tool Registry
The logs might show where the bridge loads its tool registry from.

---

## Quick Checklist

- [ ] Checked Cursor settings for MCP/bridge configuration
- [ ] Searched for bridge package in Cursor directories
- [ ] Looked for `ToolRegistry.ts` or similar files
- [ ] Checked Cursor logs for bridge location
- [ ] If bridge found: Updated `ToolRegistry.ts` with 28 new tools
- [ ] If bridge not found: Contacted Cursor support
- [ ] Restarted Cursor after any changes
- [ ] Verified tool count shows 66+ (not 38)

---

## If You Find the Bridge Package

### Update Steps
1. **Open `ToolRegistry.ts`** in bridge package
2. **Add 28 new tools** using definitions from `tools/godot_mcp_tool_registry_update.md`
3. **Map tools to commands** (see command mapping in that file)
4. **Rebuild bridge** (if needed - might just need restart)
5. **Restart Cursor**

### Tool Schemas Location
All 28 tool schemas are in: `tools/godot_mcp_tool_registry_update.md`

Each tool includes:
- Name (e.g., `mcp_godot_connect_signal`)
- Description
- Input schema (TypeScript format)
- Godot command mapping (e.g., `CONNECT_SIGNAL`)

---

## If Bridge Is Built Into Cursor

### You Have Two Options

**Option A: Wait for Cursor Update**
- Tools will appear once Cursor updates bridge
- Godot side is ready - no changes needed there

**Option B: Request Feature**
- Contact Cursor support
- Request LIST_TOOLS query support
- Or request manual tool registry update

**What to Provide:**
- `tools/godot_mcp_tool_registry_update.md` - Complete tool schemas
- `GODOT_MCP_COMPLETE_STATUS.md` - Current status summary

---

## Verification

Once bridge is updated:

1. **Restart Cursor** completely
2. **Check MCP tool list** - Should show **66+ tools** (not 38)
3. **Test new tools** - Try calling:
   - `mcp_godot_get_autoloads`
   - `mcp_godot_connect_signal`
   - `mcp_godot_list_all_groups`

---

## Current Status Summary

| Component | Status | Action Needed |
|-----------|--------|---------------|
| **Godot Plugin** | ✅ Complete | None - All tools implemented |
| **LIST_TOOLS** | ✅ Working | None - Returns tool schemas |
| **Bridge Registry** | ❌ Needs Update | **YOU NEED THIS** - Add 28 tools |
| **Tool Schemas** | ✅ Ready | In `tools/godot_mcp_tool_registry_update.md` |

---

## Most Likely Next Step

**Try Option 1 first**: Check Cursor settings for MCP configuration.

If no settings found, **try Option 2**: Search for bridge package location.

If bridge not accessible, **Option 3**: Contact Cursor support with documentation.

---

**You're almost there!** The Godot side is 100% ready. The only remaining step is updating the bridge's tool registry, which depends on finding where it's located.
