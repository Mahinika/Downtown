extends Node

## GameController - High-level game coordination
##
## Manages the overall game flow, initialization, and coordination
## between different game systems. Acts as the main entry point.
##
## Key Features:
## - Game initialization and setup
## - System coordination and event routing
## - Save/load coordination
## - High-level game state management

class_name GameController

# Game state
enum GameState { INITIALIZING, RUNNING, PAUSED, GAME_OVER }
var current_state: GameState = GameState.INITIALIZING

# References to core systems
var world: GameWorld = null
var economy: EconomySystem = null
var progression: ProgressionSystem = null
var simulation: WorldSimulation = null
var persistence: PersistenceSystem = null
var ui: UIManager = null

func _ready() -> void:
	print("[GameController] Initializing game controller")
	initialize_systems()
	setup_event_connections()
	initialize_game()

func initialize_systems() -> void:
	"""Initialize all game systems"""
	print("[GameController] Initializing systems...")

	# Get service references
	var services = get_node_or_null("/root/GameServices")
	if not services:
		push_error("[GameController] GameServices not found!")
		return

	world = GameServices.get_world()
	economy = GameServices.get_economy()
	progression = GameServices.get_progression()
	simulation = GameServices.get_simulation()
	persistence = GameServices.get_persistence()
	ui = GameServices.get_ui()

	if not validate_systems():
		push_error("[GameController] System validation failed!")
		return

	print("[GameController] All systems initialized")

func validate_systems() -> bool:
	"""Validate that all required systems are available"""
	var systems = [world, economy, progression, simulation, persistence, ui]
	for system in systems:
		if not system:
			push_error("[GameController] System not available: ", system)
			return false
	return true

func setup_event_connections() -> void:
	"""Set up event connections between systems"""

	# Population growth events
	if simulation and progression:
		simulation.population_growth.connect(_on_population_growth)
		simulation.population_decline.connect(_on_population_decline)

	# Save/load events
	if persistence:
		persistence.game_saved.connect(_on_game_saved)
		persistence.game_loaded.connect(_on_game_loaded)

	# Building events
	if world and economy:
		world.building_placed.connect(_on_building_placed)
		world.building_removed.connect(_on_building_removed)

	# Research events
	if progression:
		progression.research_completed.connect(_on_research_completed)
		progression.building_unlocked.connect(_on_building_unlocked)

	print("[GameController] Event connections established")

func initialize_game() -> void:
	"""Initialize the game world and start gameplay"""
	print("[GameController] Starting game initialization...")

	# Load building types
	load_building_types()

	# Generate world
	generate_world()

	# Spawn initial villagers
	spawn_initial_villagers()

	# Start simulation
	current_state = GameState.RUNNING
	print("[GameController] Game initialization complete")

func load_building_types() -> void:
	"""Load building type definitions"""
	if not world:
		return

	# Building types are loaded automatically by GameWorld
	# Additional initialization can be added here
	pass

func generate_world() -> void:
	"""Generate the initial game world"""
	if not world:
		return

	# World generation is handled by GameWorld
	# Additional world generation logic can be added here
	print("[GameController] World generation complete")

func spawn_initial_villagers() -> void:
	"""Spawn the initial set of villagers"""
	if not world:
		return

	# Determine spawn location (center of grid)
	var grid_size = Vector2i(50, 50)  # Default grid size
	var center_grid = grid_size / 2
	var center_pos = Vector2(center_grid.x * 32, center_grid.y * 32)  # Assuming 32px tiles

	# Spawn initial villagers
	for i in range(3):
		var offset = Vector2(randf_range(-50, 50), randf_range(-50, 50))
		var spawn_pos = center_pos + offset
		var villager_id = world.spawn_villager(spawn_pos)
		if villager_id:
			print("[GameController] Spawned initial villager: ", villager_id)

func _on_population_growth(amount: float) -> void:
	"""Handle population growth events"""
	print("[GameController] Population grew by ", amount)

	# Spawn visual villagers to match the growth
	if world and economy:
		var current_population = economy.get_resource("population")
		var current_visual_count = world.get_all_villagers().size()
		var villagers_to_spawn = int(current_population) - current_visual_count

		if villagers_to_spawn > 0:
			# Find spawn locations near existing villagers
			var spawn_positions = []
			var existing_villagers = world.get_all_villagers()

			if existing_villagers.size() > 0:
				for villager_id in existing_villagers:
					var villager = existing_villagers[villager_id]
					if villager and is_instance_valid(villager):
						spawn_positions.append(villager.position + Vector2(randf_range(-100, 100), randf_range(-100, 100)))
			else:
				# Fallback to center
				spawn_positions.append(Vector2(500, 500))

			# Spawn the villagers
			for i in range(min(villagers_to_spawn, spawn_positions.size())):
				var spawn_pos = spawn_positions[i % spawn_positions.size()]
				var villager_id = world.spawn_villager(spawn_pos)
				if villager_id:
					print("[GameController] Spawned growth villager: ", villager_id)

func _on_population_decline(amount: float) -> void:
	"""Handle population decline events"""
	print("[GameController] Population declined by ", amount)

	# Remove visual villagers to match the decline
	if world and economy:
		var current_population = economy.get_resource("population")
		var current_visual_count = world.get_all_villagers().size()
		var villagers_to_remove = current_visual_count - int(current_population)

		if villagers_to_remove > 0:
			var villagers = world.get_all_villagers()
			var villager_ids = villagers.keys()

			# Remove excess villagers
			for i in range(min(villagers_to_remove, villager_ids.size())):
				var villager_id = villager_ids[i]
				if world.remove_villager(villager_id):
					print("[GameController] Removed villager due to decline: ", villager_id)

func _on_building_placed(building_id: String, position: Vector2i) -> void:
	"""Handle building placement events"""
	print("[GameController] Building placed: ", building_id, " at ", position)

	# Trigger immediate population growth check
	if simulation:
		simulation.update_population_growth()

func _on_building_removed(building_id: String) -> void:
	"""Handle building removal events"""
	print("[GameController] Building removed: ", building_id)

func _on_research_completed(research_id: String) -> void:
	"""Handle research completion events"""
	print("[GameController] Research completed: ", research_id)

	# Show notification
	if ui:
		ui.show_toast("Research completed: " + research_id, "success")

func _on_building_unlocked(building_id: String) -> void:
	"""Handle building unlock events"""
	print("[GameController] Building unlocked: ", building_id)

	# Show notification
	if ui:
		ui.show_toast("New building unlocked: " + building_id, "success")

func _on_game_saved(save_name: String) -> void:
	"""Handle game save events"""
	print("[GameController] Game saved: ", save_name)

	if ui:
		ui.show_toast("Game saved!", "success")

func _on_game_loaded(save_name: String) -> void:
	"""Handle game load events"""
	print("[GameController] Game loaded: ", save_name)

	# Synchronize population with loaded villagers
	if world and economy:
		var loaded_villager_count = world.get_all_villagers().size()
		economy.set_resource("population", float(loaded_villager_count))

	if ui:
		ui.show_toast("Game loaded!", "success")

func pause_game() -> void:
	"""Pause the game"""
	if current_state == GameState.RUNNING:
		current_state = GameState.PAUSED
		print("[GameController] Game paused")

func resume_game() -> void:
	"""Resume the game"""
	if current_state == GameState.PAUSED:
		current_state = GameState.RUNNING
		print("[GameController] Game resumed")

func get_game_state() -> GameState:
	"""Get current game state"""
	return current_state

func is_game_running() -> bool:
	"""Check if game is currently running"""
	return current_state == GameState.RUNNING