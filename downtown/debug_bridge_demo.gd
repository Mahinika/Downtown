extends Node

# Debug Bridge Demo - Shows how to use the DebugBridge for different scenarios
# Attach this to a scene and run it to test the debug functionality

func _ready():
	print("[DebugBridgeDemo] Ready - Press F9 to dump debug state")

	# Demo 1: Basic state dump (already set up in main.gd with F9)
	print("Demo 1: Press F9 to dump current game state")

	# Demo 2: Error dump with context
	call_deferred("_demo_error_dump")

	# Demo 3: Performance dump
	call_deferred("_demo_performance_dump", 2.0)

	# Demo 4: AI state dump (if you have AI nodes)
	call_deferred("_demo_ai_dump", 5.0)

func _demo_error_dump():
	# Simulate an error condition
	var test_error = "Test error: Villager stuck in invalid state"
	DebugBridge.dump_error(test_error, {
		"test_data": "This is test context",
		"timestamp": Time.get_time_string_from_system(),
		"demo": true
	})
	print("[DebugBridgeDemo] Error dump created - check debug_state.json")

func _demo_performance_dump(delay: float):
	await get_tree().create_timer(delay).timeout

	var debug_bridge = GameServices.get_debug_bridge()
	if debug_bridge:
		debug_bridge.dump_performance({
			"demo": "Performance monitoring",
			"villager_count": VillagerManager.get_villager_count() if VillagerManager else 0,
			"building_count": BuildingManager.get_building_count() if BuildingManager else 0
		})
	print("[DebugBridgeDemo] Performance dump created")

func _demo_ai_dump(delay: float):
	await get_tree().create_timer(delay).timeout

	# If you have AI nodes, you can dump their state like this:
	# var debug_bridge = GameServices.get_debug_bridge()
	# if debug_bridge:
	#     debug_bridge.dump_ai_state(ai_node, {"context": "AI behavior check"})

	var debug_bridge = GameServices.get_debug_bridge()
	if debug_bridge:
		debug_bridge.dump_state({
			"demo": "AI State Dump",
			"job_assignments": JobSystem.job_assignments.size() if JobSystem else 0,
			"active_tasks": JobSystem.work_tasks.size() if JobSystem else 0,
			"note": "Add DebugBridge.dump_ai_state(your_ai_node) to your AI scripts"
		})
	print("[DebugBridgeDemo] AI dump created")

# Example of how to add debug dumping to your AI scripts:
func example_ai_debug():
	# In your AI node's _process or decision-making function:

	# Basic state dump
	# DebugBridge.dump_state({"ai_state": current_state, "target": target.name if target else null})

	# Error when AI gets stuck
	# if is_stuck:
	#     DebugBridge.dump_error("AI stuck", {"position": global_position, "state": current_state})

	# Performance monitoring
	# DebugBridge.dump_performance({"ai_active": true, "decisions_per_second": decision_count})

	pass