# Godot ↔ Cursor Debug Bridge

This debug bridge lets you dump live Godot game state to JSON files that Cursor can analyze for debugging, AI behavior analysis, and performance optimization.

## 🚀 Quick Start

1. **Press F9** while running your game to dump the current state
2. **Open `debug_state.json`** in Cursor
3. **Ask questions** like:
   - "Why is the AI stuck?"
   - "What's wrong with this scene tree?"
   - "Suggest fixes based on this state"

## 📋 What's Included

The debug dump contains:
- **Game time & FPS**
- **Current scene** and node hierarchy
- **Node positions, types, scripts**
- **Custom context data** (errors, AI state, performance metrics)

## 🛠️ Usage Examples

### Basic Debugging
```gdscript
# In your main.gd or any script
func _input(event):
    if event.is_action_pressed("ui_debug"):
        DebugBridge.dump_state()
```

### Error Context
```gdscript
if some_error_condition:
    DebugBridge.dump_error("AI stuck at position", {
        "position": global_position,
        "velocity": velocity,
        "target": target.name if target else null
    })
```

### Performance Monitoring
```gdscript
DebugBridge.dump_performance({
    "villager_count": VillagerManager.get_villager_count(),
    "active_tasks": JobSystem.work_tasks.size()
})
```

### AI State Analysis
```gdscript
DebugBridge.dump_ai_state(self, {
    "current_behavior": current_state,
    "decision_timer": decision_timer.time_left
})
```

## 🔧 Setup Verification

1. **Autoload**: DebugBridge should appear in Project → Project Settings → Autoload
2. **Input Action**: `ui_debug` should be bound to F9 in Project → Project Settings → Input Map
3. **Test**: Run game, press F9, check for `debug_state.json` in project root

## 📊 Cursor Integration

After dumping state, you can ask Cursor:
- "Analyze this debug state for AI issues"
- "What performance problems do you see?"
- "How can I optimize this scene structure?"
- "Why might the villagers be idle?"

## 🎯 Advanced Features

### Custom Debug Methods
Add to your AI nodes:
```gdscript
func get_debug_state() -> Dictionary:
    return {
        "state": current_state,
        "target": target.name if target else "none",
        "path_progress": path_progress,
        "stuck_timer": stuck_timer.time_left
    }
```

### Conditional Dumping
```gdscript
if is_stuck and not _last_debug_dump_time or Time.get_time() - _last_debug_dump_time > 5.0:
    DebugBridge.dump_error("AI stuck", get_debug_state())
    _last_debug_dump_time = Time.get_time()
```

## 🐛 Troubleshooting

**No debug_state.json created?**
- Check console for DebugBridge errors
- Verify autoload is registered
- Ensure write permissions in project directory

**F9 not working?**
- Check Input Map has ui_debug action
- Verify F9 is bound to ui_debug
- Test with `Input.is_action_pressed("ui_debug")` in _input

**Empty or minimal data?**
- Make sure you're in the main game scene
- Check that nodes exist when dumping

## 🚀 Next Steps

Once this works, you can extend it with:
- **HTTP server** for live Cursor queries
- **WebSocket streaming** for real-time debugging
- **Scene comparisons** between frames
- **Automated error detection**

But this JSON bridge already gives you 80% of the debugging power you need!