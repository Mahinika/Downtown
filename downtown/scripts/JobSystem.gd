extends Node

## JobSystem - Manages job assignments and work task queues for villagers
##
## Singleton Autoload that handles villager job assignment, work cycle creation,
## and task management. Creates detailed work cycles for each job type and manages
## the assignment/unassignment process with capacity constraints.
##
## Key Features:
## - Job assignment with capacity validation
## - Work cycle generation for different job types
## - Task queue management and completion tracking
## - Skill XP granting for completed tasks
## - Performance optimization through caching
##
## Usage:
##   JobSystem.assign_villager_to_building(villager_id, building_id, "lumberjack")
##   var next_task = JobSystem.get_next_task(villager_id)

## Emitted when a villager is assigned to a job at a building.
## Parameters: villager_id (String), building_id (String), job_type (String)
signal job_assigned(villager_id: String, building_id: String, job_type: String)

## Emitted when a villager is unassigned from their job.
## Parameters: villager_id (String)
signal job_unassigned(villager_id: String)

## Current job assignments: villager_id (String) -> building_id (String).
## Maps villagers to their assigned workplaces.
var job_assignments: Dictionary = {}

## Building worker tracking: building_id (String) -> Array of villager_ids (String).
## Tracks which villagers are working at each building.
var building_workers: Dictionary = {}

## Active work tasks: villager_id (String) -> Array of task dictionaries.
## Current task queues for each villager.
var work_tasks: Dictionary = {}

## Work cycle cache: villager_id (String) -> cached work cycle array.
## Performance optimization to avoid regenerating work cycles.
var work_cycles_cache: Dictionary = {}

## Building capacity cache: building_id (String) -> max workers (int).
## Cached worker capacities for performance.
var building_capacities: Dictionary = {}

# Logging throttling constants
const CYCLE_CREATION_LOG_CHANCE: float = 0.05  # 5% chance to log cycle creations
const TASK_COMPLETION_LOG_CHANCE: float = 0.05  # 5% chance to log task completions
const CYCLE_COMPLETION_LOG_CHANCE: float = 0.1  # 10% chance to log cycle completions
const EMPTY_CYCLE_LOG_CHANCE: float = 0.01  # 1% chance to log empty cycles

enum TaskType {
	MOVE_TO,
	HARVEST_RESOURCE,
	DEPOSIT_RESOURCE,
	RETURN_TO_WORKPLACE
}

func _ready() -> void:
	print("[JobSystem] Initialized")

func assign_villager_to_building(villager_id: String, building_id: String, job_type: String) -> bool:
	# Validate inputs
	if villager_id.is_empty():
		push_warning("[JobSystem] Empty villager ID")
		return false
	
	if building_id.is_empty():
		push_warning("[JobSystem] Empty building ID")
		return false
	
	if job_type.is_empty():
		push_warning("[JobSystem] Empty job type")
		return false
	
	var world = GameServices.get_world()
	if not world:
		return false

	var villager = world.get_villager(villager_id)
	if not villager or not is_instance_valid(villager):
		push_warning("[JobSystem] Invalid villager: ", villager_id)
		var debug_bridge = GameServices.get_debug_bridge()
		if debug_bridge:
			debug_bridge.dump_error("Invalid villager in job assignment", {
				"villager_id": villager_id,
				"building_id": building_id,
				"job_type": job_type,
				"world_villager_count": world.get_villager_count() if world else 0
			})
		return false
	
	# Check if villager already has a job
	if job_assignments.has(villager_id):
		unassign_villager(villager_id)
	
	# Get building data
	var building = BuildingManager.get_building(building_id)
	if not building:
		push_warning("[JobSystem] Invalid building: ", building_id)
		return false
	
	# Check workplace capacity
	var current_workers = building_workers.get(building_id, []).size()
	var max_workers = get_building_capacity(building_id)
	
	if current_workers >= max_workers:
		push_warning("[JobSystem] Building ", building_id, " is at capacity (", current_workers, "/", max_workers, ")")
		var debug_bridge = GameServices.get_debug_bridge()
		if debug_bridge:
			debug_bridge.dump_error("Building at capacity", {
				"building_id": building_id,
			"current_workers": current_workers,
			"max_workers": max_workers,
			"building_type": building.get("type", "unknown") if building else "null"
		})
		return false
	
	# Assign job
	job_assignments[villager_id] = building_id
	
	# Track building workers
	if not building_workers.has(building_id):
		building_workers[building_id] = []
	if villager_id not in building_workers[building_id]:
		building_workers[building_id].append(villager_id)
	
	# Invalidate work cycle cache for this villager
	if work_cycles_cache.has(villager_id):
		work_cycles_cache.erase(villager_id)
	
	# Assign job type to villager
	# Map job type string to GameWorld.JobType enum
	var job_type_enum = -1
	match job_type.to_lower():
		"lumberjack":
			job_type_enum = GameWorld.JobType.LUMBERJACK
		"miner":
			job_type_enum = GameWorld.JobType.MINER
		"farmer":
			job_type_enum = GameWorld.JobType.FARMER
		"engineer":
			job_type_enum = GameWorld.JobType.ENGINEER
		"miller":
			job_type_enum = GameWorld.JobType.MILLER
		"smoker":
			job_type_enum = GameWorld.JobType.SMOKER
		"brewer":
			job_type_enum = GameWorld.JobType.BREWER
		"blacksmith":
			job_type_enum = GameWorld.JobType.BLACKSMITH
	
	if villager.has_method("assign_job") and job_type_enum != -1:
		villager.assign_job(job_type_enum)
	
	job_assigned.emit(villager_id, building_id, job_type)
	print("[JobSystem] Assigned villager ", villager_id, " to building ", building_id, " (job: ", job_type, ", workers: ", current_workers + 1, "/", max_workers, ")")
	
	return true

func get_building_capacity(building_id: String) -> int:
	# Use BuildingManager's capacity system if available
	if BuildingManager and BuildingManager.has_method("get_worker_capacity"):
		return BuildingManager.get_worker_capacity(building_id)
	
	# Fallback: Check cache first
	if building_capacities.has(building_id):
		return building_capacities[building_id]
	
	# Get from building data or use default
	var building = BuildingManager.get_building(building_id)
	if not building:
		return 1  # Default capacity
	
	var building_data = building.get("building_data", {})
	# Try new field name first, fallback to old field name for compatibility
	var capacity = building_data.get("worker_capacity", building_data.get("max_workers", 1))
	
	# Cache it
	building_capacities[building_id] = capacity
	return capacity

func unassign_villager(villager_id: String) -> bool:
	# Validate input
	if villager_id.is_empty():
		push_warning("[JobSystem] Empty villager ID")
		return false
	
	if not job_assignments.has(villager_id):
		return false
	
	var building_id = job_assignments[villager_id]
	job_assignments.erase(villager_id)
	
	# Remove from building workers
	if building_workers.has(building_id):
		building_workers[building_id].erase(villager_id)
		if building_workers[building_id].is_empty():
			building_workers.erase(building_id)
	
	# Clear work tasks and cache
	if work_tasks.has(villager_id):
		work_tasks.erase(villager_id)
	if work_cycles_cache.has(villager_id):
		work_cycles_cache.erase(villager_id)
	
	job_unassigned.emit(villager_id)
	print("[JobSystem] Unassigned villager: ", villager_id)
	
	return true

func get_villager_job(villager_id: String) -> String:
	# Validate input
	if villager_id.is_empty():
		push_warning("[JobSystem] Empty villager ID")
		return ""
	
	if not job_assignments.has(villager_id):
		return ""
	
	var building_id = job_assignments[villager_id]
	if building_id.is_empty():
		return ""
	
	if not BuildingManager:
		return ""
	
	var building = BuildingManager.get_building(building_id)
	if not building or building.is_empty():
		return ""
	
	var building_data = building.get("building_data", {})
	var effects = building_data.get("effects", {})
	
	return effects.get("workplace", "")

func get_building_workers(building_id: String) -> Array:
	# Validate input
	if building_id.is_empty():
		push_warning("[JobSystem] Empty building ID")
		return []
	
	return building_workers.get(building_id, []).duplicate()

func assign_lumberjack_job(villager_id: String, lumber_hut_id: String) -> bool:
	return assign_villager_to_building(villager_id, lumber_hut_id, "lumberjack")

func assign_miner_job(villager_id: String, quarry_id: String) -> bool:
	return assign_villager_to_building(villager_id, quarry_id, "miner")

func assign_farmer_job(villager_id: String, farm_id: String) -> bool:
	return assign_villager_to_building(villager_id, farm_id, "farmer")

func assign_engineer_job(villager_id: String, workshop_id: String) -> bool:
	return assign_villager_to_building(villager_id, workshop_id, "engineer")

func assign_miller_job(villager_id: String, mill_id: String) -> bool:
	return assign_villager_to_building(villager_id, mill_id, "miller")

func assign_brewer_job(villager_id: String, brewery_id: String) -> bool:
	return assign_villager_to_building(villager_id, brewery_id, "brewer")

func assign_smoker_job(villager_id: String, smokehouse_id: String) -> bool:
	return assign_villager_to_building(villager_id, smokehouse_id, "smoker")

func assign_blacksmith_job(villager_id: String, blacksmith_id: String) -> bool:
	return assign_villager_to_building(villager_id, blacksmith_id, "blacksmith")

func create_lumberjack_work_cycle(villager_id: String) -> Array:
	# Create a work cycle task list for a lumberjack:
	# 1. Find nearest tree
	# 2. Move to tree
	# 3. Harvest tree (cut down)
	# 4. Move to nearest stockpile
	# 5. Deposit resources
	# 6. Return to lumber hut
	# 7. Repeat

	var tasks: Array = []
	var world = GameServices.get_world()

	if not job_assignments.has(villager_id):
		return tasks
	
	var building_id = job_assignments[villager_id]
	var building = BuildingManager.get_building(building_id)
	if not building:
		return tasks
	
	var villager = world.get_villager(villager_id)
	if not villager or not is_instance_valid(villager):
		return tasks
	
	var _building_data = building.get("building_data", {})
	var grid_pos = building.get("grid_position", Vector2i.ZERO)
	var workplace_pos = CityManager.grid_to_world(grid_pos)
	
	# Task 1: Find and move to nearest tree
	var task_find_tree = {
		"type": TaskType.MOVE_TO,
		"target_type": "tree",
		"description": "Find nearest tree"
	}
	tasks.append(task_find_tree)
	
	# Task 2: Harvest tree
	var task_harvest = {
		"type": TaskType.HARVEST_RESOURCE,
		"resource_type": "wood",
		"amount": 1.0,
		"description": "Cut down tree"
	}
	tasks.append(task_harvest)
	
	# Task 3: Find and move to nearest stockpile
	var task_find_stockpile = {
		"type": TaskType.MOVE_TO,
		"target_type": "stockpile",
		"description": "Find nearest stockpile"
	}
	tasks.append(task_find_stockpile)
	
	# Task 4: Deposit resources
	var task_deposit = {
		"type": TaskType.DEPOSIT_RESOURCE,
		"resource_type": "wood",
		"description": "Deposit wood"
	}
	tasks.append(task_deposit)
	
	# Task 5: Return to workplace
	var task_return = {
		"type": TaskType.RETURN_TO_WORKPLACE,
		"target_position": workplace_pos,
		"description": "Return to lumber hut"
	}
	tasks.append(task_return)
	
	return tasks

func create_miner_work_cycle(villager_id: String) -> Array:
	# Create a work cycle task list for a miner:
	# 1. Find nearest stone node
	# 2. Move to stone
	# 3. Harvest stone
	# 4. Move to nearest stockpile
	# 5. Deposit resources
	# 6. Return to quarry
	# 7. Repeat

	var tasks: Array = []
	var world = GameServices.get_world()

	if not job_assignments.has(villager_id):
		return tasks
	
	var building_id = job_assignments[villager_id]
	var building = BuildingManager.get_building(building_id)
	if not building:
		return tasks
	
	var villager = world.get_villager(villager_id)
	if not villager or not is_instance_valid(villager):
		return tasks
	
	var grid_pos = building.get("grid_position", Vector2i.ZERO)
	var workplace_pos = CityManager.grid_to_world(grid_pos)
	
	# Task 1: Find and move to nearest stone
	var task_find_stone = {
		"type": TaskType.MOVE_TO,
		"target_type": "stone",
		"description": "Find nearest stone"
	}
	tasks.append(task_find_stone)
	
	# Task 2: Harvest stone
	var task_harvest = {
		"type": TaskType.HARVEST_RESOURCE,
		"resource_type": "stone",
		"amount": 1.0,
		"description": "Mine stone"
	}
	tasks.append(task_harvest)
	
	# Task 3: Find and move to nearest stockpile
	var task_find_stockpile = {
		"type": TaskType.MOVE_TO,
		"target_type": "stockpile",
		"description": "Find nearest stockpile"
	}
	tasks.append(task_find_stockpile)
	
	# Task 4: Deposit resources
	var task_deposit = {
		"type": TaskType.DEPOSIT_RESOURCE,
		"resource_type": "stone",
		"description": "Deposit stone"
	}
	tasks.append(task_deposit)
	
	# Task 5: Return to workplace
	var task_return = {
		"type": TaskType.RETURN_TO_WORKPLACE,
		"target_position": workplace_pos,
		"description": "Return to quarry"
	}
	tasks.append(task_return)
	
	return tasks

func create_farmer_work_cycle(villager_id: String) -> Array:
	# Create a work cycle task list for a farmer:
	# 1. Work at farm (produce food)
	# 2. Move to nearest stockpile
	# 3. Deposit food
	# 4. Return to farm
	# 5. Repeat

	var tasks: Array = []
	var world = GameServices.get_world()

	if not job_assignments.has(villager_id):
		return tasks
	
	var building_id = job_assignments[villager_id]
	var building = BuildingManager.get_building(building_id)
	if not building:
		return tasks
	
	var villager = world.get_villager(villager_id)
	if not villager or not is_instance_valid(villager):
		return tasks
	
	var grid_pos = building.get("grid_position", Vector2i.ZERO)
	var workplace_pos = CityManager.grid_to_world(grid_pos)
	
	# Task 1: Work at farm (harvest crops)
	var task_harvest = {
		"type": TaskType.HARVEST_RESOURCE,
		"resource_type": "food",
		"amount": 2.0,
		"description": "Harvest crops"
	}
	tasks.append(task_harvest)
	
	# Task 2: Find and move to nearest stockpile
	var task_find_stockpile = {
		"type": TaskType.MOVE_TO,
		"target_type": "stockpile",
		"description": "Find nearest stockpile"
	}
	tasks.append(task_find_stockpile)
	
	# Task 3: Deposit resources
	var task_deposit = {
		"type": TaskType.DEPOSIT_RESOURCE,
		"resource_type": "food",
		"description": "Deposit food"
	}
	tasks.append(task_deposit)
	
	# Task 4: Return to workplace
	var task_return = {
		"type": TaskType.RETURN_TO_WORKPLACE,
		"target_position": workplace_pos,
		"description": "Return to farm"
	}
	tasks.append(task_return)
	
	return tasks

func create_miller_work_cycle(villager_id: String) -> Array:
	# Create a work cycle task list for a miller:
	# 1. Move to stockpile to check for wheat
	# 2. Move to mill
	# 3. Work at mill (processing happens automatically)
	# 4. Move to stockpile
	# 5. Deposit flour (which was produced by processing)
	# 6. Return to mill
	# 7. Repeat

	var tasks: Array = []
	var world = GameServices.get_world()

	if not job_assignments.has(villager_id):
		return tasks
	
	var building_id = job_assignments[villager_id]
	var building = BuildingManager.get_building(building_id)
	if not building:
		return tasks
	
	var villager = world.get_villager(villager_id)
	if not villager or not is_instance_valid(villager):
		return tasks
	
	var grid_pos = building.get("grid_position", Vector2i.ZERO)
	var workplace_pos = CityManager.grid_to_world(grid_pos)
	
	# Task 1: Move to stockpile to ensure wheat is available
	var task_find_stockpile = {
		"type": TaskType.MOVE_TO,
		"target_type": "stockpile",
		"description": "Check stockpile for wheat"
	}
	tasks.append(task_find_stockpile)
	
	# Task 2: Move to mill
	var task_move_to_mill = {
		"type": TaskType.MOVE_TO,
		"target_position": workplace_pos,
		"description": "Move to mill"
	}
	tasks.append(task_move_to_mill)
	
	# Task 3: Work at mill (processing happens automatically via BuildingManager)
	var task_work = {
		"type": TaskType.HARVEST_RESOURCE,
		"resource_type": "flour",
		"amount": 0.0,  # Processing produces flour automatically
		"description": "Work at mill (processing wheat to flour)"
	}
	tasks.append(task_work)
	
	# Task 4: Move to stockpile to deposit flour
	var task_deposit_stockpile = {
		"type": TaskType.MOVE_TO,
		"target_type": "stockpile",
		"description": "Move to stockpile"
	}
	tasks.append(task_deposit_stockpile)
	
	# Task 5: Deposit flour
	var task_deposit = {
		"type": TaskType.DEPOSIT_RESOURCE,
		"resource_type": "flour",
		"description": "Deposit flour"
	}
	tasks.append(task_deposit)
	
	# Task 6: Return to mill
	var task_return = {
		"type": TaskType.RETURN_TO_WORKPLACE,
		"target_position": workplace_pos,
		"description": "Return to mill"
	}
	tasks.append(task_return)
	
	return tasks

func create_brewer_work_cycle(villager_id: String) -> Array:
	# Create a work cycle task list for a brewer:
	# Similar to miller but processes wheat to beer

	var tasks: Array = []
	var world = GameServices.get_world()

	if not job_assignments.has(villager_id):
		return tasks
	
	var building_id = job_assignments[villager_id]
	var building = BuildingManager.get_building(building_id)
	if not building:
		return tasks
	
	var villager = world.get_villager(villager_id)
	if not villager or not is_instance_valid(villager):
		return tasks
	
	var grid_pos = building.get("grid_position", Vector2i.ZERO)
	var workplace_pos = CityManager.grid_to_world(grid_pos)
	
	# Task 1: Move to stockpile
	var task_find_stockpile = {
		"type": TaskType.MOVE_TO,
		"target_type": "stockpile",
		"description": "Check stockpile for wheat"
	}
	tasks.append(task_find_stockpile)
	
	# Task 2: Move to brewery
	var task_move_to_brewery = {
		"type": TaskType.MOVE_TO,
		"target_position": workplace_pos,
		"description": "Move to brewery"
	}
	tasks.append(task_move_to_brewery)
	
	# Task 3: Work at brewery
	var task_work = {
		"type": TaskType.HARVEST_RESOURCE,
		"resource_type": "beer",
		"amount": 0.0,
		"description": "Work at brewery (brewing beer)"
	}
	tasks.append(task_work)
	
	# Task 4: Move to stockpile
	var task_deposit_stockpile = {
		"type": TaskType.MOVE_TO,
		"target_type": "stockpile",
		"description": "Move to stockpile"
	}
	tasks.append(task_deposit_stockpile)
	
	# Task 5: Deposit beer
	var task_deposit = {
		"type": TaskType.DEPOSIT_RESOURCE,
		"resource_type": "beer",
		"description": "Deposit beer"
	}
	tasks.append(task_deposit)
	
	# Task 6: Return to brewery
	var task_return = {
		"type": TaskType.RETURN_TO_WORKPLACE,
		"target_position": workplace_pos,
		"description": "Return to brewery"
	}
	tasks.append(task_return)
	
	return tasks

func create_smoker_work_cycle(villager_id: String) -> Array:
	# Create a work cycle task list for a smoker:
	# Processes food to preserved_food

	var tasks: Array = []
	var world = GameServices.get_world()

	if not job_assignments.has(villager_id):
		return tasks
	
	var building_id = job_assignments[villager_id]
	var building = BuildingManager.get_building(building_id)
	if not building:
		return tasks
	
	var villager = world.get_villager(villager_id)
	if not villager or not is_instance_valid(villager):
		return tasks
	
	var grid_pos = building.get("grid_position", Vector2i.ZERO)
	var workplace_pos = CityManager.grid_to_world(grid_pos)
	
	# Task 1: Move to stockpile
	var task_find_stockpile = {
		"type": TaskType.MOVE_TO,
		"target_type": "stockpile",
		"description": "Check stockpile for food"
	}
	tasks.append(task_find_stockpile)
	
	# Task 2: Move to smokehouse
	var task_move_to_smokehouse = {
		"type": TaskType.MOVE_TO,
		"target_position": workplace_pos,
		"description": "Move to smokehouse"
	}
	tasks.append(task_move_to_smokehouse)
	
	# Task 3: Work at smokehouse
	var task_work = {
		"type": TaskType.HARVEST_RESOURCE,
		"resource_type": "preserved_food",
		"amount": 0.0,
		"description": "Work at smokehouse (preserving food)"
	}
	tasks.append(task_work)
	
	# Task 4: Move to stockpile
	var task_deposit_stockpile = {
		"type": TaskType.MOVE_TO,
		"target_type": "stockpile",
		"description": "Move to stockpile"
	}
	tasks.append(task_deposit_stockpile)
	
	# Task 5: Deposit preserved_food
	var task_deposit = {
		"type": TaskType.DEPOSIT_RESOURCE,
		"resource_type": "preserved_food",
		"description": "Deposit preserved food"
	}
	tasks.append(task_deposit)
	
	# Task 6: Return to smokehouse
	var task_return = {
		"type": TaskType.RETURN_TO_WORKPLACE,
		"target_position": workplace_pos,
		"description": "Return to smokehouse"
	}
	tasks.append(task_return)
	
	return tasks

func create_blacksmith_work_cycle(villager_id: String) -> Array:
	# Create a work cycle task list for a blacksmith:
	# Processes stone to tools

	var tasks: Array = []
	var world = GameServices.get_world()

	if not job_assignments.has(villager_id):
		return tasks
	
	var building_id = job_assignments[villager_id]
	var building = BuildingManager.get_building(building_id)
	if not building:
		return tasks
	
	var villager = world.get_villager(villager_id)
	if not villager or not is_instance_valid(villager):
		return tasks
	
	var grid_pos = building.get("grid_position", Vector2i.ZERO)
	var workplace_pos = CityManager.grid_to_world(grid_pos)
	
	# Task 1: Move to stockpile or quarry
	var task_find_stone = {
		"type": TaskType.MOVE_TO,
		"target_type": "stockpile",
		"description": "Check stockpile for stone"
	}
	tasks.append(task_find_stone)
	
	# Task 2: Move to blacksmith
	var task_move_to_blacksmith = {
		"type": TaskType.MOVE_TO,
		"target_position": workplace_pos,
		"description": "Move to blacksmith"
	}
	tasks.append(task_move_to_blacksmith)
	
	# Task 3: Work at blacksmith
	var task_work = {
		"type": TaskType.HARVEST_RESOURCE,
		"resource_type": "tools",
		"amount": 0.0,
		"description": "Work at blacksmith (forging tools)"
	}
	tasks.append(task_work)
	
	# Task 4: Move to stockpile
	var task_deposit_stockpile = {
		"type": TaskType.MOVE_TO,
		"target_type": "stockpile",
		"description": "Move to stockpile"
	}
	tasks.append(task_deposit_stockpile)
	
	# Task 5: Deposit tools
	var task_deposit = {
		"type": TaskType.DEPOSIT_RESOURCE,
		"resource_type": "tools",
		"description": "Deposit tools"
	}
	tasks.append(task_deposit)
	
	# Task 6: Return to blacksmith
	var task_return = {
		"type": TaskType.RETURN_TO_WORKPLACE,
		"target_position": workplace_pos,
		"description": "Return to blacksmith"
	}
	tasks.append(task_return)
	
	return tasks

func create_engineer_work_cycle(villager_id: String) -> Array:
	# Create a work cycle task list for an engineer:
	# Engineers boost research/technology at Advanced Workshop
	# For now, they work at the workshop to generate research points or technology bonuses

	var tasks: Array = []
	var world = GameServices.get_world()

	if not job_assignments.has(villager_id):
		return tasks
	
	var building_id = job_assignments[villager_id]
	var building = BuildingManager.get_building(building_id)
	if not building:
		return tasks
	
	var villager = world.get_villager(villager_id)
	if not villager or not is_instance_valid(villager):
		return tasks
	
	var grid_pos = building.get("grid_position", Vector2i.ZERO)
	var workplace_pos = CityManager.grid_to_world(grid_pos)
	
	# Task 1: Work at advanced workshop (boosts research/technology)
	var task_work = {
		"type": TaskType.HARVEST_RESOURCE,
		"resource_type": "gold",  # Engineers could generate gold or research bonuses
		"amount": 0.0,
		"description": "Work at advanced workshop (research and technology)"
	}
	tasks.append(task_work)
	
	# Task 2: Move to stockpile (if generating resources)
	var task_deposit_stockpile = {
		"type": TaskType.MOVE_TO,
		"target_type": "stockpile",
		"description": "Move to stockpile"
	}
	tasks.append(task_deposit_stockpile)
	
	# Task 3: Return to workshop
	var task_return = {
		"type": TaskType.RETURN_TO_WORKPLACE,
		"target_position": workplace_pos,
		"description": "Return to advanced workshop"
	}
	tasks.append(task_return)
	
	return tasks

func get_next_task(villager_id: String) -> Dictionary:
	# Validate input
	if villager_id.is_empty():
		push_warning("[JobSystem] Empty villager ID")
		return {}
	
	# Validate workplace still exists
	if job_assignments.has(villager_id):
		var building_id = job_assignments[villager_id]
		var building = BuildingManager.get_building(building_id)
		if not building or building.is_empty():
			# Workplace destroyed, unassign
			print("[JobSystem] Workplace destroyed for villager ", villager_id, ", unassigning")
			unassign_villager(villager_id)
			return {}
	
	if not work_tasks.has(villager_id) or work_tasks[villager_id].is_empty():
		# Check cache first
		if work_cycles_cache.has(villager_id):
			work_tasks[villager_id] = work_cycles_cache[villager_id].duplicate()
			print("[JobSystem] Using cached work cycle for villager ", villager_id)
		else:
			# Create new work cycle
			var job_type = get_villager_job(villager_id)
			var new_cycle: Array = []
			match job_type:
				"lumberjack":
					new_cycle = create_lumberjack_work_cycle(villager_id)
				"miner":
					new_cycle = create_miner_work_cycle(villager_id)
				"farmer":
					new_cycle = create_farmer_work_cycle(villager_id)
				"miller":
					new_cycle = create_miller_work_cycle(villager_id)
				"brewer":
					new_cycle = create_brewer_work_cycle(villager_id)
				"smoker":
					new_cycle = create_smoker_work_cycle(villager_id)
				"blacksmith":
					new_cycle = create_blacksmith_work_cycle(villager_id)
				"engineer":
					new_cycle = create_engineer_work_cycle(villager_id)
				_:
					print("[JobSystem] No job type found for villager ", villager_id, " (job_type: ", job_type, ")")
					return {}
			
			if not new_cycle.is_empty():
				work_tasks[villager_id] = new_cycle
				work_cycles_cache[villager_id] = new_cycle.duplicate()  # Cache it
				# Throttle logging
				if randf() < CYCLE_CREATION_LOG_CHANCE:  # Only log 5% of cycle creations
					print("[JobSystem] Created new work cycle for villager ", villager_id, " (", work_tasks[villager_id].size(), " tasks)")
	
	if not work_tasks.has(villager_id) or work_tasks[villager_id].is_empty():
		# Throttle logging
		if randf() < EMPTY_CYCLE_LOG_CHANCE:  # Only log 1% of empty cycles
			print("[JobSystem] Work cycle is empty for villager ", villager_id)
		return {}
	
	var next_task = work_tasks[villager_id][0]
	# Log task assignment with throttling
	if randf() < 0.1:  # Log 10% of task assignments for debugging
		print("[JobSystem] Assigned task to ", villager_id, ": ", next_task.get("description", "unknown"), " (", work_tasks[villager_id].size(), " tasks remaining)")
	return next_task

func complete_task(villager_id: String) -> void:
	# Validate input
	if villager_id.is_empty():
		push_warning("[JobSystem] Empty villager ID")
		return

	if work_tasks.has(villager_id) and not work_tasks[villager_id].is_empty():
		work_tasks[villager_id].pop_front()
		var remaining = work_tasks[villager_id].size()
		# Throttle logging
		if randf() < TASK_COMPLETION_LOG_CHANCE:  # Only log 5% of task completions
			print("[JobSystem] Villager ", villager_id, " completed task. Remaining: ", remaining)

		# Grant skill XP for task completion (Pixel Tribe inspired)
		_grant_skill_xp_for_task(villager_id)

		# If cycle is complete, clear the task list and cache so a new cycle can be created
		if remaining == 0:
			# Throttle logging
			if randf() < CYCLE_COMPLETION_LOG_CHANCE:  # Only log 10% of cycle completions
				print("[JobSystem] Work cycle complete for villager ", villager_id, ". New cycle will be created on next task request.")
			# Clear cache to force recreation
			if work_cycles_cache.has(villager_id):
				work_cycles_cache.erase(villager_id)

func _grant_skill_xp_for_task(villager_id: String) -> void:
	# Grant skill XP based on villager's job type (Pixel Tribe inspired system)
	var world = GameServices.get_world()
	if not world:
		return

	var villager = world.get_villager(villager_id)
	if not villager or not is_instance_valid(villager):
		return

	# Get villager's job type and map to skill type
	var job_type = villager.job_type
	var skill_type = _map_job_to_skill_type(job_type)

	if skill_type != -1 and SkillManager:
		# Grant XP based on skill XP rates
		var xp_amount = SkillManager.skill_xp_rates.get(skill_type, 1.0)
		SkillManager.add_skill_xp(skill_type, xp_amount)

func _map_job_to_skill_type(p_job_type: int) -> int:
	# Map GameWorld.JobType to SkillManager.SkillType
	if not SkillManager:
		return -1

	match p_job_type:
		GameWorld.JobType.LUMBERJACK:
			return SkillManager.SkillType.WOODWORKING
		GameWorld.JobType.MINER:
			return SkillManager.SkillType.MINING
		GameWorld.JobType.FARMER:
			return SkillManager.SkillType.FARMING
		GameWorld.JobType.ENGINEER:
			return SkillManager.SkillType.CONSTRUCTION
		_:
			return SkillManager.SkillType.GATHERING  # Default fallback

func cleanup() -> void:
	"""Clean up all job assignments and resources"""
	print("[JobSystem] Cleaning up job system...")

	# Clear all job assignments
	job_assignments.clear()
	building_workers.clear()
	work_tasks.clear()
	work_cycles_cache.clear()
	building_capacities.clear()

	print("[JobSystem] Cleanup complete")
