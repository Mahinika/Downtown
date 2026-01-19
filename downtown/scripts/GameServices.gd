class_name GameServicesClass
extends Node

## GameServices - Service Locator Pattern
##
## Central registry for all game services and managers.
## Replaces global autoloads with a clean service locator pattern.
##
## Usage:
##   var world = GameServices.world
##   var economy = GameServices.economy
##   var ui = GameServices.ui

# Service references
var world: GameWorldClass = null
var economy: EconomySystemClass = null
var progression: ProgressionSystemClass = null
var simulation: WorldSimulationClass = null
var persistence: PersistenceSystemClass = null
var ui: UIManagerClass = null
var debug_bridge: DebugBridgeClass = null

# Singleton instance
static var _instance: GameServicesClass = null

func _init() -> void:
	_instance = self

func _ready() -> void:
	print("[GameServices] Initializing service locator")

	# #region agent log
	var log_data = {
		"sessionId": "debug-session",
		"runId": "autoload-loading",
		"hypothesisId": "H3",
		"location": "GameServices.gd:30",
		"message": "GameServices _ready() called",
		"data": {
			"game_world_available": GameWorld != null,
			"economy_system_available": EconomySystem != null,
			"timestamp": Time.get_unix_time_from_system()
		},
		"timestamp": Time.get_unix_time_from_system() * 1000
	}

	var log_file = FileAccess.open("c:\\Users\\Ropbe\\Desktop\\Downtown\\.cursor\\debug.log", FileAccess.WRITE_READ)
	if log_file:
		log_file.seek_end()
		log_file.store_line(JSON.stringify(log_data))
		log_file.close()
	# #endregion

	initialize_services()

func initialize_services() -> void:
	"""Initialize all game services"""

	# Try to get existing autoload instances first, create new ones if not available
	if GameWorld:
		world = GameWorld
		print("[GameServices] Using existing GameWorld autoload")
	else:
		world = GameWorld.new()
		add_child(world)

	if EconomySystem:
		economy = EconomySystem
		print("[GameServices] Using existing EconomySystem autoload")
	else:
		economy = EconomySystem.new()
		add_child(economy)

	if ProgressionSystem:
		progression = ProgressionSystem
		print("[GameServices] Using existing ProgressionSystem autoload")
	else:
		progression = ProgressionSystem.new()
		add_child(progression)

	if WorldSimulation:
		simulation = WorldSimulation
		print("[GameServices] Using existing WorldSimulation autoload")
	else:
		simulation = WorldSimulation.new()
		add_child(simulation)

	if PersistenceSystem:
		persistence = PersistenceSystem
		print("[GameServices] Using existing PersistenceSystem autoload")
	else:
		persistence = PersistenceSystem.new()
		add_child(persistence)

	if UIManager:
		ui = UIManager
		print("[GameServices] Using existing UIManager autoload")
	else:
		ui = UIManager.new()
		add_child(ui)
		
	if DebugBridge:
		debug_bridge = DebugBridge
		print("[GameServices] Using existing DebugBridge autoload")
	else:
		debug_bridge = DebugBridgeClass.new()
		add_child(debug_bridge)

	print("[GameServices] All services initialized")

# Static accessors for convenience
static func get_world() -> GameWorldClass:
	return _instance.world if _instance else null

static func get_economy() -> EconomySystemClass:
	return _instance.economy if _instance else null

static func get_progression() -> ProgressionSystemClass:
	return _instance.progression if _instance else null

static func get_simulation() -> WorldSimulationClass:
	return _instance.simulation if _instance else null

static func get_persistence() -> PersistenceSystemClass:
	return _instance.persistence if _instance else null

static func get_ui() -> UIManagerClass:
	return _instance.ui if _instance else null

static func get_debug_bridge() -> DebugBridgeClass:
	return _instance.debug_bridge if _instance else null

# Service validation
func validate_services() -> bool:
	"""Validate that all required services are available"""
	var services = [world, economy, progression, simulation, persistence, ui, debug_bridge]
	for service in services:
		if not service:
			push_error("[GameServices] Service not initialized: ", service)
			return false
	return true

# Service cleanup
func cleanup_services() -> void:
	"""Clean up all services"""
	for child in get_children():
		child.queue_free()

	print("[GameServices] Services cleaned up")
