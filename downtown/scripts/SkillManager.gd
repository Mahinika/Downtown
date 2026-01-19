extends Node

## SkillManager - Village-wide skill system inspired by Pixel Tribe
##
## Manages global efficiency bonuses that reduce task completion times across all villagers.
## Skills gain XP from villager work activities and can be upgraded with gold to increase bonuses.
## Provides a progression system that improves village productivity over time.
##
## Key Features:
## - XP-based skill progression from villager work
## - Gold-based skill upgrades for immediate bonuses
## - Efficiency multipliers that reduce task completion times
## - Save/load functionality for persistent progression
## - Pixel Tribe-inspired balancing (2.5% efficiency per level)
##
## Usage:
##   SkillManager.add_skill_xp(SkillManager.SkillType.WOODWORKING, 3.0)
##   var efficiency = SkillManager.get_skill_efficiency_bonus(SkillManager.SkillType.WOODWORKING)

## Emitted when a skill reaches a new level.
## Parameters: skill_type (int), new_level (int)
signal skill_leveled_up(skill_type: int, new_level: int)

## Emitted when a skill gains XP.
## Parameters: skill_type (int), xp_amount (float)
signal skill_xp_gained(skill_type: int, xp_amount: float)

## Enumeration of all available skill types.
enum SkillType {
	CONSTRUCTION,    # Building construction and placement
	WOODWORKING,     # Lumberjack and wood processing tasks
	MINING,          # Miner and stone processing tasks
	FARMING,         # Farmer and crop harvesting tasks
	COOKING,         # Food processing and cooking tasks
	GATHERING        # General resource gathering (fire pit, etc.)
}

## Skill registry: skill_type (int) -> skill_data (Dictionary).
## Contains level, XP, and efficiency data for each skill.
var skills: Dictionary = {}

## XP rates per task completion for each skill type.
## Determines how much XP villagers gain when completing tasks.
var skill_xp_rates: Dictionary = {
	SkillType.CONSTRUCTION: 5.0,   # XP per construction task
	SkillType.WOODWORKING: 3.0,    # XP per woodworking task
	SkillType.MINING: 4.0,         # XP per mining task
	SkillType.FARMING: 2.0,        # XP per farming task
	SkillType.COOKING: 6.0,        # XP per cooking task
	SkillType.GATHERING: 1.0       # XP per gathering task
}

## Base gold cost for the first skill upgrade.
const BASE_UPGRADE_COST: int = 50

## Multiplier applied to upgrade cost for each skill level.
const UPGRADE_COST_MULTIPLIER: float = 1.5

## Base XP required to reach level 2 from level 1.
const BASE_XP_FOR_LEVEL_2: float = 100.0

## XP requirement multiplier for each subsequent level.
const XP_MULTIPLIER_PER_LEVEL: float = 1.1

## Efficiency bonus percentage per skill level (2.5% per level).
const EFFICIENCY_PER_LEVEL: float = 0.025

## Helper function to safely access ResourceManager autoload
func _get_resource_manager():
	if has_method("get_node_or_null"):
		return get_node_or_null("/root/ResourceManager")
	return null

func _ready():
	_initialize_skills()

func _initialize_skills():
	# Initialize all skills with default values
	for skill_type in SkillType.values():
		skills[skill_type] = {
			"level": 1,
			"xp": 0.0,
			"xp_to_next": BASE_XP_FOR_LEVEL_2,
			"efficiency_bonus": 0.0,
			"name": _get_skill_name(skill_type),
			"description": _get_skill_description(skill_type)
		}

func add_skill_xp(skill_type: int, xp_amount: float):
	if not skills.has(skill_type):
		push_warning("SkillManager: Unknown skill type " + str(skill_type))
		return

	skills[skill_type]["xp"] += xp_amount
	emit_signal("skill_xp_gained", skill_type, xp_amount)

	# Check for level up
	_check_level_up(skill_type)

func _check_level_up(skill_type: int):
	var skill = skills[skill_type]
	while skill["xp"] >= skill["xp_to_next"] and skill["level"] < 50:  # Max level 50
		skill["xp"] -= skill["xp_to_next"]
		skill["level"] += 1

		# Update efficiency bonus
		skill["efficiency_bonus"] = (skill["level"] - 1) * EFFICIENCY_PER_LEVEL

		# Calculate XP needed for next level
		skill["xp_to_next"] = BASE_XP_FOR_LEVEL_2 * pow(XP_MULTIPLIER_PER_LEVEL, skill["level"] - 1)

		emit_signal("skill_leveled_up", skill_type, skill["level"])

func get_skill_efficiency_bonus(skill_type: int) -> float:
	if not skills.has(skill_type):
		return 0.0
	return skills[skill_type]["efficiency_bonus"]

func get_skill_level(skill_type: int) -> int:
	if not skills.has(skill_type):
		return 1
	return skills[skill_type]["level"]

func get_skill_xp(skill_type: int) -> float:
	if not skills.has(skill_type):
		return 0.0
	return skills[skill_type]["xp"]

func get_skill_xp_to_next(skill_type: int) -> float:
	if not skills.has(skill_type):
		return BASE_XP_FOR_LEVEL_2
	return skills[skill_type]["xp_to_next"]

func get_upgrade_cost(skill_type: int) -> int:
	if not skills.has(skill_type):
		return BASE_UPGRADE_COST

	var level = skills[skill_type]["level"]
	return int(BASE_UPGRADE_COST * pow(UPGRADE_COST_MULTIPLIER, level - 1))

func can_upgrade_skill(skill_type: int) -> bool:
	if not skills.has(skill_type):
		return false

	var cost = get_upgrade_cost(skill_type)
	var resource_manager = _get_resource_manager()
	return resource_manager and resource_manager.get_resource_amount("gold") >= cost

func upgrade_skill(skill_type: int) -> bool:
	if not can_upgrade_skill(skill_type):
		return false

	var cost = get_upgrade_cost(skill_type)
	var resource_manager = _get_resource_manager()
	if resource_manager and resource_manager.consume_resource("gold", cost):
		# Directly increase efficiency (alternative to XP-based leveling)
		var skill = skills[skill_type]
		skill["level"] += 1
		skill["efficiency_bonus"] = (skill["level"] - 1) * EFFICIENCY_PER_LEVEL
		emit_signal("skill_leveled_up", skill_type, skill["level"])
		return true

	return false

func get_task_time_modifier(job_type: int) -> float:
	# Map job types to skill types and return efficiency modifier
	var skill_type = _map_job_to_skill(job_type)
	var efficiency_bonus = get_skill_efficiency_bonus(skill_type)

	# Pixel Tribe formula: new_time = old_time ÷ (1 + efficiency_bonus)
	# Return the divisor (time reduction factor)
	return 1.0 + efficiency_bonus

func _map_job_to_skill(job_type: int) -> int:
	# Map VillagerManager job types to SkillManager skill types
	match job_type:
		0: return SkillType.WOODWORKING  # LUMBERJACK
		1: return SkillType.MINING       # MINER
		2: return SkillType.FARMING      # FARMER
		3: return SkillType.CONSTRUCTION # ENGINEER
		4: return SkillType.FARMING      # MILLER (processes agricultural products)
		5: return SkillType.COOKING      # SMOKER (food preservation)
		6: return SkillType.COOKING      # BREWER (beverage production)
		7: return SkillType.MINING       # BLACKSMITH (metal/stone working)
		_: return SkillType.GATHERING    # Default to gathering

func _get_skill_name(skill_type: int) -> String:
	match skill_type:
		SkillType.CONSTRUCTION: return "Construction"
		SkillType.WOODWORKING: return "Woodworking"
		SkillType.MINING: return "Mining"
		SkillType.FARMING: return "Farming"
		SkillType.COOKING: return "Cooking"
		SkillType.GATHERING: return "Gathering"
		_: return "Unknown Skill"

func _get_skill_description(skill_type: int) -> String:
	match skill_type:
		SkillType.CONSTRUCTION: return "Improves building construction speed and quality"
		SkillType.WOODWORKING: return "Increases lumberjack efficiency and wood processing"
		SkillType.MINING: return "Enhances miner productivity and stone gathering"
		SkillType.FARMING: return "Boosts farmer output and crop yields"
		SkillType.COOKING: return "Improves food processing and cooking efficiency"
		SkillType.GATHERING: return "Increases general resource gathering speed"
		_: return "Unknown skill description"

func get_all_skills() -> Dictionary:
	return skills.duplicate(true)

# Save/Load functionality
func get_save_data() -> Dictionary:
	return {
		"skills": skills.duplicate(true)
	}

func load_save_data(data: Dictionary):
	if data.has("skills"):
		skills = data["skills"].duplicate(true)
	else:
		_initialize_skills()  # Fallback to defaults
