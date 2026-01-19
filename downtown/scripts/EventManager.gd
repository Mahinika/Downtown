extends Node

## EventManager - Manages random events and challenges
##
## Singleton Autoload that handles random events that occur during gameplay.
## Provides variety and challenge by introducing unexpected resource changes,
## visitor interactions, and weather events at regular intervals.
##
## Key Features:
## - Time-based event triggering system
## - Multiple event types (resource bonuses, shortages, visitors, weather)
## - Event duration management
## - Resource impact handling
## - Event history tracking
##
## Usage:
##   EventManager.trigger_random_event()  # Called automatically by timer
##   var active = EventManager.get_active_events()

## Emitted when an event is triggered.
## Parameters: event_id (String), event_data (Dictionary)
signal event_triggered(event_id: String, event_data: Dictionary)

## Emitted when an event is resolved or expires.
## Parameters: event_id (String), result (String)
signal event_resolved(event_id: String, result: String)

## Active events registry: event_id (String) -> event_data (Dictionary).
## Contains currently active events with their data and timing.
var active_events: Dictionary = {}

## Timer for tracking time between random events.
var event_timer: float = 0.0

## Base interval between event checks in seconds.
const EVENT_INTERVAL: float = 120.0

## Probability of triggering an event per interval (0.0 to 1.0).
const EVENT_CHANCE: float = 0.3

## Current event interval (can be modified for testing).
var event_interval: float = EVENT_INTERVAL

## Current event chance (can be modified for testing).
var event_chance: float = EVENT_CHANCE

## Helper function to safely access ResourceManager autoload
func _get_resource_manager():
	if has_method("get_node_or_null"):
		return get_node_or_null("/root/ResourceManager")
	return null

func _ready() -> void:
	print("[EventManager] Initialized")

func _process(delta: float) -> void:
	event_timer += delta
	
	if event_timer >= event_interval:
		event_timer = 0.0
		
		# Chance to trigger event
		if randf() < event_chance:
			trigger_random_event()

func trigger_random_event() -> void:
	var event_types = [
		"resource_bonus",
		"resource_shortage",
		"visitor",
		"weather"
	]
	
	var event_type = event_types[randi() % event_types.size()]
	var event_id = "event_" + str(Time.get_ticks_msec())
	
	match event_type:
		"resource_bonus":
			trigger_resource_bonus(event_id)
		"resource_shortage":
			trigger_resource_shortage(event_id)
		"visitor":
			trigger_visitor(event_id)
		"weather":
			trigger_weather(event_id)

func trigger_resource_bonus(event_id: String) -> void:
	# Validate input
	if event_id.is_empty():
		push_warning("[EventManager] Empty event ID")
		return
	
	var resources = ["wood", "stone", "food"]
	var resource = resources[randi() % resources.size()]
	var amount = 20.0 + randf() * 30.0
	
	var resource_manager = _get_resource_manager()
	if resource_manager:
		resource_manager.add_resource(resource, amount)
	
	var event_data = {
		"type": "resource_bonus",
		"title": "Resource Discovery",
		"message": "Found " + str(int(amount)) + " " + resource + "!",
		"resource": resource,
		"amount": amount,
		"duration": 0.0
	}
	
	active_events[event_id] = event_data
	event_triggered.emit(event_id, event_data)
	print("[EventManager] Resource bonus event: ", event_data.message)
	
	# Auto-resolve immediately
	event_resolved.emit(event_id, "success")

func trigger_resource_shortage(event_id: String) -> void:
	# Validate input
	if event_id.is_empty():
		push_warning("[EventManager] Empty event ID")
		return
	
	var resources = ["wood", "stone", "food"]
	var resource = resources[randi() % resources.size()]
	var amount = 10.0 + randf() * 20.0
	
	var resource_manager = _get_resource_manager()
	if resource_manager:
		resource_manager.consume_resource(resource, amount, true)
	
	var event_data = {
		"type": "resource_shortage",
		"title": "Resource Loss",
		"message": "Lost " + str(int(amount)) + " " + resource + " due to spoilage.",
		"resource": resource,
		"amount": amount,
		"duration": 0.0
	}
	
	active_events[event_id] = event_data
	event_triggered.emit(event_id, event_data)
	print("[EventManager] Resource shortage event: ", event_data.message)
	
	# Auto-resolve immediately
	event_resolved.emit(event_id, "resolved")

func trigger_visitor(event_id: String) -> void:
	# Validate input
	if event_id.is_empty():
		push_warning("[EventManager] Empty event ID")
		return
	
	var event_data = {
		"type": "visitor",
		"title": "Visitor Arrives",
		"message": "A traveler has arrived at your village!",
		"duration": 30.0
	}
	
	active_events[event_id] = event_data
	event_triggered.emit(event_id, event_data)
	print("[EventManager] Visitor event triggered")
	
	# Auto-resolve after duration
	await get_tree().create_timer(event_data.duration).timeout
	if active_events.has(event_id):
		active_events.erase(event_id)
		event_resolved.emit(event_id, "completed")

func trigger_weather(event_id: String) -> void:
	# Validate input
	if event_id.is_empty():
		push_warning("[EventManager] Empty event ID")
		return
	
	var weather_types = ["rain", "sun", "wind"]
	var weather = weather_types[randi() % weather_types.size()]
	
	var event_data = {
		"type": "weather",
		"title": "Weather Change",
		"message": "The weather has changed to " + weather + ".",
		"weather": weather,
		"duration": 60.0
	}
	
	active_events[event_id] = event_data
	event_triggered.emit(event_id, event_data)
	print("[EventManager] Weather event: ", weather)
	
	# Auto-resolve after duration
	await get_tree().create_timer(event_data.duration).timeout
	if active_events.has(event_id):
		active_events.erase(event_id)
		event_resolved.emit(event_id, "completed")

func get_active_events() -> Array:
	var events: Array = []
	for event_id in active_events:
		events.append(active_events[event_id])
	return events
