extends Node

## Autoload Test - Verifies that all autoload managers are properly loaded
##
## This script runs automatically when added to a scene and checks if all
## expected autoload managers are available and functioning.

func _ready() -> void:
	print("🔍 Testing Autoload Manager Availability...")
	test_autoloads()

func test_autoloads() -> void:
	var manager_checks = {
		"DataManager": func(): return DataManager,
		"CityManager": func(): return CityManager,
		"ResourceManager": func(): return ResourceManager,
		"ResourceNodeManager": func(): return ResourceNodeManager,
		"BuildingManager": func(): return BuildingManager,
		"VillagerManager": func(): return VillagerManager,
		"SkillManager": func(): return SkillManager,
		"JobSystem": func(): return JobSystem,
		"SeasonalManager": func(): return SeasonalManager,
		"SaveManager": func(): return SaveManager,
		"ResearchManager": func(): return ResearchManager,
		"EventManager": func(): return EventManager,
		"AssetGenerator": func(): return AssetGenerator,
		"UITheme": func(): return UITheme,
		"UIBuilder": func(): return UIBuilder,
		"PopularityManager": func(): return PopularityManager,
		"GameServices": func(): return GameServices,
		"GameWorld": func(): return GameWorld,
		"EconomySystem": func(): return EconomySystem,
		"ProgressionSystem": func(): return ProgressionSystem,
		"WorldSimulation": func(): return WorldSimulation,
		"PersistenceSystem": func(): return PersistenceSystem,
		"UIManager": func(): return UIManager,
		"PerformanceMonitor": func(): return PerformanceMonitor,
		"PerformanceRegressionTest": func(): return PerformanceRegressionTest
	}

	var failed_managers = []
	var passed_count = 0

	for manager_name in manager_checks:
		var check_func = manager_checks[manager_name]
		var manager = check_func.call()
		if manager == null:
			print("❌ " + manager_name + ": NOT LOADED")
			failed_managers.append(manager_name)
		else:
			print("✅ " + manager_name + ": LOADED")
			passed_count += 1

	print("\n📊 Autoload Test Results:")
	print("   ✅ Loaded: " + str(passed_count) + "/" + str(managers.size()))

	if failed_managers.size() > 0:
		print("   ❌ Failed: " + str(failed_managers))
		print("\n🔧 Fix Required: Check project.godot autoload configuration")
		print("   These managers need to be added or reordered in autoloads")
	else:
		print("   🎉 All autoloads loaded successfully!")

	# Special test for ResourceNodeManager since that's the reported issue
	if ResourceNodeManager != null:
		print("\n🧪 Testing ResourceNodeManager functionality:")
		var test_node = ResourceNodeManager.place_resource_node(
			ResourceNodeManager.ResourceNodeType.TREE,
			Vector2i(10, 10)
		)
		if test_node != "":
			print("   ✅ ResourceNodeManager.place_resource_node() works")
			ResourceNodeManager.remove_node(test_node)
		else:
			print("   ❌ ResourceNodeManager.place_resource_node() failed")
	else:
		print("\n❌ Cannot test ResourceNodeManager - not loaded")

	# Special test for PerformanceMonitor
	if PerformanceMonitor != null:
		print("\n🧪 Testing PerformanceMonitor functionality:")
		var fps = PerformanceMonitor.current_fps
		print("   ✅ PerformanceMonitor.current_fps: " + str(fps))
	else:
		print("\n❌ Cannot test PerformanceMonitor - not loaded")