# MCP Tool Validation Features

## Overview

The MagicaVoxel MCP Server now includes validation features that help prevent common mistakes when creating voxel models, especially for character models and complex structures.

## Implemented Features

### 1. Connection Validation

**Purpose**: Warn when new parts don't connect to existing parts in the model.

**Tools with Connection Validation:**
- `fill_box` - Checks if box connects to existing voxels
- `create_sphere` - Checks if sphere connects to existing voxels
- `create_cylinder` - Checks if cylinder connects to existing voxels

**How It Works:**
1. After reading the model, checks if there are existing voxels
2. If yes, validates that new parts connect to existing parts
3. Checks all positions in the new part for adjacent existing voxels
4. Returns warnings with specific suggestions if not connected

**Implementation:**
- Helper function: `check_connection(model, x1, y1, z1, x2, y2, z2)`
- Returns: `(connects: bool, nearest_point: Optional[tuple])`
- Used by tool handlers to validate before/after operations

**Example Output:**
```
Filled box from (4, 20, 6) to (4, 24, 10) with 20 voxels
Warning: Box does not connect to existing parts. Adjust x1 to 5 to connect to nearest part at (5,20,6)
```

**Real-World Impact:**
- Prevents arms not connecting to torso
- Prevents hands not connecting to arms
- Prevents feet not connecting to legs
- Catches disconnection issues immediately

---

### 2. Gap Detection

**Purpose**: Detect gaps between new parts and existing parts in the model.

**Tools with Gap Detection:**
- `fill_box` - Detects gaps in Y direction after filling

**How It Works:**
1. After filling a box, checks for gaps between the box and existing parts
2. Compares Y coordinates of box with existing parts in same X/Z range
3. Reports gaps with specific Y coordinates
4. Suggests filling gaps for better connection

**Implementation:**
- Helper function: `detect_gaps(model, x1, y1, z1, x2, y2, z2)`
- Returns: `list[int]` of Y coordinates where gaps exist
- Only reports small gaps (≤5 voxels) to avoid false positives

**Example Output:**
```
Filled box from (6, 24, 6) to (10, 27, 10) with 100 voxels
Detected 2-voxel gap(s) at y=26, y=27. Consider filling gaps for better connection.
```

**Real-World Impact:**
- Prevents head floating above torso
- Prevents gaps between body parts
- Helps ensure proper model structure

---

### 3. Enhanced Component Analysis

**Purpose**: Provide suggestions for connecting disconnected parts in a model.

**Tool:** `find_connected_components`

**New Feature:**
- Added `suggest_fixes` parameter (default: False)
- When `suggest_fixes=True`, provides specific coordinates to connect disconnected parts

**How It Works:**
1. Finds all disconnected components using BFS
2. Calculates center points of each component
3. For each pair of adjacent components, calculates midpoint
4. Suggests connection points (midpoints between components)
5. Provides specific coordinates to use with `fill_box` or `place_voxel`

**Implementation:**
- Enhanced existing `find_connected_components` handler
- Calculates component centers: `(min_x + max_x) // 2`, etc.
- Suggests connection at midpoint between centers

**Example Output:**
```
Found 5 component(s)
  Component 1: 1033 voxels at (5,0,5) to (11,25,11)
  Component 2: 50 voxels at (2,20,7) to (4,23,9)
  Component 3: 50 voxels at (12,20,7) to (14,23,9)
  Component 4: 60 voxels at (1,10,6) to (4,12,10)
  Component 5: 60 voxels at (12,10,6) to (15,12,10)

Suggestions to connect components:
  To connect component 1 and 2: Use fill_box or place_voxel at (3, 20, 8)
  To connect component 1 and 3: Use fill_box or place_voxel at (12, 20, 8)
  To connect component 1 and 4: Use fill_box or place_voxel at (3, 12, 8)
  To connect component 1 and 5: Use fill_box or place_voxel at (12, 12, 8)
```

**Real-World Impact:**
- Helps fix disconnected character models
- Provides actionable suggestions
- Makes it easy to connect parts after creation

---

## Helper Functions

### `check_connection(model, x1, y1, z1, x2, y2, z2) -> tuple[bool, Optional[tuple]]`

**Purpose**: Check if a box region connects to existing voxels.

**Returns:**
- `(connects: bool, nearest_point: Optional[tuple])`
- `connects`: True if box touches existing voxels
- `nearest_point`: Closest existing voxel if not connected, None if connected

---

### `detect_gaps(model, x1, y1, z1, x2, y2, z2) -> list[int]`

**Purpose**: Detect gaps in Y direction between box and existing parts.

**Returns:**
- `list[int]`: List of Y coordinates where gaps exist

**Limitations:**
- Only detects gaps in Y direction (vertical)
- Only reports gaps ≤5 voxels to avoid false positives
- Future: Could detect gaps in X and Z directions

---

## Benefits

### For AI Assistants
- **Immediate Feedback**: Know right away if parts don't connect
- **Actionable Suggestions**: Get specific coordinates to fix issues
- **Prevent Mistakes**: Catch problems during creation, not after

### For Users
- **Better Models**: Ensures proper structure and connectivity
- **Less Debugging**: Find issues early, not after hours of work
- **Learning Tool**: Understand proper model construction

### For Development
- **Quality Assurance**: Automatic validation of model structure
- **Error Prevention**: Catch common mistakes before they cause problems
- **User Experience**: Better error messages and suggestions

---

## Integration

These validation features are integrated into the existing MCP tools:
- No breaking changes - all existing tool calls work the same
- Warnings are additive - don't prevent operations, just inform
- Backward compatible - tools work without validation if model is empty
- Optional features - can be enhanced further in future phases
