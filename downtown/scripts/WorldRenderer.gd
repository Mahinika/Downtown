extends Node2D

## WorldRenderer - Visual rendering and effects system
##
## Handles all visual aspects of the game world including:
## - Building and villager visual representation
## - Particle effects and animations
## - Grid and debug visualization
## - Camera management
##
## Key Features:
## - Visual object management and caching
## - Particle effects for building placement
## - Debug visualization overlays
## - Camera controls and bounds

class_name WorldRenderer

# Visual object tracking
var building_visuals: Dictionary = {}  # building_id -> visual_node
var villager_visuals: Dictionary = {}  # villager_id -> villager_node
var resource_node_visuals: Dictionary = {}  # node_id -> visual_node

# Debug visualization
var pathfinding_debug_enabled: bool = false
var pathfinding_debug_lines: Array = []

# Camera reference
var camera: Camera2D = null

# Grid settings
const TILE_SIZE = 32
const GRID_COLOR = Color(0.3, 0.3, 0.3, 0.5)

func _ready() -> void:
	print("[WorldRenderer] Initializing world renderer")
	setup_camera()
	connect_signals()

func _process(_delta: float) -> void:
	"""Update debug visualizations"""
	if pathfinding_debug_enabled:
		update_debug_visualization()

func setup_camera() -> void:
	"""Set up the main camera"""
	camera = Camera2D.new()
	camera.name = "MainCamera"
	add_child(camera)

	# Camera settings
	camera.zoom = Vector2(1, 1)
	camera.position_smoothing_enabled = true
	camera.position_smoothing_speed = 5.0

func connect_signals() -> void:
	"""Connect to world events"""
	var world = GameServices.get_world()
	if world:
		world.building_placed.connect(_on_building_placed)
		world.building_removed.connect(_on_building_removed)
		world.villager_spawned.connect(_on_villager_spawned)
		world.villager_removed.connect(_on_villager_removed)
		world.world_updated.connect(_on_world_updated)

func create_building_visual(building_id: String, grid_pos: Vector2i, building_data: Dictionary) -> void:
	"""Create visual representation for a building"""
	if building_visuals.has(building_id):
		return

	# Create building visual container
	var building_visual = Node2D.new()
	building_visual.name = "Building_" + building_id

	# Position based on grid
	var world_pos = Vector2(grid_pos.x * TILE_SIZE, grid_pos.y * TILE_SIZE)
	building_visual.position = world_pos

	# Create building sprite/shape
	var building_sprite = create_building_sprite(building_data)
	building_visual.add_child(building_sprite)

	# Add building label
	var label = Label.new()
	label.name = "BuildingLabel"
	label.text = building_data.get("name", building_id)
	label.position = Vector2(-50, -40)
	label.add_theme_font_size_override("font_size", 10)
	building_visual.add_child(label)

	# Add worker indicator container (populated later)
	var worker_container = Node2D.new()
	worker_container.name = "WorkerIndicatorContainer"
	building_visual.add_child(worker_container)

	add_child(building_visual)
	building_visuals[building_id] = building_visual

	print("[WorldRenderer] Created building visual: ", building_id)

func create_building_sprite(building_data: Dictionary) -> Node2D:
	"""Create the visual sprite/shape for a building"""
	var container = Node2D.new()

	# Get building dimensions
	var size = building_data.get("size", [1, 1])
	var width = size[0] * TILE_SIZE
	var height = size[1] * TILE_SIZE

	# Create colored rectangle for building
	var rect = ColorRect.new()
	rect.size = Vector2(width, height)
	rect.position = Vector2(-width/2, -height/2)

	# Color based on building type
	var category = building_data.get("category", "")
	match category:
		"residential":
			rect.color = Color(0.4, 0.6, 0.8)  # Blue
		"production":
			rect.color = Color(0.6, 0.4, 0.2)  # Brown
		"industrial":
			rect.color = Color(0.5, 0.5, 0.5)  # Gray
		"storage":
			rect.color = Color(0.7, 0.7, 0.3)  # Yellow
		"commercial":
			rect.color = Color(0.8, 0.6, 0.2)  # Orange
		"public":
			rect.color = Color(0.4, 0.8, 0.4)  # Green
		_:
			rect.color = Color(0.6, 0.6, 0.6)  # Default gray

	container.add_child(rect)
	return container

func remove_building_visual(building_id: String) -> void:
	"""Remove visual representation of a building"""
	if building_visuals.has(building_id):
		var visual = building_visuals[building_id]
		if is_instance_valid(visual):
			visual.queue_free()
		building_visuals.erase(building_id)
		print("[WorldRenderer] Removed building visual: ", building_id)

func create_villager_visual(villager_id: String, villager_node: Node2D) -> void:
	"""Add visual tracking for a villager"""
	if not villager_visuals.has(villager_id):
		villager_visuals[villager_id] = villager_node
		print("[WorldRenderer] Tracking villager visual: ", villager_id)

func remove_villager_visual(villager_id: String) -> void:
	"""Remove visual tracking for a villager"""
	if villager_visuals.has(villager_id):
		villager_visuals.erase(villager_id)
		print("[WorldRenderer] Removed villager visual tracking: ", villager_id)

func update_building_worker_indicator(building_id: String) -> void:
	"""Update the worker indicator for a building"""
	if not building_visuals.has(building_id):
		return

	var visual = building_visuals[building_id]
	var container = visual.find_child("WorkerIndicatorContainer", true, false)
	if not container:
		return

	# Clear existing indicators
	for child in container.get_children():
		child.queue_free()

	# Get worker info
	var economy = GameServices.get_economy()
	if economy:
		var worker_count = economy.get_building_workers(building_id).size()
		var capacity = economy.get_building_worker_capacity(building_id)

		if capacity > 0:
			var indicator = Label.new()
			indicator.text = "👷 " + str(worker_count) + "/" + str(capacity)
			indicator.add_theme_font_size_override("font_size", 9)

			# Color based on worker status
			if worker_count > 0:
				indicator.add_theme_color_override("font_color", Color(0.7, 0.9, 1.0))
			else:
				indicator.add_theme_color_override("font_color", Color(0.5, 0.5, 0.5))

			indicator.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
			indicator.position = Vector2(-50, 20)
			indicator.size = Vector2(100, 12)
			container.add_child(indicator)

func create_building_placement_effect(position: Vector2) -> void:
	"""Create particle effect for building placement"""
	var effect_container = Node2D.new()
	effect_container.name = "PlacementEffect"
	effect_container.position = position
	add_child(effect_container)

	# Create multiple particles
	for i in range(8):
		var particle = ColorRect.new()
		particle.size = Vector2(4, 4)
		particle.color = Color(1, 1, 0.5, 0.8)  # Yellow particles
		particle.position = Vector2(randf_range(-10, 10), randf_range(-10, 10))
		effect_container.add_child(particle)

		# Animate particle
		var tween = create_tween()
		var target_pos = particle.position + Vector2(randf_range(-30, 30), randf_range(-30, 30))
		tween.tween_property(particle, "position", target_pos, 0.5)
		tween.tween_property(particle, "modulate:a", 0.0, 0.5)
		tween.tween_callback(func(): particle.queue_free())

	# Remove effect container after animation
	await get_tree().create_timer(0.6).timeout
	if is_instance_valid(effect_container):
		effect_container.queue_free()

func create_resource_gathering_effect(position: Vector2) -> void:
	"""Create effect for resource gathering"""
	var effect_container = Node2D.new()
	effect_container.name = "GatheringEffect"
	effect_container.position = position
	add_child(effect_container)

	# Create floating particles
	for i in range(5):
		var particle = Label.new()
		particle.text = "✨"
		particle.add_theme_font_size_override("font_size", 16)
		particle.position = Vector2(randf_range(-5, 5), randf_range(-5, 5))
		effect_container.add_child(particle)

		# Animate upward
		var tween = create_tween()
		tween.tween_property(particle, "position:y", particle.position.y - 40, 1.0)
		tween.tween_property(particle, "modulate:a", 0.0, 1.0)
		tween.tween_callback(func(): particle.queue_free())

	# Remove container
	await get_tree().create_timer(1.2).timeout
	if is_instance_valid(effect_container):
		effect_container.queue_free()

func draw_grid() -> void:
	"""Draw grid overlay for debugging"""
	if not pathfinding_debug_enabled:
		return

	var grid_size = Vector2i(50, 50)  # Simplified grid size for visualization

	for x in range(grid_size.x):
		for y in range(grid_size.y):
			var world_pos = Vector2(x * TILE_SIZE, y * TILE_SIZE)
			# Draw grid lines (simplified - would need actual drawing in _draw)

func update_debug_visualization() -> void:
	"""Update debug visualization elements"""
	# Clear old debug lines
	for line in pathfinding_debug_lines:
		if is_instance_valid(line):
			line.queue_free()
	pathfinding_debug_lines.clear()

	if not pathfinding_debug_enabled:
		return

	# Draw pathfinding debug info
	var world = GameServices.get_world()
	if world:
		# This would draw debug pathfinding info
		# Implementation depends on specific debug needs
		pass

func toggle_debug_visualization() -> void:
	"""Toggle debug visualization on/off"""
	pathfinding_debug_enabled = not pathfinding_debug_enabled
	print("[WorldRenderer] Debug visualization: ", "ON" if pathfinding_debug_enabled else "OFF")

	if not pathfinding_debug_enabled:
		# Clear debug elements
		for line in pathfinding_debug_lines:
			if is_instance_valid(line):
				line.queue_free()
		pathfinding_debug_lines.clear()

func _on_building_placed(building_id: String, position: Vector2i) -> void:
	"""Handle building placement events"""
	var world = GameServices.get_world()
	if world:
		var building = world.get_building(building_id)
		if building:
			var building_data = building.data
			create_building_visual(building_id, position, building_data)

func _on_building_removed(building_id: String) -> void:
	"""Handle building removal events"""
	remove_building_visual(building_id)

func _on_villager_spawned(villager_id: String) -> void:
	"""Handle villager spawn events"""
	var world = GameServices.get_world()
	if world:
		var villager_node = world.get_villager(villager_id)
		if villager_node:
			create_villager_visual(villager_id, villager_node)

func _on_villager_removed(villager_id: String) -> void:
	"""Handle villager removal events"""
	remove_villager_visual(villager_id)

func _on_world_updated() -> void:
	"""Handle world update events"""
	# Update any visual elements that need refreshing
	pass