# Godot MCP Tools Test Suite

This document provides a comprehensive test plan for all Godot MCP tools (existing + 28 new tools).

## Prerequisites

1. **Godot Editor**: Running with MCP plugin enabled (port 6400)
2. **Scene**: Open any scene in Godot (or create a test scene)
3. **Cursor**: Restarted after implementing new tools

---

## Test Categories

### 1. Basic Scene Operations (Existing Tools) ✅

#### Test 1.1: Get Scene Info
- **Tool**: `get_scene_info`
- **Expected**: Returns current scene hierarchy and metadata
- **Status**: Should work (tested successfully)

#### Test 1.2: Get Hierarchy
- **Tool**: `get_hierarchy`
- **Expected**: Returns detailed scene tree structure
- **Status**: Should work (tested successfully)

#### Test 1.3: List Scripts
- **Tool**: `list_scripts`
- **Parameters**: `folder_path: "res://scripts"`
- **Expected**: Lists all GDScript files in scripts folder
- **Status**: Should work (tested successfully)

#### Test 1.4: Get Asset List
- **Tool**: `get_asset_list`
- **Parameters**: `folder: "res://scripts"`, `type: "script"`
- **Expected**: Lists script assets
- **Status**: Should work (tested successfully)

---

### 2. Signal System Tools (NEW - Phase 1) 🆕

#### Test 2.1: Get Signal List
- **Tool**: `get_signal_list`
- **Command**: `GET_SIGNAL_LIST`
- **Parameters**: `{"node_name": "PipelineTest"}`
- **Expected**: Returns all signals defined on the node
- **Test Node**: Use any node with signals (Button, Timer, etc.)

#### Test 2.2: List Signal Connections
- **Tool**: `list_signal_connections`
- **Command**: `LIST_SIGNAL_CONNECTIONS`
- **Parameters**: `{"node_name": "PipelineTest", "signal_name": ""}` (empty = all signals)
- **Expected**: Returns all signal connections for the node

#### Test 2.3: Connect Signal
- **Tool**: `connect_signal`
- **Command**: `CONNECT_SIGNAL`
- **Parameters**: 
  ```json
  {
    "node_from": "TestButton",
    "signal_name": "pressed",
    "node_to": "TestHandler",
    "method_name": "_on_button_pressed",
    "flags": 0
  }
  ```
- **Expected**: Connects signal successfully

#### Test 2.4: Disconnect Signal
- **Tool**: `disconnect_signal`
- **Command**: `DISCONNECT_SIGNAL`
- **Parameters**: 
  ```json
  {
    "node_from": "TestButton",
    "signal_name": "pressed",
    "node_to": "TestHandler",
    "method_name": "_on_button_pressed"
  }
  ```
- **Expected**: Disconnects signal successfully

---

### 3. Node Groups Tools (NEW - Phase 1) 🆕

#### Test 3.1: Add Node to Group
- **Tool**: `add_node_to_group`
- **Command**: `ADD_NODE_TO_GROUP`
- **Parameters**: `{"node_name": "TestLabel", "group_name": "test_group"}`
- **Expected**: Adds node to group

#### Test 3.2: Get Nodes in Group
- **Tool**: `get_nodes_in_group`
- **Command**: `GET_NODES_IN_GROUP`
- **Parameters**: `{"group_name": "test_group"}`
- **Expected**: Returns all nodes in the group

#### Test 3.3: List All Groups
- **Tool**: `list_all_groups`
- **Command**: `LIST_ALL_GROUPS`
- **Parameters**: `{}`
- **Expected**: Returns all groups in the scene

#### Test 3.4: Remove Node from Group
- **Tool**: `remove_node_from_group`
- **Command**: `REMOVE_NODE_FROM_GROUP`
- **Parameters**: `{"node_name": "TestLabel", "group_name": "test_group"}`
- **Expected**: Removes node from group

---

### 4. Autoload Management (NEW - Phase 1) 🆕

#### Test 4.1: Get Autoloads
- **Tool**: `get_autoloads`
- **Command**: `GET_AUTOLOADS`
- **Parameters**: `{}`
- **Expected**: Returns list of all autoload singletons (should show 16 singletons)
- **Note**: This should work even if SET_AUTOLOAD requires project.godot editing

---

### 5. Project Settings Tools (NEW - Phase 2) 🆕

#### Test 5.1: Get Project Setting
- **Tool**: `get_project_setting`
- **Command**: `GET_PROJECT_SETTING`
- **Parameters**: `{"setting_name": "application/config/name"}`
- **Expected**: Returns project name ("Downtown")

#### Test 5.2: Set Project Setting
- **Tool**: `set_project_setting`
- **Command**: `SET_PROJECT_SETTING`
- **Parameters**: `{"setting_name": "application/config/description", "value": "Test"}`
- **Expected**: Updates project setting (be careful with this test)

---

### 6. TileMap Operations (NEW - Phase 2) 🆕

#### Test 6.1: Paint Tile
- **Tool**: `paint_tile`
- **Command**: `PAINT_TILE`
- **Parameters**: 
  ```json
  {
    "tilemap_node": "CityGrid",
    "cell_pos": [5, 5],
    "source_id": 0,
    "atlas_coords": [0, 0],
    "alternative_id": 0
  }
  ```
- **Expected**: Paints a tile at position (5, 5)
- **Note**: Requires a TileMap node in the scene

#### Test 6.2: Get Tile Info
- **Tool**: `get_tile_info`
- **Command**: `GET_TILE_INFO`
- **Parameters**: `{"tilemap_node": "CityGrid", "cell_pos": [5, 5]}`
- **Expected**: Returns tile data at position

#### Test 6.3: Erase Tile
- **Tool**: `erase_tile`
- **Command**: `ERASE_TILE`
- **Parameters**: `{"tilemap_node": "CityGrid", "cell_pos": [5, 5]}`
- **Expected**: Erases tile at position

---

### 7. Export Variables (NEW - Phase 2) 🆕

#### Test 7.1: Get Export Variables
- **Tool**: `get_export_variables`
- **Command**: `GET_EXPORT_VARIABLES`
- **Parameters**: `{"node_name": "TestNode"}` (node with export variables)
- **Expected**: Returns list of export variables

#### Test 7.2: Set Export Variable
- **Tool**: `set_export_variable`
- **Command**: `SET_EXPORT_VARIABLE`
- **Parameters**: 
  ```json
  {
    "node_name": "TestNode",
    "variable_name": "test_export_var",
    "value": 42
  }
  ```
- **Expected**: Sets export variable value

---

### 8. Bulk Operations (NEW - Phase 3) 🆕

#### Test 8.1: Bulk Create Nodes
- **Tool**: `bulk_create_nodes`
- **Command**: `BULK_CREATE_NODES`
- **Parameters**: 
  ```json
  {
    "parent_name": "SceneRoot",
    "node_specs": [
      {"type": "Label", "name": "Label1", "location": [0, 0]},
      {"type": "Label", "name": "Label2", "location": [0, 50]},
      {"type": "Button", "name": "Button1", "location": [0, 100]}
    ]
  }
  ```
- **Expected**: Creates multiple nodes at once

#### Test 8.2: Bulk Set Property
- **Tool**: `bulk_set_property`
- **Command**: `BULK_SET_PROPERTY`
- **Parameters**: 
  ```json
  {
    "node_list": ["Label1", "Label2"],
    "property_name": "visible",
    "value": false
  }
  ```
- **Expected**: Sets property on multiple nodes

#### Test 8.3: Duplicate Subtree
- **Tool**: `duplicate_subtree`
- **Command**: `DUPLICATE_SUBTREE`
- **Parameters**: 
  ```json
  {
    "node_name": "TestLabel",
    "new_parent_name": "SceneRoot",
    "new_name": "TestLabelCopy"
  }
  ```
- **Expected**: Duplicates node and children

---

### 9. UI Layout Helpers (NEW - Phase 3) 🆕

#### Test 9.1: Set Anchor
- **Tool**: `set_anchor`
- **Command**: `SET_ANCHOR`
- **Parameters**: 
  ```json
  {
    "control_node": "TestLabel",
    "anchor_side": "left",
    "anchor_value": 0.5
  }
  ```
- **Expected**: Sets control anchor

#### Test 9.2: Set Margin
- **Tool**: `set_margin`
- **Command**: `SET_MARGIN`
- **Parameters**: 
  ```json
  {
    "control_node": "TestLabel",
    "side": "left",
    "margin_value": 10
  }
  ```
- **Expected**: Sets control margin

#### Test 9.3: Apply Theme
- **Tool**: `apply_theme`
- **Command**: `APPLY_THEME`
- **Parameters**: 
  ```json
  {
    "control_node": "TestLabel",
    "theme_path": "res://themes/default_theme.tres"
  }
  ```
- **Expected**: Applies theme resource (if theme exists)

---

## Quick Test Checklist

After restarting Cursor, test these in order:

### Phase 1 (High Priority - Critical for Architecture)
- [ ] `GET_SIGNAL_LIST` - List signals on a Button node
- [ ] `LIST_SIGNAL_CONNECTIONS` - List all connections
- [ ] `ADD_NODE_TO_GROUP` - Add node to group
- [ ] `GET_NODES_IN_GROUP` - Query nodes by group
- [ ] `LIST_ALL_GROUPS` - List all groups
- [ ] `GET_AUTOLOADS` - List all 16 autoloads

### Phase 2 (High Value - Project Configuration)
- [ ] `GET_PROJECT_SETTING` - Read a project setting
- [ ] `PAINT_TILE` - Paint tile on TileMap (if TileMap exists)
- [ ] `GET_TILE_INFO` - Get tile data

### Phase 3 (Productivity - Workflow Enhancement)
- [ ] `BULK_CREATE_NODES` - Create multiple nodes
- [ ] `DUPLICATE_SUBTREE` - Duplicate a node tree
- [ ] `SET_ANCHOR` - Set control anchor

---

## Testing Instructions

1. **Open a test scene in Godot** (or use the current PipelineTest scene)
2. **Create test nodes**: 
   - Create a Button node named "TestButton"
   - Create a Label node named "TestLabel"
   - Create a Timer node named "TestTimer"
3. **Run tests in Cursor** using the tools above
4. **Verify results** in Godot editor to confirm changes took effect

---

## Expected Results

After Cursor restart:
- All 28 new commands should be available via TCP (port 6400)
- Cursor should be able to call them as MCP tools
- Tools should execute and modify the Godot project state

## Troubleshooting

If new tools don't appear:
1. Check Godot MCP plugin is running (port 6400 active)
2. Verify `command_handler.gd` compiles without errors
3. Check Cursor MCP server logs for connection issues
4. Try calling commands directly via TCP to verify they work

---

**Created**: January 2026
**Status**: Ready for testing after Cursor restart
**Total Tools**: 38 existing + 28 new = 66+ tools available
