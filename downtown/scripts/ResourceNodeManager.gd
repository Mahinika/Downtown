extends Node

## ResourceNodeManager - Manages resource nodes (trees, rocks, etc.) on the map
##
## Singleton Autoload that handles resource node placement, harvesting, and reservation system.
## Manages natural resources that villagers can harvest, including trees, stone deposits, and berry bushes.
## Implements a reservation system to prevent multiple villagers from harvesting the same node simultaneously.
##
## Key Features:
## - Resource node placement and tracking
## - Harvesting system with depletion tracking
## - Node reservation system for villager coordination
## - Resource type mapping and validation
## - Performance optimization through position-based lookups
##
## Usage:
##   var node_id = ResourceNodeManager.place_resource_node(ResourceNodeManager.ResourceNodeType.TREE, grid_pos)
##   ResourceNodeManager.reserve_node(node_id, villager_id)

## Emitted when a resource node is placed on the map.
## Parameters: node_id (String), position (Vector2i), resource_type (String)
signal resource_node_placed(node_id: String, position: Vector2i, resource_type: String)

## Emitted when a resource node is harvested.
## Parameters: node_id (String), resource_type (String), amount (float)
signal resource_node_harvested(node_id: String, resource_type: String, amount: float)

## Emitted when a resource node is completely depleted.
## Parameters: node_id (String)
signal resource_node_depleted(node_id: String)

## Registry of all resource nodes: node_id (String) -> node_data (Dictionary).
## Contains complete node information including position, type, and remaining resources.
var resource_nodes: Dictionary = {}

## Counter for generating unique node IDs.
var node_counter: int = 0

## Type-based node lookup: resource_type (String) -> Array of node_ids (String).
## Groups nodes by their resource type for efficient searching.
var nodes_by_type: Dictionary = {}

## Position-based node lookup: grid_position (Vector2i) -> node_id (String).
## Maps grid positions to node IDs for collision detection and lookups.
var nodes_by_position: Dictionary = {}

## Node reservation system: node_id (String) -> villager_id (String).
## Prevents multiple villagers from harvesting the same node simultaneously.
var reserved_nodes: Dictionary = {}

# Default resource amounts per node type (constants)
const DEFAULT_TREE_RESOURCE: float = 10.0  # Wood per tree
const DEFAULT_STONE_RESOURCE: float = 15.0  # Stone per rock
const DEFAULT_BERRY_BUSH_RESOURCE: float = 5.0  # Food per bush
const DEFAULT_MAX_SEARCH_DISTANCE: float = 500.0  # Max distance for node search

# Logging throttling constants
const RESERVATION_LOG_CHANCE: float = 0.1  # 10% chance to log reservations
const RELEASE_LOG_CHANCE: float = 0.1  # 10% chance to log releases

enum ResourceNodeType {
	TREE,  # Wood resource
	STONE,  # Stone resource
	BERRY_BUSH  # Food resource (future)
}

func _ready() -> void:
	print("[ResourceNodeManager] Initialized")

func place_resource_node(node_type: ResourceNodeType, grid_position: Vector2i, resource_amount: float = -1.0) -> String:
	# Create unique node ID
	var node_id = "node_" + str(node_counter)
	node_counter += 1
	
	# Get default resource amount if not specified
	if resource_amount < 0:
		match node_type:
			ResourceNodeType.TREE:
				resource_amount = DEFAULT_TREE_RESOURCE
			ResourceNodeType.STONE:
				resource_amount = DEFAULT_STONE_RESOURCE
			ResourceNodeType.BERRY_BUSH:
				resource_amount = DEFAULT_BERRY_BUSH_RESOURCE
			_:
				resource_amount = DEFAULT_TREE_RESOURCE
	
	# Check if position is already occupied
	if nodes_by_position.has(grid_position):
		push_warning("[ResourceNodeManager] Position already occupied: ", grid_position)
		return ""
	
	# Create node data
	var node_type_name = ResourceNodeType.keys()[node_type]
	var node_data = {
		"id": node_id,
		"type": node_type,
		"type_name": node_type_name,
		"grid_position": grid_position,
		"resource_type": get_resource_type_for_node(node_type),
		"resource_amount": resource_amount,
		"remaining_amount": resource_amount,
		"depleted": false
	}
	
	# Store node
	resource_nodes[node_id] = node_data
	nodes_by_position[grid_position] = node_id
	
	# Track by type
	if not nodes_by_type.has(node_type_name):
		nodes_by_type[node_type_name] = []
	nodes_by_type[node_type_name].append(node_id)
	
	resource_node_placed.emit(node_id, grid_position, node_type_name)
	print("[ResourceNodeManager] Placed ", node_type_name, " at ", grid_position, " (ID: ", node_id, ")")
	
	return node_id

func get_resource_type_for_node(node_type: ResourceNodeType) -> String:
	match node_type:
		ResourceNodeType.TREE:
			return "wood"
		ResourceNodeType.STONE:
			return "stone"
		ResourceNodeType.BERRY_BUSH:
			return "food"
		_:
			return ""

func harvest_resource(node_id: String, amount: float) -> float:
	# Validate inputs
	if node_id.is_empty():
		push_warning("[ResourceNodeManager] Empty node ID")
		return 0.0
	
	if amount < 0.0:
		push_warning("[ResourceNodeManager] Negative harvest amount: ", amount)
		return 0.0
	
	if not resource_nodes.has(node_id):
		push_warning("[ResourceNodeManager] Unknown resource node: ", node_id)
		return 0.0
	
	var node_data = resource_nodes[node_id]
	
	if node_data.get("depleted", false):
		return 0.0
	
	var remaining = node_data.get("remaining_amount", 0.0)
	var harvested = min(amount, remaining)
	
	node_data["remaining_amount"] = remaining - harvested
	
	# Check if depleted
	if node_data["remaining_amount"] <= 0.0:
		node_data["depleted"] = true
		node_data["remaining_amount"] = 0.0
		resource_node_depleted.emit(node_id)
	
	var resource_type = node_data.get("resource_type", "")
	resource_node_harvested.emit(node_id, resource_type, harvested)
	
	print("[ResourceNodeManager] Harvested ", harvested, " ", resource_type, " from ", node_id)
	
	return harvested

func get_node_at(grid_position: Vector2i) -> String:
	# Validate input (using CityManager's validation if available)
	if not CityManager or not CityManager.is_valid_grid_position(grid_position):
		return ""
	
	return nodes_by_position.get(grid_position, "")

func get_node_data(node_id: String) -> Dictionary:
	# Validate input
	if node_id.is_empty():
		push_warning("[ResourceNodeManager] Empty node ID")
		return {}
	
	return resource_nodes.get(node_id, {}).duplicate()

func reset_node(node_id: String) -> bool:
	# Validate input
	if node_id.is_empty():
		push_warning("[ResourceNodeManager] Empty node ID")
		return false
	
	# Reset a depleted node for respawning
	if not resource_nodes.has(node_id):
		return false
	
	var node_data = resource_nodes[node_id]
	var original_amount = node_data.get("original_amount", 10.0)
	
	# Reset node data
	node_data["remaining_amount"] = original_amount
	node_data["depleted"] = false
	
	# Release any reservations
	if reserved_nodes.has(node_id):
		reserved_nodes.erase(node_id)
	
	return true

func get_available_nodes_of_type(node_type: ResourceNodeType) -> Array:
	var node_type_name = ResourceNodeType.keys()[node_type]
	var node_ids = nodes_by_type.get(node_type_name, [])
	var available = []
	
	for node_id in node_ids:
		var node_data = resource_nodes.get(node_id, {})
		if not node_data.get("depleted", false):
			available.append(node_id)
	
	return available

func get_nearest_available_node(position: Vector2, node_type: ResourceNodeType, max_distance: float = DEFAULT_MAX_SEARCH_DISTANCE, exclude_reserved: bool = true) -> String:
	var available_nodes = get_available_nodes_of_type(node_type)
	var nearest_id: String = ""
	var nearest_distance_sq: float = max_distance * max_distance  # Use squared distance for performance
	
	for node_id in available_nodes:
		# Skip reserved nodes if exclude_reserved is true
		if exclude_reserved and reserved_nodes.has(node_id):
			continue
		
		var node_data = resource_nodes.get(node_id, {})
		var grid_pos = node_data.get("grid_position", Vector2i.ZERO)
		var world_pos = CityManager.grid_to_world(grid_pos)
		# Use distance_squared for performance (avoid sqrt calculation)
		var distance_sq = position.distance_squared_to(world_pos)
		
		if distance_sq < nearest_distance_sq:
			nearest_distance_sq = distance_sq
			nearest_id = node_id
	
	return nearest_id

func reserve_node(node_id: String, villager_id: String) -> bool:
	# Validate inputs
	if node_id.is_empty():
		push_warning("[ResourceNodeManager] Empty node ID")
		return false
	
	if villager_id.is_empty():
		push_warning("[ResourceNodeManager] Empty villager ID")
		return false
	
	if not resource_nodes.has(node_id):
		return false
	
	# Check if already reserved by another villager
	if reserved_nodes.has(node_id):
		var reserving_villager = reserved_nodes[node_id]
		if reserving_villager != villager_id:
			return false  # Already reserved by someone else
	
	reserved_nodes[node_id] = villager_id
	# Throttle logging to avoid spam
	if randf() < RESERVATION_LOG_CHANCE:  # Only log 10% of reservations
		print("[ResourceNodeManager] Node ", node_id, " reserved by villager ", villager_id)
	return true

func release_node(node_id: String, villager_id: String = "") -> void:
	if not reserved_nodes.has(node_id):
		return
	
	# If villager_id specified, only release if it matches
	if villager_id != "":
		if reserved_nodes[node_id] != villager_id:
			return  # Reserved by different villager
	
	reserved_nodes.erase(node_id)
	# Throttle logging to avoid spam
	if randf() < RELEASE_LOG_CHANCE:  # Only log 10% of releases
		print("[ResourceNodeManager] Node ", node_id, " released")

func is_node_reserved(node_id: String) -> bool:
	return reserved_nodes.has(node_id)

func get_reserving_villager(node_id: String) -> String:
	return reserved_nodes.get(node_id, "")

func remove_node(node_id: String) -> bool:
	# Validate input
	if node_id.is_empty():
		push_warning("[ResourceNodeManager] Empty node ID")
		return false
	
	if not resource_nodes.has(node_id):
		return false
	
	var node_data = resource_nodes[node_id]
	var grid_pos = node_data.get("grid_position", Vector2i.ZERO)
	var node_type_name = node_data.get("type_name", "")
	
	# Remove from tracking dictionaries
	nodes_by_position.erase(grid_pos)
	
	if nodes_by_type.has(node_type_name):
		var type_array = nodes_by_type[node_type_name]
		type_array.erase(node_id)
	
	# Release reservation if any
	if reserved_nodes.has(node_id):
		reserved_nodes.erase(node_id)
	
	resource_nodes.erase(node_id)
	print("[ResourceNodeManager] Removed node: ", node_id)
	
	return true
