extends Node

## BuildingManager - Manages building placement, tracking, and effects
##
## Singleton Autoload that handles all building-related operations including placement,
## worker assignment, production, processing chains, upgrades, and capacity management.
## Manages the complete lifecycle of buildings from placement to production effects.
##
## Key Features:
## - Building placement with validation and cost payment
## - Worker assignment and capacity tracking
## - Production and consumption systems with per-minute rates
## - Processing chains for advanced buildings (mills, workshops)
## - Building upgrades and level progression
## - State management (operational, needs workers, construction, etc.)
## - Performance optimization through caching and timers
##
## Usage:
##   var building_id = BuildingManager.place_building("hut", grid_pos)
##   BuildingManager.assign_workers_to_building(building_id, worker_count)

## Emitted when a building is successfully placed on the grid.
## Parameters: building_id (String), grid_position (Vector2i)
signal building_created(building_id: String, grid_position: Vector2i)

## Emitted when a building is removed from the grid.
## Parameters: building_id (String)
signal building_removed(building_id: String)

## Emitted when building effects (production/consumption) are applied.
## Parameters: building_id (String)
signal building_effects_applied(building_id: String)

## Emitted when a building's state changes (operational, needs workers, etc.).
## Parameters: building_id (String), state_name (String)
signal building_state_changed(building_id: String, state: String)

## Registry of all placed buildings: building_id (String) -> building_instance_data (Dictionary).
## Contains complete building information including position, type, and runtime data.
var placed_buildings: Dictionary = {}

## Counter for generating unique building IDs.
var building_counter: int = 0

## Building level progression: building_id (String) -> current_level (int, 1+).
## Tracks upgrade progress for buildings that support leveling.
var building_levels: Dictionary = {}

## Active building upgrades: building_id (String) -> {time_remaining (float), target_level (int)}.
## Tracks ongoing building upgrade operations with remaining time.
var building_upgrade_timers: Dictionary = {}

## Building capacity data: building_id (String) -> {housing_capacity, worker_capacity, storage_capacity}.
## Tracks maximum capacities for housing, workers, and storage per building.
var building_capacities: Dictionary = {}

## Worker assignments: building_id (String) -> Array of villager_ids (String).
## Tracks which villagers are assigned to work at each building.
var assigned_workers: Dictionary = {}

## Housing assignments: building_id (String) -> Array of villager_ids (String).
## Tracks which villagers live in residential buildings.
var housing_residents: Dictionary = {}

## Production accumulation: building_id (String) -> {resource_id (String) -> accumulated_amount (float)}.
## Accumulates fractional production amounts until whole units are produced.
var production_accumulation: Dictionary = {}

## Processing buildings registry: building_id (String) -> processing_data (Dictionary).
## Tracks buildings that perform resource processing (mills, workshops, etc.).
var processing_buildings: Dictionary = {}

## Processing accumulation: building_id (String) -> {process_key (String) -> accumulation_time (float)}.
## Tracks processing progress for production chains.
var processing_accumulation: Dictionary = {}

## Enumeration of possible building states.
enum BuildingState {
	OPERATIONAL,     # Building is fully functional
	NEEDS_WORKERS,   # Building requires more workers to function
	NEEDS_RESOURCES, # Building lacks required resources
	FULL_CAPACITY,   # Building has reached maximum capacity
	CONSTRUCTION     # Building is currently being upgraded
}

## Current building states: building_id (String) -> BuildingState.
## Tracks the operational state of each building.
var building_states: Dictionary = {}

## Cached reference to ProgressionManager (performance optimization).
var progression_manager: Node = null

## Cached reference to JobSystem (performance optimization).
var job_system: Node = null

## Cached buildings data dictionary (performance optimization).
## Avoids repeated DataManager.get_data("buildings") calls.
var buildings_data_cache: Dictionary = {}

## Cached resources data dictionary (performance optimization).
## Avoids repeated DataManager.get_data("resources") calls.
var resources_data_cache: Dictionary = {}

## Timer for resource production/consumption ticks (1 second intervals).
@onready var resource_timer: Timer = Timer.new()

func _ready() -> void:
	print("[BuildingManager] Initialized")
	# Cache autoload manager references (performance optimization)
	progression_manager = get_node_or_null("/root/ProgressionManager")
	job_system = get_node_or_null("/root/JobSystem")

	# Defer data caching until DataManager is definitely available
	call_deferred("initialize_data_cache")

	# Connect to JobSystem signals for worker tracking (deferred to ensure JobSystem is ready)
	call_deferred("connect_job_system_signals")

func initialize_data_cache() -> void:
	"""Initialize data cache after all autoloads are loaded"""
	# Cache data dictionaries (performance optimization)
	cache_buildings_data()
	cache_resources_data()
	setup_resource_timer()

func cache_buildings_data() -> void:
	"""Cache buildings data dictionary for faster lookups"""
	var data_manager = get_node_or_null("/root/DataManager")
	if data_manager:
		var data = data_manager.get_data("buildings")
		if data:
			buildings_data_cache = data.get("buildings", data)

func cache_resources_data() -> void:
	"""Cache resources data dictionary for faster lookups"""
	var data_manager = get_node_or_null("/root/DataManager")
	if data_manager:
		var data = data_manager.get_data("resources")
		if data:
			resources_data_cache = data.get("resources", data)

func connect_job_system_signals() -> void:
	"""Connect to JobSystem signals for worker tracking"""
	if job_system:
		job_system.job_assigned.connect(_on_worker_assigned)
		job_system.job_unassigned.connect(_on_worker_unassigned)

# Resource timer constants
const RESOURCE_TICK_INTERVAL: float = 1.0  # Seconds (represents 1 game minute for fast testing)

func setup_resource_timer() -> void:
	# Timer for resource gathering/consumption
	# Tick interval: 1 second (represents 1 game minute for fast testing)
	resource_timer.wait_time = RESOURCE_TICK_INTERVAL
	resource_timer.one_shot = false
	resource_timer.timeout.connect(_on_resource_tick)
	add_child(resource_timer)
	resource_timer.start()
	print("[BuildingManager] Resource gathering tick timer started (", RESOURCE_TICK_INTERVAL, " second intervals)")

func _on_resource_tick() -> void:
	apply_resource_effects()
	process_production_chains(RESOURCE_TICK_INTERVAL)

## Validates if a building can be placed at the specified location.
##
## Parameters:
##   building_type_id: The building type identifier (e.g., "hut", "stockpile")
##   grid_position: Grid position where building would be placed (Vector2i)
##
## Returns:
##   true if building can be placed, false if validation fails.
##
## Validation checks:
##   - Building type exists in data cache
##   - Building is unlocked in progression system
##   - Player has sufficient resources (except first stockpile is free)
##   - Grid position can accommodate building size
func can_place_building(building_type_id: String, grid_position: Vector2i) -> bool:
	# Validate inputs
	if building_type_id.is_empty():
		return false

	# Use cached buildings data (performance optimization)
	if not buildings_data_cache.has(building_type_id):
		push_warning("[BuildingManager] Unknown building type: ", building_type_id)
		return false

	var building_data = buildings_data_cache[building_type_id]

	# Check if building is unlocked (via ProgressionManager)
	if progression_manager and not progression_manager.is_building_unlocked(building_type_id):
		push_warning("[BuildingManager] Building not unlocked: ", building_type_id)
		return false
	
	# STRONGHOLD MECHANICS: Check building chain requirements (e.g., need mill before bakery)
	var requires = building_data.get("requires", [])
	if requires is Array and requires.size() > 0:
		var has_all_requirements = true
		for required_building_type in requires:
			var required_buildings = get_buildings_of_type(required_building_type)
			if required_buildings.is_empty():
				push_warning("[BuildingManager] Building requires ", required_building_type, " but none are built!")
				has_all_requirements = false
				break
		if not has_all_requirements:
			return false

	# Check resources (skip cost check for first free stockpile)
	var costs = building_data.get("cost", {})
	var is_first_stockpile = building_type_id == "stockpile" and get_buildings_of_type("stockpile").is_empty()
	var resource_manager = get_node_or_null("/root/ResourceManager")
	if not is_first_stockpile and resource_manager and not resource_manager.can_afford(costs):
		return false

	# Check grid placement
	var building_size = Vector2i(
		building_data.get("size", [1, 1])[0],
		building_data.get("size", [1, 1])[1]
	)
	if not CityManager.can_place_building(grid_position, building_size):
		return false

	return true

## Places a building on the grid and initializes all building systems.
##
## Parameters:
##   building_type_id: The building type identifier (e.g., "hut", "stockpile")
##   grid_position: Grid position where building will be placed (Vector2i)
##
## Returns:
##   Unique building_id (String) on success, empty string on failure.
##
## Side Effects:
##   - Pays building costs (unless first free stockpile)
##   - Places building on grid via CityManager
##   - Initializes capacity tracking, production systems, and processing
##   - Applies one-time effects (storage bonuses, etc.)
##   - Emits building_created signal
##   - Updates building state
func place_building(building_type_id: String, grid_position: Vector2i) -> String:
	# Performance monitoring
	if PerformanceMonitor:
		PerformanceMonitor.start_benchmark("building_placement")

	if not can_place_building(building_type_id, grid_position):
		if PerformanceMonitor:
			PerformanceMonitor.end_benchmark("building_placement")
		return ""

	# Use cached buildings data (performance optimization)
	if not buildings_data_cache.has(building_type_id):
		push_error("[BuildingManager] Building type not found in cache: ", building_type_id)
		if PerformanceMonitor:
			PerformanceMonitor.end_benchmark("building_placement")
		return ""

	var building_data = buildings_data_cache[building_type_id].duplicate()

	# Pay costs (skip payment for first free stockpile)
	var costs = building_data.get("cost", {})
	var is_first_stockpile = building_type_id == "stockpile" and get_buildings_of_type("stockpile").is_empty()
	if not is_first_stockpile:
		var resource_manager = get_node_or_null("/root/ResourceManager")
		if resource_manager:
			resource_manager.pay_costs(costs)
	else:
		print("[BuildingManager] First stockpile is free!")

	# Create unique building ID
	var building_id = building_type_id + "_" + str(building_counter)
	building_counter += 1

	# Store building data with unique ID
	building_data["id"] = building_id
	building_data["building_type_id"] = building_type_id

	# Place on grid via CityManager
	if not CityManager.place_building(building_id, grid_position, building_data):
		push_error("[BuildingManager] Failed to place building on grid!")
		return ""

	# Store building instance data
	var building_instance = {
		"building_type_id": building_type_id,
		"grid_position": grid_position,
		"building_data": building_data,
		"id": building_id
	}
	placed_buildings[building_id] = building_instance

	# Initialize building capacity tracking
	initialize_building_capacity(building_id, building_data)

	# Initialize production accumulation
	production_accumulation[building_id] = {}

	# Initialize building state
	update_building_state(building_id)

	# Apply one-time effects (like storage bonuses) immediately
	apply_building_one_time_effects(building_id, building_data)

	# Initialize processing if this is a processing building
	initialize_processing_building(building_id, building_data)

	# Emit signal
	building_created.emit(building_id, grid_position)
	print("[BuildingManager] Placed building: ", building_type_id, " at ", grid_position, " (ID: ", building_id, ")")

	# Performance monitoring
	if PerformanceMonitor:
		PerformanceMonitor.end_benchmark("building_placement")

	return building_id

func initialize_processing_building(building_id: String, building_data: Dictionary) -> void:
	"""Initialize processing data for processing buildings"""
	var effects = building_data.get("effects", {})
	if effects.has("processes"):
		processing_buildings[building_id] = effects["processes"].duplicate(true)
		print("[BuildingManager] Registered processing building: ", building_id)

func initialize_building_capacity(building_id: String, building_data: Dictionary) -> void:
	"""Initialize capacity tracking for a building"""
	var capacity_data = {
		"housing_capacity": building_data.get("housing_capacity", 0),
		"worker_capacity": building_data.get("worker_capacity", 0),
		"storage_capacity": building_data.get("storage_capacity", 0)
	}
	building_capacities[building_id] = capacity_data
	
	# Initialize worker/resident tracking
	if capacity_data.worker_capacity > 0:
		assigned_workers[building_id] = []
	if capacity_data.housing_capacity > 0:
		housing_residents[building_id] = []

func apply_building_one_time_effects(_building_id: String, building_data: Dictionary) -> void:
	# Apply effects that should only happen once (like storage bonuses)
	var effects = building_data.get("effects", {})
	var category = building_data.get("category", "")
	
	# Handle storage bonuses (one-time only)
	if effects.has("storage_bonus"):
		var bonus = effects.get("storage_bonus", 0)
		# Apply storage bonus to all resources (use cached data)
		var resource_manager = get_node_or_null("/root/ResourceManager")
		if resource_manager:
			for resource_id in resources_data_cache:
				resource_manager.increase_storage_capacity(resource_id, bonus)
			print("[BuildingManager] Applied storage bonus: +", bonus, " to all resources")

	# Handle trade bonuses (one-time only)
	if effects.has("trade_bonus"):
		var bonus = effects.get("trade_bonus", 1.0)
		# TODO: Implement trade bonus system
		print("[BuildingManager] Trade bonus effect ready: ", bonus, " (implementation pending)")

	# Handle happiness bonuses (ongoing effect)
	if effects.has("happiness_bonus"):
		var bonus = effects.get("happiness_bonus", 0)
		print("[BuildingManager] Well provides happiness bonus: +", bonus)

	# Handle health bonuses (ongoing effect)
	if effects.has("health_bonus"):
		var bonus = effects.get("health_bonus", 0)
		print("[BuildingManager] Well provides health bonus: +", bonus)

	# Handle research bonuses (ongoing effect)
	if effects.has("research_bonus"):
		var bonus = effects.get("research_bonus", 1.0)
		print("[BuildingManager] Advanced Workshop provides research bonus: ", bonus, "x")
		# Update research bonuses when building is placed
		call_deferred("update_research_bonuses")

	# Handle morale bonuses (ongoing effect - same as happiness)
	if effects.has("morale_bonus"):
		var bonus = effects.get("morale_bonus", 0)
		print("[BuildingManager] Shrine provides morale bonus: +", bonus)

	# Handle technology bonuses (one-time only)
	if effects.has("technology_bonus"):
		var bonus = effects.get("technology_bonus", 1.0)
		# TODO: Apply technology advancement bonus
		print("[BuildingManager] Technology bonus effect ready: ", bonus, "x (implementation pending)")
	
	# STRONGHOLD MECHANICS INTEGRATION
	# Track food variety when buildings produce food
	if effects.has("food_type"):
		var food_type = effects.get("food_type", "")
		if PopularityManager:
			PopularityManager.set_food_type_active(food_type, true)
			print("[BuildingManager] Activated food type: ", food_type)
	
	# Track ale coverage for inns
	if effects.has("ale_coverage"):
		var coverage = effects.get("ale_coverage", 0)
		if PopularityManager:
			# Calculate actual peasants covered (simplified - uses total population)
			# In a full implementation, would check distance to inn
			var total_population: float = 0.0
			var resource_manager = get_node_or_null("/root/ResourceManager")
			if resource_manager:
				total_population = resource_manager.get_resource("population")
			var current_coverage = PopularityManager.get_ale_coverage()
			var new_coverage = min(coverage, int(total_population) - current_coverage)
			if new_coverage > 0:
				PopularityManager.set_ale_coverage(current_coverage + new_coverage)
				print("[BuildingManager] Inn provides ale coverage for ", new_coverage, " peasants")
	
	# Track Fear Factor buildings (Bad Things)
	if category == "fear" or effects.has("fear_level"):
		var fear_level = building_data.get("fear_level", effects.get("fear_level", 0))
		if PopularityManager and fear_level > 0:
			var current_fear = PopularityManager.get_fear_level()
			PopularityManager.set_fear_level(current_fear + fear_level)
			print("[BuildingManager] Added fear level: +", fear_level, " (Total: ", current_fear + fear_level, ")")
	
	# Track Good Things buildings (Entertainment)
	if category == "entertainment" or effects.has("good_level"):
		var good_level = building_data.get("good_level", effects.get("good_level", 0))
		if PopularityManager and good_level > 0:
			var current_good = PopularityManager.get_good_level()
			PopularityManager.set_good_level(current_good + good_level)
			print("[BuildingManager] Added good things level: +", good_level, " (Total: ", current_good + good_level, ")")

func remove_building(building_id: String) -> bool:
	# Validate input
	if building_id.is_empty():
		push_warning("[BuildingManager] Empty building ID")
		return false
	
	if not placed_buildings.has(building_id):
		return false
	
	var building_instance = placed_buildings[building_id]
	var building_data = building_instance.get("building_data", {})
	var effects = building_data.get("effects", {})
	var category = building_data.get("category", "")
	
	# STRONGHOLD MECHANICS: Remove building effects from PopularityManager
	if effects.has("food_type"):
		var food_type = effects.get("food_type", "")
		# Check if any other buildings produce this food type
		var other_buildings_produce = false
		for other_id in placed_buildings:
			if other_id != building_id:
				var other_data = placed_buildings[other_id].get("building_data", {})
				var other_effects = other_data.get("effects", {})
				if other_effects.get("food_type", "") == food_type:
					other_buildings_produce = true
					break
		if PopularityManager and not other_buildings_produce:
			PopularityManager.set_food_type_active(food_type, false)
			print("[BuildingManager] Deactivated food type: ", food_type)
	
	# Remove ale coverage for inns
	if effects.has("ale_coverage"):
		var coverage = effects.get("ale_coverage", 0)
		if PopularityManager:
			var current_coverage = PopularityManager.get_ale_coverage()
			PopularityManager.set_ale_coverage(max(0, current_coverage - coverage))
			print("[BuildingManager] Removed ale coverage: ", coverage)
	
	# Remove Fear Factor level
	if category == "fear" or effects.has("fear_level"):
		var fear_level = building_data.get("fear_level", effects.get("fear_level", 0))
		if PopularityManager and fear_level > 0:
			var current_fear = PopularityManager.get_fear_level()
			PopularityManager.set_fear_level(max(0, current_fear - fear_level))
			print("[BuildingManager] Removed fear level: -", fear_level)
	
	# Remove Good Things level
	if category == "entertainment" or effects.has("good_level"):
		var good_level = building_data.get("good_level", effects.get("good_level", 0))
		if PopularityManager and good_level > 0:
			var current_good = PopularityManager.get_good_level()
			PopularityManager.set_good_level(max(0, current_good - good_level))
			print("[BuildingManager] Removed good things level: -", good_level)
	
	placed_buildings.erase(building_id)
	
	# Clean up capacity tracking
	building_capacities.erase(building_id)
	assigned_workers.erase(building_id)
	housing_residents.erase(building_id)
	production_accumulation.erase(building_id)
	building_states.erase(building_id)
	
	# Also remove from CityManager
	CityManager.remove_building(building_id)

	# Update research bonuses when building is removed
	call_deferred("update_research_bonuses")

	building_removed.emit(building_id)
	print("[BuildingManager] Removed building: ", building_id)

	# Update mini-map
	if get_tree().current_scene and get_tree().current_scene.has_method("update_minimap"):
		get_tree().current_scene.update_minimap()

	return true

## Returns building type definition data for a building type ID.
##
## Parameters:
##   building_type_id: The building type identifier (e.g., "hut", "stockpile")
##
## Returns:
##   Dictionary containing building type definition (name, description, costs, effects, etc.),
##   or empty Dictionary if building type not found.
func get_building_type_data(building_type_id: String) -> Dictionary:
	"""Get building type definition data from cache"""
	if building_type_id.is_empty():
		return {}
	
	if not buildings_data_cache.has(building_type_id):
		push_warning("[BuildingManager] Unknown building type: ", building_type_id)
		return {}
	
	return buildings_data_cache[building_type_id]

func get_building(building_id: String) -> Dictionary:
	# Validate input
	if building_id.is_empty():
		push_warning("[BuildingManager] Empty building ID")
		return {}
	
	return placed_buildings.get(building_id, {})

func get_all_buildings() -> Dictionary:
	return placed_buildings.duplicate()

func get_buildings_of_type(building_type_id: String) -> Array:
	# Validate input
	if building_type_id.is_empty():
		push_warning("[BuildingManager] Empty building type ID")
		return []
	
	var result = []
	for building_id in placed_buildings:
		var building = placed_buildings[building_id]
		if building.get("building_type_id") == building_type_id:
			result.append(building_id)
	return result

# ==================== Capacity System ====================

func get_housing_capacity(building_id: String) -> int:
	"""Get housing capacity for a building"""
	if not building_capacities.has(building_id):
		return 0
	return building_capacities[building_id].get("housing_capacity", 0)

func get_worker_capacity(building_id: String) -> int:
	"""Get worker capacity for a building"""
	if not building_capacities.has(building_id):
		return 0
	return building_capacities[building_id].get("worker_capacity", 0)

func get_storage_capacity(building_id: String) -> int:
	"""Get storage capacity for a building"""
	if not building_capacities.has(building_id):
		return 0
	return building_capacities[building_id].get("storage_capacity", 0)

func get_assigned_workers(building_id: String) -> Array:
	"""Get list of worker IDs assigned to a building"""
	return assigned_workers.get(building_id, []).duplicate()

func get_worker_count(building_id: String) -> int:
	"""Get number of workers assigned to a building"""
	return assigned_workers.get(building_id, []).size()

func get_housing_count(building_id: String) -> int:
	"""Get number of residents in a building"""
	return housing_residents.get(building_id, []).size()

func has_worker_capacity(building_id: String) -> bool:
	"""Check if building has available worker capacity"""
	var capacity = get_worker_capacity(building_id)
	var current = get_worker_count(building_id)
	return current < capacity

func has_housing_capacity(building_id: String) -> bool:
	"""Check if building has available housing capacity"""
	var capacity = get_housing_capacity(building_id)
	var current = get_housing_count(building_id)
	return current < capacity

func get_total_housing_capacity() -> int:
	"""Calculate total housing capacity from all residential buildings"""
	var total_capacity: int = 0
	for building_id in placed_buildings:
		var capacity = get_housing_capacity(building_id)
		if capacity > 0:
			total_capacity += capacity
	return total_capacity

# ==================== Worker Assignment Tracking ====================

func _on_worker_assigned(villager_id: String, building_id: String, _job_type: String) -> void:
	"""Called when JobSystem assigns a worker to a building"""
	if not assigned_workers.has(building_id):
		assigned_workers[building_id] = []
	if villager_id not in assigned_workers[building_id]:
		assigned_workers[building_id].append(villager_id)
	update_building_state(building_id)

func _on_worker_unassigned(villager_id: String) -> void:
	"""Called when JobSystem unassigns a worker from a building"""
	# Find which building this worker was assigned to
	for building_id in assigned_workers:
		if villager_id in assigned_workers[building_id]:
			assigned_workers[building_id].erase(villager_id)
			update_building_state(building_id)
			break

# ==================== Production Rate System ====================

func apply_resource_effects() -> void:
	"""Apply resource gathering/consumption for all buildings with proper per-minute rates"""
	# Timer ticks every second (RESOURCE_TICK_INTERVAL = 1.0)
	# Production rates are per-minute, so we accumulate per-second amounts
	var resource_manager = get_node_or_null("/root/ResourceManager")
	var seconds_per_tick = RESOURCE_TICK_INTERVAL
	var minutes_per_tick = seconds_per_tick / 60.0
	
	for building_id in placed_buildings:
		var building = placed_buildings[building_id]
		var building_data = building.get("building_data", {})
		var effects = building_data.get("effects", {})
		
		# Check if this is a workplace without passive production_rate
		# If it has production_rate, allow it to produce passively (e.g., farms can produce both ways)
		var production_rates = building_data.get("production_rate", {})
		var is_workplace_only = effects.has("workplace") and production_rates.is_empty()
		
		if is_workplace_only:
			# Workplace-only buildings don't produce resources passively (only via villager work)
			# Only apply consumption (if any)
			var workplace_consumption_rates = building_data.get("consumption_rate", {})
			if workplace_consumption_rates.is_empty():
				var consumes = effects.get("consumes", {})
				for resource_id in consumes:
					var rate_per_minute = float(consumes[resource_id])
					var consumption_amount = rate_per_minute * minutes_per_tick
					if resource_manager:
						resource_manager.consume_resource(resource_id, consumption_amount, true)
			else:
				for resource_id in workplace_consumption_rates:
					var rate_per_minute = float(workplace_consumption_rates[resource_id])
					var consumption_amount = rate_per_minute * minutes_per_tick
					if resource_manager:
						resource_manager.consume_resource(resource_id, consumption_amount, true)
			building_effects_applied.emit(building_id)
			continue
		
		# building_data is used below for production calculations
		
		# Calculate production based on workers assigned and efficiency
		var worker_count = get_worker_count(building_id)
		var base_efficiency = building_data.get("efficiency", 1.0)
		
		# STRONGHOLD MECHANICS: Calculate travel distance efficiency
		var travel_efficiency = calculate_travel_distance_efficiency(building_id)
		
		# STRONGHOLD MECHANICS: Apply PopularityManager production modifiers (fear/good things)
		var production_multiplier = 1.0
		var production_penalty = 1.0
		if PopularityManager:
			production_multiplier = PopularityManager.get_production_multiplier()  # Fear bonus
			production_penalty = PopularityManager.get_production_penalty()  # Good things penalty
		
		# Combine all efficiency factors
		var efficiency = base_efficiency * travel_efficiency * production_multiplier * production_penalty
		
		# Handle resource gathering with production rates (passive production buildings only)
		# Reuse production_rates already declared earlier in this function scope
		if production_rates.is_empty():
			# Fallback to old "effects.gathers" system for backward compatibility
			var gathers = effects.get("gathers", {})
			for resource_id in gathers:
				var rate_per_minute = float(gathers[resource_id])
				production_rates[resource_id] = rate_per_minute
		
		# Apply production rates (scaled by workers and efficiency)
		for resource_id in production_rates:
			var base_rate_per_minute = float(production_rates[resource_id])
			var production_per_worker = building_data.get("production_per_worker", base_rate_per_minute)
			
			# Calculate actual production rate
			var actual_rate: float
			if production_per_worker > 0.0 and get_worker_capacity(building_id) > 0:
				# Worker-based production (scales with workers and their individual efficiency)
				var total_worker_efficiency = 0.0
				var assigned_workers = get_assigned_workers(building_id)

				if assigned_workers.size() > 0:
					# Calculate average efficiency of assigned workers
					for villager_id in assigned_workers:
						var game_world = get_node_or_null("/root/GameWorld")
						var villager = game_world.get_villager(villager_id) if game_world else null
						if villager and villager.has_method("get_work_efficiency"):
							total_worker_efficiency += villager.get_work_efficiency()
						else:
							total_worker_efficiency += 1.0  # Default efficiency
					total_worker_efficiency /= assigned_workers.size()
				else:
					total_worker_efficiency = 1.0

				actual_rate = production_per_worker * worker_count * efficiency * total_worker_efficiency
			else:
				# Base production (no workers needed, or building doesn't use workers)
				actual_rate = base_rate_per_minute * efficiency

			# Apply seasonal building efficiency modifier
			if SeasonalManager:
				var seasonal_building_modifier = SeasonalManager.get_building_modifier()
				actual_rate *= seasonal_building_modifier

			# Accumulate production (per-minute rate * minutes per tick)
			var production_amount = actual_rate * minutes_per_tick
			
			if not production_accumulation.has(building_id):
				production_accumulation[building_id] = {}
			if not production_accumulation[building_id].has(resource_id):
				production_accumulation[building_id][resource_id] = 0.0
			
			production_accumulation[building_id][resource_id] += production_amount
		
		# Handle resource consumption
		var consumption_rates = building_data.get("consumption_rate", {})
		if consumption_rates.is_empty():
			# Fallback to old "effects.consumes" system
			var consumes = effects.get("consumes", {})
			for resource_id in consumes:
				var rate_per_minute = float(consumes[resource_id])
				consumption_rates[resource_id] = rate_per_minute
		
		for resource_id in consumption_rates:
			var rate_per_minute = float(consumption_rates[resource_id])
			var consumption_amount = rate_per_minute * minutes_per_tick
			if resource_manager:
				resource_manager.consume_resource(resource_id, consumption_amount, true)
		
		building_effects_applied.emit(building_id)
	
	# Apply accumulated production (convert to integers for resource amounts)
	for building_id in production_accumulation:
		for resource_id in production_accumulation[building_id]:
			var accumulated = production_accumulation[building_id][resource_id]
			if accumulated >= 1.0:  # Only add whole units
				var amount_to_add = int(accumulated)
				
				# Special handling for population: enforce housing capacity limit
				if resource_id == "population":
					var current_population = resource_manager.get_resource("population") if resource_manager else 0.0
					var total_housing_capacity = get_total_housing_capacity()
					var available_capacity = max(0, total_housing_capacity - current_population)
					amount_to_add = min(amount_to_add, available_capacity)
				
				if amount_to_add > 0 and resource_manager:
					resource_manager.add_resource(resource_id, float(amount_to_add))
					production_accumulation[building_id][resource_id] -= float(amount_to_add)

# ==================== Building State Management ====================

func update_building_state(building_id: String) -> void:
	"""Update building state based on capacity, workers, and resources"""
	if not placed_buildings.has(building_id):
		return

	var building = placed_buildings[building_id]
	var _building_data = building.get("building_data", {})

	var state = BuildingState.OPERATIONAL
	
	# Check if workplace needs workers
	var worker_capacity = get_worker_capacity(building_id)
	if worker_capacity > 0:
		var worker_count = get_worker_count(building_id)
		if worker_count < worker_capacity:
			state = BuildingState.NEEDS_WORKERS
		elif worker_count >= worker_capacity:
			state = BuildingState.FULL_CAPACITY
	
	# Check if residential building is full
	var housing_capacity = get_housing_capacity(building_id)
	if housing_capacity > 0:
		var housing_count = get_housing_count(building_id)
		if housing_count >= housing_capacity:
			state = BuildingState.FULL_CAPACITY
	
	# Check if building needs resources (future implementation)
	# For now, buildings always have resources
	
	var old_state = building_states.get(building_id, BuildingState.OPERATIONAL)
	building_states[building_id] = state
	
	if old_state != state:
		var state_names = ["OPERATIONAL", "NEEDS_WORKERS", "NEEDS_RESOURCES", "FULL_CAPACITY", "CONSTRUCTION"]
		building_state_changed.emit(building_id, state_names[state as int])

func get_building_state(building_id: String) -> BuildingState:
	"""Get current state of a building"""
	return building_states.get(building_id, BuildingState.OPERATIONAL)

func get_building_state_name(building_id: String) -> String:
	"""Get human-readable state name for a building"""
	var state = get_building_state(building_id)
	var state_names = ["OPERATIONAL", "NEEDS_WORKERS", "NEEDS_RESOURCES", "FULL_CAPACITY", "CONSTRUCTION"]
	return state_names[state as int]

func update_research_bonuses() -> void:
	"""Update research bonuses from buildings"""
	if ResearchManager and ResearchManager.has_method("update_research_bonuses"):
		ResearchManager.update_research_bonuses()

# Building Level and Upgrade System (Pixel Tribe inspired)

func get_building_level(building_id: String) -> int:
	"""Get current level of a building (default: 1)"""
	return building_levels.get(building_id, 1)

func get_max_villager_level_for_building(building_id: String) -> int:
	"""Get maximum villager level allowed by this building's current level"""
	if not placed_buildings.has(building_id):
		return 5  # Default max level

	var building_data = placed_buildings[building_id]
	var building_type = building_data.get("building_type", "")
	var base_data = buildings_data_cache.get(building_type, {})

	var current_level = get_building_level(building_id)

	# Check if building has upgrade data
	if base_data.has("upgrades"):
		var upgrade_key = "level_" + str(current_level)
		if base_data["upgrades"].has(upgrade_key):
			return base_data["upgrades"][upgrade_key].get("max_villager_level", base_data.get("max_villager_level", 5))

	# Return base level max villager level
	return base_data.get("max_villager_level", 5)

func can_upgrade_building(building_id: String) -> bool:
	"""Check if a building can be upgraded"""
	if not placed_buildings.has(building_id):
		return false

	var building_data = placed_buildings[building_id]
	var building_type = building_data.get("building_type", "")
	var base_data = buildings_data_cache.get(building_type, {})

	if not base_data.has("upgrades"):
		return false

	var current_level = get_building_level(building_id)
	var next_level_key = "level_" + str(current_level + 1)

	if not base_data["upgrades"].has(next_level_key):
		return false  # No more upgrades available

	var upgrade_data = base_data["upgrades"][next_level_key]
	var costs = upgrade_data.get("cost", {})

	var resource_manager = get_node_or_null("/root/ResourceManager")
	return resource_manager and resource_manager.can_afford(costs)

func get_upgrade_cost(building_id: String) -> Dictionary:
	"""Get upgrade cost for a building"""
	if not placed_buildings.has(building_id):
		return {}

	var building_data = placed_buildings[building_id]
	var building_type = building_data.get("building_type", "")
	var base_data = buildings_data_cache.get(building_type, {})

	if not base_data.has("upgrades"):
		return {}

	var current_level = get_building_level(building_id)
	var next_level_key = "level_" + str(current_level + 1)

	if base_data["upgrades"].has(next_level_key):
		return base_data["upgrades"][next_level_key].get("cost", {})

	return {}

func get_upgrade_time(building_id: String) -> float:
	"""Get upgrade time in seconds for a building"""
	if not placed_buildings.has(building_id):
		return 0.0

	var building_data = placed_buildings[building_id]
	var building_type = building_data.get("building_type", "")
	var base_data = buildings_data_cache.get(building_type, {})

	if not base_data.has("upgrades"):
		return 0.0

	var current_level = get_building_level(building_id)
	var next_level_key = "level_" + str(current_level + 1)

	if base_data["upgrades"].has(next_level_key):
		return float(base_data["upgrades"][next_level_key].get("time", 300))  # Default 5 minutes

	return 0.0

func start_building_upgrade(building_id: String) -> bool:
	"""Start upgrading a building"""
	if not can_upgrade_building(building_id):
		return false

	var upgrade_cost = get_upgrade_cost(building_id)
	var resource_manager = get_node_or_null("/root/ResourceManager")
	if not resource_manager or not resource_manager.spend_resources(upgrade_cost):
		return false

	var upgrade_time = get_upgrade_time(building_id)
	var target_level = get_building_level(building_id) + 1

	building_upgrade_timers[building_id] = {
		"time_remaining": upgrade_time,
		"target_level": target_level
	}

	building_states[building_id] = BuildingState.CONSTRUCTION
	building_state_changed.emit(building_id, "CONSTRUCTION")

	print("[BuildingManager] Started upgrade for building ", building_id, " to level ", target_level)
	return true

func _process_upgrade_timers(delta: float) -> void:
	"""Process building upgrade timers (call this in _process)"""
	var completed_upgrades = []

	for building_id in building_upgrade_timers.keys():
		var upgrade_data = building_upgrade_timers[building_id]
		upgrade_data["time_remaining"] -= delta

		if upgrade_data["time_remaining"] <= 0:
			completed_upgrades.append(building_id)

	for building_id in completed_upgrades:
		complete_building_upgrade(building_id)

func complete_building_upgrade(building_id: String) -> void:
	"""Complete a building upgrade"""
	if not building_upgrade_timers.has(building_id):
		return

	var upgrade_data = building_upgrade_timers[building_id]
	var target_level = upgrade_data["target_level"]

	building_levels[building_id] = target_level
	building_upgrade_timers.erase(building_id)

	building_states[building_id] = BuildingState.OPERATIONAL
	building_state_changed.emit(building_id, "OPERATIONAL")

	print("[BuildingManager] Completed upgrade for building ", building_id, " to level ", target_level)

func get_building_upgrade_progress(building_id: String) -> float:
	"""Get upgrade progress as percentage (0-100)"""
	if not building_upgrade_timers.has(building_id):
		return 100.0

	var upgrade_data = building_upgrade_timers[building_id]
	var total_time = get_upgrade_time(building_id)
	if total_time <= 0:
		return 100.0

	var remaining_time = upgrade_data.get("time_remaining", 0.0)
	return ((total_time - remaining_time) / total_time) * 100.0

func process_production_chains(delta: float) -> void:
	"""Process production chains for processing buildings"""
	var resource_manager = get_node_or_null("/root/ResourceManager")
	for building_id in processing_buildings.keys():
		if not placed_buildings.has(building_id):
			continue

		var building_data = placed_buildings[building_id]
		var building_type = building_data.get("building_type_id", "")
		var base_data = buildings_data_cache.get(building_type, {})

		if not base_data.has("effects") or not base_data["effects"].has("processes"):
			continue

		# Check if building has workers
		var worker_count = get_worker_count(building_id)
		if worker_count <= 0:
			continue

		var processes = base_data["effects"]["processes"]

		for process_key in processes.keys():
			var process_data = processes[process_key]
			var input_resource = process_key
			var output_resource = process_data.get("output", "")
			var input_rate = process_data.get("input_rate", 1.0)
			var output_rate = process_data.get("rate", 1.0)

			# Check if we have enough input resources
			var available_input = resource_manager.get_resource_amount(input_resource) if resource_manager else 0.0
			if available_input < input_rate * delta:
				continue  # Not enough input

			# Initialize processing accumulation if needed
			if not processing_accumulation.has(building_id):
				processing_accumulation[building_id] = {}
			if not processing_accumulation[building_id].has(process_key):
				processing_accumulation[building_id][process_key] = 0.0

			# Accumulate processing time
			processing_accumulation[building_id][process_key] += delta

			# Check if we have enough time accumulated for one processing cycle
			var processing_time_needed = 60.0 / output_rate  # Time for one output unit in seconds
			if processing_accumulation[building_id][process_key] >= processing_time_needed:
				# Process one batch
				processing_accumulation[building_id][process_key] -= processing_time_needed

			# Consume input
			if resource_manager:
				resource_manager.spend_resource(input_resource, input_rate)

			# Produce output
			if resource_manager:
				resource_manager.add_resource(output_resource, output_rate)
			
			# STRONGHOLD MECHANICS: Track food variety for processed foods
			# Check if output is a food type (bread, preserved_food, meat, etc.)
			if output_resource == "bread" or output_resource == "preserved_food" or output_resource == "meat":
				# building_data is already declared at line 906, so we access the nested building_data property
				var building_instance_data = building_data.get("building_data", {})
				var effects = building_instance_data.get("effects", {})
				if effects.has("food_type"):
					var food_type = effects.get("food_type", "")
					if PopularityManager:
						PopularityManager.set_food_type_active(food_type, true)

			print("[BuildingManager] ", building_id, " processed ", input_rate, " ", input_resource, " into ", output_rate, " ", output_resource)

## Calculates travel distance efficiency for a building.
## Production efficiency decreases based on distance to nearest stockpile.
## Formula: efficiency = 1.0 - (distance / max_distance) * penalty_factor
## Max distance: 500 pixels (no penalty up to this)
## Penalty factor: 0.3 (30% max efficiency loss)
func calculate_travel_distance_efficiency(building_id: String) -> float:
	if not placed_buildings.has(building_id):
		return 1.0
	
	var building_instance = placed_buildings[building_id]
	var grid_pos = building_instance.get("grid_position", Vector2i.ZERO)
	var building_world_pos = CityManager.grid_to_world(grid_pos)
	
	# Find nearest stockpile
	var stockpiles = get_buildings_of_type("stockpile")
	if stockpiles.is_empty():
		return 1.0  # No stockpile, no penalty
	
	var nearest_distance = INF
	for stockpile_id in stockpiles:
		var stockpile_instance = placed_buildings.get(stockpile_id, {})
		var stockpile_grid_pos = stockpile_instance.get("grid_position", Vector2i.ZERO)
		var stockpile_world_pos = CityManager.grid_to_world(stockpile_grid_pos)
		
		# Use pathfinding distance if available, otherwise Euclidean distance
		var distance: float
		var path = CityManager.get_navigation_path(grid_pos, stockpile_grid_pos)
		if path and path.size() > 1:
			# Calculate path length
			distance = 0.0
			for i in range(path.size() - 1):
				distance += path[i].distance_to(path[i + 1])
		else:
			# Fallback to Euclidean distance
			distance = building_world_pos.distance_to(stockpile_world_pos)
		
		if distance < nearest_distance:
			nearest_distance = distance
	
	# Apply distance penalty
	const MAX_DISTANCE = 500.0  # pixels (no penalty up to this)
	const PENALTY_FACTOR = 0.3  # 30% max efficiency loss
	
	if nearest_distance <= MAX_DISTANCE:
		return 1.0  # No penalty within max distance
	
	var efficiency_loss = ((nearest_distance - MAX_DISTANCE) / MAX_DISTANCE) * PENALTY_FACTOR
	return clamp(1.0 - efficiency_loss, 0.7, 1.0)  # Min 70% efficiency

## Updates food consumption based on ration level and population.
func update_food_consumption() -> void:
	var popularity_manager = get_node_or_null("/root/PopularityManager")
	var resource_manager = get_node_or_null("/root/ResourceManager")
	if not popularity_manager or not resource_manager:
		return

	var population = resource_manager.get_resource("population")
	var consumption_per_peasant = popularity_manager.get_food_consumption_per_peasant()
	var total_consumption = population * consumption_per_peasant

	# Apply food consumption (consume from available food types)
	# Prefer preserved_food (longer shelf life), then bread, then regular food
	var food_types = ["preserved_food", "bread", "food"]
	for food_type in food_types:
		var available = resource_manager.get_resource(food_type)
		if available > 0:
			var to_consume = min(total_consumption, available)
			resource_manager.consume_resource(food_type, to_consume, true)
			total_consumption -= to_consume
			if total_consumption <= 0:
				break

## Applies tax income based on tax level and population.
func apply_tax_income() -> void:
	var popularity_manager = get_node_or_null("/root/PopularityManager")
	var resource_manager = get_node_or_null("/root/ResourceManager")
	if not popularity_manager or not resource_manager:
		return

	var tax_income = popularity_manager.get_tax_income()
	if tax_income > 0:
		resource_manager.add_resource("gold", tax_income)

func _process(delta: float) -> void:
	"""Process upgrade timers and production chains"""
	_process_upgrade_timers(delta)
	
	# STRONGHOLD MECHANICS: Update food consumption and tax income periodically
	# Update every 10 seconds (matching PopularityManager update cycle)
	if not has_node("stronghold_timer"):
		var stronghold_timer = Timer.new()
		stronghold_timer.name = "stronghold_timer"
		stronghold_timer.wait_time = 10.0
		stronghold_timer.timeout.connect(_on_stronghold_update)
		stronghold_timer.autostart = true
		add_child(stronghold_timer)
	
	# Update idle peasant count for PopularityManager
	update_idle_peasant_count()

func _on_stronghold_update() -> void:
	"""Periodic update for Stronghold mechanics"""
	update_food_consumption()
	apply_tax_income()

## Updates idle peasant count for PopularityManager.
func update_idle_peasant_count() -> void:
	var popularity_manager = get_node_or_null("/root/PopularityManager")
	var villager_manager = get_node_or_null("/root/VillagerManager")
	var resource_manager = get_node_or_null("/root/ResourceManager")
	if not popularity_manager or not villager_manager or not resource_manager:
		return

	var total_population = int(resource_manager.get_resource("population"))
	var total_workers = 0
	
	# Count workers assigned to buildings
	for building_id in assigned_workers:
		total_workers += assigned_workers[building_id].size()
	
	# Also count villagers with jobs from JobSystem
	# JobSystem.job_assignments maps villager_id -> building_id
	# The size of this dictionary is the total number of villagers with jobs
	var job_system = get_node_or_null("/root/JobSystem")
	if job_system and "job_assignments" in job_system:
		var job_count = job_system.job_assignments.size()
		total_workers += job_count
	
	var idle_count = max(0, total_population - total_workers)
	PopularityManager.set_idle_peasant_count(idle_count)

func cleanup() -> void:
	"""Clean up all buildings and resources"""
	print("[BuildingManager] Cleaning up buildings...")

	# Remove all buildings
	for building_id in placed_buildings.keys():
		remove_building(building_id)

	# Clear data structures
	placed_buildings.clear()
	assigned_workers.clear()
	building_counter = 0

	# Stop the resource gathering timer
	if resource_timer and resource_timer.is_inside_tree():
		resource_timer.stop()

	print("[BuildingManager] Cleanup complete")
