extends TestBase

## CoreSystemTests - Tests for core game systems and managers
##
## Tests basic manager existence, data loading, resource systems,
## building systems, villager systems, and job systems.

class_name CoreSystemTests

func _ready() -> void:
	super._ready()
	run_core_system_tests()

func run_core_system_tests() -> void:
	"""Run all core system tests"""
	print("\n[TEST] Starting Core System Tests...\n")

	# Manager Existence Tests
	test_all_managers_exist()
	test_manager_initialization()

	# Data Loading Tests
	test_data_loading()
	test_building_data_integrity()
	test_resource_data_integrity()

	# Resource System Tests
	test_resource_system_complete()
	test_resource_operations()

	# Building System Tests
	test_building_system_complete()
	test_building_placement_validation()
	test_building_states()

	# Villager System Tests
	test_villager_system_complete()
	test_villager_operations()

	# Job System Tests
	test_job_system_complete()
	test_job_assignments()

	# City Manager Tests
	test_city_manager_pathfinding()
	test_city_manager_grid()

	# Print results
	print_test_summary()

# ==================== Manager Existence Tests ====================

func test_all_managers_exist() -> void:
	print("[TEST] All Managers Exist...")

	var managers = [
		"DataManager", "ResourceManager", "BuildingManager", "CityManager",
		"VillagerManager", "ResourceNodeManager", "JobSystem", "SkillManager",
		"SaveManager", "ProgressionManager", "ResearchManager", "EventManager",
		"SeasonalManager", "AssetGenerator", "UITheme", "UIBuilder", "PopularityManager"
	]

	for manager_name in managers:
		assert_manager_exists(manager_name)

func test_manager_initialization() -> void:
	print("\n[TEST] Manager Initialization...")

	# Test that managers have basic properties initialized
	if DataManager:
		assert_property_exists(DataManager, "buildings_data", "DataManager")
		assert_property_exists(DataManager, "resources_data", "DataManager")

	if ResourceManager:
		assert_property_exists(ResourceManager, "resources", "ResourceManager")
		assert_property_exists(ResourceManager, "storage_capacities", "ResourceManager")

	if BuildingManager:
		assert_property_exists(BuildingManager, "buildings", "BuildingManager")
		assert_property_exists(BuildingManager, "processing_buildings", "BuildingManager")

# ==================== Data Loading Tests ====================

func test_data_loading() -> void:
	print("\n[TEST] Data Loading...")

	if not DataManager:
		record_test("DataLoading_ManagerExists", false, "DataManager not found")
		return

	# Test resources data loaded
	var resources = DataManager.get_resources_data()
	var has_resources = (resources != null and not resources.is_empty())
	record_test("DataLoading_Resources", has_resources,
		"Resources data loaded: " + str(has_resources))

	# Test buildings data loaded
	var buildings = DataManager.get_buildings_data()
	var has_buildings = (buildings != null and not buildings.is_empty())
	record_test("DataLoading_Buildings", has_buildings,
		"Buildings data loaded: " + str(has_buildings))

func test_building_data_integrity() -> void:
	print("\n[TEST] Building Data Integrity...")

	if not DataManager:
		record_test("BuildingDataIntegrity_ManagerExists", false, "DataManager not found")
		return

	var buildings = DataManager.get_buildings_data()
	var all_valid = true
	var missing_fields = []

	for building_id in buildings:
		var building = buildings[building_id]
		if not building.has("id"):
			missing_fields.append(building_id + ":id")
		if not building.has("name"):
			missing_fields.append(building_id + ":name")
		if not building.has("category"):
			missing_fields.append(building_id + ":category")
		if not building.has("cost"):
			missing_fields.append(building_id + ":cost")
		if not building.has("size"):
			missing_fields.append(building_id + ":size")

	all_valid = (missing_fields.size() == 0)
	record_test("BuildingDataIntegrity_RequiredFields", all_valid,
		"Building data integrity: " + str(missing_fields.size()) + " missing fields")

func test_resource_data_integrity() -> void:
	print("\n[TEST] Resource Data Integrity...")

	if not DataManager:
		record_test("ResourceDataIntegrity_ManagerExists", false, "DataManager not found")
		return

	var resources = DataManager.get_resources_data()
	var all_valid = true
	var missing_fields = []

	for resource_id in resources:
		var resource = resources[resource_id]
		if not resource.has("id"):
			missing_fields.append(resource_id + ":id")
		if not resource.has("name"):
			missing_fields.append(resource_id + ":name")

	all_valid = (missing_fields.size() == 0)
	record_test("ResourceDataIntegrity_RequiredFields", all_valid,
		"Resource data integrity: " + str(missing_fields.size()) + " missing fields")

# ==================== Resource System Tests ====================

func test_resource_system_complete() -> void:
	print("\n[TEST] Resource System Complete...")

	if not ResourceManager:
		record_test("ResourceSystem_ManagerExists", false, "ResourceManager not found")
		return

	# Test resource operations
	var initial_wood = ResourceManager.get_resource("wood")
	ResourceManager.add_resource("wood", 50.0)
	var after_add = ResourceManager.get_resource("wood")
	var add_passed = (after_add == initial_wood + 50.0)
	record_test("ResourceSystem_Add", add_passed,
		"Add: " + str(initial_wood) + " -> " + str(after_add))

	ResourceManager.consume_resource("wood", 25.0)
	var after_consume = ResourceManager.get_resource("wood")
	var consume_passed = (after_consume == after_add - 25.0)
	record_test("ResourceSystem_Consume", consume_passed,
		"Consume: " + str(after_add) + " -> " + str(after_consume))

	# Test can_afford
	var costs = {"wood": 10, "stone": 5}
	var can_afford = ResourceManager.can_afford(costs)
	record_test("ResourceSystem_CanAfford", can_afford is bool,
		"Can afford check: " + str(can_afford))

	# Test storage capacity
	var capacity = ResourceManager.get_storage_capacity("food")
	record_test("ResourceSystem_StorageCapacity", capacity > 0,
		"Storage capacity: " + str(capacity))

func test_resource_operations() -> void:
	print("\n[TEST] Resource Operations...")

	if not ResourceManager:
		record_test("ResourceOperations_ManagerExists", false, "ResourceManager not found")
		return

	# Test set_resource
	ResourceManager.set_resource("wood", 100.0)
	var wood_amount = ResourceManager.get_resource("wood")
	record_test("ResourceOperations_SetResource", wood_amount == 100.0,
		"Set resource: " + str(wood_amount))

	# Test resource limits
	ResourceManager.set_resource("wood", 10000.0)  # Over capacity
	var limited_wood = ResourceManager.get_resource("wood")
	var capacity = ResourceManager.get_storage_capacity("wood")
	var properly_limited = (limited_wood <= capacity)
	record_test("ResourceOperations_ResourceLimits", properly_limited,
		"Resource properly limited: " + str(limited_wood) + " <= " + str(capacity))

# ==================== Building System Tests ====================

func test_building_system_complete() -> void:
	print("\n[TEST] Building System Complete...")

	if not BuildingManager:
		record_test("BuildingSystem_ManagerExists", false, "BuildingManager not found")
		return

	# Test building placement validation
	var grid_pos = Vector2i(20, 20)
	var can_place = BuildingManager.can_place_building("hut", grid_pos)
	record_test("BuildingSystem_CanPlace", can_place is bool,
		"Can place hut: " + str(can_place))

	# Test processing buildings registration
	var has_processing = BuildingManager.has("processing_buildings")
	record_test("BuildingSystem_ProcessingTracking", has_processing,
		"Processing buildings tracking: " + str(has_processing))

	# Test building states
	var has_states = BuildingManager.has("building_states")
	record_test("BuildingSystem_StateTracking", has_states,
		"Building states tracking: " + str(has_states))

func test_building_placement_validation() -> void:
	print("\n[TEST] Building Placement Validation...")

	if not BuildingManager:
		record_test("BuildingPlacement_ManagerExists", false, "BuildingManager not found")
		return

	var has_validate = BuildingManager.has_method("can_place_building")
	record_test("BuildingPlacement_ValidationMethod", has_validate,
		"can_place_building exists: " + str(has_validate))

	# Test validation with different scenarios
	if has_validate:
		var grid_pos = Vector2i(50, 50)
		var can_place_hut = BuildingManager.can_place_building("hut", grid_pos)
		record_test("BuildingPlacement_CanPlaceHut", can_place_hut is bool,
			"Can place hut validation: " + str(can_place_hut))

func test_building_states() -> void:
	print("\n[TEST] Building States...")

	if not BuildingManager:
		record_test("BuildingStates_ManagerExists", false, "BuildingManager not found")
		return

	var has_states = BuildingManager.has("building_states")
	var has_get_state = BuildingManager.has_method("get_building_state")
	record_test("BuildingStates_Tracking", has_states,
		"Building states tracking: " + str(has_states))
	record_test("BuildingStates_GetState", has_get_state,
		"get_building_state exists: " + str(has_get_state))

# ==================== Villager System Tests ====================

func test_villager_system_complete() -> void:
	print("\n[TEST] Villager System Complete...")

	var world = GameServices.get_world()
	if not world:
		record_test("VillagerSystem_ManagerExists", false, "GameWorld not found")
		return

	# Test villager spawning
	var spawn_pos = Vector2(200, 200)
	var villager_id = world.spawn_villager(spawn_pos)
	var spawn_passed = (villager_id != "")
	record_test("VillagerSystem_Spawn", spawn_passed,
		"Spawned villager: " + villager_id)

	if spawn_passed:
		# Test villager retrieval
		var villager = world.get_villager(villager_id)
		var retrieved = (villager != null and is_instance_valid(villager))
		record_test("VillagerSystem_Retrieval", retrieved,
			"Retrieved villager: " + str(retrieved))

func test_villager_operations() -> void:
	print("\n[TEST] Villager Operations...")

	if not VillagerManager:
		record_test("VillagerOperations_ManagerExists", false, "VillagerManager not found")
		return

	var world = GameServices.get_world()

	# Test villager removal
	var spawn_pos = Vector2(250, 250)
	var villager_id = world.spawn_villager(spawn_pos)

	if not villager_id.is_empty():
		var exists_before = world.get_villager(villager_id) != null
		world.remove_villager(villager_id)
		var exists_after = world.get_villager(villager_id) != null

		record_test("VillagerOperations_SpawnAndRemove", exists_before and not exists_after,
			"Villager spawn and remove: before=" + str(exists_before) + ", after=" + str(exists_after))

# ==================== Job System Tests ====================

func test_job_system_complete() -> void:
	print("\n[TEST] Job System Complete...")

	if not JobSystem:
		record_test("JobSystem_ManagerExists", false, "JobSystem not found")
		return

	# Test job assignment tracking
	var has_assignments = JobSystem.has("job_assignments")
	record_test("JobSystem_Assignments", has_assignments,
		"Job assignments tracking: " + str(has_assignments))

	# Test work cycles
	var has_cycles = JobSystem.has("work_cycles_cache")
	record_test("JobSystem_WorkCycles", has_cycles,
		"Work cycles cache: " + str(has_cycles))

	# Test all job assignment functions exist
	var job_functions = [
		"assign_lumberjack_job", "assign_miner_job", "assign_farmer_job",
		"assign_miller_job", "assign_brewer_job", "assign_blacksmith_job",
		"assign_smoker_job", "assign_engineer_job"
	]

	for func_name in job_functions:
		var has_func = JobSystem.has_method(func_name)
		record_test("JobSystem_" + func_name, has_func,
			func_name + " exists: " + str(has_func))

func test_job_assignments() -> void:
	print("\n[TEST] Job Assignments...")

	if not JobSystem or not VillagerManager or not BuildingManager:
		record_test("JobAssignments_ManagersExist", false, "Required managers not found")
		return

	# Test job assignment structure
	var has_assignments = JobSystem.has("job_assignments")
	var has_building_workers = JobSystem.has("building_workers")

	record_test("JobAssignments_Assignments", has_assignments,
		"Job assignments tracking: " + str(has_assignments))
	record_test("JobAssignments_BuildingWorkers", has_building_workers,
		"Building workers tracking: " + str(has_building_workers))

# ==================== City Manager Tests ====================

func test_city_manager_pathfinding() -> void:
	print("\n[TEST] CityManager Pathfinding...")

	if not CityManager:
		record_test("CityManager_Exists", false, "CityManager not found")
		return

	var has_pathfinding = CityManager.has_method("get_navigation_path")
	var has_astar = CityManager.has("astar")
	record_test("CityManager_Pathfinding", has_pathfinding,
		"get_navigation_path exists: " + str(has_pathfinding))
	record_test("CityManager_AStar", has_astar,
		"AStar pathfinding graph exists: " + str(has_astar))

	# Test pathfinding calculation
	if has_pathfinding:
		var start = Vector2i(10, 10)
		var end = Vector2i(15, 15)
		var path = CityManager.get_navigation_path(start, end)
		var path_valid = (path != null and path.size() > 0)
		record_test("CityManager_PathCalculation", path_valid,
			"Path calculation works: " + str(path_valid))

func test_city_manager_grid() -> void:
	print("\n[TEST] CityManager Grid...")

	if not CityManager:
		record_test("CityManagerGrid_Exists", false, "CityManager not found")
		return

	var has_grid = CityManager.has("grid")
	var has_get_cell = CityManager.has_method("get_grid_cell")
	record_test("CityManagerGrid_GridExists", has_grid,
		"Grid exists: " + str(has_grid))
	record_test("CityManagerGrid_GetCell", has_get_cell,
		"get_grid_cell exists: " + str(has_get_cell))