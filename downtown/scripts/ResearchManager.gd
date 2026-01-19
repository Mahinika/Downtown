extends Node

## ResearchManager - Manages research/technology system
##
## Singleton Autoload that handles research projects, technology unlocks, and
## research progress tracking. Provides a tech tree system where players can
## invest time and resources to unlock advanced buildings and improvements.
##
## Key Features:
## - Research project management with prerequisites
## - Time-based research progression
## - Technology unlock system
## - Building-based research bonuses
## - Save/load integration
##
## Usage:
##   ResearchManager.start_research("basic_tools")
##   var progress = ResearchManager.get_research_progress("basic_tools")

## Emitted when a research project is completed.
## Parameters: research_id (String)
signal research_completed(research_id: String)

## Emitted when a technology is unlocked through research.
## Parameters: tech_id (String)
signal technology_unlocked(tech_id: String)

## Available research registry: research_id (String) -> research_data (Dictionary).
## Contains all research projects with their costs, times, and unlocks.
var available_research: Dictionary = {}

## List of completed research project IDs.
var completed_research: Array[String] = []

## List of unlocked technology IDs.
var unlocked_technologies: Array[String] = []

## Active research tracking: research_id (String) -> progress_data (Dictionary).
## Contains ongoing research projects with their progress and timing.
var active_research: Dictionary = {}

## Base research speed multiplier.
var base_research_rate: float = 1.0

## Combined research speed bonuses from buildings.
var current_research_bonuses: float = 1.0

## Helper function to safely access ResourceManager autoload
func _get_resource_manager():
	if has_method("get_node_or_null"):
		return get_node_or_null("/root/ResourceManager")
	return null

func _ready() -> void:
	print("[ResearchManager] Initialized")
	initialize_research()

func initialize_research() -> void:
	# Basic research available from start
	available_research["basic_tools"] = {
		"id": "basic_tools",
		"name": "Basic Tools",
		"description": "Improve tool making efficiency",
		"cost": {"wood": 50, "stone": 30},
		"time_required": 60.0,  # seconds
		"unlocks": ["tool_workshop"],
		"completed": false
	}
	
	available_research["woodworking"] = {
		"id": "woodworking",
		"name": "Woodworking",
		"description": "Advanced wood processing techniques",
		"cost": {"wood": 100, "stone": 50},
		"time_required": 120.0,
		"unlocks": ["lumber_hut"],
		"completed": false,
		"requires": ["basic_tools"]
	}
	
	available_research["mining"] = {
		"id": "mining",
		"name": "Mining",
		"description": "Stone extraction techniques",
		"cost": {"wood": 80, "stone": 100},
		"time_required": 90.0,
		"unlocks": ["stone_quarry"],
		"completed": false,
		"requires": ["basic_tools"]
	}
	
	available_research["agriculture"] = {
		"id": "agriculture",
		"name": "Agriculture",
		"description": "Farming and crop cultivation",
		"cost": {"wood": 100, "food": 50},
		"time_required": 150.0,
		"unlocks": ["farm"],
		"completed": false,
		"requires": ["woodworking"]
	}

func can_start_research(research_id: String) -> bool:
	# Validate input
	if research_id.is_empty():
		push_warning("[ResearchManager] Empty research ID")
		return false
	
	if not available_research.has(research_id):
		return false
	
	if research_id in completed_research:
		return false
	
	var research = available_research[research_id]
	
	# Check requirements
	var requires = research.get("requires", [])
	for req_id in requires:
		if req_id.is_empty():
			continue
		if req_id not in completed_research:
			return false
	
	# Check cost
	var cost = research.get("cost", {})
	var resource_manager = _get_resource_manager()
	if not resource_manager or not resource_manager.can_afford(cost):
		return false
	
	return true


func complete_research(research_id: String) -> void:
	# Validate input
	if research_id.is_empty():
		push_warning("[ResearchManager] Empty research ID")
		return
	
	if not available_research.has(research_id):
		return
	
	var research = available_research[research_id]
	research["completed"] = true
	research["in_progress"] = false
	completed_research.append(research_id)
	
	# Unlock technologies
	var unlocks = research.get("unlocks", [])
	for tech_id in unlocks:
		unlock_technology(tech_id)
	
	research_completed.emit(research_id)
	print("[ResearchManager] Research completed: ", research.get("name", research_id))

func unlock_technology(tech_id: String) -> void:
	# Validate input
	if tech_id.is_empty():
		push_warning("[ResearchManager] Empty technology ID")
		return
	
	if tech_id in unlocked_technologies:
		return
	
	unlocked_technologies.append(tech_id)
	technology_unlocked.emit(tech_id)
	print("[ResearchManager] Technology unlocked: ", tech_id)

func is_technology_unlocked(tech_id: String) -> bool:
	return tech_id in unlocked_technologies

func start_research(research_id: String) -> bool:
	"""Start a research project"""
	if research_id in active_research:
		print("[ResearchManager] Research already active: ", research_id)
		return false

	if not available_research.has(research_id):
		print("[ResearchManager] Unknown research: ", research_id)
		return false

	var research = available_research[research_id]

	# Check prerequisites
	if research.has("requires"):
		for req in research.get("requires", []):
			if req not in completed_research:
				print("[ResearchManager] Prerequisite not met: ", req)
				return false

	# Check cost
	var cost = research.get("cost", {})
	var resource_manager = _get_resource_manager()
	if not resource_manager or not resource_manager.can_afford(cost):
		print("[ResearchManager] Cannot afford research cost")
		return false

	# Pay cost
	resource_manager.pay_costs(cost)

	# Start research
	active_research[research_id] = {
		"progress": 0.0,
		"total_time": research.get("time_required", 60.0),
		"start_time": Time.get_unix_time_from_system()
	}

	print("[ResearchManager] Started research: ", research.get("name", research_id))
	return true

func stop_research(research_id: String) -> void:
	"""Stop an active research project"""
	if research_id in active_research:
		active_research.erase(research_id)
		print("[ResearchManager] Stopped research: ", research_id)

func get_research_progress(research_id: String) -> float:
	"""Get progress percentage (0-1) for a research project"""
	if research_id in active_research:
		var progress_data = active_research[research_id]
		return progress_data.progress / progress_data.total_time
	return 0.0

func get_research_time_remaining(research_id: String) -> float:
	"""Get remaining time in seconds for a research project"""
	if research_id in active_research:
		var progress_data = active_research[research_id]
		return progress_data.total_time - progress_data.progress
	return 0.0

func update_research_bonuses() -> void:
	"""Update research speed bonuses from buildings"""
	current_research_bonuses = 1.0

	if not BuildingManager:
		return

	# Check for Advanced Workshop buildings
	var workshops = BuildingManager.get_buildings_of_type("advanced_workshop")
	for workshop_id in workshops:
		var building_data = BuildingManager.get_building_data(workshop_id)
		if building_data and building_data.has("effects"):
			var effects = building_data.effects
			if effects.has("research_bonus"):
				var bonus = effects.get("research_bonus", 1.0)
				current_research_bonuses *= bonus

	print("[ResearchManager] Research bonuses updated: ", current_research_bonuses)

func update_research(delta: float) -> void:
	"""Update active research progress"""
	if active_research.is_empty():
		return

	var total_speed = base_research_rate * current_research_bonuses

	for research_id in active_research.keys():
		var progress_data = active_research[research_id]
		progress_data.progress += delta * total_speed

		# Check if completed
		if progress_data.progress >= progress_data.total_time:
			complete_research(research_id)

func get_available_research() -> Array:
	"""Get list of research that can be started"""
	var available = []

	for research_id in available_research.keys():
		var research = available_research[research_id]
		if research.get("completed", false):
			continue

		if research_id in active_research:
			continue

		# Check prerequisites
		var can_start = true
		if research.has("requires"):
			for req in research.get("requires", []):
				if req not in completed_research:
					can_start = false
					break

		if can_start:
			available.append(research_id)

	return available

func get_active_research() -> Array:
	"""Get list of currently active research"""
	return active_research.keys()

func get_completed_research() -> Array:
	"""Get list of completed research"""
	return completed_research.duplicate()

func _process(delta: float) -> void:
	update_research(delta)
