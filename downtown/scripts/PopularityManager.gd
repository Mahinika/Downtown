extends Node

## PopularityManager - Manages popularity (0-100) and population growth
##
## Singleton Autoload that handles popularity tracking, calculation, and population growth
## based on Stronghold: Definitive Edition mechanics.
##
## Key Features:
## - Popularity tracking (0-100 range)
## - Population growth based on popularity (>50 = growth, <50 = decline)
## - Popularity factors: food variety, taxes, ale, entertainment, fear, housing, rations
## - Automatic population growth/decline based on popularity
##
## Usage:
##   PopularityManager.set_tax_level(PopularityManager.TaxLevel.AVERAGE)
##   var pop = PopularityManager.get_popularity()

## Emitted when popularity changes significantly (>= 5 points).
## Parameters: new_popularity (float), old_popularity (float)
signal popularity_changed(new_popularity: float, old_popularity: float)

## Emitted when population growth occurs.
## Parameters: growth_amount (float)
signal population_growth(growth_amount: float)

## Emitted when population declines.
## Parameters: decline_amount (float)
signal population_decline(decline_amount: float)

## Current popularity value (0.0 to 100.0).
## Ranges from 0 (mass exodus) to 100 (maximum growth).
var popularity: float = 50.0

## Tax level enumeration matching Stronghold system.
enum TaxLevel {
	NO_TAX,        # 0 gold, 0 popularity penalty
	LOW,           # +X gold, -5 popularity
	AVERAGE,       # +2X gold, -10 popularity
	MEAN,          # +3X gold, -20 popularity
	EXTORTIONATE   # +4X gold, -35 popularity
}

## Current tax level setting.
var current_tax_level: TaxLevel = TaxLevel.NO_TAX

## Ration level enumeration.
enum RationLevel {
	LOW,     # 0.1 food/peasant/month, -10 popularity
	NORMAL,  # 0.2 food/peasant/month, 0 popularity
	DOUBLE   # 0.4 food/peasant/month, +15 popularity
}

## Current ration level setting.
var current_ration_level: RationLevel = RationLevel.NORMAL

## Food variety tracking: food_type (String) -> is_active (bool).
## Tracks which food types are currently being produced/consumed.
var active_food_types: Dictionary = {}

## Fear factor level (0-5). Sum of all "Bad Things" building levels.
## Increases production but decreases popularity and health.
var fear_level: int = 0

## Good things level (0-5). Sum of all "Good Things" building levels.
## Increases popularity and health but decreases production.
var good_level: int = 0

## Ale coverage: Number of peasants covered by inns.
## Provides happiness bonus (+4 per covered peasant).
var ale_coverage: int = 0

## Total population (peasants only, not soldiers).
## Used for consumption and tax calculations.
var total_population: int = 0

## Idle peasant count (peasants without jobs).
## Excess idle peasants (>24) reduce popularity.
var idle_peasant_count: int = 0

## Maximum idle peasants allowed before popularity penalty.
const MAX_IDLE_PEASANTS: int = 24

## Timer for periodic popularity updates and population growth.
var update_timer: Timer

func _ready() -> void:
	print("[PopularityManager] Initialized")
	
	# Create timer for periodic updates (every 10 seconds)
	update_timer = Timer.new()
	update_timer.wait_time = 10.0
	update_timer.timeout.connect(_on_update_timer)
	update_timer.autostart = true
	add_child(update_timer)
	
	# Initialize active food types
	active_food_types = {
		"food": false,
		"bread": false,
		"preserved_food": false,
		"meat": false,
		"apples": false
	}

func _on_update_timer() -> void:
	"""Periodically update popularity and check for population growth"""
	var old_popularity = popularity
	calculate_popularity()
	var resource_manager = get_node_or_null("/root/ResourceManager")
	var population_count = resource_manager.get_resource("population") if resource_manager else 0.0
	print("[PopularityManager] Timer update - Popularity: ", popularity, ", Housing capacity: ", calculate_housing_capacity(), ", Population: ", population_count)

	# Check for population growth/decline
	update_population_growth()
	
	# Emit signal if popularity changed significantly
	if abs(popularity - old_popularity) >= 5.0:
		popularity_changed.emit(popularity, old_popularity)

## Calculates current popularity based on all factors.
##
## Factors:
## - Tax penalty (-5 to -35)
## - Ration level (-10 to +15)
## - Food variety bonus (+2 per unique type, max +10)
## - Ale coverage (+4 per covered peasant, max +20)
## - Fear level (-2 per level, max -10)
## - Good things level (+5 per level, max +25)
## - Idle peasant penalty (-1 per excess idle, max -10)
## - Base popularity starts at 50
func calculate_popularity() -> void:
	# Start with base popularity
	var calculated_popularity: float = 50.0
	
	# Tax penalty
	var tax_penalty: float = 0.0
	match current_tax_level:
		TaxLevel.NO_TAX:
			tax_penalty = 0.0
		TaxLevel.LOW:
			tax_penalty = -5.0
		TaxLevel.AVERAGE:
			tax_penalty = -10.0
		TaxLevel.MEAN:
			tax_penalty = -20.0
		TaxLevel.EXTORTIONATE:
			tax_penalty = -35.0
	
	calculated_popularity += tax_penalty
	
	# Ration level bonus/penalty
	var ration_bonus: float = 0.0
	match current_ration_level:
		RationLevel.LOW:
			ration_bonus = -10.0
		RationLevel.NORMAL:
			ration_bonus = 0.0
		RationLevel.DOUBLE:
			ration_bonus = +15.0
	
	calculated_popularity += ration_bonus
	
	# Food variety bonus (+2 per unique active food type, max +10 for 5+ types)
	var unique_food_types = 0
	for food_type in active_food_types:
		if active_food_types[food_type]:
			unique_food_types += 1
	
	var food_variety_bonus = min(unique_food_types * 2.0, 10.0)
	calculated_popularity += food_variety_bonus
	
	# Ale coverage bonus (+4 per covered peasant, capped at 20 popularity max)
	var ale_bonus = min(ale_coverage * 4.0, 20.0)
	calculated_popularity += ale_bonus
	
	# Fear level penalty (-2 per level, max -10)
	calculated_popularity -= fear_level * 2.0
	
	# Good things bonus (+5 per level, max +25)
	calculated_popularity += good_level * 5.0
	
	# Idle peasant penalty (-1 per excess idle over MAX_IDLE_PEASANTS)
	var excess_idle = max(0, idle_peasant_count - MAX_IDLE_PEASANTS)
	var idle_penalty = min(excess_idle * 1.0, 10.0)  # Max -10 popularity
	calculated_popularity -= idle_penalty
	
	# Clamp popularity to 0-100 range
	popularity = clamp(calculated_popularity, 0.0, 100.0)

## Updates population growth based on popularity.
##
## Rules:
## - Popularity > 50: Population grows (if housing available)
## - Popularity < 50: Population declines (peasants leave)
## - Popularity == 50: Stable population
##
## Growth Rate:
## - Popularity 50-60: +0.1 population per 10 seconds
## - Popularity 60-75: +0.2 population per 10 seconds
## - Popularity 75-90: +0.3 population per 10 seconds
## - Popularity 90-100: +0.5 population per 10 seconds
## - Popularity < 50: -0.1 to -0.5 population per 10 seconds (based on how low)
func update_population_growth() -> void:
	var resource_manager = get_node_or_null("/root/ResourceManager")
	if not resource_manager:
		return

	# Check available housing capacity
	var housing_capacity = calculate_housing_capacity()
	var current_population = resource_manager.get_resource("population")
	
	var growth_amount: float = 0.0
	
	if popularity > 50.0:
		# Population grows
		if current_population < housing_capacity:
			print("[PopularityManager] Population growth check - Current: ", current_population, ", Housing capacity: ", housing_capacity, ", Popularity: ", popularity)
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
				print("[PopularityManager] Growing population by ", growth_amount)
				resource_manager.add_resource("population", growth_amount)
				population_growth.emit(growth_amount)
	
	elif popularity < 50.0:
		# Population declines (peasants leave)
		if current_population > 0:
			# Calculate decline rate based on how low popularity is
			var decline_rate: float = 0.0
			if popularity <= 10.0:
				decline_rate = 0.5
			elif popularity <= 25.0:
				decline_rate = 0.3
			elif popularity <= 35.0:
				decline_rate = 0.2
			else:
				decline_rate = 0.1
			
			# Apply decline
			growth_amount = -decline_rate
			var new_population = max(0.0, current_population + growth_amount)
			resource_manager.set_resource("population", new_population)
			
			# If population decreased, remove random villagers
			if new_population < current_population:
				var decline_amount = current_population - new_population
				population_decline.emit(decline_amount)
				var villagers_to_remove = int(decline_amount)
				remove_random_villagers(villagers_to_remove)

## Calculates total housing capacity from all residential buildings.
func calculate_housing_capacity() -> float:
	if not BuildingManager:
		return 0.0
	
	var all_buildings = BuildingManager.get_all_buildings()
	var total_capacity: float = 0.0
	
	for building_id in all_buildings:
		var building_data = all_buildings[building_id]
		var building_type_data = BuildingManager.get_building_type_data(building_data.get("building_type_id", ""))
		
		if building_type_data:
			var housing_capacity = building_type_data.get("housing_capacity", 0)
			if housing_capacity > 0:
				total_capacity += float(housing_capacity)
	
	return total_capacity

## Removes random villagers when population declines.
func remove_random_villagers(count: int) -> void:
	var world = GameServices.get_world()
	if not world:
		return

	var all_villagers = world.get_all_villagers()
	var villager_ids = all_villagers.keys()

	if villager_ids.size() <= count:
		# Remove all villagers
		for villager_id in villager_ids:
			world.remove_villager(villager_id)
	else:
		# Remove random villagers
		for i in range(count):
			var random_index = randi() % villager_ids.size()
			var random_villager_id = villager_ids[random_index]
			world.remove_villager(random_villager_id)
			villager_ids.remove_at(random_index)

## Sets the tax level.
func set_tax_level(level: TaxLevel) -> void:
	current_tax_level = level
	calculate_popularity()
	print("[PopularityManager] Tax level set to: ", TaxLevel.keys()[level])

## Gets the current tax level.
func get_tax_level() -> TaxLevel:
	return current_tax_level

## Gets tax income per update cycle (10 seconds) based on tax level and population.
func get_tax_income() -> float:
	var resource_manager = get_node_or_null("/root/ResourceManager")
	if not resource_manager:
		return 0.0

	var population = resource_manager.get_resource("population")
	var base_income_per_peasant = 0.1  # 0.1 gold per peasant per 10 seconds
	
	var multiplier: float = 0.0
	match current_tax_level:
		TaxLevel.NO_TAX:
			multiplier = 0.0
		TaxLevel.LOW:
			multiplier = 1.0
		TaxLevel.AVERAGE:
			multiplier = 2.0
		TaxLevel.MEAN:
			multiplier = 3.0
		TaxLevel.EXTORTIONATE:
			multiplier = 4.0
	
	return population * base_income_per_peasant * multiplier

## Sets the ration level.
func set_ration_level(level: RationLevel) -> void:
	current_ration_level = level
	calculate_popularity()
	print("[PopularityManager] Ration level set to: ", RationLevel.keys()[level])

## Gets the current ration level.
func get_ration_level() -> RationLevel:
	return current_ration_level

## Gets food consumption per peasant per update cycle (10 seconds) based on ration level.
func get_food_consumption_per_peasant() -> float:
	match current_ration_level:
		RationLevel.LOW:
			return 0.1 / 30.0  # 0.1 per month = ~0.003 per 10 seconds
		RationLevel.NORMAL:
			return 0.2 / 30.0  # 0.2 per month = ~0.007 per 10 seconds
		RationLevel.DOUBLE:
			return 0.4 / 30.0  # 0.4 per month = ~0.013 per 10 seconds
	return 0.0

## Sets a food type as active or inactive.
func set_food_type_active(food_type: String, is_active: bool) -> void:
	if active_food_types.has(food_type):
		active_food_types[food_type] = is_active
		calculate_popularity()

## Gets whether a food type is active.
func get_food_type_active(food_type: String) -> bool:
	return active_food_types.get(food_type, false)

## Gets the current popularity value.
func get_popularity() -> float:
	return popularity

## Sets the fear level (sum of all Bad Things buildings).
func set_fear_level(level: int) -> void:
	fear_level = clamp(level, 0, 5)
	calculate_popularity()

## Gets the current fear level.
func get_fear_level() -> int:
	return fear_level

## Sets the good things level (sum of all Good Things buildings).
func set_good_level(level: int) -> void:
	good_level = clamp(level, 0, 5)
	calculate_popularity()

## Gets the current good things level.
func get_good_level() -> int:
	return good_level

## Sets the ale coverage count.
func set_ale_coverage(count: int) -> void:
	ale_coverage = max(0, count)
	calculate_popularity()

## Gets the current ale coverage count.
func get_ale_coverage() -> int:
	return ale_coverage

## Sets the idle peasant count.
func set_idle_peasant_count(count: int) -> void:
	idle_peasant_count = max(0, count)
	calculate_popularity()

## Gets the current idle peasant count.
func get_idle_peasant_count() -> int:
	return idle_peasant_count

## Gets the production multiplier based on fear level.
## Fear level increases production: +10% per level (max +150% at level 5).
func get_production_multiplier() -> float:
	return 1.0 + (fear_level * 0.10)  # +10% per level

## Gets the production penalty based on good things level.
## Good things decrease production: -5% per level (max -50% at level 5).
func get_production_penalty() -> float:
	return 1.0 - (good_level * 0.10)  # -10% per level

## Gets the villager health modifier based on fear/good things.
## Fear: -5% health per level (max -25%)
## Good Things: +5% health per level (max +25%)
func get_health_modifier() -> float:
	return 1.0 - (fear_level * 0.05) + (good_level * 0.05)
