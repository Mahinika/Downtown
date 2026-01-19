extends Node

## GameWorld - Unified world management system
##
## Consolidates CityManager, BuildingManager, and VillagerManager functionality
## into a single, cohesive world management system.
##
## Key Features:
## - Grid-based world layout and pathfinding
## - Building placement, tracking, and effects
## - Villager spawning, management, and job assignment
## - Unified world state management
##
## Usage:
##   var world = GameWorld.new()
##   world.initialize_grid(100, 100)
##   var building_id = world.place_building("hut", grid_pos)

# class_name GameWorld  # Removed to avoid autoload conflict

# Emitted when a building is successfully placed
signal building_placed(building_id: String, position: Vector2i)

# Emitted when a building is removed
signal building_removed(building_id: String)

# Emitted when a villager is spawned
signal villager_spawned(villager_id: String)

# Emitted when a villager is removed
signal villager_removed(villager_id: String)

# Emitted when the world state changes
signal world_updated()

# Grid dimensions
const GRID_WIDTH: int = 100
var grid_height: int = 100

# Job types for villagers
enum JobType {
	LUMBERJACK,  # Cuts trees for wood
	MINER,       # Mines stone from quarries
	FARMER,      # Grows food on farms
	ENGINEER,    # Works in advanced workshops
	MILLER,      # Processes wheat into flour
	SMOKER,      # Preserves food
	BREWER,      # Brews beer from wheat
	BLACKSMITH   # Forges tools from stone
}

# Grid occupation tracking: Vector2i -> building_id or null
var occupied_tiles: Dictionary = {}

# Building storage: building_id -> building_data
var buildings: Dictionary = {}
var building_counter: int = 0

# Villager storage: villager_id -> villager_node
var villagers: Dictionary = {}
var villager_counter: int = 0

# Pathfinding data
var pathfinding_graph: AStar2D = AStar2D.new()
var pathfinding_cache: Dictionary = {}

# Building types cache
var building_types: Dictionary = {}

# Preloaded scenes
@onready var villager_scene = preload("res://scenes/Villager.tscn")

# Object pools
var villager_pool: ObjectPool = null

func _ready() -> void:
	print("[GameWorld] Initializing world management system")
	initialize_grid(GRID_WIDTH, grid_height)
	load_building_types()
	initialize_pathfinding()
	initialize_object_pools()

func initialize_grid(width: int, height: int) -> void:
	"""Initialize the world grid"""
	grid_height = height
	print("[GameWorld] Initialized grid: ", width, "x", height)

	# Initialize pathfinding graph
	for x in range(width):
		for y in range(height):
			var point_id = x + y * width
			pathfinding_graph.add_point(point_id, Vector2(x, y))

	# Connect adjacent points
	for x in range(width):
		for y in range(height):
			var point_id = x + y * width
			# Connect to adjacent tiles (4-way connectivity)
			var neighbors = [
				Vector2i(x + 1, y),  # Right
				Vector2i(x - 1, y),  # Left
				Vector2i(x, y + 1),  # Down
				Vector2i(x, y - 1)   # Up
			]

			for neighbor in neighbors:
				if neighbor.x >= 0 and neighbor.x < width and neighbor.y >= 0 and neighbor.y < height:
					var neighbor_id = neighbor.x + neighbor.y * width
					if not pathfinding_graph.are_points_connected(point_id, neighbor_id):
						pathfinding_graph.connect_points(point_id, neighbor_id)

func load_building_types() -> void:
	"""Load building type definitions"""
	var data_manager = get_node_or_null("/root/DataManager")
	if not data_manager:
		push_error("[GameWorld] DataManager not found!")
		return

	var buildings_data = data_manager.get_data("buildings")
	if not buildings_data:
		push_error("[GameWorld] Buildings data not loaded!")
		return

	building_types = buildings_data.get("buildings", {})
	print("[GameWorld] Loaded ", building_types.size(), " building types")

func initialize_pathfinding() -> void:
	"""Initialize pathfinding graph"""
	# Pathfinding graph is already initialized in initialize_grid
	# Additional setup can be added here if needed
	pass

func initialize_object_pools() -> void:
	"""Initialize object pools for performance"""
	villager_pool = ObjectPool.new()
	villager_pool.name = "VillagerPool"
	add_child(villager_pool)

	# Pre-create some villagers
	villager_pool.initialize(villager_scene, 10, 100)
	print("[GameWorld] Object pools initialized")

func can_place_building(building_type: String, grid_pos: Vector2i) -> bool:
	"""Check if a building can be placed at the given position"""
	if not building_types.has(building_type):
		return false

	var building_data = building_types[building_type]
	var size = building_data.get("size", [1, 1])

	# Check if all tiles in the building footprint are free
	for x in range(size[0]):
		for y in range(size[1]):
			var check_pos = grid_pos + Vector2i(x, y)
			if not is_valid_grid_position(check_pos) or is_tile_occupied(check_pos):
				return false

	return true

func place_building(building_type: String, grid_pos: Vector2i) -> String:
	"""Place a building at the specified grid position"""
	if not can_place_building(building_type, grid_pos):
		push_error("[GameWorld] Cannot place building ", building_type, " at ", grid_pos)
		return ""

	var building_data = building_types[building_type]
	var size = building_data.get("size", [1, 1])

	# Generate unique building ID
	building_counter += 1
	var building_id = building_type + "_" + str(building_counter)

	# Store building data
	var building_instance = {
		"id": building_id,
		"type": building_type,
		"grid_position": grid_pos,
		"size": size,
		"data": building_data.duplicate()
	}
	buildings[building_id] = building_instance

	# Mark tiles as occupied
	for x in range(size[0]):
		for y in range(size[1]):
			var tile_pos = grid_pos + Vector2i(x, y)
			occupied_tiles[tile_pos] = building_id

			# Disable pathfinding for this tile
			var point_id = tile_pos.x + tile_pos.y * GRID_WIDTH
			if pathfinding_graph.has_point(point_id):
				pathfinding_graph.set_point_disabled(point_id, true)

	# Clear pathfinding cache
	pathfinding_cache.clear()

	building_placed.emit(building_id, grid_pos)
	world_updated.emit()

	print("[GameWorld] Placed building ", building_id, " at ", grid_pos)
	return building_id

func remove_building(building_id: String) -> bool:
	"""Remove a building from the world"""
	if not buildings.has(building_id):
		return false

	var building = buildings[building_id]
	var grid_pos = building.grid_position
	var size = building.size

	# Free occupied tiles
	for x in range(size[0]):
		for y in range(size[1]):
			var tile_pos = grid_pos + Vector2i(x, y)
			occupied_tiles.erase(tile_pos)

			# Re-enable pathfinding for this tile
			var point_id = tile_pos.x + tile_pos.y * GRID_WIDTH
			if pathfinding_graph.has_point(point_id):
				pathfinding_graph.set_point_disabled(point_id, false)

	# Remove building data
	buildings.erase(building_id)

	# Clear pathfinding cache
	pathfinding_cache.clear()

	building_removed.emit(building_id)
	world_updated.emit()

	print("[GameWorld] Removed building ", building_id)
	return true

func get_building(building_id: String) -> Dictionary:
	"""Get building data by ID"""
	return buildings.get(building_id, {})

func get_all_buildings() -> Dictionary:
	"""Get all buildings in the world"""
	return buildings.duplicate()

func is_valid_grid_position(pos: Vector2i) -> bool:
	"""Check if a grid position is valid"""
	return pos.x >= 0 and pos.x < GRID_WIDTH and pos.y >= 0 and pos.y < grid_height

func is_tile_occupied(pos: Vector2i) -> bool:
	"""Check if a tile is occupied by a building"""
	return occupied_tiles.has(pos)

func get_navigation_path(start_grid: Vector2i, end_grid: Vector2i) -> Array[Vector2]:
	"""Get a navigation path between two grid positions"""
	var cache_key = str(start_grid) + "->" + str(end_grid)

	if pathfinding_cache.has(cache_key):
		return pathfinding_cache[cache_key]

	if not is_valid_grid_position(start_grid) or not is_valid_grid_position(end_grid):
		return []

	var start_id = start_grid.x + start_grid.y * GRID_WIDTH
	var end_id = end_grid.x + end_grid.y * GRID_WIDTH

	if not pathfinding_graph.has_point(start_id) or not pathfinding_graph.has_point(end_id):
		return []

	var path_ids = pathfinding_graph.get_point_path(start_id, end_id)
	var path = []
	for point_id in path_ids:
		# Check if point_id is already a Vector2 (position) or an integer (ID)
		if point_id is Vector2:
			# Already a position
			path.append(point_id)
		else:
			# Convert from ID to position
			var grid_x = int(point_id) % GRID_WIDTH
			var grid_y = int(point_id) / GRID_WIDTH
			path.append(Vector2(float(grid_x), float(grid_y)))

	pathfinding_cache[cache_key] = path
	return path

func spawn_villager(spawn_position: Vector2, parent_node: Node = null) -> String:
	"""Spawn a villager at the specified world position"""
	if not villager_pool:
		push_error("[GameWorld] Villager pool not initialized!")
		return ""

	# Get villager from pool
	var villager = villager_pool.get_object()
	if not villager:
		push_error("[GameWorld] Failed to get villager from pool!")
		return ""

	villager_counter += 1
	var villager_id = "villager_" + str(villager_counter)

	# Configure villager
	villager.name = villager_id
	villager.villager_id = villager_id
	villager.position = spawn_position

	# Add to scene tree
	if parent_node:
		parent_node.add_child(villager)
	else:
		add_child(villager)

	# Track villager
	villagers[villager_id] = villager

	villager_spawned.emit(villager_id)
	print("[GameWorld] Spawned villager ", villager_id, " at ", spawn_position)

	return villager_id

func remove_villager(villager_id: String) -> bool:
	"""Remove a villager from the world"""
	if not villagers.has(villager_id):
		return false

	var villager = villagers[villager_id]
	if is_instance_valid(villager):
		# Return to pool instead of destroying
		villager_pool.return_object(villager)

	villagers.erase(villager_id)
	villager_removed.emit(villager_id)

	print("[GameWorld] Removed villager ", villager_id, " (returned to pool)")
	return true

func get_villager(villager_id: String) -> Node:
	"""Get villager node by ID"""
	return villagers.get(villager_id)

func get_all_villagers() -> Dictionary:
	"""Get all villagers in the world"""
	return villagers.duplicate()

func get_housing_capacity() -> int:
	"""Calculate total housing capacity from all residential buildings"""
	var total_capacity = 0
	for building_id in buildings:
		var building = buildings[building_id]
		var building_data = building.data
		var housing_capacity = building_data.get("housing_capacity", 0)
		total_capacity += housing_capacity
	return total_capacity

func get_worker_capacity(building_id: String) -> int:
	"""Get worker capacity for a building"""
	var building = buildings.get(building_id, {})
	var building_data = building.get("data", {})
	return building_data.get("worker_capacity", 0)

func get_worker_count(building_id: String) -> int:
	"""Get number of workers assigned to a building"""
	# This will need to be implemented when we add job system integration
	return 0
