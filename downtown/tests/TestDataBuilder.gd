extends Node

## TestDataBuilder - Factory methods for creating consistent test data
##
## Provides standardized methods for creating test objects (villagers, buildings, resources)
## to ensure consistent test setup and reduce code duplication.

class_name TestDataBuilder

## Villager Creation

static func create_test_villager(position: Vector2 = Vector2(100, 100), job_type: String = "") -> String:
	"""Create a test villager with optional job assignment"""
	if not VillagerManager:
		push_error("VillagerManager not available")
		return ""

	var world = GameServices.get_world()
	if not world:
		push_error("GameWorld not available")
		return ""

	var villager_id = world.spawn_villager(position)
	if villager_id.is_empty():
		push_error("Failed to create test villager")
		return ""

	# Mark as test villager for cleanup
	var villager = world.get_villager(villager_id)
	if villager:
		villager.test_villager = true

	# Assign job if specified
	if not job_type.is_empty() and JobSystem:
		JobSystem.assign_villager_to_building(villager_id, "", job_type)

	return villager_id

static func create_multiple_villagers(count: int, start_position: Vector2 = Vector2(100, 100), spacing: float = 50.0) -> Array:
	"""Create multiple test villagers in a grid pattern"""
	var villager_ids = []

	for i in range(count):
		var row = i / 5  # 5 villagers per row
		var col = i % 5
		var position = start_position + Vector2(col * spacing, row * spacing)
		var villager_id = create_test_villager(position)
		if not villager_id.is_empty():
			villager_ids.append(villager_id)

	return villager_ids

## Building Creation

static func create_test_building(building_type: String, grid_pos: Vector2i, assign_workers: bool = false) -> String:
	"""Create a test building with required resources"""
	if not BuildingManager or not ResourceManager:
		push_error("BuildingManager or ResourceManager not available")
		return ""

	# Ensure we have enough resources
	var building_data = DataManager.get_buildings_data().get(building_type, {})
	var costs = building_data.get("cost", {})

	for resource_type in costs:
		var cost = costs[resource_type]
		var current = ResourceManager.get_resource(resource_type)
		if current < cost:
			ResourceManager.add_resource(resource_type, cost - current + 10)  # Extra buffer

	var building_id = BuildingManager.place_building(building_type, grid_pos)
	if building_id.is_empty():
		push_error("Failed to create test building: " + building_type)
		return ""

	# Mark as test building for cleanup
	if BuildingManager.buildings.has(building_id):
		BuildingManager.buildings[building_id].test_building = true

	# Assign workers if requested
	if assign_workers and JobSystem:
		var capacity = BuildingManager.get_worker_capacity(building_id)
		for i in range(min(capacity, 2)):  # Assign up to 2 workers for testing
			var villager_id = create_test_villager(Vector2(200 + i * 50, 200))
			if not villager_id.is_empty():
				JobSystem.assign_villager_to_building(villager_id, building_id, "")

	return building_id

static func create_test_buildings(building_types: Array, start_grid_pos: Vector2i, spacing: int = 2) -> Dictionary:
	"""Create multiple test buildings in a grid"""
	var buildings = {}

	var index = 0
	for building_type in building_types:
		var row = index / 4  # 4 buildings per row
		var col = index % 4
		var grid_pos = start_grid_pos + Vector2i(col * spacing, row * spacing)

		var building_id = create_test_building(building_type, grid_pos)
		if not building_id.is_empty():
			buildings[building_type] = building_id
		index += 1

	return buildings

## Production Chain Creation

static func create_bread_production_chain(start_grid_pos: Vector2i) -> Dictionary:
	"""Create a complete bread production chain: Farm -> Mill -> Bakery"""
	var chain = {}

	# Farm (produces wheat)
	chain["farm"] = create_test_building("farm", start_grid_pos)

	# Mill (processes wheat -> flour)
	chain["mill"] = create_test_building("mill", start_grid_pos + Vector2i(2, 0))

	# Bakery (processes flour -> bread)
	chain["bakery"] = create_test_building("bakery", start_grid_pos + Vector2i(4, 0))

	return chain

static func create_ale_production_chain(start_grid_pos: Vector2i) -> Dictionary:
	"""Create a complete ale production chain: Hops Farm -> Brewery -> Inn"""
	var chain = {}

	# Hops Farm (produces hops)
	chain["hops_farm"] = create_test_building("hops_farm", start_grid_pos)

	# Brewery (processes hops -> beer)
	chain["brewery"] = create_test_building("brewery", start_grid_pos + Vector2i(2, 0))

	# Inn (consumes beer)
	chain["inn"] = create_test_building("inn", start_grid_pos + Vector2i(4, 0))

	return chain

static func create_meat_production_chain(start_grid_pos: Vector2i) -> Dictionary:
	"""Create a complete meat production chain: Hunter Hut -> Smoker"""
	var chain = {}

	# Hunter Hut (produces meat)
	chain["hunter_hut"] = create_test_building("hunter_hut", start_grid_pos)

	# Smoker (processes meat -> smoked meat)
	chain["smoker"] = create_test_building("smoker", start_grid_pos + Vector2i(2, 0))

	return chain

## Resource Management

static func setup_basic_resources(amount: float = 1000.0) -> void:
	"""Set up basic resources for testing"""
	if not ResourceManager:
		return

	var basic_resources = ["wood", "stone", "food", "gold", "wheat", "flour", "bread", "hops", "beer"]
	for resource in basic_resources:
		ResourceManager.set_resource(resource, amount)

static func setup_processing_resources() -> void:
	"""Set up resources needed for processing chain testing"""
	if not ResourceManager:
		return

	ResourceManager.set_resource("wheat", 100.0)
	ResourceManager.set_resource("flour", 50.0)
	ResourceManager.set_resource("bread", 25.0)
	ResourceManager.set_resource("hops", 80.0)
	ResourceManager.set_resource("beer", 40.0)
	ResourceManager.set_resource("meat", 60.0)

## Job Assignment Helpers

static func assign_workers_to_building(building_id: String, worker_count: int) -> Array:
	"""Assign workers to a building for testing"""
	var assigned_workers = []

	if not JobSystem or not BuildingManager:
		return assigned_workers

	var capacity = BuildingManager.get_worker_capacity(building_id)
	var workers_to_assign = min(worker_count, capacity)

	for i in range(workers_to_assign):
		var villager_id = create_test_villager(Vector2(300 + i * 30, 300))
		if not villager_id.is_empty():
			var job_type = BuildingManager.get_building_job_type(building_id)
			JobSystem.assign_villager_to_building(villager_id, building_id, job_type)
			assigned_workers.append(villager_id)

	return assigned_workers

## Research and Progression Setup

static func unlock_basic_buildings() -> void:
	"""Unlock basic buildings for testing"""
	if not ProgressionSystem:
		return

	var basic_buildings = ["hut", "lumber_hut", "quarry", "farm", "fire_pit"]
	for building in basic_buildings:
		ProgressionSystem.unlock_building(building)

static func setup_basic_research() -> void:
	"""Set up basic research state for testing"""
	if not ResearchManager:
		return

	# Unlock basic technologies
	var basic_tech = ["agriculture", "masonry", "tool_making"]
	for tech in basic_tech:
		if ResearchManager.available_research.has(tech):
			ResearchManager.unlock_technology(tech)

## Seasonal Setup

static func set_season(season_name: String) -> void:
	"""Set the current season for testing"""
	if not SeasonalManager:
		return

	# This would need to be implemented based on SeasonalManager's API
	# For now, just ensure SeasonalManager exists
	pass

## UI Test Helpers

static func create_test_ui_panel(panel_type: String) -> Control:
	"""Create a test UI panel for UI testing"""
	if not UIBuilder:
		return null

	var create_method = "create_" + panel_type + "_panel"
	if UIBuilder.has_method(create_method):
		return UIBuilder.call(create_method)

	return null

## Cleanup Helpers

static func cleanup_test_objects() -> void:
	"""Clean up all test objects"""
	# This is handled by TestBase._reset_game_state(), but can be called directly
	pass