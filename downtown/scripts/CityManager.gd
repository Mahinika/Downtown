extends Node

## CityManager - Core city state and grid management
##
## Singleton Autoload that manages the city grid, building placement, and pathfinding system.
## Handles all grid-based operations including building placement validation, tile occupation tracking,
## and AStar2D pathfinding for villager navigation.
##
## Key Features:
## - Grid-based city layout (100x100 tiles)
## - Building placement and removal with validation
## - AStar2D pathfinding system with caching
## - World-to-grid and grid-to-world coordinate conversion
## - Dynamic pathfinding updates when buildings are placed/removed
##
## Usage:
##   var can_place = CityManager.can_place_building(grid_pos, building_size)
##   var path = CityManager.get_navigation_path(start_grid, end_grid)

## Emitted when a building is successfully placed on the grid.
## Parameters: building_id (String), position (Vector2i)
signal building_placed(building_id: String, position: Vector2i)

## Emitted when a building is removed from the grid.
## Parameters: building_id (String), position (Vector2i)
signal building_removed(building_id: String, position: Vector2i)

## Emitted when the grid state changes (building placed/removed).
signal grid_updated()

## Grid width in tiles (100x100 = 10,000 tiles total).
## Can be increased further or made infinite with chunking.
const GRID_WIDTH: int = 100

## Grid height in tiles.
const GRID_HEIGHT: int = 100

## Size of each tile in pixels (32x32 pixels per tile).
const TILE_SIZE: int = 32

## Grid occupation map: grid position (Vector2i) -> building_id (String).
## Tracks which tiles are occupied by buildings.
var grid: Dictionary = {}

## Building registry: building_id (String) -> building_data (Dictionary).
## Stores complete building data including grid position and building properties.
var buildings: Dictionary = {}

## AStar2D pathfinding graph for villager navigation.
## Initialized with all grid tiles as points, connected for 4-directional movement.
var astar: AStar2D = AStar2D.new()

## Point ID mapping: grid position (Vector2i) -> AStar point_id (int).
## Used to convert grid positions to AStar point IDs for pathfinding.
var point_ids: Dictionary = {}

## Pathfinding cache for performance optimization.
## Key: "start_grid,end_grid" (String), Value: Array of world positions (Vector2).
## Caches calculated paths to avoid recalculating the same routes.
var pathfinding_cache: Dictionary = {}

## Maximum number of cached paths before oldest entries are removed (FIFO).
const PATHFINDING_CACHE_SIZE: int = 100

func _ready() -> void:
	print("[CityManager] Initialized")
	initialize_pathfinding()

## Returns the grid dimensions as a Vector2i.
##
## Returns:
##   Vector2i(GRID_WIDTH, GRID_HEIGHT) - The size of the city grid.
func get_grid_size() -> Vector2i:
	return Vector2i(GRID_WIDTH, GRID_HEIGHT)

## Checks if a grid tile is occupied by a building.
##
## Parameters:
##   grid_pos: Grid position to check (Vector2i)
##
## Returns:
##   true if tile is occupied, false if empty.
func is_tile_occupied(grid_pos: Vector2i) -> bool:
	return grid.has(grid_pos)

## Validates if a building can be placed at the given position.
##
## Parameters:
##   grid_pos: Top-left corner grid position for the building (Vector2i)
##   building_size: Size of the building in tiles (Vector2i)
##
## Returns:
##   true if all required tiles are available and within grid bounds, false otherwise.
##
## Checks:
##   - All tiles in building_size area are unoccupied
##   - All tiles are within grid boundaries (0 to GRID_WIDTH/HEIGHT)
func can_place_building(grid_pos: Vector2i, building_size: Vector2i) -> bool:
	# Check if all tiles for this building are available
	for x in range(building_size.x):
		for y in range(building_size.y):
			var check_pos = grid_pos + Vector2i(x, y)
			if is_tile_occupied(check_pos):
				return false
			if check_pos.x < 0 or check_pos.x >= GRID_WIDTH or check_pos.y < 0 or check_pos.y >= GRID_HEIGHT:
				return false
	return true

## Places a building on the grid at the specified position.
##
## Parameters:
##   building_id: Unique identifier for the building (String)
##   grid_pos: Top-left corner grid position (Vector2i)
##   building_data: Dictionary containing building properties including "size" array
##
## Returns:
##   true if building was successfully placed, false if validation failed.
##
## Side Effects:
##   - Marks all tiles in building_size area as occupied
##   - Updates pathfinding graph (disables tiles under building)
##   - Clears pathfinding cache
##   - Stores building data in buildings dictionary
##   - Emits building_placed and grid_updated signals
func place_building(building_id: String, grid_pos: Vector2i, building_data: Dictionary) -> bool:
	# Validate inputs
	if building_id.is_empty():
		push_warning("[CityManager] Empty building ID")
		return false
	
	if not is_valid_grid_position(grid_pos):
		push_warning("[CityManager] Invalid grid position: ", grid_pos)
		return false
	
	if building_data.is_empty():
		push_warning("[CityManager] Empty building data")
		return false
	
	var building_size = Vector2i(
		building_data.get("size", [1, 1])[0],
		building_data.get("size", [1, 1])[1]
	)
	
	if not can_place_building(grid_pos, building_size):
		return false
	
	# Mark tiles as occupied
	for x in range(building_size.x):
		for y in range(building_size.y):
			grid[grid_pos + Vector2i(x, y)] = building_id
	
	# Update pathfinding (disable tiles under building)
	update_pathfinding_for_building(grid_pos, building_size, true)
	
	# Clear pathfinding cache (building placement invalidates cached paths)
	clear_pathfinding_cache()
	
	# Store building data
	var full_building_data = building_data.duplicate()
	full_building_data["grid_position"] = grid_pos
	buildings[building_id] = full_building_data
	
	building_placed.emit(building_id, grid_pos)
	grid_updated.emit()
	return true

## Gets the building ID at a specific grid position.
##
## Parameters:
##   grid_pos: Grid position to check (Vector2i)
##
## Returns:
##   building_id (String) if tile is occupied, empty string if empty or invalid position.
func get_building_at(grid_pos: Vector2i) -> String:
	# Validate input
	if not is_valid_grid_position(grid_pos):
		return ""
	
	return grid.get(grid_pos, "")

## Retrieves building data for a given building ID.
##
## Parameters:
##   building_id: Unique identifier for the building (String)
##
## Returns:
##   Dictionary containing building data including grid_position, or empty dictionary if not found.
func get_building_data(building_id: String) -> Dictionary:
	# Validate input
	if building_id.is_empty():
		push_warning("[CityManager] Empty building ID")
		return {}
	
	return buildings.get(building_id, {})

func remove_building(building_id: String) -> bool:
	# Validate input
	if building_id.is_empty():
		push_warning("[CityManager] Empty building ID")
		return false
	
	if not buildings.has(building_id):
		return false
	
	var building_data = buildings[building_id]
	var grid_pos = building_data.get("grid_position", Vector2i.ZERO)
	var building_size = Vector2i(
		building_data.get("size", [1, 1])[0],
		building_data.get("size", [1, 1])[1]
	)
	
	# Remove from grid
	for x in range(building_size.x):
		for y in range(building_size.y):
			var tile_pos = grid_pos + Vector2i(x, y)
			grid.erase(tile_pos)
	
	# Update pathfinding (re-enable tiles)
	update_pathfinding_for_building(grid_pos, building_size, false)
	
	# Clear pathfinding cache (building removal invalidates cached paths)
	clear_pathfinding_cache()
	
	# Remove from buildings dictionary
	buildings.erase(building_id)
	
	building_removed.emit(building_id, grid_pos)
	grid_updated.emit()
	return true

## Converts world position (pixels) to grid position (tiles).
##
## Parameters:
##   world_pos: World position in pixels (Vector2)
##
## Returns:
##   Grid position as Vector2i (tile coordinates).
##
## Note: Uses integer division to convert pixel coordinates to tile coordinates.
func world_to_grid(world_pos: Vector2) -> Vector2i:
	return Vector2i(
		int(world_pos.x / TILE_SIZE),
		int(world_pos.y / TILE_SIZE)
	)

## Converts grid position (tiles) to world position (pixels).
##
## Parameters:
##   grid_pos: Grid position in tiles (Vector2i)
##
## Returns:
##   World position as Vector2 (center of tile in pixels).
##
## Note: Returns the center point of the tile for accurate positioning.
func grid_to_world(grid_pos: Vector2i) -> Vector2:
	return Vector2(
		grid_pos.x * TILE_SIZE + TILE_SIZE / 2.0,
		grid_pos.y * TILE_SIZE + TILE_SIZE / 2.0
	)

# ==================== Pathfinding System ====================

## Initializes the AStar2D pathfinding system.
##
## Creates pathfinding points for all grid tiles and connects them for 4-directional movement
## (up, down, left, right). Called automatically during _ready().
##
## Side Effects:
##   - Populates astar with all grid points
##   - Populates point_ids mapping
##   - Connects adjacent tiles bidirectionally
func initialize_pathfinding() -> void:
	# Initialize AStar2D grid for pathfinding
	# Create points for all grid tiles
	for x in range(GRID_WIDTH):
		for y in range(GRID_HEIGHT):
			var grid_pos = Vector2i(x, y)
			var point_id = get_point_id(grid_pos)
			astar.add_point(point_id, Vector2(x, y))
			point_ids[grid_pos] = point_id
	
	# Connect adjacent points (4-directional movement: up, down, left, right)
	for x in range(GRID_WIDTH):
		for y in range(GRID_HEIGHT):
			var point_id = get_point_id(Vector2i(x, y))
			
			# Connect to adjacent tiles
			var neighbors = [
				Vector2i(x + 1, y),  # Right
				Vector2i(x - 1, y),  # Left
				Vector2i(x, y + 1),  # Down
				Vector2i(x, y - 1)   # Up
			]
			
			for neighbor_pos in neighbors:
				if is_valid_grid_position(neighbor_pos):
					var neighbor_id = get_point_id(neighbor_pos)
					if not astar.are_points_connected(point_id, neighbor_id):
						astar.connect_points(point_id, neighbor_id, false)  # Bidirectional
	
	print("[CityManager] Pathfinding system initialized (", GRID_WIDTH * GRID_HEIGHT, " points)")

## Converts a grid position to a unique AStar point ID.
##
## Parameters:
##   grid_pos: Grid position (Vector2i)
##
## Returns:
##   Unique integer point ID calculated as: y * GRID_WIDTH + x
func get_point_id(grid_pos: Vector2i) -> int:
	# Convert grid position to unique point ID
	# Using a simple hash: y * width + x
	return grid_pos.y * GRID_WIDTH + grid_pos.x

## Validates if a grid position is within bounds.
##
## Parameters:
##   grid_pos: Grid position to validate (Vector2i)
##
## Returns:
##   true if position is within grid bounds (0 to GRID_WIDTH/HEIGHT), false otherwise.
func is_valid_grid_position(grid_pos: Vector2i) -> bool:
	return grid_pos.x >= 0 and grid_pos.x < GRID_WIDTH and grid_pos.y >= 0 and grid_pos.y < GRID_HEIGHT

## Clears the pathfinding cache.
##
## Called automatically when grid changes (building placed/removed) to invalidate cached paths.
## Ensures pathfinding results remain accurate after grid modifications.
func clear_pathfinding_cache() -> void:
	"""Clear pathfinding cache (called when grid changes)"""
	pathfinding_cache.clear()

func update_pathfinding_for_building(grid_pos: Vector2i, building_size: Vector2i, is_occupied: bool) -> void:
	# Update pathfinding graph when a building is placed or removed
	# Mark tiles as solid (non-walkable) when building is placed
	for x in range(building_size.x):
		for y in range(building_size.y):
			var tile_pos = grid_pos + Vector2i(x, y)
			if not is_valid_grid_position(tile_pos):
				continue
			
			var _point_id = get_point_id(tile_pos)
			
			if is_occupied:
				# Remove point from AStar (or disable it)
				# We'll disable by removing connections instead of removing the point
				disable_pathfinding_point(tile_pos)
			else:
				# Re-enable point
				enable_pathfinding_point(tile_pos)

func disable_pathfinding_point(grid_pos: Vector2i) -> void:
	# Disable a point by removing all its connections
	var point_id = get_point_id(grid_pos)
	var neighbors = [
		Vector2i(grid_pos.x + 1, grid_pos.y),
		Vector2i(grid_pos.x - 1, grid_pos.y),
		Vector2i(grid_pos.x, grid_pos.y + 1),
		Vector2i(grid_pos.x, grid_pos.y - 1)
	]
	
	for neighbor_pos in neighbors:
		if is_valid_grid_position(neighbor_pos):
			var neighbor_id = get_point_id(neighbor_pos)
			if astar.are_points_connected(point_id, neighbor_id):
				astar.disconnect_points(point_id, neighbor_id)

func enable_pathfinding_point(grid_pos: Vector2i) -> void:
	# Re-enable a point by reconnecting to valid neighbors
	var point_id = get_point_id(grid_pos)
	var neighbors = [
		Vector2i(grid_pos.x + 1, grid_pos.y),
		Vector2i(grid_pos.x - 1, grid_pos.y),
		Vector2i(grid_pos.x, grid_pos.y + 1),
		Vector2i(grid_pos.x, grid_pos.y - 1)
	]
	
	for neighbor_pos in neighbors:
		if is_valid_grid_position(neighbor_pos):
			# Only connect if neighbor is not occupied
			if not is_tile_occupied(neighbor_pos):
				var neighbor_id = get_point_id(neighbor_pos)
				if not astar.are_points_connected(point_id, neighbor_id):
					astar.connect_points(point_id, neighbor_id, false)

## Calculates a navigation path from start to end grid positions.
##
## Parameters:
##   start_grid: Starting grid position (Vector2i)
##   end_grid: Destination grid position (Vector2i)
##
## Returns:
##   Array of world positions (Vector2) representing the path, or empty array if no path exists.
##
## Features:
##   - Uses pathfinding cache for performance (checks cache before calculating)
##   - Converts grid positions to world positions (center of tiles)
##   - Implements FIFO cache eviction when cache size limit reached
##   - Returns empty array for invalid positions or unreachable destinations
##
## Note: Cached paths are invalidated when buildings are placed/removed.
func get_navigation_path(start_grid: Vector2i, end_grid: Vector2i) -> Array[Vector2]:
	# Get path from start to end grid positions
	# Returns array of world positions (Vector2)
	# Uses caching for performance optimization

	if not is_valid_grid_position(start_grid) or not is_valid_grid_position(end_grid):
		return []

	# Performance monitoring
	if PerformanceMonitor:
		PerformanceMonitor.start_benchmark("pathfinding")
	
	# Check cache first (performance optimization)
	var cache_key = str(start_grid) + "," + str(end_grid)
	if pathfinding_cache.has(cache_key):
		return pathfinding_cache[cache_key].duplicate()
	
	var start_id = get_point_id(start_grid)
	var end_id = get_point_id(end_grid)
	
	# Check if points exist in AStar
	if not astar.has_point(start_id) or not astar.has_point(end_id):
		return []
	
	# Get path as grid positions
	var path_points = astar.get_point_path(start_id, end_id)
	
	if path_points.is_empty():
		return []
	
	# Convert grid positions to world positions
	var world_path: Array[Vector2] = []
	for point in path_points:
		var grid_pos = Vector2i(int(point.x), int(point.y))
		var world_pos = grid_to_world(grid_pos)
		world_path.append(world_pos)
	
	# Cache the result (performance optimization)
	if pathfinding_cache.size() >= PATHFINDING_CACHE_SIZE:
		# Remove oldest entry (simple FIFO - remove first key)
		var first_key = pathfinding_cache.keys()[0]
		pathfinding_cache.erase(first_key)
	
	pathfinding_cache[cache_key] = world_path.duplicate()

	# Performance monitoring
	if PerformanceMonitor:
		PerformanceMonitor.end_benchmark("pathfinding")

	return world_path

func get_path_simple(start_grid: Vector2i, end_grid: Vector2i) -> Array:
	# Simplified version that returns grid positions (for debugging or direct use)
	if not is_valid_grid_position(start_grid) or not is_valid_grid_position(end_grid):
		return []
	
	var start_id = get_point_id(start_grid)
	var end_id = get_point_id(end_grid)
	
	if not astar.has_point(start_id) or not astar.has_point(end_id):
		return []
	
	var path_points = astar.get_point_path(start_id, end_id)
	
	var grid_path: Array = []
	for point in path_points:
		grid_path.append(Vector2i(int(point.x), int(point.y)))
	
	return grid_path
