extends Node

## VillagerManager - Manages all villagers, jobs, and work assignments
##
## Singleton Autoload that handles villager creation, job assignment, and lifecycle management.
## Manages the complete villager system including spawning, job assignment tracking,
## and villager-node relationships.
##
## Key Features:
## - Villager spawning with unique IDs and scene instantiation
## - Job type enumeration and assignment tracking
## - Villager lifecycle management (spawn/remove)
## - Performance optimization through preloaded resources
## - Event-driven architecture with signals
##
## Usage:
##   var villager_id = VillagerManager.spawn_villager(spawn_pos)
##   VillagerManager.assign_job(villager_id, VillagerManager.JobType.LUMBERJACK)

## Emitted when a villager is successfully spawned.
## Parameters: villager_id (String)
signal villager_spawned(villager_id: String)

## Emitted when a villager is removed from the game.
## Parameters: villager_id (String)
signal villager_removed(villager_id: String)

## Emitted when a villager is assigned a job.
## Parameters: villager_id (String), job_type (String)
signal villager_job_assigned(villager_id: String, job_type: String)

## Preloaded villager scene for performance optimization.
## Loaded once at startup to avoid runtime loading delays.
const VILLAGER_SCENE = preload("res://scenes/villager.tscn")

## Preloaded villager script for performance optimization.
## Used as fallback if scene is not available.
const VILLAGER_SCRIPT = preload("res://scripts/Villager.gd")

## Registry of all active villagers: villager_id (String) -> villager_node (Node).
## Tracks villager nodes for management and reference.
var villagers: Dictionary = {}

## Counter for generating unique villager IDs.
var villager_counter: int = 0

## Job assignment tracking: job_type (String) -> Array of villager_ids (String).
## Tracks which villagers are assigned to each job type.
var jobs: Dictionary = {}

## Enumeration of all available job types for villagers.
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

func _ready() -> void:
	print("[VillagerManager] Initialized")

## Spawns a new villager at the specified position.
##
## Parameters:
##   spawn_position: World position where villager will be placed (Vector2)
##   parent_node: Parent node to add villager to (optional, defaults to current scene)
##
## Returns:
##   Unique villager_id (String) on success, empty string on failure.
##
## Side Effects:
##   - Creates villager node and adds to scene tree
##   - Registers villager in villagers dictionary
##   - Calls villager.initialize() if method exists
##   - Emits villager_spawned signal
##
## Uses preloaded resources for performance optimization.
func spawn_villager(spawn_position: Vector2, parent_node: Node = null) -> String:
	# Create unique villager ID
	var villager_id = "villager_" + str(villager_counter)
	villager_counter += 1

	# Use preloaded villager scene for performance
	var villager_instance: CharacterBody2D = null

	if VILLAGER_SCENE:
		villager_instance = VILLAGER_SCENE.instantiate() as CharacterBody2D
	else:
		# Fallback: create villager directly from preloaded script
		if VILLAGER_SCRIPT:
			villager_instance = CharacterBody2D.new()
			villager_instance.set_script(VILLAGER_SCRIPT)
		else:
			push_error("[VillagerManager] Preloaded villager resources not available!")
			return ""

	if not villager_instance:
		push_error("[VillagerManager] Failed to create villager instance!")
		return ""

	villager_instance.name = villager_id
	villager_instance.position = spawn_position

	# Add to scene tree
	var target_parent = parent_node
	if not target_parent:
		target_parent = get_tree().current_scene

	if target_parent:
		target_parent.add_child(villager_instance)
	else:
		push_error("[VillagerManager] Cannot find parent node to spawn villager!")
		return ""

	# Store villager reference
	villagers[villager_id] = villager_instance

	# Initialize villager data
	if villager_instance.has_method("initialize"):
		villager_instance.initialize(villager_id)

	villager_spawned.emit(villager_id)
	print("[VillagerManager] Spawned villager: ", villager_id, " at ", spawn_position)

	return villager_id

func remove_villager(villager_id: String) -> bool:
	# Validate input
	if villager_id.is_empty():
		push_warning("[VillagerManager] Empty villager ID")
		return false
	
	if not villagers.has(villager_id):
		return false
	
	var villager = villagers[villager_id]
	if is_instance_valid(villager):
		villager.queue_free()
	
	villagers.erase(villager_id)
	villager_removed.emit(villager_id)
	print("[VillagerManager] Removed villager: ", villager_id)
	return true

func assign_job(villager_id: String, job_type: JobType) -> bool:
	# Validate inputs
	if villager_id.is_empty():
		push_warning("[VillagerManager] Empty villager ID")
		return false
	
	if not villagers.has(villager_id):
		return false
	
	var villager = villagers[villager_id]
	if not is_instance_valid(villager):
		return false
	
	# Assign job to villager
	if villager.has_method("assign_job"):
		villager.assign_job(job_type)
	
	# Track job assignment
	var job_name = JobType.keys()[job_type]
	if not jobs.has(job_name):
		jobs[job_name] = []
	
	if villager_id in jobs[job_name]:
		return true  # Already assigned
	
	jobs[job_name].append(villager_id)
	villager_job_assigned.emit(villager_id, job_name)
	print("[VillagerManager] Assigned job ", job_name, " to villager ", villager_id)
	return true

func get_villager(villager_id: String) -> Node:
	# Validate input
	if villager_id.is_empty():
		push_warning("[VillagerManager] Empty villager ID")
		return null
	
	return villagers.get(villager_id, null)

func get_all_villagers() -> Dictionary:
	return villagers.duplicate()

func get_villagers_with_job(job_type: JobType) -> Array:
	var job_name = JobType.keys()[job_type]
	return jobs.get(job_name, []).duplicate()

func cleanup() -> void:
	"""Clean up all villagers and resources"""
	print("[VillagerManager] Cleaning up villagers...")

	# Remove all villagers
	for villager_id in villagers.keys():
		remove_villager(villager_id)

	# Clear data structures
	villagers.clear()
	jobs.clear()
	villager_counter = 0

	print("[VillagerManager] Cleanup complete")
