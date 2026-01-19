extends Node

## ProgressionManager - Manages goals, achievements, and unlocks
##
## Singleton Autoload that handles player progression through goals, achievements,
## and building unlocks. Provides a structured advancement system that guides
## the player through the game's content.
##
## Key Features:
## - Goal completion tracking with prerequisites
## - Achievement system for milestones
## - Building unlock progression
## - Favorite building tracking
## - Resource-based goal validation
##
## Usage:
##   ProgressionManager.check_goal_progress("first_hut")
##   var unlocked = ProgressionManager.is_building_unlocked("lumber_hut")

## Emitted when a goal is completed.
## Parameters: goal_id (String)
signal goal_completed(goal_id: String)

## Emitted when a building is unlocked through progression.
## Parameters: building_id (String)
signal building_unlocked(building_id: String)

## Goal registry: goal_id (String) -> goal_data (Dictionary).
## Contains all available goals with their requirements and rewards.
var goals: Dictionary = {}

## Achievement registry: achievement_id (String) -> achievement_data (Dictionary).
## Contains all available achievements and their completion status.
var achievements: Dictionary = {}

## List of building IDs that are currently unlocked for construction.
var unlocked_buildings: Array[String] = []

## List of goal IDs that have been completed.
var completed_goals: Array[String] = []

## List of building IDs that the player has favorited.
var favorite_buildings: Array[String] = []

## Helper function to safely access ResourceManager autoload
func _get_resource_manager():
	if has_method("get_node_or_null"):
		return get_node_or_null("/root/ResourceManager")
	return null

func _ready() -> void:
	print("[ProgressionManager] Initialized")
	initialize_progression()

func initialize_progression() -> void:
	# Start with basic buildings unlocked
	unlocked_buildings = ["hut", "fire_pit", "storage_pit", "tool_workshop", "lumber_hut", "stockpile", "stone_quarry", "farm"]
	
	# Initialize goals
	create_initial_goals()
	
	# Initialize achievements
	create_initial_achievements()

func create_initial_goals() -> void:
	# Goal: Build first hut
	goals["first_hut"] = {
		"id": "first_hut",
		"name": "First Home",
		"description": "Build your first hut",
		"type": "build_building",
		"target": "hut",
		"target_count": 1,
		"current_count": 0,
		"reward": {"unlock": "tool_workshop"},
		"completed": false
	}
	
	# Goal: Harvest 100 wood
	goals["harvest_100_wood"] = {
		"id": "harvest_100_wood",
		"name": "Wood Gatherer",
		"description": "Harvest 100 wood",
		"type": "harvest_resource",
		"target": "wood",
		"target_amount": 100.0,
		"current_amount": 0.0,
		"reward": {"unlock": "lumber_hut"},
		"completed": false
	}
	
	# Goal: Reach 20 population
	goals["reach_20_population"] = {
		"id": "reach_20_population",
		"name": "Growing Village",
		"description": "Reach 20 population",
		"type": "reach_population",
		"target": 20,
		"current": 0,
		"reward": {"unlock": "stockpile"},
		"completed": false
	}
	
	# Goal: Build lumber hut
	goals["build_lumber_hut"] = {
		"id": "build_lumber_hut",
		"name": "Lumber Industry",
		"description": "Build a lumber hut",
		"type": "build_building",
		"target": "lumber_hut",
		"target_count": 1,
		"current_count": 0,
		"reward": {"unlock": "stone_quarry"},
		"completed": false
	}
	
	# Goal: Harvest 50 stone
	goals["harvest_50_stone"] = {
		"id": "harvest_50_stone",
		"name": "Stone Worker",
		"description": "Harvest 50 stone",
		"type": "harvest_resource",
		"target": "stone",
		"target_amount": 50.0,
		"current_amount": 0.0,
		"reward": {"unlock": "farm"},
		"completed": false
	}

	# Advanced building unlock goals
	goals["reach_50_population"] = {
		"id": "reach_50_population",
		"name": "Growing Settlement",
		"description": "Reach 50 population",
		"type": "reach_population",
		"target": 50,
		"current": 0,
		"reward": {"unlock": "well"},
		"completed": false
	}

	goals["build_research_center"] = {
		"id": "build_research_center",
		"name": "Knowledge Seekers",
		"description": "Build a research center",
		"type": "complete_research",
		"target": "basic_tools",
		"reward": {"unlock": "market"},
		"completed": false
	}

	goals["accumulate_200_gold"] = {
		"id": "accumulate_200_gold",
		"name": "Wealth Builder",
		"description": "Accumulate 200 gold through trade",
		"type": "accumulate_resource",
		"target": "gold",
		"target_amount": 200.0,
		"current_amount": 0.0,
		"reward": {"unlock": "shrine"},
		"completed": false
	}

	goals["research_technology"] = {
		"id": "research_technology",
		"name": "Technological Advancement",
		"description": "Complete advanced research",
		"type": "complete_research",
		"target": "agriculture",
		"reward": {"unlock": "advanced_workshop"},
		"completed": false
	}

func create_initial_achievements() -> void:
	achievements["first_building"] = {
		"id": "first_building",
		"name": "Builder",
		"description": "Build your first building",
		"completed": false
	}
	
	achievements["first_villager"] = {
		"id": "first_villager",
		"name": "Community Leader",
		"description": "Have your first villager",
		"completed": false
	}
	
	achievements["harvest_master"] = {
		"id": "harvest_master",
		"name": "Harvest Master",
		"description": "Harvest 500 total resources",
		"completed": false
	}

func check_goal_progress(goal_id: String) -> void:
	# Validate input
	if goal_id.is_empty():
		push_warning("[ProgressionManager] Empty goal ID")
		return
	
	if not goals.has(goal_id) or goals[goal_id].get("completed", false):
		return
	
	var goal = goals[goal_id]
	var goal_type = goal.get("type", "")
	
	match goal_type:
		"build_building":
			var building_type = goal.get("target", "")
			if BuildingManager:
				var current_count = BuildingManager.get_buildings_of_type(building_type).size()
				goal["current_count"] = current_count
				
				if current_count >= goal.get("target_count", 1):
					complete_goal(goal_id)
			else:
				push_warning("[ProgressionManager] BuildingManager not available")
		
		"harvest_resource":
			# Tracked separately via resource_changed signal
			pass
		
		"reach_population":
			var resource_manager = _get_resource_manager()
			if resource_manager:
				var current_pop = resource_manager.get_resource("population")
				goal["current"] = int(current_pop)

				if current_pop >= goal.get("target", 0):
					complete_goal(goal_id)

		"accumulate_resource":
			var resource_manager = _get_resource_manager()
			if resource_manager:
				var current_amount = resource_manager.get_resource(goal.get("target", ""))
				goal["current_amount"] = current_amount

				if current_amount >= goal.get("target_amount", 0.0):
					complete_goal(goal_id)

		"complete_research":
			if ResearchManager:
				var research_id = goal.get("target", "")
				if ResearchManager and research_id in ResearchManager.completed_research:
					complete_goal(goal_id)

func complete_goal(goal_id: String) -> void:
	# Validate input
	if goal_id.is_empty():
		push_warning("[ProgressionManager] Empty goal ID")
		return
	
	if not goals.has(goal_id):
		return
	
	var goal = goals[goal_id]
	if goal.get("completed", false):
		return
	
	goal["completed"] = true
	completed_goals.append(goal_id)
	
	# Apply reward
	var reward = goal.get("reward", {})
	if reward.has("unlock"):
		unlock_building(reward["unlock"])
	
	goal_completed.emit(goal_id)
	print("[ProgressionManager] Goal completed: ", goal.get("name", goal_id))

func unlock_building(building_id: String) -> void:
	# Validate input
	if building_id.is_empty():
		push_warning("[ProgressionManager] Empty building ID")
		return
	
	if building_id in unlocked_buildings:
		return
	
	unlocked_buildings.append(building_id)
	building_unlocked.emit(building_id)
	print("[ProgressionManager] Building unlocked: ", building_id)

func toggle_favorite_building(building_id: String) -> void:
	"""Toggle favorite status for a building"""
	if building_id.is_empty():
		push_warning("[ProgressionManager] Empty building ID")
		return
	
	if building_id in favorite_buildings:
		favorite_buildings.erase(building_id)
	else:
		favorite_buildings.append(building_id)
	
	print("[ProgressionManager] Building favorite toggled: ", building_id, " (favorited: ", building_id in favorite_buildings, ")")

func is_building_favorite(building_id: String) -> bool:
	"""Check if a building is favorited"""
	if building_id.is_empty():
		return false
	return building_id in favorite_buildings

func get_favorite_buildings() -> Array:
	"""Get list of favorited building IDs"""
	return favorite_buildings.duplicate()

func is_building_unlocked(building_id: String) -> bool:
	# Validate input
	if building_id.is_empty():
		return false
	
	return building_id in unlocked_buildings

func get_active_goals() -> Array:
	var active: Array = []
	for goal_id in goals:
		var goal = goals[goal_id]
		if not goal.get("completed", false):
			active.append(goal)
	return active

func update_resource_harvest_goal(resource_id: String, amount: float) -> void:
	# Update harvest goals for this resource
	for goal_id in goals:
		var goal = goals[goal_id]
		if goal.get("type") == "harvest_resource" and goal.get("target") == resource_id:
			if not goal.get("completed", false):
				var current = goal.get("current_amount", 0.0)
				goal["current_amount"] = current + amount
				
				if goal["current_amount"] >= goal.get("target_amount", 0.0):
					complete_goal(goal_id)
