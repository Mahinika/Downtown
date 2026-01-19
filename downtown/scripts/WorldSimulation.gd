extends Node

## WorldSimulation - Unified world simulation system
##
## Consolidates SeasonalManager, EventManager, and PopularityManager functionality
## into a single, cohesive world simulation system.
##
## Key Features:
## - Time progression and seasonal changes
## - Random events and their effects
## - Population growth and happiness simulation
## - Weather and environmental effects
##
## Usage:
##   var simulation = WorldSimulation.new()
##   simulation.start_season_cycle()
##   var happiness = simulation.calculate_population_happiness()

# class_name WorldSimulation  # Removed to avoid autoload conflict

# Emitted when season changes
signal season_changed(new_season: String, old_season: String)

# Emitted when weather changes
signal weather_changed(new_weather: String, old_weather: String)

# Emitted when a random event occurs
signal event_triggered(event_id: String, event_data: Dictionary)

# Emitted when population changes
signal population_growth(amount: float)
signal population_decline(amount: float)

# Seasons
enum Season { SPRING, SUMMER, AUTUMN, WINTER }
const SEASON_NAMES = ["Spring", "Summer", "Autumn", "Winter"]

# Weather types
enum Weather { CLEAR, RAINY, STORMY, SNOWY }
const WEATHER_NAMES = ["Clear", "Rainy", "Stormy", "Snowy"]

# Current simulation state
var current_season: Season = Season.SPRING
var current_weather: Weather = Weather.CLEAR
var season_timer: float = 0.0
var weather_timer: float = 0.0

# Simulation constants
const SEASON_DURATION: float = 300.0  # 5 minutes per season
const WEATHER_CHANGE_CHANCE: float = 0.1  # 10% chance per minute
const POPULATION_UPDATE_INTERVAL: float = 10.0  # Update every 10 seconds
const NEEDS_WARNING_INTERVAL: float = 30.0  # Check villager needs every 30 seconds
const TUTORIAL_CHECK_INTERVAL: float = 5.0  # Check for tutorial triggers every 5 seconds

# Population tracking
var popularity: float = 50.0
var population_timer: float = 0.0
var needs_warning_timer: float = 0.0
var tutorial_timer: float = 0.0

# Event system
var random_events: Dictionary = {}
var active_events: Dictionary = {}
var event_timer: float = 0.0

func _ready() -> void:
	print("[WorldSimulation] Initializing world simulation system")
	initialize_events()
	reset_timers()

func _process(delta: float) -> void:
	"""Process world simulation"""
	season_timer += delta
	weather_timer += delta
	population_timer += delta
	event_timer += delta
	needs_warning_timer += delta
	tutorial_timer += delta

	# Update seasons
	if season_timer >= SEASON_DURATION:
		advance_season()
		season_timer = 0.0

	# Update weather
	if weather_timer >= 60.0:  # Check every minute
		update_weather()
		weather_timer = 0.0

	# Update population
	if population_timer >= POPULATION_UPDATE_INTERVAL:
		update_population_growth()
		population_timer = 0.0

	# Check villager needs warnings
	if needs_warning_timer >= NEEDS_WARNING_INTERVAL:
		check_villager_needs_warnings()
		needs_warning_timer = 0.0

	# Check tutorial triggers
	if tutorial_timer >= TUTORIAL_CHECK_INTERVAL:
		check_tutorial_triggers()
		tutorial_timer = 0.0

	# Process active events
	process_active_events(delta)

func reset_timers() -> void:
	"""Reset all simulation timers"""
	season_timer = 0.0
	weather_timer = 0.0
	population_timer = 0.0
	event_timer = 0.0
	needs_warning_timer = 0.0
	tutorial_timer = 0.0

func advance_season() -> void:
	"""Advance to the next season"""
	var old_season_name = SEASON_NAMES[current_season]
	current_season = (current_season + 1) % Season.size() as Season
	var new_season_name = SEASON_NAMES[current_season]

	season_changed.emit(new_season_name, old_season_name)
	print("[WorldSimulation] Season changed: ", old_season_name, " -> ", new_season_name)

func update_weather() -> void:
	"""Potentially change the weather"""
	if randf() < WEATHER_CHANGE_CHANCE:
		var old_weather_name = WEATHER_NAMES[current_weather]

		# Weather change logic based on season
		match current_season:
			Season.SPRING:
				current_weather = Weather.CLEAR if randf() < 0.7 else Weather.RAINY
			Season.SUMMER:
				current_weather = Weather.CLEAR if randf() < 0.8 else Weather.STORMY
			Season.AUTUMN:
				current_weather = Weather.CLEAR if randf() < 0.6 else Weather.RAINY
			Season.WINTER:
				current_weather = Weather.CLEAR if randf() < 0.5 else Weather.SNOWY

		var new_weather_name = WEATHER_NAMES[current_weather]
		if new_weather_name != old_weather_name:
			weather_changed.emit(new_weather_name, old_weather_name)
			print("[WorldSimulation] Weather changed: ", old_weather_name, " -> ", new_weather_name)

func update_population_growth() -> void:
	"""Update population growth based on current conditions"""
	var game_world = get_node_or_null("/root/GameWorld")
	if not game_world:
		return

	var housing_capacity = game_world.get_housing_capacity()
	var current_population = get_current_population()

	var growth_amount: float = 0.0

	if popularity > 50.0:
		# Population grows if we have housing capacity
		if current_population < housing_capacity:
			# Calculate growth rate based on popularity
			if popularity >= 90.0:
				growth_amount = 1.0
			elif popularity >= 75.0:
				growth_amount = 0.7
			elif popularity >= 60.0:
				growth_amount = 0.4
			else:
				growth_amount = 0.2

			# Cap growth to housing capacity
			if current_population + growth_amount > housing_capacity:
				growth_amount = housing_capacity - current_population

			if growth_amount > 0.0:
				var economy_system = get_node_or_null("/root/EconomySystem")
				if economy_system:
					economy_system.add_resource("population", growth_amount)
					population_growth.emit(growth_amount)
					print("[WorldSimulation] Population grew by ", growth_amount)

	elif popularity < 50.0:
		# Population declines
		if current_population > 0:
			# Calculate decline rate
			var decline_rate: float = 0.0
			if popularity <= 10.0:
				decline_rate = 0.5
			elif popularity <= 25.0:
				decline_rate = 0.3
			elif popularity <= 35.0:
				decline_rate = 0.4
			else:
				decline_rate = 0.2

			growth_amount = -decline_rate

			var new_population = max(0.0, current_population + growth_amount)
			var economy_system = get_node_or_null("/root/EconomySystem")
			if economy_system:
				economy_system.set_resource("population", new_population)
				population_decline.emit(-growth_amount)  # Emit positive decline amount
				print("[WorldSimulation] Population declined by ", -growth_amount)

func get_current_population() -> float:
	"""Get current population count"""
	var economy_system = get_node_or_null("/root/EconomySystem")
	if economy_system:
		return economy_system.get_resource("population")
	return 0.0

func calculate_population_happiness() -> float:
	"""Calculate overall population happiness"""
	# This is a simplified calculation - in a full implementation,
	# this would consider housing quality, job satisfaction, food, etc.
	var base_happiness = 50.0

	# Weather effects
	match current_weather:
		Weather.CLEAR:
			base_happiness += 5.0
		Weather.RAINY:
			base_happiness -= 2.0
		Weather.STORMY:
			base_happiness -= 5.0
		Weather.SNOWY:
			base_happiness -= 3.0

	# Seasonal effects
	match current_season:
		Season.SPRING:
			base_happiness += 3.0
		Season.SUMMER:
			base_happiness += 5.0
		Season.AUTUMN:
			base_happiness += 2.0
		Season.WINTER:
			base_happiness -= 5.0

	return clamp(base_happiness, 0.0, 100.0)

func initialize_events() -> void:
	"""Initialize random event definitions"""
	random_events = {
		"drought": {
			"id": "drought",
			"name": "Drought",
			"description": "Severe drought reduces crop yields",
			"duration": 180.0,  # 3 minutes
			"effects": {
				"food_production_modifier": 0.5,
				"population_happiness_modifier": -10.0
			},
			"probability": 0.05  # 5% chance per check
		},
		"plague": {
			"id": "plague",
			"name": "Plague",
			"description": "Disease spreads through the village",
			"duration": 240.0,  # 4 minutes
			"effects": {
				"population_growth_modifier": -0.5,
				"population_happiness_modifier": -20.0
			},
			"probability": 0.03  # 3% chance per check
		},
		"good_harvest": {
			"id": "good_harvest",
			"name": "Good Harvest",
			"description": "Exceptional harvest boosts food production",
			"duration": 120.0,  # 2 minutes
			"effects": {
				"food_production_modifier": 1.5,
				"population_happiness_modifier": 10.0
			},
			"probability": 0.08  # 8% chance per check
		}
	}
	print("[WorldSimulation] Initialized ", random_events.size(), " random events")

func check_random_events() -> void:
	"""Check if a random event should occur"""
	for event_id in random_events:
		var event_data = random_events[event_id]
		if randf() < event_data.probability:
			trigger_event(event_id)

func trigger_event(event_id: String) -> void:
	"""Trigger a random event"""
	if active_events.has(event_id):
		return  # Event already active

	var event_data = random_events[event_id].duplicate()
	event_data["start_time"] = Time.get_unix_time_from_system()

	active_events[event_id] = event_data
	event_triggered.emit(event_id, event_data)

	print("[WorldSimulation] Event triggered: ", event_data.name)

func process_active_events(delta: float) -> void:
	"""Process active events and check for expiration"""
	var expired_events = []

	for event_id in active_events:
		var event_data = active_events[event_id]
		var elapsed = Time.get_unix_time_from_system() - event_data.start_time

		if elapsed >= event_data.duration:
			expired_events.append(event_id)

	# Remove expired events
	for event_id in expired_events:
		active_events.erase(event_id)
		print("[WorldSimulation] Event ended: ", random_events[event_id].name)

func get_season_name() -> String:
	"""Get current season name"""
	return SEASON_NAMES[current_season]

func get_weather_name() -> String:
	"""Get current weather name"""
	return WEATHER_NAMES[current_weather]

func get_popularity() -> float:
	"""Get current popularity value"""
	return popularity

func set_popularity(value: float) -> void:
	"""Set popularity value"""
	popularity = clamp(value, 0.0, 100.0)

func get_active_events() -> Dictionary:
	"""Get currently active events"""
	return active_events.duplicate()

func check_villager_needs_warnings() -> void:
	"""Check villager needs and show warnings if needed"""
	var ui = GameServices.get_ui()
	if not ui or not ui.has_method("show_villager_needs_warnings"):
		return

	ui.show_villager_needs_warnings()

func check_tutorial_triggers() -> void:
	"""Check for tutorial triggers"""
	var ui = GameServices.get_ui()
	if ui and ui.has_method("check_tutorial_triggers"):
		ui.check_tutorial_triggers()