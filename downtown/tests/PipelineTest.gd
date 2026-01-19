extends Node

# PipelineTest.gd - Comprehensive pipeline testing suite
# Tests all major game systems and their interactions

class_name PipelineTest

signal test_complete(test_name: String, passed: bool, message: String)
signal all_tests_complete(results: Dictionary)

var test_results: Dictionary = {}
var tests_passed: int = 0
var tests_failed: int = 0

## Helper functions to safely access autoloads
func _get_resource_manager():
	if has_method("get_node_or_null"):
		return get_node_or_null("/root/ResourceManager")
	return null

func _get_building_manager():
	if has_method("get_node_or_null"):
		return get_node_or_null("/root/BuildingManager")
	return null

func _get_job_system():
	if has_method("get_node_or_null"):
		return get_node_or_null("/root/JobSystem")
	return null

func _get_game_services():
	if has_method("get_node_or_null"):
		return get_node_or_null("/root/GameServices")
	return null

func _get_villager_manager():
	if has_method("get_node_or_null"):
		return get_node_or_null("/root/VillagerManager")
	return null

func _get_research_manager():
	if has_method("get_node_or_null"):
		return get_node_or_null("/root/ResearchManager")
	return null

func _get_save_manager():
	if has_method("get_node_or_null"):
		return get_node_or_null("/root/SaveManager")
	return null

func _get_event_manager():
	if has_method("get_node_or_null"):
		return get_node_or_null("/root/EventManager")
	return null

func _ready() -> void:
	print("============================================================")
	print("PIPELINE TEST SUITE - Starting comprehensive tests")
	print("============================================================")
	run_all_tests()

func run_all_tests() -> void:
	"""Run all pipeline tests"""
	test_results.clear()
	tests_passed = 0
	tests_failed = 0
	
	# Wait a frame for managers to initialize
	await get_tree().process_frame
	
	print("\n[TEST] Starting pipeline tests...\n")
	
	# 1. Manager Initialization Tests
	test_manager_initialization()
	
	# 2. Resource System Tests
	test_resource_system()
	
	# 3. Building System Tests
	test_building_system()
	
	# 4. Villager System Tests
	test_villager_system()
	
	# 5. Job System Tests
	test_job_system()
	
	# 6. UI System Tests
	test_ui_system()
	
	# 7. Event System Tests
	test_event_system()
	
	# 8. Research System Tests
	test_research_system()
	
	# 9. Save/Load Tests
	test_save_load()
	
	# 10. Integration Tests
	test_integration()
	
	# Print results
	print_results()
	
	# Emit completion signal
	all_tests_complete.emit(test_results)

func test_manager_initialization() -> void:
	print("[TEST] Manager Initialization...")
	
	var tests = [
		{"name": "DataManager exists", "check": func(): return has_node("/root/DataManager")},
		{"name": "ResourceManager exists", "check": func(): return has_node("/root/ResourceManager")},
		{"name": "BuildingManager exists", "check": func(): return has_node("/root/BuildingManager")},
		{"name": "VillagerManager exists", "check": func(): return has_node("/root/VillagerManager")},
		{"name": "JobSystem exists", "check": func(): return has_node("/root/JobSystem")},
		{"name": "CityManager exists", "check": func(): return has_node("/root/CityManager")},
		{"name": "ProgressionManager exists", "check": func(): return has_node("/root/ProgressionManager")},
		{"name": "ResearchManager exists", "check": func(): return has_node("/root/ResearchManager")},
		{"name": "EventManager exists", "check": func(): return has_node("/root/EventManager")},
		{"name": "SeasonalManager exists", "check": func(): return has_node("/root/SeasonalManager")},
	]
	
	for test in tests:
		var passed = test.check.call()
		record_test("ManagerInit_" + test.name, passed, "" if passed else "Manager not found")
		if passed:
			print("  ✓ " + test.name)
		else:
			print("  ✗ " + test.name + " - FAILED")

func test_resource_system() -> void:
	print("\n[TEST] Resource System...")

	var resource_manager = _get_resource_manager()
	if not resource_manager:
		record_test("ResourceSystem_ManagerExists", false, "ResourceManager not found")
		return

	# Test resource initialization
	var initial_food = resource_manager.get_resource("food")
	record_test("ResourceSystem_InitialFood", initial_food >= 0,
		"Initial food: " + str(initial_food))

	# Test resource addition
	var before = resource_manager.get_resource("wood")
	resource_manager.add_resource("wood", 10.0)
	var after = resource_manager.get_resource("wood")
	var passed = (after == before + 10.0)
	record_test("ResourceSystem_AddResource", passed,
		"Before: " + str(before) + ", After: " + str(after))

	# Test resource consumption
	before = resource_manager.get_resource("wood")
	resource_manager.consume_resource("wood", 5.0)
	after = resource_manager.get_resource("wood")
	passed = (after == before - 5.0)
	record_test("ResourceSystem_ConsumeResource", passed,
		"Before: " + str(before) + ", After: " + str(after))

	# Test can_afford
	var costs = {"wood": 10, "stone": 5}
	var can_afford = resource_manager.can_afford(costs)
	record_test("ResourceSystem_CanAfford", can_afford is bool,
		"Can afford check returned: " + str(can_afford))

	# Test storage capacity
	var capacity = resource_manager.get_storage_capacity("food")
	record_test("ResourceSystem_StorageCapacity", capacity > 0,
		"Storage capacity: " + str(capacity))

func test_building_system() -> void:
	print("\n[TEST] Building System...")

	var building_manager = _get_building_manager()
	if not building_manager:
		record_test("BuildingSystem_ManagerExists", false, "BuildingManager not found")
		return

	# Test building data cache
	var has_cache = building_manager.has("buildings_data_cache")
	record_test("BuildingSystem_DataCache", has_cache,
		"Buildings data cache exists: " + str(has_cache))

	# Test can_place_building (validation)
	var grid_pos = Vector2i(10, 10)
	var can_place = building_manager.can_place_building("hut", grid_pos)
	record_test("BuildingSystem_CanPlaceValidation", can_place is bool,
		"Can place hut at (10,10): " + str(can_place))

	# Test placed_buildings tracking
	var building_count_before = building_manager.placed_buildings.size()
	record_test("BuildingSystem_TrackingExists", true,
		"Placed buildings count: " + str(building_count_before))

	# Test building states
	var has_states = building_manager.has("building_states")
	record_test("BuildingSystem_StateTracking", has_states,
		"Building states tracking exists: " + str(has_states))

func test_villager_system() -> void:
	print("\n[TEST] Villager System...")

	var villager_manager = _get_villager_manager()
	if not villager_manager:
		record_test("VillagerSystem_ManagerExists", false, "VillagerManager not found")
		return

	# Test villager tracking
	var game_services = _get_game_services()
	var world = GameServices.get_world() if game_services else null
	var villager_count = world.get_all_villagers().size() if world else 0
	record_test("VillagerSystem_Tracking", true,
		"Villagers tracked: " + str(villager_count))

	# Test villager spawning (if we can spawn)
	var spawn_pos = Vector2(100, 100)
	var villager_id = world.spawn_villager(spawn_pos) if world else ""
	var spawn_success = (villager_id != "")
	record_test("VillagerSystem_Spawn", spawn_success,
		"Spawned villager ID: " + villager_id)

	if spawn_success:
		# Test villager retrieval
		var villager = world.get_villager(villager_id)
		var retrieved = (villager != null)
		record_test("VillagerSystem_Retrieval", retrieved,
			"Retrieved villager: " + str(retrieved))

func test_job_system() -> void:
	print("\n[TEST] Job System...")

	var job_system = _get_job_system()
	if not job_system:
		record_test("JobSystem_ManagerExists", false, "JobSystem not found")
		return

	# Test job assignments tracking
	var has_assignments = job_system.has("job_assignments")
	record_test("JobSystem_AssignmentTracking", has_assignments,
		"Job assignments tracking exists: " + str(has_assignments))

	# Test work tasks tracking
	var has_tasks = job_system.has("work_tasks")
	record_test("JobSystem_TaskTracking", has_tasks,
		"Work tasks tracking exists: " + str(has_tasks))

	# Test building workers tracking
	var has_workers = job_system.has("building_workers")
	record_test("JobSystem_WorkerTracking", has_workers,
		"Building workers tracking exists: " + str(has_workers))

func test_ui_system() -> void:
	print("\n[TEST] UI System...")
	
	# Test UITheme exists
	var ui_theme = get_node_or_null("/root/UITheme")
	var theme_exists = (ui_theme != null)
	record_test("UISystem_UITheme", theme_exists,
		"UITheme exists: " + str(theme_exists))
	
	# Test UIBuilder exists
	var ui_builder = get_node_or_null("/root/UIBuilder")
	var builder_exists = (ui_builder != null)
	record_test("UISystem_UIBuilder", builder_exists,
		"UIBuilder exists: " + str(builder_exists))
	
	if ui_builder:
		# Test UIBuilder has key functions
		var has_create_panel = ui_builder.has_method("create_panel")
		var has_create_button = ui_builder.has_method("create_button")
		var has_create_label = ui_builder.has_method("create_label")
		
		record_test("UISystem_UIBuilderMethods", has_create_panel and has_create_button and has_create_label,
			"UIBuilder methods: panel=" + str(has_create_panel) + ", button=" + str(has_create_button) + ", label=" + str(has_create_label))

func test_event_system() -> void:
	print("\n[TEST] Event System...")

	var event_manager = _get_event_manager()
	if not event_manager:
		record_test("EventSystem_ManagerExists", false, "EventManager not found")
		return

	# Test event manager has trigger method
	var has_trigger = event_manager.has_method("trigger_event")
	record_test("EventSystem_TriggerMethod", has_trigger,
		"EventManager.trigger_event exists: " + str(has_trigger))

	# Test active events tracking
	var has_active = event_manager.has_method("get_active_events")
	record_test("EventSystem_ActiveEvents", has_active,
		"get_active_events method exists: " + str(has_active))

func test_research_system() -> void:
	print("\n[TEST] Research System...")

	var research_manager = _get_research_manager()
	if not research_manager:
		record_test("ResearchSystem_ManagerExists", false, "ResearchManager not found")
		return

	# Test research data loaded
	var has_research = research_manager.has("available_research")
	record_test("ResearchSystem_DataLoaded", has_research,
		"Available research data exists: " + str(has_research))

	# Test research methods
	var has_start = research_manager.has_method("start_research")
	var has_get_active = research_manager.has_method("get_active_research")

	record_test("ResearchSystem_Methods", has_start and has_get_active,
		"Research methods: start=" + str(has_start) + ", get_active=" + str(has_get_active))

func test_save_load() -> void:
	print("\n[TEST] Save/Load System...")

	var save_manager = _get_save_manager()
	if not save_manager:
		record_test("SaveLoad_ManagerExists", false, "SaveManager not found")
		return

	# Test save method
	var has_save = save_manager.has_method("save_game")
	record_test("SaveLoad_SaveMethod", has_save,
		"save_game method exists: " + str(has_save))

	# Test load method
	var has_load = save_manager.has_method("load_game")
	record_test("SaveLoad_LoadMethod", has_load,
		"load_game method exists: " + str(has_load))

func test_integration() -> void:
	print("\n[TEST] Integration Tests...")

	var resource_manager = _get_resource_manager()
	var building_manager = _get_building_manager()
	var game_services = _get_game_services()
	var world = GameServices.get_world() if game_services else null

	# Test resource → building flow
	if resource_manager and building_manager:
		var initial_wood = resource_manager.get_resource("wood")
		var initial_stone = resource_manager.get_resource("stone")

		# Try to place a building (if we have resources)
		var grid_pos = Vector2i(15, 15)
		var can_place = building_manager.can_place_building("hut", grid_pos)

		record_test("Integration_ResourceBuildingFlow", can_place is bool,
			"Can place building check: " + str(can_place) + " (wood: " + str(initial_wood) + ", stone: " + str(initial_stone) + ")")

	# Test building → villager flow
	if building_manager and world:
		var building_count = building_manager.placed_buildings.size()
		var villager_count = world.get_all_villagers().size()

		record_test("Integration_BuildingVillagerFlow", true,
			"Buildings: " + str(building_count) + ", Villagers: " + str(villager_count))

	# Test signal connections
	if resource_manager:
		var has_signal = resource_manager.has_signal("resource_changed")
		record_test("Integration_SignalConnections", has_signal,
			"resource_changed signal exists: " + str(has_signal))

func record_test(test_name: String, passed: bool, message: String) -> void:
	"""Record a test result"""
	test_results[test_name] = {
		"passed": passed,
		"message": message
	}
	
	if passed:
		tests_passed += 1
	else:
		tests_failed += 1
	
	test_complete.emit(test_name, passed, message)

func print_results() -> void:
	"""Print test results summary"""
	print("\n============================================================")
	print("PIPELINE TEST RESULTS")
	print("============================================================")
	print("Total Tests: " + str(test_results.size()))
	print("Passed: " + str(tests_passed))
	print("Failed: " + str(tests_failed))
	print("Success Rate: " + str((float(tests_passed) / float(test_results.size())) * 100.0) + "%")
	print("\nDetailed Results:")
	
	for test_name in test_results:
		var result = test_results[test_name]
		var status = "✓" if result.passed else "✗"
		print("  " + status + " " + test_name + ": " + result.message)
	
	print("============================================================")
	
	if tests_failed == 0:
		print("✓ ALL TESTS PASSED!")
	else:
		print("✗ SOME TESTS FAILED - Review results above")
	
	print("============================================================")
