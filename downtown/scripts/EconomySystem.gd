extends Node

## EconomySystem - Unified economic management system
##
## Consolidates ResourceManager, JobSystem, and economic building functionality
## into a single, cohesive economic management system.
##
## Key Features:
## - Resource tracking and transactions
## - Production and consumption systems
## - Job assignment and worker management
## - Economic building effects
##
## Usage:
##   var economy = EconomySystem.new()
##   economy.add_resource("wood", 50)
##   economy.assign_worker("villager_1", "lumber_hut_1")

# class_name EconomySystem  # Removed to avoid autoload conflict

# Emitted when a resource amount changes
signal resource_changed(resource_id: String, amount: float, new_total: float)

# Emitted when a villager is assigned to a job
signal villager_job_assigned(villager_id: String, building_id: String, job_type: String)

# Emitted when a villager is unassigned from a job
signal villager_job_unassigned(villager_id: String)

# Resource storage: resource_id -> current_amount
var resources: Dictionary = {}

# Resource metadata: resource_id -> resource_data
var resource_metadata: Dictionary = {}

# Job assignments: villager_id -> {building_id, job_type}
var job_assignments: Dictionary = {}

# Building workers: building_id -> Array[villager_ids]
var building_workers: Dictionary = {}

# Production/consumption timers
var resource_timer: Timer

func _ready() -> void:
	print("[EconomySystem] Initializing economic management system")
	load_resource_definitions()
	initialize_resource_timer()

func load_resource_definitions() -> void:
	"""Load resource definitions from DataManager"""
	var data_manager = get_node_or_null("/root/DataManager")
	if not data_manager:
		push_error("[EconomySystem] DataManager not found!")
		return

	var resources_data = data_manager.get_data("resources")
	if not resources_data:
		push_error("[EconomySystem] Resources data not loaded!")
		return

	var resource_list = resources_data.get("resources", {})
	for resource_id in resource_list:
		var resource_data = resource_list[resource_id]
		resource_metadata[resource_id] = resource_data
		resources[resource_id] = resource_data.get("starting_amount", 0.0)

	print("[EconomySystem] Loaded ", resource_metadata.size(), " resource types")

func initialize_resource_timer() -> void:
	"""Initialize the resource production/consumption timer"""
	resource_timer = Timer.new()
	resource_timer.wait_time = 1.0  # 1 second = 1 game minute
	resource_timer.timeout.connect(_on_resource_tick)
	add_child(resource_timer)
	resource_timer.start()

func _on_resource_tick() -> void:
	"""Process resource production and consumption"""
	process_building_production()

func process_building_production() -> void:
	"""Process production and consumption for all buildings"""
	# This will be implemented when we integrate with GameWorld
	# For now, it's a placeholder
	pass

func get_resource(resource_id: String) -> float:
	"""Get current amount of a resource"""
	return resources.get(resource_id, 0.0)

func set_resource(resource_id: String, amount: float) -> void:
	"""Set the amount of a resource"""
	var old_amount = resources.get(resource_id, 0.0)
	resources[resource_id] = amount
	resource_changed.emit(resource_id, amount - old_amount, amount)

func add_resource(resource_id: String, amount: float) -> void:
	"""Add to a resource amount"""
	var current = get_resource(resource_id)
	set_resource(resource_id, current + amount)

func consume_resource(resource_id: String, amount: float) -> bool:
	"""Consume a resource if sufficient amount is available"""
	var current = get_resource(resource_id)
	if current >= amount:
		set_resource(resource_id, current - amount)
		return true
	return false

func can_afford(costs: Dictionary) -> bool:
	"""Check if all required resources are available"""
	for resource_id in costs:
		var required = costs[resource_id]
		var available = get_resource(resource_id)
		if available < required:
			return false
	return true

func pay_costs(costs: Dictionary) -> bool:
	"""Pay the costs if affordable"""
	if not can_afford(costs):
		return false

	for resource_id in costs:
		var amount = costs[resource_id]
		consume_resource(resource_id, amount)

	return true

func get_storage_capacity(resource_id: String) -> float:
	"""Get storage capacity for a resource"""
	var metadata = resource_metadata.get(resource_id, {})
	return metadata.get("max_storage", 100.0)

func assign_worker(villager_id: String, building_id: String, job_type: String) -> bool:
	"""Assign a villager to work at a building"""
	# Check if villager is already assigned
	if job_assignments.has(villager_id):
		unassign_worker(villager_id)

	# Check building capacity
	var current_workers = building_workers.get(building_id, []).size()
	var max_workers = get_building_worker_capacity(building_id)
	if current_workers >= max_workers:
		return false

	# Assign the job
	job_assignments[villager_id] = {
		"building_id": building_id,
		"job_type": job_type
	}

	# Add to building worker list
	if not building_workers.has(building_id):
		building_workers[building_id] = []
	building_workers[building_id].append(villager_id)

	villager_job_assigned.emit(villager_id, building_id, job_type)
	print("[EconomySystem] Assigned ", villager_id, " to ", building_id, " as ", job_type)

	return true

func unassign_worker(villager_id: String) -> bool:
	"""Unassign a villager from their job"""
	if not job_assignments.has(villager_id):
		return false

	var assignment = job_assignments[villager_id]
	var building_id = assignment.building_id

	# Remove from job assignments
	job_assignments.erase(villager_id)

	# Remove from building worker list
	if building_workers.has(building_id):
		building_workers[building_id].erase(villager_id)
		if building_workers[building_id].is_empty():
			building_workers.erase(building_id)

	villager_job_unassigned.emit(villager_id)
	print("[EconomySystem] Unassigned ", villager_id, " from job")

	return true

func get_villager_job(villager_id: String) -> Dictionary:
	"""Get job assignment for a villager"""
	return job_assignments.get(villager_id, {})

func get_building_workers(building_id: String) -> Array:
	"""Get list of workers assigned to a building"""
	return building_workers.get(building_id, []).duplicate()

func get_building_worker_capacity(building_id: String) -> int:
	"""Get worker capacity for a building"""
	# This will need to query GameWorld for building data
	# For now, return a default
	var game_world = get_node_or_null("/root/GameWorld")
	if game_world:
		return game_world.get_worker_capacity(building_id)
	return 1  # Default

func get_all_resources() -> Dictionary:
	"""Get all resources and their current amounts"""
	return resources.duplicate()

func get_resource_metadata(resource_id: String) -> Dictionary:
	"""Get metadata for a specific resource"""
	return resource_metadata.get(resource_id, {})