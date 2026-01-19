extends Node

## SaveManager - Handles game state persistence

## Helper function to safely access ResourceManager autoload
func _get_resource_manager():
	if has_method("get_node_or_null"):
		return get_node_or_null("/root/ResourceManager")
	return null
##
## Singleton Autoload that manages saving and loading of complete game states.
## Serializes all game data including resources, buildings, villagers, and progression
## to JSON files for cross-session persistence.
##
## Key Features:
## - Complete game state serialization/deserialization
## - Save file management and listing
## - Automatic directory creation
## - Error handling and validation
## - Timestamp tracking for save files
##
## Usage:
##   SaveManager.save_game("my_save")
##   SaveManager.load_game("my_save")

## Emitted when a game save is completed successfully.
## Parameters: save_name (String)
signal game_saved(save_name: String)

## Emitted when a game load is completed successfully.
## Parameters: save_name (String)
signal game_loaded(save_name: String)

## Directory path where save files are stored.
const SAVE_DIRECTORY: String = "user://saves/"

## File extension for save files.
const SAVE_EXTENSION: String = ".save"

func _ready() -> void:
	print("[SaveManager] Initialized")
	ensure_save_directory()

func ensure_save_directory() -> void:
	# Create saves directory if it doesn't exist
	if not DirAccess.dir_exists_absolute(SAVE_DIRECTORY):
		DirAccess.make_dir_recursive_absolute(SAVE_DIRECTORY)

func save_game(save_name: String = "autosave") -> bool:
	# Validate input
	if save_name.is_empty():
		push_warning("[SaveManager] Empty save name, using default")
		save_name = "autosave"
	
	var save_path = SAVE_DIRECTORY + save_name + SAVE_EXTENSION
	
	var save_data = {
		"version": "1.0",
		"timestamp": Time.get_unix_time_from_system(),
		"resources": get_resources_data(),
		"buildings": get_buildings_data(),
		"building_levels": get_building_levels_data(),
		"villagers": get_villagers_data(),
		"resource_nodes": get_resource_nodes_data(),
		"skills": get_skills_data(),
		"progression": get_progression_data(),
		"research": get_research_data(),
		"seasonal": get_seasonal_data(),
		"job_assignments": get_job_assignments_data()
	}
	
	var file = FileAccess.open(save_path, FileAccess.WRITE)
	if not file:
		push_error("[SaveManager] Failed to open save file: " + save_path)
		return false
	
	var json_string = JSON.stringify(save_data)
	file.store_string(json_string)
	file.close()
	
	game_saved.emit(save_name)
	print("[SaveManager] Game saved: ", save_name)
	return true

func load_game(save_name: String = "autosave") -> bool:
	# Validate input
	if save_name.is_empty():
		push_warning("[SaveManager] Empty save name, using default")
		save_name = "autosave"
	
	var save_path = SAVE_DIRECTORY + save_name + SAVE_EXTENSION
	
	if not FileAccess.file_exists(save_path):
		push_error("[SaveManager] Save file not found: " + save_path)
		return false
	
	var file = FileAccess.open(save_path, FileAccess.READ)
	if not file:
		push_error("[SaveManager] Failed to open save file: " + save_path)
		return false
	
	var content = file.get_as_text()
	file.close()
	
	var json = JSON.new()
	var error = json.parse(content)
	if error != OK:
		push_error("[SaveManager] Failed to parse save file: ", json.get_error_message())
		return false
	
	var save_data = json.data
	
	# Load game state (order matters - resources first, then buildings, then villagers, then systems)
	load_resources_data(save_data.get("resources", {}))
	load_building_levels_data(save_data.get("building_levels", {}))
	load_buildings_data(save_data.get("buildings", {}), save_data.get("building_levels", {}))
	load_resource_nodes_data(save_data.get("resource_nodes", {}))
	load_progression_data(save_data.get("progression", {}))  # Load before villagers (affects unlocks)
	load_research_data(save_data.get("research", {}))  # Load before villagers (affects unlocks)
	load_villagers_data(save_data.get("villagers", {}))
	load_skills_data(save_data.get("skills", {}))
	load_seasonal_data(save_data.get("seasonal", {}))
	load_job_assignments_data(save_data.get("job_assignments", {}))  # Load last (requires villagers and buildings)
	
	game_loaded.emit(save_name)
	print("[SaveManager] Game loaded: ", save_name)
	return true

func get_resources_data() -> Dictionary:
	if not ResourceManager:
		return {}
	
	var resource_manager = _get_resource_manager()
	if not resource_manager:
		return {}

	var resources = {}
	var all_resources = resource_manager.get_all_resources()
	for resource_id in all_resources:
		resources[resource_id] = {
			"amount": resource_manager.get_resource(resource_id),
			"capacity": resource_manager.get_storage_capacity(resource_id)
		}
	return resources

func get_buildings_data() -> Dictionary:
	if not BuildingManager:
		return {}
	
	var buildings = {}
	var all_buildings = BuildingManager.get_all_buildings()
	for building_id in all_buildings:
		var building = all_buildings[building_id]
		var grid_pos = building.get("grid_position", Vector2i.ZERO)
		buildings[building_id] = {
			"building_type_id": building.get("building_type_id", ""),
			"grid_position": [grid_pos.x, grid_pos.y]  # Convert Vector2i to array for JSON
		}
	return buildings

func get_villagers_data() -> Dictionary:
	var world = GameServices.get_world()
	if not world:
		return {}

	var villagers = {}
	var all_villagers = world.get_all_villagers()
	for villager_id in all_villagers:
		var villager = world.get_villager(villager_id) if world else null
		if villager and is_instance_valid(villager):
			# Get job assignment building_id from JobSystem
			var building_id = ""
			if JobSystem and JobSystem.job_assignments.has(villager_id):
				building_id = JobSystem.job_assignments[villager_id]
			
			var pos = villager.position
			villagers[villager_id] = {
				"position": [pos.x, pos.y],  # Convert Vector2 to array for JSON
				"job_type": villager.job_type,
				"building_id": building_id
			}
	return villagers

func get_resource_nodes_data() -> Dictionary:
	if not ResourceNodeManager:
		return {}
	
	var nodes = {}
	var all_nodes = ResourceNodeManager.resource_nodes
	for node_id in all_nodes:
		var node_data = all_nodes[node_id]
		var grid_pos = node_data.get("grid_position", Vector2i.ZERO)
		nodes[node_id] = {
			"type": node_data.get("type_name", ""),
			"grid_position": [grid_pos.x, grid_pos.y],  # Convert Vector2i to array for JSON
			"remaining_amount": node_data.get("remaining_amount", 0.0)
		}
	return nodes

func get_building_levels_data() -> Dictionary:
	if not BuildingManager:
		return {}
	return BuildingManager.building_levels.duplicate(true)

func get_skills_data() -> Dictionary:
	if not SkillManager:
		return {}
	return SkillManager.get_save_data()

func load_building_levels_data(data: Dictionary) -> void:
	if not BuildingManager:
		return
	BuildingManager.building_levels = data.duplicate(true)

func load_resources_data(data: Dictionary) -> void:
	if not ResourceManager:
		return
	
	var resource_manager = _get_resource_manager()
	if not resource_manager:
		return

	for resource_id in data:
		var resource_info = data[resource_id]
		resource_manager.set_resource(resource_id, resource_info.get("amount", 0.0))
		resource_manager.set_storage_capacity(resource_id, resource_info.get("capacity", resource_manager.DEFAULT_STORAGE_CAPACITY))

func load_buildings_data(data: Dictionary, building_levels_data: Dictionary = {}) -> void:
	"""Load buildings from save data"""
	if not BuildingManager:
		return
	
	# Clear existing buildings and visuals first
	# Get all existing buildings and remove them
	var all_buildings = BuildingManager.get_all_buildings()
	for existing_id in all_buildings:
		BuildingManager.remove_building(existing_id)
	
	# Place saved buildings
	for building_id in data:
		var building_info = data[building_id]
		var building_type_id = building_info.get("building_type_id", "")
		var grid_pos_data = building_info.get("grid_position", [0, 0])
		# Convert array back to Vector2i
		var grid_position = Vector2i(grid_pos_data[0] if grid_pos_data is Array and grid_pos_data.size() >= 2 else 0, 
									  grid_pos_data[1] if grid_pos_data is Array and grid_pos_data.size() >= 2 else 0)
		
		if building_type_id.is_empty():
			push_warning("[SaveManager] Empty building type ID for building: ", building_id)
			continue
		
		# Place building via BuildingManager
		var new_building_id = BuildingManager.place_building(building_type_id, grid_position)
		if new_building_id.is_empty():
			push_warning("[SaveManager] Failed to place building: ", building_type_id, " at ", grid_position)
			continue
		
		# Restore building level if available
		if building_levels_data.has(building_id):
			var level = building_levels_data[building_id]
			if BuildingManager.has_method("set_building_level"):
				BuildingManager.set_building_level(new_building_id, level)
			else:
				# Fallback: set directly in building_levels dictionary
				BuildingManager.building_levels[new_building_id] = level
		
		print("[SaveManager] Loaded building: ", building_type_id, " at ", grid_position, " (level: ", building_levels_data.get(building_id, 1), ")")
	
	# Request visual recreation from main scene
	# This will be handled by the main scene's load handler via signal

func load_villagers_data(data: Dictionary) -> void:
	"""Load villagers from save data"""
	var world = GameServices.get_world()
	if not world:
		return

	# Clear existing villagers first
	var all_villagers = world.get_all_villagers()
	for villager_id in all_villagers:
		world.remove_villager(villager_id)
	
	# Spawn saved villagers
	for villager_id in data:
		var villager_info = data[villager_id]
		var pos_data = villager_info.get("position", [0, 0])
		# Convert array back to Vector2
		var position = Vector2(pos_data[0] if pos_data is Array and pos_data.size() >= 2 else 0.0,
								pos_data[1] if pos_data is Array and pos_data.size() >= 2 else 0.0)
		var job_type = villager_info.get("job_type", -1)
		var building_id = villager_info.get("building_id", "")
		
		# Spawn villager
		var new_villager_id = world.spawn_villager(position)
		if new_villager_id.is_empty():
			push_warning("[SaveManager] Failed to spawn villager at ", position)
			continue

		# Restore job assignment if available
		if job_type >= 0:
			var villager = world.get_villager(new_villager_id)
			if villager and is_instance_valid(villager):
				villager.assign_job(job_type)
		
		# Assign to building if building_id is provided
		if not building_id.is_empty() and JobSystem:
			# Get job type string from building
			var building = BuildingManager.get_building(building_id)
			if building:
				var building_data = building.get("building_data", {})
				var effects = building_data.get("effects", {})
				var job_type_str = effects.get("workplace", "")
				if not job_type_str.is_empty():
					JobSystem.assign_villager_to_building(new_villager_id, building_id, job_type_str)
		
		print("[SaveManager] Loaded villager: ", new_villager_id, " at ", position)

func load_resource_nodes_data(data: Dictionary) -> void:
	"""Load resource nodes from save data"""
	if not ResourceNodeManager:
		return
	
	# Clear existing nodes first
	var all_nodes = ResourceNodeManager.resource_nodes.duplicate()
	for node_id in all_nodes:
		ResourceNodeManager.remove_node(node_id)
	
	# Place saved nodes
	for node_id in data:
		var node_info = data[node_id]
		var node_type_str = node_info.get("type", "")
		var grid_pos_data = node_info.get("grid_position", [0, 0])
		# Convert array back to Vector2i
		var grid_position = Vector2i(grid_pos_data[0] if grid_pos_data is Array and grid_pos_data.size() >= 2 else 0,
									   grid_pos_data[1] if grid_pos_data is Array and grid_pos_data.size() >= 2 else 0)
		var remaining_amount = node_info.get("remaining_amount", 0.0)
		
		if node_type_str.is_empty():
			push_warning("[SaveManager] Empty node type for node: ", node_id)
			continue
		
		# Map string type to ResourceNodeType enum
		var node_type = ResourceNodeManager.ResourceNodeType.TREE
		match node_type_str.to_lower():
			"tree":
				node_type = ResourceNodeManager.ResourceNodeType.TREE
			"stone":
				node_type = ResourceNodeManager.ResourceNodeType.STONE
			"berry_bush":
				node_type = ResourceNodeManager.ResourceNodeType.BERRY_BUSH
			_:
				push_warning("[SaveManager] Unknown node type: ", node_type_str)
				continue
		
		# Place node
		var new_node_id = ResourceNodeManager.place_resource_node(node_type, grid_position, remaining_amount)
		if new_node_id.is_empty():
			push_warning("[SaveManager] Failed to place node: ", node_type_str, " at ", grid_position)
			continue
		
		# Update remaining amount if different from default
		if ResourceNodeManager.resource_nodes.has(new_node_id):
			ResourceNodeManager.resource_nodes[new_node_id]["remaining_amount"] = remaining_amount
		
		print("[SaveManager] Loaded node: ", node_type_str, " at ", grid_position, " (remaining: ", remaining_amount, ")")

func load_skills_data(data: Dictionary) -> void:
	if not SkillManager:
		return
	SkillManager.load_save_data(data)

func get_progression_data() -> Dictionary:
	"""Get progression system data (goals, achievements, unlocks)"""
	if not ProgressionSystem:
		return {}

	return {
		"completed_goals": ProgressionSystem.completed_goals.duplicate(),
		"unlocked_buildings": ProgressionSystem.unlocked_buildings.duplicate(),
		"favorite_buildings": ProgressionSystem.favorite_buildings.duplicate(),
		"goals": ProgressionSystem.goals.duplicate(true),  # Deep copy to preserve goal progress
		"achievements": ProgressionSystem.achievements.duplicate(true)
	}

func load_progression_data(data: Dictionary) -> void:
	"""Load progression system data"""
	if not ProgressionSystem:
		return

	if data.has("completed_goals"):
		ProgressionSystem.completed_goals = data["completed_goals"].duplicate()

	if data.has("unlocked_buildings"):
		ProgressionSystem.unlocked_buildings = data["unlocked_buildings"].duplicate()

	if data.has("favorite_buildings"):
		ProgressionSystem.favorite_buildings = data["favorite_buildings"].duplicate()

	if data.has("goals"):
		ProgressionSystem.goals = data["goals"].duplicate(true)

	if data.has("achievements"):
		ProgressionSystem.achievements = data["achievements"].duplicate(true)
	
	print("[SaveManager] Loaded progression data")

func get_research_data() -> Dictionary:
	"""Get research system data (completed research, active research, unlocks)"""
	if not ResearchManager:
		return {}
	
	return {
		"completed_research": ResearchManager.completed_research.duplicate(),
		"unlocked_technologies": ResearchManager.unlocked_technologies.duplicate(),
		"active_research": ResearchManager.active_research.duplicate(true),  # Deep copy for progress data
		"available_research": ResearchManager.available_research.duplicate(true)  # Preserve completion status
	}

func load_research_data(data: Dictionary) -> void:
	"""Load research system data"""
	if not ResearchManager:
		return
	
	if data.has("completed_research"):
		ResearchManager.completed_research = data["completed_research"].duplicate()
	
	if data.has("unlocked_technologies"):
		ResearchManager.unlocked_technologies = data["unlocked_technologies"].duplicate()
	
	if data.has("active_research"):
		ResearchManager.active_research = data["active_research"].duplicate(true)
	
	if data.has("available_research"):
		# Merge with existing available_research to preserve structure
		for research_id in data["available_research"]:
			if ResearchManager.available_research.has(research_id):
				# Update completion status
				var saved_data = data["available_research"][research_id]
				ResearchManager.available_research[research_id]["completed"] = saved_data.get("completed", false)
	
	print("[SaveManager] Loaded research data")

func get_seasonal_data() -> Dictionary:
	"""Get seasonal system data (current season, weather, day count)"""
	if not SeasonalManager:
		return {}
	
	return {
		"current_season": SeasonalManager.current_season,
		"current_weather": SeasonalManager.current_weather,
		"day_count": SeasonalManager.day_count,
		"season_day": SeasonalManager.season_day,
		"weather_timer": SeasonalManager.weather_timer
	}

func load_seasonal_data(data: Dictionary) -> void:
	"""Load seasonal system data"""
	if not SeasonalManager:
		return
	
	if data.has("current_season"):
		SeasonalManager.current_season = data["current_season"]
	
	if data.has("current_weather"):
		SeasonalManager.current_weather = data["current_weather"]
	
	if data.has("day_count"):
		SeasonalManager.day_count = data["day_count"]
	
	if data.has("season_day"):
		SeasonalManager.season_day = data["season_day"]
	
	if data.has("weather_timer"):
		SeasonalManager.weather_timer = data["weather_timer"]
	
	print("[SaveManager] Loaded seasonal data")

func get_job_assignments_data() -> Dictionary:
	"""Get job assignment data (villager -> building mappings)"""
	if not JobSystem:
		return {}
	
	return JobSystem.job_assignments.duplicate()

func load_job_assignments_data(data: Dictionary) -> void:
	"""Load job assignment data and reassign villagers"""
	var world = GameServices.get_world()
	if not JobSystem or not world:
		return
	
	# Clear existing assignments first
	for villager_id in JobSystem.job_assignments.keys():
		JobSystem.unassign_villager(villager_id)
	
	# Restore job assignments
	for villager_id in data.keys():
		var building_id = data[villager_id]
		if building_id.is_empty():
			continue
		
		# Verify villager and building still exist
		var villager = world.get_villager(villager_id)
		if not villager or not is_instance_valid(villager):
			continue
		
		var building = BuildingManager.get_building(building_id)
		if not building:
			continue
		
		# Get job type from building
		var building_data = building.get("building_data", {})
		var effects = building_data.get("effects", {})
		var job_type = effects.get("workplace", "")
		
		if not job_type.is_empty():
			JobSystem.assign_villager_to_building(villager_id, building_id, job_type)
	
	print("[SaveManager] Loaded job assignments data")

func list_saves() -> Array[String]:
	var saves: Array[String] = []
	var dir = DirAccess.open(SAVE_DIRECTORY)
	if not dir:
		return saves
	
	dir.list_dir_begin()
	var file_name = dir.get_next()
	while file_name != "":
		if file_name.ends_with(SAVE_EXTENSION):
			var save_name = file_name.trim_suffix(SAVE_EXTENSION)
			saves.append(save_name)
		file_name = dir.get_next()
	
	return saves
