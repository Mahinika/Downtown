extends Node

## Debug Commands - Console-based debugging tools
##
## Add this to your main scene for runtime debugging capabilities.
## Call these functions from the Godot debugger console.

func debug_check_managers() -> void:
	"""Check if all managers are properly initialized"""
	print("🔍 Checking manager status...")

	var managers = {
		"GameServices": GameServices,
		"GameWorld": GameWorld,
		"EconomySystem": EconomySystem,
		"SeasonalManager": SeasonalManager,
		"JobSystem": JobSystem,
		"ResourceManager": ResourceManager,
		"BuildingManager": BuildingManager,
		"VillagerManager": VillagerManager,
		"DataManager": DataManager,
		"UIManager": UIManager
	}

	for manager_name in managers:
		var manager = managers[manager_name]
		if manager == null:
			print("❌ " + manager_name + ": NULL")
		else:
			print("✅ " + manager_name + ": OK")
			# Try to call a basic method to test functionality
			if manager.has_method("get_class"):
				print("   Class: " + manager.get_class())

func debug_memory_usage() -> void:
	"""Show detailed memory usage information"""
	print("📊 Memory Usage Report:")

	var static_memory = Performance.get_monitor(Performance.MEMORY_STATIC)
	var dynamic_memory = Performance.get_monitor(Performance.MEMORY_DYNAMIC)
	var static_max = Performance.get_monitor(Performance.MEMORY_STATIC_MAX)
	var dynamic_max = Performance.get_monitor(Performance.MEMORY_DYNAMIC_MAX)

	print("   Static Memory: %.2f MB (max: %.2f MB)" % [static_memory / 1000000.0, static_max / 1000000.0])
	print("   Dynamic Memory: %.2f MB (max: %.2f MB)" % [dynamic_memory / 1000000.0, dynamic_max / 1000000.0])
	print("   Total Memory: %.2f MB" % [(static_memory + dynamic_memory) / 1000000.0])

func debug_performance_stats() -> void:
	"""Show performance statistics"""
	print("⚡ Performance Statistics:")

	var fps = Performance.get_monitor(Performance.TIME_FPS)
	var process_time = Performance.get_monitor(Performance.TIME_PROCESS)
	var physics_time = Performance.get_monitor(Performance.TIME_PHYSICS_PROCESS)

	print("   FPS: %.1f" % fps)
	print("   Process Time: %.3f ms" % (process_time * 1000))
	print("   Physics Time: %.3f ms" % (physics_time * 1000))
	print("   Frame Time: %.3f ms" % ((process_time + physics_time) * 1000))

func debug_list_nodes() -> void:
	"""List all nodes in the current scene"""
	print("📋 Scene Node Hierarchy:")

	var root = get_tree().root
	_print_node_tree(root, 0)

func _print_node_tree(node: Node, depth: int) -> void:
	var indent = "  ".repeat(depth)
	print(indent + node.name + " (" + node.get_class() + ")")

	for child in node.get_children():
		_print_node_tree(child, depth + 1)

func debug_test_villagers() -> void:
	"""Test villager functionality"""
	print("👥 Testing Villagers:")

	if not VillagerManager:
		print("❌ VillagerManager not available")
		return

	var villagers = VillagerManager.get_all_villagers()
	print("   Found " + str(villagers.size()) + " villagers")

	for villager_id in villagers:
		var villager = VillagerManager.get_villager(villager_id)
		if villager:
			print("   ✅ " + villager_id + ": " + str(villager.current_state) + " at " + str(villager.position))
		else:
			print("   ❌ " + villager_id + ": NULL")

func debug_test_resources() -> void:
	"""Test resource system"""
	print("💰 Testing Resources:")

	if not ResourceManager:
		print("❌ ResourceManager not available")
		return

	var resources = ResourceManager.resources
	for resource_id in resources:
		var amount = ResourceManager.get_resource(resource_id)
		print("   " + resource_id + ": " + str(amount))

func debug_force_gc() -> void:
	"""Force garbage collection"""
	print("🗑️  Forcing garbage collection...")
	Performance.force_gc()
	print("✅ GC completed")

func debug_show_stack() -> void:
	"""Show current call stack (limited info available)"""
	print("📚 Call Stack Information:")
	print("   Current scene: " + get_tree().current_scene.name)
	print("   Frame: " + str(Engine.get_frames_drawn()))
	print("   Time: " + str(Engine.get_time_scale()))

	# Try to get some stack info
	var stack = get_stack()
	if stack.size() > 0:
		print("   Stack trace:")
		for i in range(min(5, stack.size())):
			var frame = stack[i]
			print("     " + frame.function + "() in " + frame.source + ":" + str(frame.line))

# Easy console commands - call these from the debugger
func help() -> void:
	"""Show available debug commands"""
	print("🐛 Available Debug Commands:")
	print("   debug_check_managers()     - Check if all managers are initialized")
	print("   debug_memory_usage()       - Show memory usage statistics")
	print("   debug_performance_stats()  - Show performance metrics")
	print("   debug_list_nodes()         - List all nodes in scene hierarchy")
	print("   debug_test_villagers()     - Test villager system")
	print("   debug_test_resources()     - Test resource system")
	print("   debug_force_gc()           - Force garbage collection")
	print("   debug_show_stack()         - Show call stack information")
	print("   help()                     - Show this help message")