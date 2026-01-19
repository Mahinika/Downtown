class_name PersistenceSystemClass
extends Node

## PersistenceSystem - Unified persistence management system
signal game_saved(save_name: String)

# Emitted when a game is successfully loaded
signal game_loaded(save_name: String)

# Data cache: filename -> data
var data_cache: Dictionary = {}

# Save directory
const SAVE_DIR = "user://saves/"
const SAVE_EXTENSION = ".sav"

func _ready() -> void:
	print("[PersistenceSystem] Initializing persistence management system")
	ensure_save_directory_exists()

func ensure_save_directory_exists() -> void:
	"""Ensure the save directory exists"""
	var dir = DirAccess.open("user://")
	if not dir.dir_exists("saves"):
		dir.make_dir("saves")
		print("[PersistenceSystem] Created saves directory")

func get_data(filename: String) -> Dictionary:
	"""Load data from a JSON file"""
	if data_cache.has(filename):
		return data_cache[filename]

	var filepath = "res://data/" + filename + ".json"
	if not FileAccess.file_exists(filepath):
		push_error("[PersistenceSystem] Data file not found: ", filepath)
		return {}

	var file = FileAccess.open(filepath, FileAccess.READ)
	if not file:
		push_error("[PersistenceSystem] Failed to open data file: ", filepath)
		return {}

	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(json_text)
	if error != OK:
		push_error("[PersistenceSystem] Failed to parse JSON in ", filepath, ": ", json.get_error_message())
		return {}

	var data = json.get_data()
	data_cache[filename] = data
	print("[PersistenceSystem] Loaded data from ", filename)

	return data

func save_game(save_name: String) -> bool:
	"""Save the current game state"""
	var save_data = collect_save_data()
	var save_path = SAVE_DIR + save_name + SAVE_EXTENSION

	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if not file:
		push_error("[PersistenceSystem] Failed to create save file: ", save_path)
		return false

	var json_text = JSON.stringify(save_data, "\t")
	file.store_string(json_text)
	file.close()

	game_saved.emit(save_name)
	print("[PersistenceSystem] Game saved: ", save_name)

	return true

func load_game(save_name: String) -> bool:
	"""Load a saved game state"""
	var save_path = SAVE_DIR + save_name + SAVE_EXTENSION

	if not FileAccess.file_exists(save_path):
		push_error("[PersistenceSystem] Save file not found: ", save_path)
		return false

	var file = FileAccess.open(save_path, FileAccess.READ)
	if not file:
		push_error("[PersistenceSystem] Failed to open save file: ", save_path)
		return false

	var json_text = file.get_as_text()
	file.close()

	var json = JSON.new()
	var error = json.parse(json_text)
	if error != OK:
		push_error("[PersistenceSystem] Failed to parse save file: ", json.get_error_message())
		return false

	var save_data = json.get_data()
	if not apply_save_data(save_data):
		push_error("[PersistenceSystem] Failed to apply save data")
		return false

	game_loaded.emit(save_name)
	print("[PersistenceSystem] Game loaded: ", save_name)

	return true

func collect_save_data() -> Dictionary:
	"""Collect all game data for saving"""
	var save_data = {
		"version": "1.0",
		"timestamp": Time.get_unix_time_from_system(),
		"resources": {},
		"buildings": {},
		"building_levels": {},
		"villagers": {},
		"job_assignments": {},
		"research": {},
		"progression": {},
		"seasonal": {},
		"skills": {}
	}

	# Collect data from all systems
	var economy_system = get_node_or_null("/root/EconomySystem")
	if economy_system:
		save_data.resources = get_resources_data(economy_system)

	var game_world = get_node_or_null("/root/GameWorld")
	if game_world:
		save_data.buildings = get_buildings_data(game_world)
		save_data.villagers = get_villagers_data(game_world)

	var progression_system = get_node_or_null("/root/ProgressionSystem")
	if progression_system:
		save_data.progression = get_progression_data(progression_system)
		save_data.research = get_research_data(progression_system)

	var world_simulation = get_node_or_null("/root/WorldSimulation")
	if world_simulation:
		save_data.seasonal = get_seasonal_data(world_simulation)

	return save_data

func apply_save_data(save_data: Dictionary) -> bool:
	"""Apply loaded save data to all systems"""
	# Apply data in correct order (dependencies)

	# 1. Resources
	var economy_system = get_node_or_null("/root/EconomySystem")
	if economy_system and save_data.has("resources"):
		if not apply_resources_data(save_data.resources, economy_system):
			return false

	# 2. Progression (unlocks buildings)
	var progression_system = get_node_or_null("/root/ProgressionSystem")
	if progression_system:
		if save_data.has("progression"):
			if not apply_progression_data(save_data.progression, progression_system):
				return false
		if save_data.has("research"):
			if not apply_research_data(save_data.research, progression_system):
				return false

	# 3. Buildings
	var game_world = get_node_or_null("/root/GameWorld")
	if game_world and save_data.has("buildings"):
		if not apply_buildings_data(save_data.buildings, game_world):
			return false

	# 4. Villagers (after buildings for job assignment)
	if game_world and save_data.has("villagers"):
		if not apply_villagers_data(save_data.villagers, game_world):
			return false

	# 5. Job assignments (requires villagers and buildings)
	if save_data.has("job_assignments"):
		if not apply_job_assignments_data(save_data.job_assignments):
			return false

	# 6. Skills
	if save_data.has("skills"):
		if not apply_skills_data(save_data.skills):
			return false

	# 7. Seasonal data
	var world_simulation = get_node_or_null("/root/WorldSimulation")
	if world_simulation and save_data.has("seasonal"):
		if not apply_seasonal_data(save_data.seasonal, world_simulation):
			return false

	return true

func get_resources_data(economy_system: Node) -> Dictionary:
	"""Collect resources data for saving"""
	var resources = {}
	var all_resources = economy_system.get_all_resources()
	for resource_id in all_resources:
		resources[resource_id] = {
			"amount": economy_system.get_resource(resource_id),
			"capacity": economy_system.get_storage_capacity(resource_id)
		}
	return resources

func get_buildings_data(game_world: Node) -> Dictionary:
	"""Collect buildings data for saving"""
	var buildings = {}
	var all_buildings = game_world.get_all_buildings()
	for building_id in all_buildings:
		var building = all_buildings[building_id]
		var grid_pos = building.grid_position
		buildings[building_id] = {
			"building_type_id": building.building_type_id,
			"grid_position": [grid_pos.x, grid_pos.y]
		}
	return buildings

func get_villagers_data(game_world: Node) -> Dictionary:
	"""Collect villagers data for saving"""
	var villagers = {}
	var all_villagers = game_world.get_all_villagers()
	for villager_id in all_villagers:
		var villager = all_villagers[villager_id]
		if villager and is_instance_valid(villager):
			var pos = villager.position
			villagers[villager_id] = {
				"position": [pos.x, pos.y]
			}
	return villagers

func get_progression_data(progression_system: Node) -> Dictionary:
	"""Collect progression data for saving"""
	return {
		"completed_goals": progression_system.get_completed_goals(),
		"unlocked_buildings": progression_system.get_unlocked_buildings()
	}

func get_research_data(progression_system: Node) -> Dictionary:
	"""Collect research data for saving"""
	return {
		"active_research": progression_system.active_research.duplicate(),
		"completed_research": []  # Would need to track this in ProgressionSystem
	}

func get_seasonal_data(world_simulation: Node) -> Dictionary:
	"""Collect seasonal data for saving"""
	return {
		"current_season": world_simulation.current_season,
		"current_weather": world_simulation.current_weather,
		"popularity": world_simulation.popularity
	}

func apply_resources_data(data: Dictionary, economy_system: Node) -> bool:
	"""Apply resources data from save"""
	for resource_id in data:
		var resource_data = data[resource_id]
		economy_system.set_resource(resource_id, resource_data.get("amount", 0.0))
	return true

func apply_buildings_data(data: Dictionary, game_world: Node) -> bool:
	"""Apply buildings data from save"""
	for building_id in data:
		var building_data = data[building_id]
		var building_type_id = building_data.get("building_type_id", "")
		var grid_pos_data = building_data.get("grid_position", [0, 0])
		var grid_position = Vector2i(grid_pos_data[0], grid_pos_data[1])

		var new_building_id = game_world.place_building(building_type_id, grid_position)
		if new_building_id.is_empty():
			push_warning("[PersistenceSystem] Failed to place building ", building_type_id)
	return true

func apply_villagers_data(data: Dictionary, game_world: Node) -> bool:
	"""Apply villagers data from save"""
	for villager_id in data:
		var villager_data = data[villager_id]
		var pos_data = villager_data.get("position", [0, 0])
		var position = Vector2(pos_data[0], pos_data[1])

		var new_villager_id = game_world.spawn_villager(position)
		if new_villager_id.is_empty():
			push_warning("[PersistenceSystem] Failed to spawn villager at ", position)
	return true

func apply_progression_data(data: Dictionary, progression_system: Node) -> bool:
	"""Apply progression data from save"""
	if data.has("completed_goals"):
		progression_system.completed_goals = data.completed_goals.duplicate()
	if data.has("unlocked_buildings"):
		progression_system.unlocked_buildings = data.unlocked_buildings.duplicate()
	return true

func apply_research_data(data: Dictionary, progression_system: Node) -> bool:
	"""Apply research data from save"""
	if data.has("active_research"):
		progression_system.active_research = data.active_research.duplicate()
	return true

func apply_seasonal_data(data: Dictionary, world_simulation: Node) -> bool:
	"""Apply seasonal data from save"""
	if data.has("current_season"):
		world_simulation.current_season = data.current_season
	if data.has("current_weather"):
		world_simulation.current_weather = data.current_weather
	if data.has("popularity"):
		world_simulation.popularity = data.popularity
	return true

func apply_job_assignments_data(data: Dictionary) -> bool:
	"""Apply job assignments data from save"""
	var economy_system = get_node_or_null("/root/EconomySystem")
	if not economy_system:
		return false

	for villager_id in data:
		var building_id = data[villager_id]
		# This would need to determine job type from building
		# For now, assume default job type
		economy_system.assign_worker(villager_id, building_id, "default")
	return true

func apply_skills_data(data: Dictionary) -> bool:
	"""Apply skills data from save"""
	# This would need to be implemented in ProgressionSystem
	return true

func list_saves() -> Array[String]:
	"""List all available save files"""
	var saves = []
	var dir = DirAccess.open(SAVE_DIR)
	if dir:
		dir.list_dir_begin()
		var filename = dir.get_next()
		while filename != "":
			if filename.ends_with(SAVE_EXTENSION):
				saves.append(filename.trim_suffix(SAVE_EXTENSION))
			filename = dir.get_next()
	return saves

func delete_save(save_name: String) -> bool:
	"""Delete a save file"""
	var save_path = SAVE_DIR + save_name + SAVE_EXTENSION
	if FileAccess.file_exists(save_path):
		var dir = DirAccess.open("user://")
		dir.remove(save_path)
		return true
	return false