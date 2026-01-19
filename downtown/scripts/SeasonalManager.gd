extends Node

## SeasonalManager - Manages seasons, weather, and seasonal effects
##
## Singleton Autoload that handles seasonal gameplay mechanics including weather changes,
## resource availability modifiers, and seasonal events. Creates dynamic gameplay
## by making resource gathering and building efficiency vary by season and weather.
##
## Key Features:
## - Four-season cycle with different resource multipliers
## - Weather system with various conditions and effects
## - Seasonal events and challenges
## - Villager morale and health modifiers
## - Performance-optimized modifier caching
##
## Usage:
##   var food_modifier = SeasonalManager.get_resource_modifier("food")
##   var morale_modifier = SeasonalManager.get_villager_modifier("morale")

## Emitted when the season changes.
## Parameters: new_season (String), days_in_season (int)
signal season_changed(new_season: String, days_in_season: int)

## Emitted when the weather changes.
## Parameters: new_weather (String), severity (float)
signal weather_changed(new_weather: String, severity: float)

## Emitted when a seasonal event occurs.
## Parameters: event_type (String), data (Dictionary)
signal seasonal_event_triggered(event_type: String, data: Dictionary)

## Season enumeration.
enum Season {
	SPRING,
	SUMMER,
	AUTUMN,
	WINTER
}

## Weather condition enumeration.
enum Weather {
	CLEAR,
	CLOUDY,
	RAINY,
	STORM,
	SNOW,
	BLIZZARD,
	HEATWAVE,
	DROUGHT
}

## Number of days each season lasts.
const SEASON_LENGTH_DAYS = 30

## Real seconds per game day.
const DAY_LENGTH_SECONDS = 60.0

## Human-readable season names indexed by Season enum.
const SEASON_NAMES = ["Spring", "Summer", "Autumn", "Winter"]

## Human-readable weather names indexed by Weather enum.
const WEATHER_NAMES = ["Clear", "Cloudy", "Rainy", "Storm", "Snow", "Blizzard", "Heatwave", "Drought"]

## Current season (changes every 30 days).
var current_season: Season = Season.SPRING

## Current weather condition.
var current_weather: Weather = Weather.CLEAR

## Current day within the season (1-30).
var day_in_season: int = 1

## Total days elapsed since game start.
var total_days: int = 0

## Timer for tracking day progression.
var season_timer: float = 0.0

## Duration remaining for current weather condition.
var weather_duration: float = 0.0

## Severity of current weather (0.0 to 1.0).
var weather_severity: float = 0.0

## Seasonal and weather modifiers affecting gameplay.
var seasonal_modifiers = {
	"food_gathering": 1.0,
	"wood_gathering": 1.0,
	"stone_gathering": 1.0,
	"building_efficiency": 1.0,
	"villager_morale": 1.0,
	"villager_health": 1.0,
	"movement_speed": 1.0,
	"work_efficiency": 1.0
}

# Cached modifier values for performance (updated only on changes)
var _cached_villager_modifiers: Dictionary = {}
var _cache_dirty: bool = true

# Seasonal resource availability
var seasonal_resource_multipliers = {
	Season.SPRING: {
		"food": 1.2,    # Spring growth
		"wood": 0.8,    # Less wood available
		"stone": 1.0,   # Normal stone availability
	},
	Season.SUMMER: {
		"food": 1.5,    # Peak harvest season
		"wood": 1.0,    # Normal wood availability
		"stone": 1.0,   # Normal stone availability
	},
	Season.AUTUMN: {
		"food": 1.3,    # Second harvest
		"wood": 1.2,    # Trees preparing for winter
		"stone": 1.0,   # Normal stone availability
	},
	Season.WINTER: {
		"food": 0.5,    # Scarce food in winter
		"wood": 1.4,    # More wood gathering (firewood)
		"stone": 0.7,   # Harder to quarry in cold
	}
}

## Helper function to safely access ResourceManager autoload
func _get_resource_manager():
	if has_method("get_node_or_null"):
		return get_node_or_null("/root/ResourceManager")
	return null

func _ready() -> void:
	print("[SeasonalManager] Initialized - Starting in Spring")
	update_seasonal_modifiers()
	_update_villager_modifier_cache()  # Initialize cache
	start_new_weather()

func start_new_weather() -> void:
	"""Initialize weather at startup"""
	# Set initial weather based on season
	var weather_weights = get_seasonal_weather_weights()
	current_weather = select_weighted_weather(weather_weights)
	weather_duration = randf_range(300.0, 1800.0)  # 5-30 minutes
	weather_severity = randf_range(0.1, 1.0)
	
	print("[SeasonalManager] Initial weather: ", WEATHER_NAMES[current_weather])
	weather_changed.emit(WEATHER_NAMES[current_weather], weather_severity)
	
	# Apply initial weather effects
	apply_weather_effects()

func _process(delta: float) -> void:
	# Update season timer
	season_timer += delta
	if season_timer >= DAY_LENGTH_SECONDS:
		season_timer = 0.0
		advance_day()

	# Update weather duration
	if weather_duration > 0:
		weather_duration -= delta
		if weather_duration <= 0:
			change_weather()

	# Apply seasonal challenges
	apply_seasonal_challenges(delta)

func advance_day() -> void:
	day_in_season += 1
	total_days += 1

	# Check for season change
	if day_in_season > SEASON_LENGTH_DAYS:
		change_season()
	else:
		# Random chance for weather change (10% per day)
		if randf() < 0.1:
			change_weather()
		# Chance for seasonal events
		check_seasonal_events()

func change_season() -> void:
	var old_season = current_season
	current_season = ((current_season + 1) % 4) as Season
	day_in_season = 1

	print("[SeasonalManager] Season changed from ", SEASON_NAMES[old_season], " to ", SEASON_NAMES[current_season])
	update_seasonal_modifiers()
	season_changed.emit(SEASON_NAMES[current_season], SEASON_LENGTH_DAYS)

	# Season-specific events
	match current_season:
		Season.SPRING:
			trigger_seasonal_event("spring_thaw", {"description": "Ice melts, revealing new resources"})
		Season.SUMMER:
			trigger_seasonal_event("summer_solstice", {"description": "Longest day brings bountiful harvests"})
		Season.AUTUMN:
			trigger_seasonal_event("autumn_harvest", {"description": "Time to gather winter stores"})
		Season.WINTER:
			trigger_seasonal_event("winter_solstice", {"description": "Darkest time - prepare for survival"})

func change_weather() -> void:
	var old_weather = current_weather

	# Weather probabilities based on season
	var weather_weights = get_seasonal_weather_weights()
	current_weather = select_weighted_weather(weather_weights)
	weather_duration = randf_range(300.0, 1800.0)  # 5-30 minutes
	weather_severity = randf_range(0.1, 1.0)

	print("[SeasonalManager] Weather changed from ", WEATHER_NAMES[old_weather], " to ", WEATHER_NAMES[current_weather])
	weather_changed.emit(WEATHER_NAMES[current_weather], weather_severity)

	# Apply weather effects
	apply_weather_effects()

func get_seasonal_weather_weights() -> Array:
	# Return array of [Weather, weight] pairs based on current season
	match current_season:
		Season.SPRING:
			return [
				[Weather.CLEAR, 0.4],
				[Weather.CLOUDY, 0.3],
				[Weather.RAINY, 0.25],
				[Weather.STORM, 0.05]
			]
		Season.SUMMER:
			return [
				[Weather.CLEAR, 0.5],
				[Weather.CLOUDY, 0.2],
				[Weather.HEATWAVE, 0.2],
				[Weather.STORM, 0.1]
			]
		Season.AUTUMN:
			return [
				[Weather.CLEAR, 0.3],
				[Weather.CLOUDY, 0.3],
				[Weather.RAINY, 0.3],
				[Weather.STORM, 0.1]
			]
		Season.WINTER:
			return [
				[Weather.CLEAR, 0.3],
				[Weather.CLOUDY, 0.2],
				[Weather.SNOW, 0.3],
				[Weather.BLIZZARD, 0.2]
			]
	return [[Weather.CLEAR, 1.0]]

func select_weighted_weather(weights: Array) -> Weather:
	var total_weight = 0.0
	for weight_pair in weights:
		total_weight += weight_pair[1]

	var random_value = randf() * total_weight
	var current_weight = 0.0

	for weight_pair in weights:
		current_weight += weight_pair[1]
		if random_value <= current_weight:
			return weight_pair[0]

	return Weather.CLEAR

func update_seasonal_modifiers() -> void:
	# Update resource gathering modifiers
	var resource_mults = seasonal_resource_multipliers[current_season]
	for resource in resource_mults:
		match resource:
			"food":
				seasonal_modifiers.food_gathering = resource_mults[resource]
			"wood":
				seasonal_modifiers.wood_gathering = resource_mults[resource]
			"stone":
				seasonal_modifiers.stone_gathering = resource_mults[resource]

	# Season-specific modifiers
	match current_season:
		Season.SPRING:
			seasonal_modifiers.villager_morale = 1.1  # Hopeful spring
			seasonal_modifiers.building_efficiency = 1.0
		Season.SUMMER:
			seasonal_modifiers.villager_morale = 1.2  # Pleasant summer
			seasonal_modifiers.building_efficiency = 1.1  # Better working conditions
		Season.AUTUMN:
			seasonal_modifiers.villager_morale = 0.9  # Preparing for winter
			seasonal_modifiers.building_efficiency = 1.0
		Season.WINTER:
			seasonal_modifiers.villager_morale = 0.7  # Harsh winter conditions
			seasonal_modifiers.building_efficiency = 0.8  # Cold weather slows work
			seasonal_modifiers.villager_health = 0.9  # Winter health risks

	# Apply weather effects on top of seasonal modifiers
	apply_weather_effects()

	# Mark cache as dirty since modifiers changed
	_cache_dirty = true

func apply_weather_effects() -> void:
	# Reset weather modifiers
	seasonal_modifiers.movement_speed = 1.0
	seasonal_modifiers.work_efficiency = 1.0
	seasonal_modifiers.building_efficiency *= 1.0  # Don't reset, multiply

	match current_weather:
		Weather.RAINY:
			seasonal_modifiers.movement_speed = 0.8
			seasonal_modifiers.work_efficiency = 0.9
		Weather.STORM:
			seasonal_modifiers.movement_speed = 0.6
			seasonal_modifiers.work_efficiency = 0.7
			seasonal_modifiers.building_efficiency *= 0.8
		Weather.SNOW:
			seasonal_modifiers.movement_speed = 0.7
			seasonal_modifiers.work_efficiency = 0.8
		Weather.BLIZZARD:
			seasonal_modifiers.movement_speed = 0.5
			seasonal_modifiers.work_efficiency = 0.6
			seasonal_modifiers.building_efficiency *= 0.7
		Weather.HEATWAVE:
			seasonal_modifiers.work_efficiency = 0.8
			seasonal_modifiers.villager_health = 0.9
		Weather.DROUGHT:
			seasonal_modifiers.food_gathering *= 0.7
			seasonal_modifiers.work_efficiency = 0.9

func check_seasonal_events() -> void:
	# Random seasonal events
	var event_chance = 0.02  # 2% chance per day

	if randf() < event_chance:
		match current_season:
			Season.SPRING:
				if randf() < 0.5:
					trigger_seasonal_event("early_frost", {"description": "Unexpected frost damages crops", "food_penalty": 0.2})
				else:
					trigger_seasonal_event("abundant_rain", {"description": "Heavy rains boost plant growth", "food_bonus": 0.3})
			Season.SUMMER:
				if randf() < 0.3:
					trigger_seasonal_event("locust_swarm", {"description": "Locusts devour crops", "food_penalty": 0.4})
			Season.AUTUMN:
				if randf() < 0.4:
					trigger_seasonal_event("bountiful_harvest", {"description": "Exceptionally good harvest", "food_bonus": 0.5})
			Season.WINTER:
				if randf() < 0.6:
					trigger_seasonal_event("harsh_blizzard", {"description": "Severe blizzard reduces work efficiency", "efficiency_penalty": 0.5, "duration": 3})

func trigger_seasonal_event(event_type: String, data: Dictionary) -> void:
	print("[SeasonalManager] Seasonal event: ", event_type, " - ", data.get("description", ""))
	seasonal_event_triggered.emit(event_type, data)

	# Apply immediate effects
	if data.has("food_bonus"):
		seasonal_modifiers.food_gathering *= (1.0 + data.food_bonus)
	if data.has("food_penalty"):
		seasonal_modifiers.food_gathering *= (1.0 - data.food_penalty)
	if data.has("efficiency_penalty"):
		seasonal_modifiers.work_efficiency *= (1.0 - data.efficiency_penalty)

# Public API functions
func get_current_season_name() -> String:
	return SEASON_NAMES[current_season]

func get_current_weather_name() -> String:
	return WEATHER_NAMES[current_weather]

func get_season_progress() -> float:
	return float(day_in_season) / float(SEASON_LENGTH_DAYS)

func get_resource_modifier(resource_type: String) -> float:
	match resource_type:
		"food":
			return seasonal_modifiers.food_gathering
		"wood":
			return seasonal_modifiers.wood_gathering
		"stone":
			return seasonal_modifiers.stone_gathering
		_:
			return 1.0

func get_villager_modifier(modifier_type: String) -> float:
	# Update cache if dirty
	if _cache_dirty:
		_update_villager_modifier_cache()

	return _cached_villager_modifiers.get(modifier_type, 1.0)

func _update_villager_modifier_cache() -> void:
	"""Update cached villager modifiers for performance"""
	_cached_villager_modifiers = {
		"morale": seasonal_modifiers.villager_morale,
		"health": seasonal_modifiers.villager_health,
		"movement": seasonal_modifiers.movement_speed,
		"work": seasonal_modifiers.work_efficiency
	}
	_cache_dirty = false

func get_building_modifier() -> float:
	return seasonal_modifiers.building_efficiency

func is_harsh_weather() -> bool:
	return current_weather in [Weather.STORM, Weather.BLIZZARD, Weather.HEATWAVE]

func apply_seasonal_challenges(delta: float) -> void:
	"""Apply seasonal challenges and difficulties"""
	var resource_manager = _get_resource_manager()

	# Winter food consumption challenge
	if current_season == Season.WINTER and resource_manager:
		# Increased food consumption in winter (villagers eat more to stay warm)
		var winter_food_penalty = 0.2  # 20% more food consumption
		var food_consumption = winter_food_penalty * delta / DAY_LENGTH_SECONDS  # Per day rate
		resource_manager.consume_resource("food", food_consumption, true)

	# Summer building efficiency challenge is handled by seasonal modifiers
	# Autumn resource spoilage
	if current_season == Season.AUTUMN and resource_manager:
		# Chance of food spoilage in autumn
		var spoilage_chance = 0.001 * delta  # 0.1% chance per second
		if randf() < spoilage_chance:
			var food_amount = resource_manager.get_resource("food")
			if food_amount > 0:
				var spoilage_amount = min(food_amount * 0.05, 2.0)  # Up to 5% or 2 units
				resource_manager.consume_resource("food", spoilage_amount, true)
				seasonal_event_triggered.emit("food_spoilage", {
					"description": "Food spoiled in storage (" + String.num(spoilage_amount, 1) + " units lost)"
				})

	# Weather damage effects
	apply_weather_damage(delta)

func apply_weather_damage(delta: float) -> void:
	"""Apply weather-based damage to buildings and resources"""
	if not BuildingManager:
		return

	var damage_chance = 0.0
	var damage_description = ""

	match current_weather:
		Weather.STORM:
			damage_chance = 0.005 * delta  # 0.5% chance per second
			damage_description = "Storm damaged buildings"
		Weather.BLIZZARD:
			damage_chance = 0.003 * delta  # 0.3% chance per second
			damage_description = "Blizzard caused structural damage"
		Weather.HEATWAVE:
			damage_chance = 0.002 * delta  # 0.2% chance per second
			damage_description = "Heatwave caused material degradation"

	if damage_chance > 0 and randf() < damage_chance:
		# Find a random building to damage
		if not BuildingManager:
			return
		
		var all_buildings = BuildingManager.get_all_buildings()
		if all_buildings == null or all_buildings.is_empty():
			return
		
		# Get building IDs (keys) as an array and pick a random one
		# BuildingManager.get_all_buildings() returns Dictionary: building_id -> building_data
		var building_ids: Array = all_buildings.keys()
		
		if building_ids.is_empty():
			return
		
		var random_index = randi() % building_ids.size()
		var random_building_id: String = building_ids[random_index] as String
		
		if random_building_id.is_empty():
			return
		
		# In a real implementation, this could reduce building efficiency or require repairs
		# For now, just trigger an event
		seasonal_event_triggered.emit("weather_damage", {
			"description": damage_description + " - " + random_building_id
		})

func is_bad_season_for_food() -> bool:
	return current_season == Season.WINTER
