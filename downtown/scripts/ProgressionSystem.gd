class_name ProgressionSystemClass
extends Node

## ProgressionSystem - Unified progression management system
##
## Consolidates ProgressionManager, ResearchManager, and SkillManager functionality
## into a single, cohesive progression management system.
##
## Key Features:
## - Goal completion tracking and rewards
## - Research technology progression
## - Villager skill development
## - Achievement system
## - Building unlocks
##
## Usage:
##   var progression = ProgressionSystem.new()
##   progression.start_research("advanced_tools")
##   var unlocked = progression.is_building_unlocked("advanced_workshop")

# Emitted when a goal is completed
signal goal_completed(goal_id: String)

# Emitted when a building is unlocked
signal building_unlocked(building_id: String)

# Emitted when research is completed
signal research_completed(research_id: String)

# Emitted when a villager levels up a skill
signal skill_leveled_up(villager_id: String, skill_name: String, new_level: int)

# Goal definitions: goal_id -> goal_data
var goals: Dictionary = {}

# Completed goals
var completed_goals: Array[String] = []

# Unlocked buildings
var unlocked_buildings: Array[String] = []

# Favorite buildings (requested by UI/Save system)
var favorite_buildings: Array[String] = []

# Achievements (requested by UI/Save system)
var achievements: Dictionary = {}

# Research data: research_id -> research_data
var research_projects: Dictionary = {}

# Active research: research_id -> progress (0.0 to 1.0)
var active_research: Dictionary = {}

# Villager skills: villager_id -> {skill_name: level}
var villager_skills: Dictionary = {}

# Research timer
var research_timer: Timer

func _ready() -> void:
	print("[ProgressionSystem] Initializing progression management system")
	initialize_default_unlocks()
	load_goals()
	load_research()
	initialize_research_timer()

func _process(delta: float) -> void:
	"""Process research progress"""
	process_research_progress(delta)

func initialize_default_unlocks() -> void:
	"""Initialize default building unlocks"""
	unlocked_buildings = [
		"hut", "fire_pit", "storage_pit", "tool_workshop",
		"lumber_hut", "stockpile", "stone_quarry", "farm"
	]
	print("[ProgressionSystem] Initialized with ", unlocked_buildings.size(), " default building unlocks")

func load_goals() -> void:
	"""Load goal definitions"""
	goals = {
		"reach_20_population": {
			"id": "reach_20_population",
			"name": "Growing Village",
			"description": "Reach 20 population",
			"type": "population",
			"target": 20,
			"reward": {"unlock": "house"}
		},
		"reach_50_population": {
			"id": "reach_50_population",
			"name": "Growing Settlement",
			"description": "Reach 50 population",
			"type": "population",
			"target": 50,
			"reward": {"unlock": "market"}
		},
		"build_10_huts": {
			"id": "build_10_huts",
			"name": "Housing Expansion",
			"description": "Build 10 huts",
			"type": "building_count",
			"building_type": "hut",
			"target": 10,
			"reward": {"unlock": "advanced_workshop"}
		}
	}
	print("[ProgressionSystem] Loaded ", goals.size(), " goals")

func load_research() -> void:
	"""Load research project definitions"""
	research_projects = {
		"advanced_tools": {
			"id": "advanced_tools",
			"name": "Advanced Tools",
			"description": "Unlock advanced tool crafting",
			"cost": {"gold": 100, "wood": 50},
			"time": 300,  # seconds
			"requirements": [],
			"unlocks": ["blacksmith"]
		},
		"agriculture": {
			"id": "agriculture",
			"name": "Agriculture",
			"description": "Improve farming techniques",
			"cost": {"gold": 150, "wood": 30},
			"time": 450,
			"requirements": ["reach_20_population"],
			"unlocks": ["bakery"]
		}
	}
	print("[ProgressionSystem] Loaded ", research_projects.size(), " research projects")

func initialize_research_timer() -> void:
	"""Initialize research processing timer"""
	research_timer = Timer.new()
	research_timer.wait_time = 1.0  # Process every second
	research_timer.timeout.connect(_on_research_tick)
	add_child(research_timer)
	research_timer.start()

func _on_research_tick() -> void:
	"""Process research progress"""
	process_research_progress(1.0)

func process_research_progress(delta: float) -> void:
	"""Update active research progress"""
	for research_id in active_research.keys():
		var current_progress = active_research[research_id]
		var research_data = research_projects[research_id]
		var total_time = research_data.time

		current_progress += delta / total_time
		active_research[research_id] = current_progress

		if current_progress >= 1.0:
			complete_research(research_id)

func start_research(research_id: String) -> bool:
	"""Start a research project"""
	if not research_projects.has(research_id):
		push_error("[ProgressionSystem] Unknown research: ", research_id)
		return false

	if active_research.has(research_id):
		push_warning("[ProgressionSystem] Research already in progress: ", research_id)
		return false

	# Check requirements
	var research_data = research_projects[research_id]
	if not check_research_requirements(research_data):
		return false

	# Check costs
	if not can_afford_research(research_data):
		return false

	# Pay costs
	pay_research_costs(research_data)

	# Start research
	active_research[research_id] = 0.0
	print("[ProgressionSystem] Started research: ", research_id)

	return true

func complete_research(research_id: String) -> void:
	"""Complete a research project"""
	if not active_research.has(research_id):
		return

	active_research.erase(research_id)

	# Apply unlocks
	var research_data = research_projects[research_id]
	var unlocks = research_data.get("unlocks", [])
	for unlock_id in unlocks:
		unlock_building(unlock_id)

	research_completed.emit(research_id)
	print("[ProgressionSystem] Completed research: ", research_id)

func check_research_requirements(research_data: Dictionary) -> bool:
	"""Check if research requirements are met"""
	var requirements = research_data.get("requirements", [])
	for requirement in requirements:
		if requirement.begins_with("reach_"):
			# Population requirement
			var target_pop = requirement.split("_")[1].to_int()
			var current_pop = get_current_population()
			if current_pop < target_pop:
				return false
		elif not completed_goals.has(requirement):
			return false
	return true

func can_afford_research(research_data: Dictionary) -> bool:
	"""Check if research costs can be afforded"""
	var costs = research_data.get("cost", {})
	var economy_system = get_node_or_null("/root/EconomySystem")
	if not economy_system:
		return false
	return economy_system.can_afford(costs)

func pay_research_costs(research_data: Dictionary) -> bool:
	"""Pay research costs"""
	var costs = research_data.get("cost", {})
	var economy_system = get_node_or_null("/root/EconomySystem")
	if not economy_system:
		return false
	return economy_system.pay_costs(costs)

func unlock_building(building_id: String) -> void:
	"""Unlock a building for construction"""
	if building_id in unlocked_buildings:
		return

	unlocked_buildings.append(building_id)
	building_unlocked.emit(building_id)
	print("[ProgressionSystem] Building unlocked: ", building_id)

func is_building_unlocked(building_id: String) -> bool:
	"""Check if a building is unlocked"""
	return building_id in unlocked_buildings

func check_goal_completion(goal_id: String) -> bool:
	"""Check if a goal is completed"""
	if completed_goals.has(goal_id):
		return true

	var goal = goals.get(goal_id, {})
	if goal.is_empty():
		return false

	var goal_type = goal.get("type", "")
	match goal_type:
		"population":
			var target = goal.get("target", 0)
			var current = get_current_population()
			if current >= target:
				complete_goal(goal_id)
				return true
		"building_count":
			var building_type = goal.get("building_type", "")
			var target = goal.get("target", 0)
			var current = get_building_count(building_type)
			if current >= target:
				complete_goal(goal_id)
				return true

	return false

func complete_goal(goal_id: String) -> void:
	"""Complete a goal and apply rewards"""
	if completed_goals.has(goal_id):
		return

	completed_goals.append(goal_id)

	# Apply rewards
	var goal = goals[goal_id]
	var reward = goal.get("reward", {})
	if reward.has("unlock"):
		unlock_building(reward.unlock)

	goal_completed.emit(goal_id)
	print("[ProgressionSystem] Goal completed: ", goal_id)

func get_current_population() -> int:
	"""Get current population count"""
	var economy_system = get_node_or_null("/root/EconomySystem")
	if economy_system:
		return int(economy_system.get_resource("population"))
	return 0

func get_building_count(building_type: String) -> int:
	"""Get count of buildings of a specific type"""
	var game_world = get_node_or_null("/root/GameWorld")
	if not game_world:
		return 0

	var count = 0
	var buildings = game_world.get_all_buildings()
	for building_id in buildings:
		var building = buildings[building_id]
		if building.get("type", "") == building_type:
			count += 1
	return count

func get_villager_skill_level(villager_id: String, skill_name: String) -> int:
	"""Get skill level for a villager"""
	var villager_skills_dict = villager_skills.get(villager_id, {})
	return villager_skills_dict.get(skill_name, 0)

func increase_skill_level(villager_id: String, skill_name: String, amount: int = 1) -> void:
	"""Increase a villager's skill level"""
	if not villager_skills.has(villager_id):
		villager_skills[villager_id] = {}

	var current_level = get_villager_skill_level(villager_id, skill_name)
	var new_level = current_level + amount

	villager_skills[villager_id][skill_name] = new_level
	skill_leveled_up.emit(villager_id, skill_name, new_level)

	print("[ProgressionSystem] ", villager_id, " leveled up ", skill_name, " to level ", new_level)

func get_active_goals() -> Array:
	"""Get list of active (uncompleted) goals"""
	var active = []
	for goal_id in goals:
		if not completed_goals.has(goal_id):
			active.append(goal_id)
	return active

func get_completed_goals() -> Array:
	"""Get list of completed goals"""
	return completed_goals.duplicate()

func get_unlocked_buildings() -> Array:
	"""Get list of unlocked buildings"""
	return unlocked_buildings.duplicate()

func is_building_favorite(building_id: String) -> bool:
	return building_id in favorite_buildings

func toggle_favorite_building(building_id: String) -> void:
	if building_id in favorite_buildings:
		favorite_buildings.erase(building_id)
	else:
		favorite_buildings.append(building_id)
