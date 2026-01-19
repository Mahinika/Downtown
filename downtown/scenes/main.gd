extends Node2D

var ui_layer: CanvasLayer = null

# Main game scene - Coordinates UI, camera, input, and manager interactions

@onready var resource_hud: Control
@onready var building_panel: Control
var selected_building_type: String = ""
var selected_building_id: String = ""

# Tooltip system
var tooltip_panel: Panel = null
var tooltip_label: Label = null
var hovered_object = null

# UI State Management
enum UIState {
	FULL,        # All UI visible
	MINIMAL,     # Only essential UI (resources, time)
	PLACEMENT    # Building placement mode (hide panels, show preview)
}
var current_ui_state: UIState = UIState.FULL
var camera_zoom: float = 1.0
var camera_pan_start: Vector2 = Vector2.ZERO
var is_panning: bool = false
var is_zooming: bool = false
var last_pinch_distance: float = 0.0
var touch_positions: Dictionary = {}  # Store touch positions for better gesture handling
var initial_zoom: float = 1.0
var zoom_sensitivity: float = 0.005  # Mobile-friendly zoom sensitivity
var _ui_interaction_active: bool = false  # Flag to prevent world input during UI interactions

func _reset_ui_interaction_flag() -> void:
	"""Reset the UI interaction flag after UI processes input"""
	_ui_interaction_active = false

# Visual tracking
var building_visuals: Dictionary = {}  # building_id -> visual_node
var villager_visuals: Dictionary = {}  # villager_id -> villager_node
var resource_node_visuals: Dictionary = {}  # node_id -> visual_node
var resource_cards: Dictionary = {}  # resource_id -> resource_card Control

# Grid container for game objects
var grid_container: Node2D

# Building preview
var building_preview: ColorRect

func _ready():
	"""Initialize the main game scene"""
	print("[Main] Initializing Downtown city management game...")

	# Create a visible debug label to show game status
	var debug_label = Label.new()
	debug_label.name = "DebugLabel"
	debug_label.text = "Downtown Game Starting..."
	debug_label.set_position(Vector2(50, 50))
	debug_label.add_theme_font_size_override("font_size", 24)
	add_child(debug_label)

	# Wait for autoloads to be ready
	await get_tree().process_frame

	# Check autoload availability
	var status_text = "Game Status:\n"
	status_text += "DataManager: " + ("✓" if DataManager else "✗") + "\n"
	status_text += "ResourceManager: " + ("✓" if ResourceManager else "✗") + "\n"
	status_text += "GameServices: " + ("✓" if GameServices else "✗") + "\n"
	status_text += "UIManager: " + ("✓" if UIManager else "✗") + "\n"

	debug_label.text = status_text

	# Initialize game through GameServices
	if GameServices:
		print("[Main] GameServices available, initializing world...")
		status_text += "\nInitializing world..."
		debug_label.text = status_text

		# Try to start the game world
		if GameServices.world:
			print("[Main] GameWorld initialized")
			status_text += "\nGameWorld: ✓"
		else:
			print("[Main] GameWorld not available")
			status_text += "\nGameWorld: ✗"

		debug_label.text = status_text

	else:
		push_error("[Main] GameServices not available - game cannot start")
		status_text += "\n❌ CRITICAL: GameServices missing!"
		debug_label.text = status_text
		debug_label.add_theme_color_override("font_color", Color.RED)

	# Set up basic camera
	var camera = $Camera2D
	if camera:
		print("[Main] Camera initialized")
		status_text += "\nCamera: ✓"
	else:
		push_warning("[Main] Camera not found")
		status_text += "\nCamera: ✗"

	debug_label.text = status_text
	print("[Main] Game initialization complete")

func _process(delta: float):
	"""Main game loop"""
	pass

func _input(event):
	"""Handle input events"""
	if event.is_action_pressed("ui_debug"):
		var debug_bridge = GameServices.get_debug_bridge()
		if debug_bridge:
			debug_bridge.dump_state()
		print("[Main] Debug state dumped - check debug_state.json")

func _on_season_changed(season: String) -> void:
	"""Handle season changes"""
	print("[Main] Season changed to: ", season)

func _on_weather_changed(weather: String) -> void:
	"""Handle weather changes"""
	print("[Main] Weather changed to: ", weather)

func _on_seasonal_event(event_data: Dictionary) -> void:
	"""Handle seasonal events"""
	print("[Main] Seasonal event: ", event_data)

func _exit_tree() -> void:
	"""Clean up signal connections to prevent memory leaks"""
	# Disconnect SeasonalManager signals
	if SeasonalManager:
		if SeasonalManager.is_connected("season_changed", _on_season_changed):
			SeasonalManager.season_changed.disconnect(_on_season_changed)
		if SeasonalManager.is_connected("weather_changed", _on_weather_changed):
			SeasonalManager.weather_changed.disconnect(_on_weather_changed)
		if SeasonalManager.is_connected("seasonal_event_triggered", _on_seasonal_event):
			SeasonalManager.seasonal_event_triggered.disconnect(_on_seasonal_event)

	# Clean up all game systems
	if GameServices:
		GameServices.cleanup_services()

	# Clean up managers
	if VillagerManager:
		VillagerManager.cleanup()
	if BuildingManager:
		BuildingManager.cleanup()
	if JobSystem:
		JobSystem.cleanup()
	if UIManager:
		UIManager.cleanup()
