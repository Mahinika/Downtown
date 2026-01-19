# Code Review Checklist

Based on documented error patterns in `memory-bank/Downtown/error-patterns.md`

## Before Committing

Run validation:
```bash
npm run validate
```

## Critical Checks (Must Fix)

### ✅ Signal Connections
- [ ] **No lambda functions in signal connections** (Pattern 1)
  - ❌ `button.connect("pressed", func(): do_something())`
  - ✅ `button.connect("pressed", _on_button_pressed)`
  - Check: Search for `.connect(` and verify no `func(` follows

### ✅ Autoload References
- [ ] **No strict typing on Autoload references** (Pattern 2)
  - ❌ `var manager: ManagerName`
  - ✅ `var manager` (no type hint)
  - Check: Autoloads should use `get_node("/root/ManagerName")` in `_ready()` if needed

### ✅ Script Inheritance
- [ ] **Script extends correct base class** (Pattern 11)
  - Node2D scripts extend `Node2D`
  - Autoload scripts extend `Node` (not `Resource`)
  - Check: Verify `extends` matches scene node type

## High Priority Checks

### ✅ Signal Cleanup
- [ ] **All signal connections have cleanup** (Pattern 3, 6)
  - Check: Every `connect()` should have corresponding `disconnect()` in `_exit_tree()`
  - Pattern: Use `_exit_tree()` for cleanup

### ✅ Type Safety
- [ ] **Use type-specific math functions** (Pattern 4)
  - ❌ `max(a, b)` or `clamp(v, min, max)`
  - ✅ `maxi(a, b)` or `clampi(v, min, max)` for integers
  - ✅ `maxf(a, b)` or `clampf(v, min, max)` for floats

### ✅ API Compatibility
- [ ] **Use Godot 4.x API** (Pattern 7, 15)
  - ❌ `rect_min_size`
  - ✅ `custom_minimum_size`
  - Check: No deprecated properties or methods

### ✅ DataManager API
- [ ] **Use correct DataManager methods** (Pattern 14)
  - ❌ `DataManager.get_resource_data(id)`
  - ✅ `DataManager.get_resources_data()["resources"].get(id, {})`
  - Check: Verify method exists before calling

## Medium Priority Checks

### ✅ Null Safety
- [ ] **Node access uses null checks**
  - ❌ `$Node.property`
  - ✅ `var node = get_node_or_null("Node"); if node: node.property`
  - Check: Especially for dynamic nodes

### ✅ Visibility
- [ ] **Explicit visibility settings** (Pattern 8)
  - Set `visible = true` and `modulate = Color.WHITE` in `_ready()`
  - Check: Sprite initialization

### ✅ Camera Positioning
- [ ] **Camera anchor mode correct** (Pattern 9, 12)
  - Use `ANCHOR_MODE_DRAG_CENTER` for game cameras
  - Use `camera.position` not `camera.global_position`
  - Check: Camera initialization code

### ✅ Positioning Calculations
- [ ] **Unit positioning on surfaces** (Pattern 10)
  - Calculate based on actual surface properties, not hard-coded values
  - Check: Road surface, building placement

## Code Quality Checks

### ✅ Type Hints
- [ ] **Variables have type hints where possible**
  - `var value: int = 10` not `var value = 10`
  - Functions have return types: `func name() -> void:`

### ✅ Error Handling
- [ ] **push_warning/push_error have context**
  - Include `[ClassName]` prefix: `push_warning("[ClassName] Message")`
  - Check: All error messages are descriptive

### ✅ Resource Cleanup
- [ ] **Proper cleanup in _exit_tree()**
  - Disconnect signals
  - Free resources
  - Clear arrays/dictionaries

## Quick Reference

### Common Patterns to Avoid
1. ❌ Lambda in signals → ✅ Named methods
2. ❌ Strict Autoload types → ✅ No type hints on Autoloads
3. ❌ Generic max/min → ✅ maxi/mini/clampi or maxf/minf/clampf
4. ❌ rect_min_size → ✅ custom_minimum_size
5. ❌ Missing null checks → ✅ get_node_or_null() with validation

### Validation Commands
```bash
# Quick validation
npm run validate

# Verbose (includes suggestions)
npm run validate:verbose

# Pre-commit check
npm run precommit
```

## When Adding New Code

1. **Run validation**: `npm run validate`
2. **Check error patterns**: Review `memory-bank/Downtown/error-patterns.md`
3. **Test in Godot**: Open project and check for warnings/errors
4. **Verify type hints**: Add types to new variables/functions
5. **Check signal cleanup**: Ensure new signals are disconnected

## Related Documentation

- Error Patterns: `memory-bank/Downtown/error-patterns.md`
- System Patterns: `memory-bank/Downtown/systemPatterns.md`
- Tech Context: `memory-bank/Downtown/techContext.md`
