class_name UIManagerClass
extends Node

## UIManager - Unified UI management system

const THEME_COLORS = {
	"primary": Color(0.2, 0.4, 0.8),
	"secondary": Color(0.4, 0.6, 1.0),
	"accent": Color(1.0, 0.8, 0.2),
	"success": Color(0.2, 0.8, 0.4),
	"warning": Color(1.0, 0.6, 0.2),
	"error": Color(0.8, 0.2, 0.2),
	"text_primary": Color(0.9, 0.9, 0.9),
	"text_secondary": Color(0.7, 0.7, 0.7),
	"text_muted": Color(0.5, 0.5, 0.5),
	"bg_primary": Color(0.15, 0.15, 0.15),
	"bg_secondary": Color(0.2, 0.2, 0.2),
	"bg_surface": Color(0.25, 0.25, 0.25)
}

# Font sizes
const FONT_SIZES = {
	"xs": 10,
	"sm": 12,
	"md": 14,
	"lg": 16,
	"xl": 18,
	"xxl": 24
}

# UI layer reference
var ui_layer: CanvasLayer = null

# Active panels
var active_panels: Dictionary = {}

# Tutorial system
var tutorial_messages: Dictionary = {}
var tutorial_dismissed: Array = []

func _ready() -> void:
	print("[UIManager] Initializing UI management system")
	setup_ui_layer()

func setup_ui_layer() -> void:
	"""Set up the main UI layer"""
	ui_layer = CanvasLayer.new()
	ui_layer.name = "UIManagerLayer"
	add_child(ui_layer)

func get_color(color_name: String) -> Color:
	"""Get a theme color by name"""
	return THEME_COLORS.get(color_name, Color.WHITE)

func get_font_size(size_name: String) -> int:
	"""Get a font size by name"""
	return FONT_SIZES.get(size_name, 12)

func create_panel(title: String, size: Vector2, position: Vector2 = Vector2(100, 100)) -> Panel:
	"""Create a themed panel with title"""
	var panel = Panel.new()
	panel.custom_minimum_size = size
	panel.position = position

	# Apply theme styling
	var style_box = create_style_box(get_color("bg_surface"), 8)
	style_box.border_color = get_color("primary")
	style_box.border_width_left = 2
	style_box.border_width_right = 2
	style_box.border_width_top = 2
	style_box.border_width_bottom = 2
	panel.add_theme_stylebox_override("panel", style_box)

	# Add title label
	var title_label = Label.new()
	title_label.text = title
	title_label.add_theme_font_size_override("font_size", get_font_size("lg"))
	title_label.add_theme_color_override("font_color", get_color("text_primary"))
	title_label.position = Vector2(10, 10)
	panel.add_child(title_label)

	ui_layer.add_child(panel)
	active_panels[title] = panel

	return panel

func create_button(text: String, parent: Node, size: Vector2) -> Button:
	"""Create a themed button"""
	var button = Button.new()
	button.text = text
	button.custom_minimum_size = size

	# Apply theme styling
	var normal_style = create_style_box(get_color("bg_secondary"), 4)
	var hover_style = create_style_box(get_color("secondary"), 4)
	var pressed_style = create_style_box(get_color("primary"), 4)

	button.add_theme_stylebox_override("normal", normal_style)
	button.add_theme_stylebox_override("hover", hover_style)
	button.add_theme_stylebox_override("pressed", pressed_style)

	parent.add_child(button)
	return button

func create_label(text: String, parent: Node, font_size: String = "md") -> Label:
	"""Create a themed label"""
	var label = Label.new()
	label.text = text
	label.add_theme_font_size_override("font_size", get_font_size(font_size))
	label.add_theme_color_override("font_color", get_color("text_primary"))

	parent.add_child(label)
	return label

func create_resource_card(resource_id: String, current_amount: int, max_amount: int, parent: Node) -> Control:
	"""Create a resource display card"""
	var card = Panel.new()
	card.custom_minimum_size = Vector2(120, 60)

	# Apply styling
	var style_box = create_style_box(get_color("bg_surface"), 4)
	style_box.border_color = get_color("accent")
	style_box.border_width_left = 1
	style_box.border_width_right = 1
	style_box.border_width_top = 1
	style_box.border_width_bottom = 1
	card.add_theme_stylebox_override("panel", style_box)

	# Add tooltip with detailed resource information
	var tooltip_text = generate_resource_tooltip(resource_id, current_amount, max_amount)
	if tooltip_text != "":
		card.tooltip_text = tooltip_text

	# Layout container
	var container = VBoxContainer.new()
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.add_theme_constant_override("separation", 4)
	container.add_theme_constant_override("margin_left", 8)
	container.add_theme_constant_override("margin_right", 8)
	container.add_theme_constant_override("margin_top", 6)
	container.add_theme_constant_override("margin_bottom", 6)
	card.add_child(container)

	# Resource name
	var name_label = create_label(resource_id.capitalize(), container, "sm")
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Amount display
	var amount_text = str(current_amount)
	if max_amount > 0:
		amount_text += "/" + str(max_amount)

	var amount_label = create_label(amount_text, container, "lg")
	amount_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	parent.add_child(card)
	return card

func create_building_card(building_id: String, building_data: Dictionary, parent: Node) -> Button:
	"""Create a building selection card"""
	var card = Button.new()
	card.custom_minimum_size = Vector2(120, 140)
	card.text = ""  # We'll add custom content

	# Apply button styling
	var normal_style = create_style_box(get_color("bg_surface"), 6)
	var hover_style = create_style_box(get_color("secondary"), 6)
	var pressed_style = create_style_box(get_color("primary"), 6)

	normal_style.border_color = get_color("text_muted")
	normal_style.border_width_left = 1
	normal_style.border_width_right = 1
	normal_style.border_width_top = 1
	normal_style.border_width_bottom = 1

	card.add_theme_stylebox_override("normal", normal_style)
	card.add_theme_stylebox_override("hover", hover_style)
	card.add_theme_stylebox_override("pressed", pressed_style)

	# Layout container
	var container = VBoxContainer.new()
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.add_theme_constant_override("separation", 4)
	container.add_theme_constant_override("margin_left", 8)
	container.add_theme_constant_override("margin_right", 8)
	container.add_theme_constant_override("margin_top", 8)
	container.add_theme_constant_override("margin_bottom", 8)
	card.add_child(container)

	# Building name
	var name_label = create_label(building_data.get("name", building_id), container, "md")
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Category
	var category = building_data.get("category", "")
	if category:
		var category_label = create_label(category.capitalize(), container, "xs")
		category_label.add_theme_color_override("font_color", get_color("text_muted"))
		category_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Cost display
	var cost = building_data.get("cost", {})
	if not cost.is_empty():
		var cost_text = "Cost: "
		var cost_parts = []
		for resource in cost:
			cost_parts.append(str(cost[resource]) + " " + resource)
		cost_text += ", ".join(cost_parts)

		var cost_label = create_label(cost_text, container, "xs")
		cost_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART

	parent.add_child(card)
	return card

func create_style_box(bg_color: Color, corner_radius: int = 4, border_width: int = 0) -> StyleBoxFlat:
	"""Create a styled StyleBoxFlat"""
	var style_box = StyleBoxFlat.new()
	style_box.bg_color = bg_color
	style_box.corner_radius_top_left = corner_radius
	style_box.corner_radius_top_right = corner_radius
	style_box.corner_radius_bottom_left = corner_radius
	style_box.corner_radius_bottom_right = corner_radius

	if border_width > 0:
		style_box.border_width_left = border_width
		style_box.border_width_right = border_width
		style_box.border_width_top = border_width
		style_box.border_width_bottom = border_width
		style_box.border_color = bg_color.lightened(0.2)

	return style_box

func show_toast(message: String, type: String = "info", duration: float = 3.0) -> void:
	"""Show a toast notification"""
	var toast = Panel.new()

	# Calculate size based on message length
	var label = Label.new()
	label.text = message
	label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	var min_size = label.get_minimum_size()
	toast.custom_minimum_size = Vector2(max(300, min_size.x + 40), max(60, min_size.y + 20))

	# Position at top center
	var viewport_size = get_viewport().get_visible_rect().size
	toast.position = Vector2(
		(viewport_size.x - toast.custom_minimum_size.x) / 2,
		20
	)

	# Apply styling based on type
	var bg_color = get_color("bg_surface")
	var border_color = get_color("text_muted")

	match type:
		"success":
			border_color = get_color("success")
			toast.add_theme_color_override("font_color", get_color("success"))
		"warning":
			border_color = get_color("warning")
			toast.add_theme_color_override("font_color", get_color("warning"))
		"error":
			border_color = get_color("error")
			toast.add_theme_color_override("font_color", get_color("error"))
		"hunger":
			border_color = Color(1.0, 0.5, 0.2)  # Orange for hunger
			toast.add_theme_color_override("font_color", Color(1.0, 0.7, 0.4))
		"unhappy":
			border_color = Color(0.8, 0.4, 0.8)  # Purple for unhappiness
			toast.add_theme_color_override("font_color", Color(0.9, 0.6, 0.9))

	var style_box = create_style_box(bg_color, 8, 3)
	style_box.border_color = border_color
	toast.add_theme_stylebox_override("panel", style_box)

	# Message label
	var message_label = create_label(message, toast, "md")
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.position = Vector2(20, 10)
	message_label.size = Vector2(toast.custom_minimum_size.x - 40, toast.custom_minimum_size.y - 20)

	ui_layer.add_child(toast)

	# Animate in with bounce effect
	toast.modulate.a = 0.0
	toast.scale = Vector2(0.8, 0.8)
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(toast, "modulate:a", 1.0, 0.3)
	tween.tween_property(toast, "scale", Vector2(1.0, 1.0), 0.3).set_trans(Tween.TRANS_BACK).set_ease(Tween.EASE_OUT)

	# Add icon based on type
	var icon_label = Label.new()
	icon_label.position = Vector2(10, 10)
	match type:
		"success": icon_label.text = "✅"
		"warning": icon_label.text = "⚠️"
		"error": icon_label.text = "❌"
		"hunger": icon_label.text = "🍽️"
		"unhappy": icon_label.text = "😞"
		_: icon_label.text = "ℹ️"
	toast.add_child(icon_label)

	# Auto-remove after duration
	await get_tree().create_timer(duration).timeout

	if is_instance_valid(toast):
		tween = create_tween()
		tween.set_parallel(true)
		tween.tween_property(toast, "modulate:a", 0.0, 0.2)
		tween.tween_property(toast, "scale", Vector2(0.9, 0.9), 0.2)
		tween.tween_callback(_remove_toast.bind(toast))

func show_villager_needs_warnings() -> void:
	"""Check and show warnings about villager needs"""
	var game_world = GameServicesClass.get_world()
	if not game_world:
		push_warning("[UIManager] GameWorld not available")
		return

	var hungry_count = 0
	var unhappy_count = 0
	var starving_count = 0

	var villagers = game_world.get_all_villagers()
	for villager_id in villagers:
		var villager = villagers[villager_id]
		if villager and villager.has_method("get_needs_status"):
			var needs = villager.get_needs_status()
			if needs.get("hunger", 100.0) < 30.0:
				hungry_count += 1
			if needs.get("hunger", 100.0) <= 0.0:
				starving_count += 1
			if needs.get("happiness", 50.0) < 30.0:
				unhappy_count += 1

	# Show warnings
	if starving_count > 0:
		show_toast(str(starving_count) + " villagers are starving!", "error", 5.0)
	elif hungry_count > 0:
		show_toast(str(hungry_count) + " villagers are hungry", "hunger", 4.0)

	if unhappy_count > 0:
		show_toast(str(unhappy_count) + " villagers are unhappy", "unhappy", 4.0)

func generate_resource_tooltip(resource_id: String, current_amount: int, max_amount: int) -> String:
	"""Generate detailed tooltip for a resource"""
	var lines = []
	lines.append("📦 " + resource_id.capitalize())

	# Current amount and capacity
	lines.append("Amount: " + str(current_amount))
	if max_amount > 0:
		lines.append("Capacity: " + str(max_amount))
		var percent_full = (float(current_amount) / float(max_amount)) * 100.0
		lines.append("Usage: " + str(int(percent_full)) + "%")

		if percent_full >= 90.0:
			lines.append("⚠️ Nearly full!")
		elif current_amount == 0:
			lines.append("⚠️ Empty!")

	# Production/Consumption rates
	var economy = GameServicesClass.get_economy()
	if economy and economy.has_method("get_resource_rate"):
		var rate = economy.get_resource_rate(resource_id)
		if rate != 0.0:
			lines.append("")
			if rate > 0:
				lines.append("📈 Production: +" + str(rate) + "/min")
			else:
				lines.append("📉 Consumption: " + str(rate) + "/min")

	# Special information based on resource type
	lines.append("")
	match resource_id:
		"food":
			lines.append("🍽️ Used to feed villagers")
			lines.append("⚡ Affects work efficiency")
			lines.append("❤️ Prevents starvation")
		"wood":
			lines.append("🌲 Gathered by lumberjacks")
			lines.append("🏗️ Used for construction")
			lines.append("⚙️ Required for tools")
		"stone":
			lines.append("⛏️ Mined by miners")
			lines.append("🏗️ Used for advanced buildings")
			lines.append("⚒️ Required for blacksmithing")
		"population":
			lines.append("👥 Total number of villagers")
			lines.append("📈 Grows automatically")
			lines.append("🏠 Housing increases growth rate")
		"tools":
			lines.append("⚒️ Produced by blacksmiths")
			lines.append("⚡ Increases work efficiency")
			lines.append("🏭 Required for advanced production")
		"gold":
			lines.append("💰 Used for research and upgrades")
			lines.append("🏆 Victory condition")
			lines.append("⚙️ Generated by advanced buildings")
		_:
			lines.append("Resource used in production")

	# Quick tips
	if current_amount == 0 and resource_id == "food":
		lines.append("")
		lines.append("💡 Tip: Build farms to produce food!")

	return "\n".join(lines)

func show_tutorial_message(tutorial_id: String, title: String, message: String, auto_dismiss_time: float = 10.0) -> void:
	"""Show a tutorial message if not already dismissed"""
	if tutorial_dismissed.has(tutorial_id):
		return

	# Create tutorial panel
	var tutorial_panel = create_panel(title, Vector2(400, 200), Vector2(100, 100))
	tutorial_panel.custom_minimum_size = Vector2(400, 200)

	var container = VBoxContainer.new()
	container.set_anchors_preset(Control.PRESET_FULL_RECT)
	container.add_theme_constant_override("separation", 10)
	tutorial_panel.add_child(container)

	# Message text
	var message_label = create_label(message, container, "md")
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	message_label.size_flags_vertical = Control.SIZE_EXPAND_FILL

	# Dismiss button
	var dismiss_button = create_button("Got it!", container, Vector2(100, 30))
	dismiss_button.connect("pressed", Callable(self, "_on_tutorial_dismissed").bind(tutorial_id, tutorial_panel))

	# Auto-dismiss timer
	if auto_dismiss_time > 0:
		var timer = Timer.new()
		timer.wait_time = auto_dismiss_time
		timer.one_shot = true
		timer.connect("timeout", Callable(self, "_on_tutorial_dismissed").bind(tutorial_id, tutorial_panel))
		tutorial_panel.add_child(timer)
		timer.start()

	# Store tutorial
	tutorial_messages[tutorial_id] = tutorial_panel

func _on_tutorial_dismissed(tutorial_id: String, panel: Panel) -> void:
	"""Handle tutorial dismissal"""
	if not tutorial_dismissed.has(tutorial_id):
		tutorial_dismissed.append(tutorial_id)

	if is_instance_valid(panel):
		close_panel(panel)

	if tutorial_messages.has(tutorial_id):
		tutorial_messages.erase(tutorial_id)

func check_tutorial_triggers() -> void:
	"""Check for tutorial triggers based on game state"""
	var game_world = GameServicesClass.get_world()
	var economy = GameServicesClass.get_economy()

	if not game_world or not economy:
		push_warning("[UIManager] GameWorld or Economy not available for tutorial checks")
		return

	# Tutorial 1: First villager spawns
	var population = economy.get_resource("population")
	if population >= 1 and not tutorial_dismissed.has("first_villager"):
		show_tutorial_message(
			"first_villager",
			"👋 Welcome to Downtown!",
			"Your first villager has arrived! They will automatically work, but they need food to stay productive. Build a hut for housing and a farm for food production.",
			15.0
		)

	# Tutorial 2: First building placed
	var buildings_placed = game_world.get_all_buildings().size()
	if buildings_placed >= 1 and not tutorial_dismissed.has("first_building"):
		show_tutorial_message(
			"first_building",
			"🏗️ Building Placed!",
			"Great! Buildings provide housing and production. Assign villagers to jobs by right-clicking on buildings. Try building a farm to produce food.",
			12.0
		)

	# Tutorial 3: Villager is hungry
	var villagers = game_world.get_all_villagers()
	var hungry_found = false
	for villager_id in villagers:
		var villager = villagers[villager_id]
		if villager and villager.has_method("get_needs_status"):
			var needs = villager.get_needs_status()
			if needs.get("hunger", 100.0) < 50.0:
				hungry_found = true
				break

	if hungry_found and not tutorial_dismissed.has("villager_hungry"):
		show_tutorial_message(
			"villager_hungry",
			"🍽️ Villagers Need Food!",
			"Your villagers are getting hungry! Build farms to produce food. Hungry villagers work less efficiently and may eventually starve.",
			10.0
		)

	# Tutorial 4: First resource production
	var food_amount = economy.get_resource("food")
	if food_amount >= 5 and not tutorial_dismissed.has("first_food"):
		show_tutorial_message(
			"first_food",
			"🌾 Food Production Started!",
			"Excellent! You're now producing food. Food keeps villagers fed and productive. As your population grows, you'll need more farms.",
			8.0
		)

func create_minimap() -> Control:
	"""Create an enhanced minimap showing buildings, villagers, and resources"""
	var minimap = Panel.new()
	minimap.custom_minimum_size = Vector2(200, 200)
	minimap.position = Vector2(10, get_viewport().get_visible_rect().size.y - 210)

	var style_box = create_style_box(Color(0.1, 0.1, 0.1, 0.8), 4, 2)
	style_box.border_color = Color(0.5, 0.5, 0.5)
	minimap.add_theme_stylebox_override("panel", style_box)

	# Title
	var title = create_label("Minimap", minimap, "sm")
	title.position = Vector2(10, 5)

	# Minimap viewport (simplified representation)
	var map_view = Control.new()
	map_view.custom_minimum_size = Vector2(180, 150)
	map_view.position = Vector2(10, 25)
	minimap.add_child(map_view)

	# Add minimap to UI layer
	ui_layer.add_child(minimap)
	return minimap

func update_minimap(minimap: Control) -> void:
	"""Update the minimap with current game state"""
	if not minimap or not is_instance_valid(minimap):
		return

	var map_view = minimap.get_node_or_null("MapView")
	if not map_view:
		map_view = Control.new()
		map_view.name = "MapView"
		map_view.custom_minimum_size = Vector2(180, 150)
		minimap.add_child(map_view)

	# Clear previous elements
	for child in map_view.get_children():
		child.queue_free()

	var game_world = GameServicesClass.get_world()
	if not game_world:
		push_warning("[UIManager] GameWorld not available for minimap update")
		return

	# Get world bounds for scaling
	var city_size = CityManager.get_grid_size()
	var scale_factor = Vector2(180.0 / city_size.x, 150.0 / city_size.y)

	# Draw buildings
	var buildings = game_world.get_all_buildings()
	for building_id in buildings:
		var building = buildings[building_id]
		if building and building.has("grid_position"):
			var grid_pos = building.grid_position
			var map_pos = Vector2(grid_pos.x * scale_factor.x, grid_pos.y * scale_factor.y)

			var building_dot = ColorRect.new()
			building_dot.size = Vector2(3, 3)
			building_dot.position = map_pos
			building_dot.color = Color(0.7, 0.7, 0.3)  # Yellow for buildings
			map_view.add_child(building_dot)

	# Draw villagers
	var villagers = game_world.get_all_villagers()
	for villager_id in villagers:
		var villager = villagers[villager_id]
		if villager:
			var world_pos = villager.position
			var grid_pos = CityManager.world_to_grid(world_pos)
			var map_pos = Vector2(grid_pos.x * scale_factor.x, grid_pos.y * scale_factor.y)

			var villager_dot = ColorRect.new()
			villager_dot.size = Vector2(2, 2)
			villager_dot.position = map_pos

			# Color based on villager status
			if villager.has_method("get_needs_status"):
				var needs = villager.get_needs_status()
				var hunger = needs.get("hunger", 100.0)
				if hunger < 30.0:
					villager_dot.color = Color(1.0, 0.4, 0.4)  # Red for hungry
				else:
					villager_dot.color = Color(0.4, 0.8, 1.0)  # Blue for healthy
			else:
				villager_dot.color = Color(0.4, 0.8, 1.0)  # Default blue

			map_view.add_child(villager_dot)

func animate_panel_entrance(panel: Control) -> void:
	"""Add smooth entrance animation to a panel"""
	if not panel:
		return

	# Start slightly scaled down and transparent
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.9, 0.9)

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(panel, "modulate:a", 1.0, 0.3)
	tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.3)

func create_bottom_navigation_bar(parent: Node, viewport_size: Vector2) -> Control:
	"""Create bottom navigation bar"""
	var nav_bar = Panel.new()
	nav_bar.name = "BottomNavBar"

	# Size and position
	var nav_height = int(56 * (viewport_size.y / 1080.0))  # Scale based on reference height
	nav_bar.custom_minimum_size = Vector2(viewport_size.x, nav_height)
	nav_bar.position = Vector2(0, viewport_size.y - nav_height)

	# Apply styling
	var style_box = create_style_box(get_color("bg_primary"), 0, 1)
	style_box.border_color = get_color("text_muted")
	nav_bar.add_theme_stylebox_override("panel", style_box)

	# Navigation container
	var nav_container = HBoxContainer.new()
	nav_container.name = "NavContainer"
	nav_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	nav_container.add_theme_constant_override("separation", 4)
	nav_bar.add_child(nav_container)

	parent.add_child(nav_bar)
	return nav_bar

func close_panel(panel: Control) -> void:
	"""Close and remove a panel with animation"""
	if not panel or not is_instance_valid(panel):
		return

	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(panel, "modulate:a", 0.0, 0.2)
	tween.tween_property(panel, "scale", Vector2(0.9, 0.9), 0.2)
	tween.tween_callback(_remove_panel.bind(panel))

func get_active_panels() -> Dictionary:
	"""Get currently active panels"""
	return active_panels.duplicate()

func clear_panel(panel_name: String) -> void:
	"""Clear a specific panel"""
	if active_panels.has(panel_name):
		var panel = active_panels[panel_name]
		if is_instance_valid(panel):
			close_panel(panel)
		active_panels.erase(panel_name)

func _remove_toast(toast: Control) -> void:
	"""Helper function to remove toast"""
	if is_instance_valid(toast):
		toast.queue_free()

func _remove_panel(panel: Control) -> void:
	"""Helper function to remove panel"""
	if is_instance_valid(panel):
		panel.queue_free()

func cleanup() -> void:
	"""Clean up all UI elements and resources"""
	print("[UIManager] Cleaning up UI elements...")

	# Remove all active UI elements
	for panel in active_panels:
		_remove_panel(panel)
	active_panels.clear()

	# Clear tutorial state
	tutorial_messages.clear()
	tutorial_dismissed.clear()

	print("[UIManager] Cleanup complete")
