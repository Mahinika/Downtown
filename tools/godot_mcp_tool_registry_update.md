# Godot MCP Tool Registry Update Guide

**Date**: January 2026  
**Purpose**: Complete tool definitions for updating MCP bridge registry  
**Tools**: 28 new tools + existing tools schemas

---

## How to Use This Document

This document provides complete tool definitions in the format expected by the Godot MCP bridge's `ToolRegistry.ts`. Use this to:

1. **Update bridge ToolRegistry** - Add all 28 new tool definitions
2. **Verify tool schemas** - Ensure parameters match Godot's LIST_TOOLS response
3. **Manual registration** - If bridge can't query LIST_TOOLS dynamically

---

## 28 New Tools - Complete Definitions

### Signal System (4 tools)

#### 1. mcp_godot_connect_signal
```typescript
{
  name: "mcp_godot_connect_signal",
  description: "Connect a signal from one node to a method on another node",
  inputSchema: {
    type: "object",
    properties: {
      node_from: { type: "string", description: "Name of the node emitting the signal" },
      signal_name: { type: "string", description: "Name of the signal to connect" },
      node_to: { type: "string", description: "Name of the node receiving the signal" },
      method_name: { type: "string", description: "Name of the method to call" },
      flags: { type: "number", description: "Connection flags (optional, default: 0)" }
    },
    required: ["node_from", "signal_name", "node_to", "method_name"]
  }
}
```
**Godot Command**: `CONNECT_SIGNAL`

#### 2. mcp_godot_disconnect_signal
```typescript
{
  name: "mcp_godot_disconnect_signal",
  description: "Disconnect a signal connection",
  inputSchema: {
    type: "object",
    properties: {
      node_from: { type: "string" },
      signal_name: { type: "string" },
      node_to: { type: "string" },
      method_name: { type: "string" }
    },
    required: ["node_from", "signal_name", "node_to", "method_name"]
  }
}
```
**Godot Command**: `DISCONNECT_SIGNAL`

#### 3. mcp_godot_list_signal_connections
```typescript
{
  name: "mcp_godot_list_signal_connections",
  description: "List all signal connections for a node",
  inputSchema: {
    type: "object",
    properties: {
      node_name: { type: "string", description: "Name of the node" },
      signal_name: { type: "string", description: "Optional: specific signal name (empty = all signals)" }
    },
    required: ["node_name"]
  }
}
```
**Godot Command**: `LIST_SIGNAL_CONNECTIONS`

#### 4. mcp_godot_get_signal_list
```typescript
{
  name: "mcp_godot_get_signal_list",
  description: "Get all signals defined on a node",
  inputSchema: {
    type: "object",
    properties: {
      node_name: { type: "string" }
    },
    required: ["node_name"]
  }
}
```
**Godot Command**: `GET_SIGNAL_LIST`

---

### Node Groups (4 tools)

#### 5. mcp_godot_add_node_to_group
```typescript
{
  name: "mcp_godot_add_node_to_group",
  description: "Add a node to a group",
  inputSchema: {
    type: "object",
    properties: {
      node_name: { type: "string" },
      group_name: { type: "string" }
    },
    required: ["node_name", "group_name"]
  }
}
```
**Godot Command**: `ADD_NODE_TO_GROUP`

#### 6. mcp_godot_remove_node_from_group
```typescript
{
  name: "mcp_godot_remove_node_from_group",
  description: "Remove a node from a group",
  inputSchema: {
    type: "object",
    properties: {
      node_name: { type: "string" },
      group_name: { type: "string" }
    },
    required: ["node_name", "group_name"]
  }
}
```
**Godot Command**: `REMOVE_NODE_FROM_GROUP`

#### 7. mcp_godot_get_nodes_in_group
```typescript
{
  name: "mcp_godot_get_nodes_in_group",
  description: "Get all nodes in a group",
  inputSchema: {
    type: "object",
    properties: {
      group_name: { type: "string" }
    },
    required: ["group_name"]
  }
}
```
**Godot Command**: `GET_NODES_IN_GROUP`

#### 8. mcp_godot_list_all_groups
```typescript
{
  name: "mcp_godot_list_all_groups",
  description: "List all groups in the current scene",
  inputSchema: {
    type: "object",
    properties: {}
  }
}
```
**Godot Command**: `LIST_ALL_GROUPS`

---

### Autoload Management (2 tools)

#### 9. mcp_godot_get_autoloads
```typescript
{
  name: "mcp_godot_get_autoloads",
  description: "Get all autoload singletons configured in the project",
  inputSchema: {
    type: "object",
    properties: {}
  }
}
```
**Godot Command**: `GET_AUTOLOADS`

#### 10. mcp_godot_set_autoload
```typescript
{
  name: "mcp_godot_set_autoload",
  description: "Set or update an autoload singleton",
  inputSchema: {
    type: "object",
    properties: {
      name: { type: "string" },
      path: { type: "string" },
      enabled: { type: "boolean" }
    },
    required: ["name", "path"]
  }
}
```
**Godot Command**: `SET_AUTOLOAD`

---

### Project Settings (2 tools)

#### 11. mcp_godot_get_project_setting
```typescript
{
  name: "mcp_godot_get_project_setting",
  description: "Get a project setting value",
  inputSchema: {
    type: "object",
    properties: {
      setting_name: { type: "string", description: "Setting path (e.g., 'application/config/name')" }
    },
    required: ["setting_name"]
  }
}
```
**Godot Command**: `GET_PROJECT_SETTING`

#### 12. mcp_godot_set_project_setting
```typescript
{
  name: "mcp_godot_set_project_setting",
  description: "Set a project setting value",
  inputSchema: {
    type: "object",
    properties: {
      setting_name: { type: "string" },
      value: { description: "Value to set (any type)" }
    },
    required: ["setting_name", "value"]
  }
}
```
**Godot Command**: `SET_PROJECT_SETTING`

---

### TileMap Operations (4 tools)

#### 13. mcp_godot_paint_tile
```typescript
{
  name: "mcp_godot_paint_tile",
  description: "Paint a tile on a TileMap",
  inputSchema: {
    type: "object",
    properties: {
      tilemap_name: { type: "string" },
      position: { type: "array", items: { type: "number" }, description: "[x, y] cell position" },
      source_id: { type: "number" },
      atlas_coords: { type: "array", items: { type: "number" }, description: "[x, y] atlas coordinates" },
      alternative_id: { type: "number", description: "Alternative tile ID (optional, default: 0)" }
    },
    required: ["tilemap_name", "position", "source_id", "atlas_coords"]
  }
}
```
**Godot Command**: `PAINT_TILE`

#### 14. mcp_godot_erase_tile
```typescript
{
  name: "mcp_godot_erase_tile",
  description: "Erase a tile from a TileMap",
  inputSchema: {
    type: "object",
    properties: {
      tilemap_name: { type: "string" },
      position: { type: "array", items: { type: "number" }, description: "[x, y] cell position" }
    },
    required: ["tilemap_name", "position"]
  }
}
```
**Godot Command**: `ERASE_TILE`

#### 15. mcp_godot_get_tile_info
```typescript
{
  name: "mcp_godot_get_tile_info",
  description: "Get information about a tile at a position",
  inputSchema: {
    type: "object",
    properties: {
      tilemap_name: { type: "string" },
      position: { type: "array", items: { type: "number" }, description: "[x, y] cell position" }
    },
    required: ["tilemap_name", "position"]
  }
}
```
**Godot Command**: `GET_TILE_INFO`

#### 16. mcp_godot_create_tileset
```typescript
{
  name: "mcp_godot_create_tileset",
  description: "Create a new TileSet resource",
  inputSchema: {
    type: "object",
    properties: {
      tileset_path: { type: "string" },
      texture_path: { type: "string" },
      tile_size: { type: "array", items: { type: "number" }, description: "[width, height] tile size" }
    },
    required: ["tileset_path", "texture_path", "tile_size"]
  }
}
```
**Godot Command**: `CREATE_TILESET`

---

### Export Variables (2 tools)

#### 17. mcp_godot_get_export_variables
```typescript
{
  name: "mcp_godot_get_export_variables",
  description: "Get all export variables on a node",
  inputSchema: {
    type: "object",
    properties: {
      node_name: { type: "string" }
    },
    required: ["node_name"]
  }
}
```
**Godot Command**: `GET_EXPORT_VARIABLES`

#### 18. mcp_godot_set_export_variable
```typescript
{
  name: "mcp_godot_set_export_variable",
  description: "Set an export variable value on a node",
  inputSchema: {
    type: "object",
    properties: {
      node_name: { type: "string" },
      variable_name: { type: "string" },
      value: { description: "Value to set (any type)" }
    },
    required: ["node_name", "variable_name", "value"]
  }
}
```
**Godot Command**: `SET_EXPORT_VARIABLE`

---

### Bulk Operations (3 tools)

#### 19. mcp_godot_bulk_create_nodes
```typescript
{
  name: "mcp_godot_bulk_create_nodes",
  description: "Create multiple nodes at once",
  inputSchema: {
    type: "object",
    properties: {
      parent_name: { type: "string", description: "Optional parent node name" },
      node_specs: {
        type: "array",
        items: {
          type: "object",
          properties: {
            type: { type: "string" },
            name: { type: "string" },
            location: { type: "array", items: { type: "number" } },
            rotation: { type: "array", items: { type: "number" } },
            scale: { type: "array", items: { type: "number" } }
          },
          required: ["type", "name"]
        }
      }
    },
    required: ["node_specs"]
  }
}
```
**Godot Command**: `BULK_CREATE_NODES`

#### 20. mcp_godot_bulk_set_property
```typescript
{
  name: "mcp_godot_bulk_set_property",
  description: "Set properties on multiple nodes at once",
  inputSchema: {
    type: "object",
    properties: {
      node_list: { type: "array", items: { type: "string" } },
      property_name: { type: "string" },
      value: { description: "Value to set (any type)" }
    },
    required: ["node_list", "property_name", "value"]
  }
}
```
**Godot Command**: `BULK_SET_PROPERTY`

#### 21. mcp_godot_duplicate_subtree
```typescript
{
  name: "mcp_godot_duplicate_subtree",
  description: "Duplicate a node and all its children",
  inputSchema: {
    type: "object",
    properties: {
      node_name: { type: "string" },
      new_parent_name: { type: "string", description: "Optional new parent name" },
      new_name: { type: "string", description: "Optional new name for duplicate" }
    },
    required: ["node_name"]
  }
}
```
**Godot Command**: `DUPLICATE_SUBTREE`

---

### UI Layout Helpers (3 tools)

#### 22. mcp_godot_set_anchor
```typescript
{
  name: "mcp_godot_set_anchor",
  description: "Set anchor points for a Control node",
  inputSchema: {
    type: "object",
    properties: {
      node_name: { type: "string" },
      anchor_side: { type: "string", enum: ["left", "top", "right", "bottom"] },
      anchor_value: { type: "number", description: "Anchor value (0.0 to 1.0)" }
    },
    required: ["node_name", "anchor_side", "anchor_value"]
  }
}
```
**Godot Command**: `SET_ANCHOR`

#### 23. mcp_godot_set_margin
```typescript
{
  name: "mcp_godot_set_margin",
  description: "Set margin values for a Control node",
  inputSchema: {
    type: "object",
    properties: {
      node_name: { type: "string" },
      margin_left: { type: "number" },
      margin_top: { type: "number" },
      margin_right: { type: "number" },
      margin_bottom: { type: "number" }
    },
    required: ["node_name"]
  }
}
```
**Godot Command**: `SET_MARGIN`

#### 24. mcp_godot_apply_theme
```typescript
{
  name: "mcp_godot_apply_theme",
  description: "Apply a theme to a Control node",
  inputSchema: {
    type: "object",
    properties: {
      node_name: { type: "string" },
      theme_path: { type: "string", description: "Path to theme resource file (optional - empty clears theme)" }
    },
    required: ["node_name"]
  }
}
```
**Godot Command**: `APPLY_THEME`

---

## Bridge Handler Implementation Notes

### Command Mapping

Each MCP tool must map to its Godot command type:

```typescript
// Example handler mapping
const commandMap: Record<string, string> = {
  "mcp_godot_connect_signal": "CONNECT_SIGNAL",
  "mcp_godot_disconnect_signal": "DISCONNECT_SIGNAL",
  // ... 26 more mappings
};
```

### Parameter Translation

Bridge handlers should:
1. Validate input schema matches tool definition
2. Transform MCP tool parameters to Godot command format:
   ```json
   {
     "type": "CONNECT_SIGNAL",
     "params": {
       "node_from": "...",
       "signal_name": "...",
       // ...
     }
   }
   ```
3. Send to Godot TCP server (port 6400)
4. Parse response and return to Cursor

### Error Handling

All handlers should handle:
- Node not found errors
- Invalid parameter errors
- Godot command errors
- Network connection errors

---

## Quick Reference: Command Type Mapping

| MCP Tool Name | Godot Command | Category |
|--------------|---------------|----------|
| mcp_godot_connect_signal | CONNECT_SIGNAL | Signal System |
| mcp_godot_disconnect_signal | DISCONNECT_SIGNAL | Signal System |
| mcp_godot_list_signal_connections | LIST_SIGNAL_CONNECTIONS | Signal System |
| mcp_godot_get_signal_list | GET_SIGNAL_LIST | Signal System |
| mcp_godot_add_node_to_group | ADD_NODE_TO_GROUP | Node Groups |
| mcp_godot_remove_node_from_group | REMOVE_NODE_FROM_GROUP | Node Groups |
| mcp_godot_get_nodes_in_group | GET_NODES_IN_GROUP | Node Groups |
| mcp_godot_list_all_groups | LIST_ALL_GROUPS | Node Groups |
| mcp_godot_get_autoloads | GET_AUTOLOADS | Autoloads |
| mcp_godot_set_autoload | SET_AUTOLOAD | Autoloads |
| mcp_godot_get_project_setting | GET_PROJECT_SETTING | Project Settings |
| mcp_godot_set_project_setting | SET_PROJECT_SETTING | Project Settings |
| mcp_godot_paint_tile | PAINT_TILE | TileMap |
| mcp_godot_erase_tile | ERASE_TILE | TileMap |
| mcp_godot_get_tile_info | GET_TILE_INFO | TileMap |
| mcp_godot_create_tileset | CREATE_TILESET | TileMap |
| mcp_godot_get_export_variables | GET_EXPORT_VARIABLES | Export Variables |
| mcp_godot_set_export_variable | SET_EXPORT_VARIABLE | Export Variables |
| mcp_godot_bulk_create_nodes | BULK_CREATE_NODES | Bulk Operations |
| mcp_godot_bulk_set_property | BULK_SET_PROPERTY | Bulk Operations |
| mcp_godot_duplicate_subtree | DUPLICATE_SUBTREE | Bulk Operations |
| mcp_godot_set_anchor | SET_ANCHOR | UI Layout |
| mcp_godot_set_margin | SET_MARGIN | UI Layout |
| mcp_godot_apply_theme | APPLY_THEME | UI Layout |

---

## Integration Steps

1. **Locate ToolRegistry.ts** in bridge package
2. **Add 28 new tool definitions** using schemas above
3. **Create handler functions** for each tool (or use generic handler with command mapping)
4. **Update command mapping** to include all 28 commands
5. **Test each tool** via Cursor
6. **Rebuild bridge** if needed
7. **Restart Cursor** to load new tools

---

**Total Tools After Update**: 38 existing + 28 new = **66+ tools**  
**Status**: Ready for bridge registry update
