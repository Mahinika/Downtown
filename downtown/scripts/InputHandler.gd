extends Node

## InputHandler - Input processing and camera controls
##
## Handles all user input including mouse, keyboard, and touch events.
## Manages camera controls, building placement, and UI interactions.
##
## Key Features:
## - Mouse and touch input processing
## - Camera panning and zooming
## - Building placement controls
## - UI interaction handling
## - Input validation and filtering

class_name InputHandler

# Input state
var is_left_click: bool = false
var is_right_click: bool = false
var click_position: Vector2 = Vector2.ZERO
var camera_pan_start: Vector2 = Vector2.ZERO
var is_panning: bool = false
var is_zooming: bool = false
var last_pinch_distance: float = 0.0
var touch_positions: Dictionary = {}
var _ui_interaction_active: bool = false

# Camera settings
var camera_zoom: float = 1.0
var zoom_sensitivity: float = 0.005
var initial_zoom: float = 1.0

# Building placement
var selected_building_type: String = ""
var building_preview: ColorRect = null

func _ready() -> void:
	print("[InputHandler] Initializing input handler")
	setup_building_preview()

func _input(event: InputEvent) -> void:
	"""Process input events"""
	if _ui_interaction_active:
		return

	# Handle mouse/touch input
	if event is InputEventMouseButton:
		handle_mouse_button(event)
	elif event is InputEventMouseMotion:
		handle_mouse_motion(event)
	elif event is InputEventScreenTouch:
		handle_touch(event)
	elif event is InputEventScreenDrag:
		handle_touch_drag(event)
	elif event is InputEventKey:
		handle_keyboard(event)

func handle_mouse_button(event: InputEventMouseButton) -> void:
	"""Handle mouse button events"""
	if event.button_index == MOUSE_BUTTON_LEFT:
		if event.pressed:
			is_left_click = true
			click_position = event.position
			handle_left_click_start(event.position)
		else:
			handle_left_click_release(event.position)
			is_left_click = false

	elif event.button_index == MOUSE_BUTTON_RIGHT:
		if event.pressed:
			is_right_click = true
			click_position = event.position
			handle_right_click(event.position)
		else:
			is_right_click = false

	# Handle mouse wheel for zooming
	if event.button_index == MOUSE_BUTTON_WHEEL_UP:
		zoom_camera(1.1, event.position)
	elif event.button_index == MOUSE_BUTTON_WHEEL_DOWN:
		zoom_camera(0.9, event.position)

func handle_mouse_motion(event: InputEventMouseMotion) -> void:
	"""Handle mouse motion events"""
	if is_panning and is_left_click:
		# Pan camera
		var delta = event.relative
		var renderer = GameServices.get_world()
		if renderer and renderer.camera:
			renderer.camera.position -= delta / renderer.camera.zoom.x

func handle_touch(event: InputEventScreenTouch) -> void:
	"""Handle touch events"""
	touch_positions[event.index] = event.position

	if event.pressed:
		if touch_positions.size() == 1:
			# Single touch - prepare for pan or click
			is_left_click = true
			click_position = event.position
			handle_left_click_start(event.position)
		elif touch_positions.size() == 2:
			# Two finger touch - start pinch zoom
			start_pinch_zoom()
	else:
		# Touch released
		if touch_positions.size() == 1:
			# Single touch release
			handle_left_click_release(event.position)
			is_left_click = false
		elif touch_positions.size() == 0:
			# All touches released
			is_left_click = false
			is_panning = false
			is_zooming = false

	touch_positions.erase(event.index)

func handle_touch_drag(event: InputEventScreenDrag) -> void:
	"""Handle touch drag events"""
	touch_positions[event.index] = event.position

	if touch_positions.size() == 1 and is_left_click:
		# Single finger drag - pan camera
		if not selected_building_type:
			is_panning = true
			var delta = event.relative
			var renderer = GameServices.get_world()
			if renderer and renderer.camera:
				renderer.camera.position -= delta / renderer.camera.zoom.x

	elif touch_positions.size() == 2:
		# Two finger drag - pinch zoom
		update_pinch_zoom()

func handle_keyboard(event: InputEventKey) -> void:
	"""Handle keyboard events"""
	if event.pressed:
		match event.keycode:
			KEY_ESCAPE:
				cancel_building_placement()
			KEY_F1:
				toggle_debug_visualization()
			KEY_F5:
				quick_save()
			KEY_F9:
				quick_load()

func handle_left_click_start(position: Vector2) -> void:
	"""Handle left click start"""
	_ui_interaction_active = true
	get_viewport().set_input_as_handled()

	# Reset interaction flag after a short delay
	call_deferred("_reset_ui_interaction_flag")

func handle_left_click_release(position: Vector2) -> void:
	"""Handle left click release"""
	if _is_click_on_ui(position):
		return

	if selected_building_type:
		handle_building_placement(position)
	else:
		handle_world_click(position)

func handle_right_click(position: Vector2) -> void:
	"""Handle right click"""
	cancel_building_placement()

func handle_building_placement(screen_position: Vector2) -> void:
	"""Handle building placement at screen position"""
	var renderer = GameServices.get_world()
	if not renderer or not renderer.camera:
		return

	# Convert screen to world position
	var world_pos = screen_to_world(screen_position)
	var grid_pos = world_to_grid(world_pos)

	# Try to place building
	var world = GameServices.get_world()
	if world and world.can_place_building(selected_building_type, grid_pos):
		var building_id = world.place_building(selected_building_type, grid_pos)
		if building_id:
			print("[InputHandler] Building placed: ", selected_building_type, " at ", grid_pos)

			# Create placement effect
			var renderer_instance = GameServices.get_world()
			if renderer_instance:
				renderer_instance.create_building_placement_effect(world_pos)

			# Clear selection
			selected_building_type = ""
			if building_preview:
				building_preview.queue_free()
				building_preview = null

			# Update UI
			var ui = GameServices.get_ui()
			if ui:
				ui.update_all_resource_displays()
		else:
			print("[InputHandler] Failed to place building")
	else:
		print("[InputHandler] Cannot place building at ", grid_pos)

func handle_world_click(position: Vector2) -> void:
	"""Handle clicking on the world"""
	var world_pos = screen_to_world(position)
	var grid_pos = world_to_grid(world_pos)

	var world = GameServices.get_world()
	if world:
		# Check for building at position
		var building_id = world.get_building_at_position(grid_pos)
		if building_id:
			select_building(building_id)
		else:
			# Handle empty space click (could be for camera focus, etc.)
			pass

func select_building(building_type: String) -> void:
	"""Select a building type for placement"""
	selected_building_type = building_type
	print("[InputHandler] Selected building: ", building_type)

	# Update preview if we have one
	update_building_preview()

func cancel_building_placement() -> void:
	"""Cancel current building placement"""
	selected_building_type = ""
	if building_preview:
		building_preview.queue_free()
		building_preview = null
	print("[InputHandler] Building placement cancelled")

func setup_building_preview() -> void:
	"""Set up building preview node"""
	building_preview = ColorRect.new()
	building_preview.name = "BuildingPreview"
	building_preview.color = Color(0.0, 1.0, 0.0, 0.4)  # Semi-transparent green
	building_preview.mouse_filter = Control.MOUSE_FILTER_IGNORE

func update_building_preview() -> void:
	"""Update building preview position and validity"""
	if not selected_building_type or not building_preview:
		return

	var mouse_pos = get_viewport().get_mouse_position()
	var world_pos = screen_to_world(mouse_pos)
	var grid_pos = world_to_grid(world_pos)

	# Update preview position
	var renderer = GameServices.get_world()
	if renderer:
		var tile_size = 32  # Assuming tile size
		building_preview.position = Vector2(grid_pos.x * tile_size, grid_pos.y * tile_size)

		# Check validity and update color
		var world = GameServices.get_world()
		if world and world.can_place_building(selected_building_type, grid_pos):
			building_preview.color = Color(0.0, 1.0, 0.0, 0.4)  # Green for valid
		else:
			building_preview.color = Color(1.0, 0.0, 0.0, 0.4)  # Red for invalid

		# Add to scene if not already added
		if not building_preview.get_parent():
			renderer.add_child(building_preview)

func zoom_camera(zoom_factor: float, center_point: Vector2) -> void:
	"""Zoom camera by factor, centered on point"""
	var renderer = GameServices.get_world()
	if not renderer or not renderer.camera:
		return

	var old_zoom = renderer.camera.zoom.x
	var new_zoom = clamp(old_zoom * zoom_factor, 0.5, 3.0)

	if new_zoom != old_zoom:
		var zoom_center = screen_to_world(center_point)
		renderer.camera.zoom = Vector2(new_zoom, new_zoom)

		# Adjust position to zoom toward mouse
		var zoom_change = new_zoom / old_zoom
		var offset = zoom_center - renderer.camera.position
		renderer.camera.position = zoom_center - offset / zoom_change

func start_pinch_zoom() -> void:
	"""Start pinch-to-zoom gesture"""
	if touch_positions.size() == 2:
		var touches = touch_positions.values()
		last_pinch_distance = touches[0].distance_to(touches[1])
		initial_zoom = camera_zoom
		is_zooming = true

func update_pinch_zoom() -> void:
	"""Update pinch-to-zoom gesture"""
	if touch_positions.size() == 2 and is_zooming:
		var touches = touch_positions.values()
		var current_distance = touches[0].distance_to(touches[1])

		if last_pinch_distance > 0:
			var zoom_factor = current_distance / last_pinch_distance
			var new_zoom = initial_zoom * zoom_factor
			new_zoom = clamp(new_zoom, 0.5, 3.0)

			var renderer = GameServices.get_world()
			if renderer and renderer.camera:
				renderer.camera.zoom = Vector2(new_zoom, new_zoom)

		last_pinch_distance = current_distance

func screen_to_world(screen_pos: Vector2) -> Vector2:
	"""Convert screen position to world position"""
	var renderer = GameServices.get_world()
	if renderer and renderer.camera:
		return renderer.camera.get_screen_transform().affine_inverse() * screen_pos
	return screen_pos

func world_to_grid(world_pos: Vector2) -> Vector2i:
	"""Convert world position to grid coordinates"""
	var tile_size = 32  # Assuming 32px tiles
	return Vector2i(
		floor(world_pos.x / tile_size),
		floor(world_pos.y / tile_size)
	)

func _is_click_on_ui(screen_position: Vector2) -> bool:
	"""Check if click is on UI elements"""
	var ui = GameServices.get_ui()
	if ui:
		# Check UI panels and controls
		# This would need implementation based on UI layout
		pass
	return false

func toggle_debug_visualization() -> void:
	"""Toggle debug visualization"""
	var renderer = GameServices.get_world()
	if renderer and renderer.has_method("toggle_debug_visualization"):
		renderer.toggle_debug_visualization()

func quick_save() -> void:
	"""Quick save game"""
	var persistence = GameServices.get_persistence()
	if persistence:
		persistence.save_game("quick_save")
		var ui = GameServices.get_ui()
		if ui:
			ui.show_toast("Quick save completed!", "success")

func quick_load() -> void:
	"""Quick load game"""
	var persistence = GameServices.get_persistence()
	if persistence:
		persistence.load_game("quick_save")
		var ui = GameServices.get_ui()
		if ui:
			ui.show_toast("Quick load completed!", "success")

func _reset_ui_interaction_flag() -> void:
	"""Reset the UI interaction flag"""
	_ui_interaction_active = false