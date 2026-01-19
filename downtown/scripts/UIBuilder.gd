extends Node

## Cached references for performance
var _ui_theme = null
var _data_manager = null
var _resource_manager = null

## UIBuilder - Comprehensive UI creation system for city management interface
##
## Provides high-level UI creation functions for building consistent, data-driven
## user interface elements. Creates resource cards, building cards, panels, and
## other UI components with proper theming and mobile-optimized layouts.
##
## Key Features:
## - Data-driven UI templates (ResourceCard, BuildingCard)
## - Mobile-optimized touch targets and layouts
## - Theme integration with UITheme
## - Panel creation and management
## - Research and skills UI components
## - Event display systems
##
## Usage:
##   var resource_card = UIBuilder.create_resource_card("food", 50, 100, parent)
##   var building_card = UIBuilder.create_building_card("hut", building_data, parent)

func animate_panel_entrance(panel: Control) -> void:
	"""Add smooth entrance animation to a panel"""
	panel.modulate.a = 0.0
	panel.scale = Vector2(0.9, 0.9)
	var tween = panel.get_tree().create_tween()
	tween.set_parallel(true)
	tween.tween_property(panel, "modulate:a", 1.0, 0.2)
	tween.tween_property(panel, "scale", Vector2(1.0, 1.0), 0.2)

func create_panel(parent: Node, size: Vector2, position: Vector2) -> Control:
	var panel = Panel.new()
	panel.custom_minimum_size = size
	panel.position = position
	parent.add_child(panel)
	return panel

func create_button(text: String, parent: Node, size: Vector2, with_icon: bool = false) -> Button:
	var btn = Button.new()
	btn.text = text
	if size != Vector2(0, 0):
		btn.custom_minimum_size = size
	else:
		btn.custom_minimum_size = Vector2(160, 40)
	parent.add_child(btn)
	return btn

## Helper function to safely access UITheme autoload with caching
func _get_ui_theme():
	if _ui_theme:
		return _ui_theme

	if has_method("get_node_or_null"):
		_ui_theme = get_node_or_null("/root/UITheme")

	return _ui_theme

## Helper function to safely access DataManager autoload with caching
func _get_data_manager():
	if _data_manager:
		return _data_manager

	if has_method("get_node_or_null"):
		_data_manager = get_node_or_null("/root/DataManager")

	return _data_manager

## Helper function to safely access ResourceManager autoload with caching
func _get_resource_manager():
	if _resource_manager:
		return _resource_manager

	if has_method("get_node_or_null"):
		_resource_manager = get_node_or_null("/root/ResourceManager")

	return _resource_manager

func create_resource_card(resource_id: String, current_amount: int, max_amount: int, parent: Node) -> Control:
	# Get resource data from DataManager
	var data_manager = _get_data_manager()
	if not data_manager:
		push_error("[UIBuilder] DataManager not available!")
		return null

	var resources_data = data_manager.get_resources_data()
	var resource_data = {}
	if resources_data and resources_data.has("resources"):
		resource_data = resources_data["resources"].get(resource_id, {})

	if resource_data.is_empty():
		push_warning("UIBuilder: No resource data found for " + resource_id)
		resource_data = {"name": resource_id.capitalize(), "description": "Resource"}

	var ui_theme = _get_ui_theme()
	if not ui_theme:
		push_error("[UIBuilder] UITheme not available!")
		return null

	# Create main card container (larger for better readability and touch)
	var card = Panel.new()
	card.name = "ResourceCard_" + resource_id
	# Larger cards for better mobile usability
	# Default to mobile size, will be adjusted if needed
	var card_width = 160
	var card_height = 80
	card.custom_minimum_size = Vector2(card_width, card_height)
	parent.add_child(card)

	# Apply theme styling
	var style_box = ui_theme.create_style_box(
		ui_theme.get_color("bg_surface"),
		ui_theme.get_color("border_primary"),
		1, 6
	)
	style_box.shadow_color = Color(0, 0, 0, 0.3)
	style_box.shadow_offset = Vector2(0, 2)
	style_box.shadow_size = 3
	card.add_theme_stylebox_override("panel", style_box)

	# Create layout container
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 2)
	vbox.add_theme_constant_override("margin_left", 8)
	vbox.add_theme_constant_override("margin_right", 8)
	vbox.add_theme_constant_override("margin_top", 6)
	vbox.add_theme_constant_override("margin_bottom", 6)
	card.add_child(vbox)

	# Resource name label
	var name_label = Label.new()
	name_label.name = "NameLabel"
	name_label.text = resource_data.get("name", resource_id.capitalize())
	name_label.add_theme_font_size_override("font_size", ui_theme.get_font_size("sm"))
	name_label.add_theme_color_override("font_color", ui_theme.get_resource_color(resource_id))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(name_label)

	# Resource value display (amount/max)
	var value_container = HBoxContainer.new()
	value_container.add_theme_constant_override("separation", 4)
	vbox.add_child(value_container)

	var value_label = Label.new()
	value_label.name = "ValueLabel"
	value_label.text = str(current_amount)
	value_label.add_theme_font_size_override("font_size", _get_ui_theme().get_font_size("lg"))
	value_label.add_theme_color_override("font_color", _get_ui_theme().get_color("text_primary"))
	value_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	value_container.add_child(value_label)

	if max_amount > 0:
		var separator_label = Label.new()
		separator_label.text = "/"
		separator_label.add_theme_font_size_override("font_size", _get_ui_theme().get_font_size("md"))
		separator_label.add_theme_color_override("font_color", _get_ui_theme().get_color("text_muted"))
		value_container.add_child(separator_label)

		var max_label = Label.new()
		max_label.name = "MaxLabel"
		max_label.text = str(max_amount)
		max_label.add_theme_font_size_override("font_size", _get_ui_theme().get_font_size("md"))
		max_label.add_theme_color_override("font_color", _get_ui_theme().get_color("text_muted"))
		value_container.add_child(max_label)

	# Resource rate label (shows production/consumption per minute)
	var rate_label = Label.new()
	rate_label.name = "RateLabel"
	rate_label.text = "0/min"
	rate_label.add_theme_font_size_override("font_size", _get_ui_theme().get_font_size("xs"))
	rate_label.add_theme_color_override("font_color", _get_ui_theme().get_color("text_muted"))
	rate_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	rate_label.visible = true
	vbox.add_child(rate_label)

	# Add tooltip with description (prepared for future tooltip system)
	if resource_data.has("description"):
		var _tooltip_text = resource_data["description"]
		if max_amount > 0:
			_tooltip_text += "\n\nCapacity: " + str(max_amount)
		# Note: Godot doesn't have built-in tooltips for Panels, so we'd need to add a custom tooltip system
		# For now, this is prepared for when tooltips are implemented

	return card

func create_building_card(building_id: String, building_data: Dictionary, _parent: Node) -> Button:
	# Create main card container (Button for interactivity)
	var card = Button.new()
	card.name = "BuildingCard_" + building_id
	card.custom_minimum_size = Vector2(120, 140)
	card.flat = false
	
	# Create layout container
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 4)
	vbox.add_theme_constant_override("margin_left", 8)
	vbox.add_theme_constant_override("margin_right", 8)
	vbox.add_theme_constant_override("margin_top", 8)
	vbox.add_theme_constant_override("margin_bottom", 8)
	card.add_child(vbox)
	
	# Building name label
	var name_label = Label.new()
	name_label.name = "NameLabel"
	name_label.text = building_data.get("name", building_id)
	name_label.add_theme_font_size_override("font_size", _get_ui_theme().get_font_size("sm"))
	name_label.add_theme_color_override("font_color", _get_ui_theme().get_color("text_primary"))
	name_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	name_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(name_label)
	
	# Category indicator (small label)
	var category = building_data.get("category", "")
	if category != "default":
		var category_label = Label.new()
		category_label.name = "CategoryLabel"
		category_label.text = category.capitalize()
		category_label.add_theme_font_size_override("font_size", _get_ui_theme().get_font_size("xs"))
		category_label.add_theme_color_override("font_color", _get_ui_theme().get_color("text_muted"))
		category_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(category_label)
	
	# Cost display
	var cost = building_data.get("cost", {})
	if not cost.is_empty():
		var cost_container = VBoxContainer.new()
		cost_container.name = "CostContainer"
		cost_container.add_theme_constant_override("separation", 2)
		vbox.add_child(cost_container)
		
		var cost_title = Label.new()
		cost_title.text = "Cost:"
		cost_title.add_theme_font_size_override("font_size", _get_ui_theme().get_font_size("xs"))
		cost_title.add_theme_color_override("font_color", _get_ui_theme().get_color("text_secondary"))
		cost_container.add_child(cost_title)

		for resource_id in cost:
			var cost_label = Label.new()
			var resource_name = resource_id.capitalize()
			var amount = cost[resource_id]
			
			cost_label.text = str(amount) + " " + resource_name
			cost_label.add_theme_font_size_override("font_size", _get_ui_theme().get_font_size("xs"))
			cost_label.add_theme_color_override("font_color", _get_ui_theme().get_resource_color(resource_id))
			cost_container.add_child(cost_label)
	
	# Size indicator
	var size = building_data.get("size", [1, 1])
	if size[0] > 1 or size[1] > 1:
		var size_label = Label.new()
		size_label.text = str(size[0]) + "x" + str(size[1])
		size_label.add_theme_font_size_override("font_size", _get_ui_theme().get_font_size("xs") - 2)
		size_label.add_theme_color_override("font_color", _get_ui_theme().get_color("text_muted"))
		size_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		vbox.add_child(size_label)
	
	# Category-based styling (reuse category variable from above)
	var bg_color: Color = _get_ui_theme().get_color("bg_secondary")
	match category:
		"residential":
			bg_color = Color(0.3, 0.6, 0.9)  # Blue for housing
		"production":
			bg_color = Color(0.9, 0.6, 0.3)  # Orange for production
		"storage":
			bg_color = Color(0.6, 0.9, 0.3)  # Green for storage
		"commercial":
			bg_color = Color(0.9, 0.8, 0.3)  # Yellow for commerce
		"infrastructure":
			bg_color = Color(0.7, 0.7, 0.8)  # Gray for infrastructure
		_:
			bg_color = _get_ui_theme().get_color("accent_primary")

	var styles = _get_ui_theme().create_button_style(
		bg_color,
		bg_color.lightened(0.15),
		bg_color.darkened(0.1),
		_get_ui_theme().get_color("accent_primary")
	)
	
	card.add_theme_stylebox_override("normal", styles.normal)
	card.add_theme_stylebox_override("hover", styles.hover)
	card.add_theme_stylebox_override("pressed", styles.pressed)
	
	# Tooltip - generate simple tooltip from building data
	var tooltip: String = building_data.get("name", building_id)
	if building_data.has("description"):
		tooltip += "\n" + building_data["description"]
	card.tooltip_text = tooltip
	
	return card

func _get_building_button_styles(category: String) -> Dictionary:
	var base_color = _get_ui_theme().get_color("bg_surface")
	var accent_color = _get_ui_theme().get_color("accent_primary")

	# Category-specific color variations
	match category:
		"residential":
			accent_color = Color(0.3, 0.6, 0.9)  # Blue for housing
		"production":
			accent_color = Color(0.9, 0.6, 0.3)  # Orange for production
		"storage":
			accent_color = Color(0.6, 0.9, 0.3)  # Green for storage
		"commercial":
			accent_color = Color(0.9, 0.8, 0.3)  # Yellow for commerce
		"infrastructure":
			accent_color = Color(0.7, 0.7, 0.8)  # Gray for infrastructure
		_:
			accent_color = _get_ui_theme().get_color("accent_primary")

	return {
		"normal": _get_ui_theme().create_style_box(base_color, _get_ui_theme().get_color("border_primary"), 1, 8),
		"hover": _get_ui_theme().create_style_box(base_color.lightened(0.1), accent_color, 2, 8),
		"pressed": _get_ui_theme().create_style_box(base_color.darkened(0.1), accent_color, 2, 8),
		"disabled": _get_ui_theme().create_style_box(_get_ui_theme().get_color("bg_secondary").darkened(0.2), _get_ui_theme().get_color("border_secondary"), 1, 8)
	}

func create_label(text: String, font_size_key: String, color_key: String, parent: Node) -> Label:
	var lab = Label.new()
	lab.text = text
	lab.add_theme_font_size_override("font_size", _get_ui_theme().get_font_size(font_size_key))
	lab.add_theme_color_override("font_color", _get_ui_theme().get_color(color_key))
	parent.add_child(lab)
	return lab

func create_progress_bar(min_val: int, max_val: int, parent: Node, size: Vector2) -> ProgressBar:
	var pb = ProgressBar.new()
	pb.min_value = min_val
	pb.max_value = max_val
	pb.custom_minimum_size = size
	parent.add_child(pb)
	return pb

func create_toast(message: String, toast_type: String, parent: Node, duration: float = 3.0) -> void:
	"""Create a modern toast notification"""
	var toast = Panel.new()
	toast.name = "Toast_" + str(Time.get_ticks_msec())
	toast.set_anchors_preset(Control.PRESET_TOP_WIDE)
	toast.position = Vector2(0, 100)
	toast.custom_minimum_size = Vector2(300, 60)
	parent.add_child(toast)
	
	# Style based on toast type
	var bg_color = _get_ui_theme().get_color("bg_surface")
	var border_color = _get_ui_theme().get_color("border_primary")
	match toast_type:
		"success":
			bg_color = Color(0.2, 0.8, 0.3)
			border_color = Color(0.1, 0.6, 0.2)
		"warning":
			bg_color = Color(0.9, 0.7, 0.2)
			border_color = Color(0.7, 0.5, 0.1)
		"error":
			bg_color = Color(0.8, 0.2, 0.2)
			border_color = Color(0.6, 0.1, 0.1)
		_:
			bg_color = _get_ui_theme().get_color("bg_surface")
			border_color = _get_ui_theme().get_color("border_primary")
	
	var style_box = _get_ui_theme().create_style_box(bg_color, border_color, 2, 8)
	toast.add_theme_stylebox_override("panel", style_box)
	
	# Message label
	var message_label = Label.new()
	message_label.text = message
	message_label.set_anchors_preset(Control.PRESET_FULL_RECT)
	message_label.add_theme_constant_override("margin_left", 12)
	message_label.add_theme_constant_override("margin_right", 12)
	message_label.add_theme_constant_override("margin_top", 8)
	message_label.add_theme_constant_override("margin_bottom", 8)
	message_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	message_label.vertical_alignment = VERTICAL_ALIGNMENT_CENTER
	message_label.add_theme_font_size_override("font_size", _get_ui_theme().get_font_size("base"))
	message_label.add_theme_color_override("font_color", _get_ui_theme().get_color("text_primary"))
	toast.add_child(message_label)
	
	# Auto-remove after duration
	await get_tree().create_timer(duration).timeout
	if is_instance_valid(toast):
		toast.queue_free()

# Phase 2 UI Panel Templates

func create_research_card(research_id: String, research_data: Dictionary, parent: Node, is_active: bool = false, progress: float = 0.0, time_remaining: float = 0.0) -> Control:
	"""Create a card for a single research project"""
	var card = Panel.new()
	card.name = "ResearchCard_" + research_id
	card.custom_minimum_size = Vector2(0, 100) if is_active else Vector2(0, 80)
	parent.add_child(card)
	
	# Apply theme styling
	var style_box = _get_ui_theme().create_style_box(
		_get_ui_theme().get_color("bg_surface"),
		_get_ui_theme().get_color("border_primary"),
		1, 6
	)
	card.add_theme_stylebox_override("panel", style_box)
	
	# Create layout container
	var vbox = VBoxContainer.new()
	vbox.name = "CardVBox"
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 4)
	vbox.add_theme_constant_override("margin_left", 12)
	vbox.add_theme_constant_override("margin_right", 12)
	vbox.add_theme_constant_override("margin_top", 8)
	vbox.add_theme_constant_override("margin_bottom", 8)
	card.add_child(vbox)
	
	# Research name
	var name_label = Label.new()
	name_label.name = "NameLabel"
	name_label.text = research_data.get("name", research_id)
	name_label.add_theme_font_size_override("font_size", _get_ui_theme().get_font_size("md"))
	name_label.add_theme_color_override("font_color", _get_ui_theme().get_color("text_primary"))
	vbox.add_child(name_label)
	
	# Description
	var desc_label = Label.new()
	desc_label.name = "DescLabel"
	desc_label.text = research_data.get("description", "")
	desc_label.add_theme_font_size_override("font_size", _get_ui_theme().get_font_size("sm"))
	desc_label.add_theme_color_override("font_color", _get_ui_theme().get_color("text_secondary"))
	desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	vbox.add_child(desc_label)
	
	# Cost display
	var cost = research_data.get("cost", {})
	if not cost.is_empty():
		var cost_container = HBoxContainer.new()
		cost_container.add_theme_constant_override("separation", 8)
		vbox.add_child(cost_container)
		
		var cost_label = Label.new()
		cost_label.text = "Cost: "
		cost_label.add_theme_font_size_override("font_size", _get_ui_theme().get_font_size("xs"))
		cost_label.add_theme_color_override("font_color", _get_ui_theme().get_color("text_muted"))
		cost_container.add_child(cost_label)
		
		for resource_id in cost:
			var resource_label = Label.new()
			resource_label.text = str(cost[resource_id]) + " " + resource_id.capitalize()
			resource_label.add_theme_font_size_override("font_size", _get_ui_theme().get_font_size("xs"))
			resource_label.add_theme_color_override("font_color", _get_ui_theme().get_resource_color(resource_id))
			cost_container.add_child(resource_label)
	
	# Progress bar and time remaining (if active)
	if is_active:
		var progress_bar = ProgressBar.new()
		progress_bar.value = progress * 100
		progress_bar.max_value = 100
		progress_bar.custom_minimum_size = Vector2(0, 24)
		vbox.add_child(progress_bar)
		
		var progress_label = Label.new()
		progress_label.text = String.num(progress * 100, 1) + "% - " + String.num(time_remaining, 1) + "s remaining"
		progress_label.add_theme_font_size_override("font_size", _get_ui_theme().get_font_size("xs"))
		progress_label.add_theme_color_override("font_color", _get_ui_theme().get_color("text_secondary"))
		vbox.add_child(progress_label)
	
	# Store research_id in metadata for button callbacks
	card.set_meta("research_id", research_id)
	card.set_meta("is_active", is_active)
	
	return card

func create_skill_card(skill_type: int, skill_data: Dictionary, parent: Node) -> Button:
	"""Create a card for a single skill"""
	var card = Button.new()
	card.name = "SkillCard_" + str(skill_type)
	card.custom_minimum_size = Vector2(0, 100)
	card.flat = false
	parent.add_child(card)
	
	# Create layout container
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 4)
	vbox.add_theme_constant_override("margin_left", 12)
	vbox.add_theme_constant_override("margin_right", 12)
	vbox.add_theme_constant_override("margin_top", 8)
	vbox.add_theme_constant_override("margin_bottom", 8)
	card.add_child(vbox)
	
	# Skill name and level
	var name_label = Label.new()
	name_label.name = "NameLabel"
	var skill_name = SkillManager._get_skill_name(skill_type) if SkillManager else "Skill"
	var level = skill_data.get("level", 1)
	name_label.text = skill_name + " (Lv." + str(level) + ")"
	name_label.add_theme_font_size_override("font_size", _get_ui_theme().get_font_size("md"))
	name_label.add_theme_color_override("font_color", _get_ui_theme().get_color("text_primary"))
	vbox.add_child(name_label)
	
	# Efficiency bonus
	var efficiency = skill_data.get("efficiency_bonus", 0.0)
	var efficiency_label = Label.new()
	efficiency_label.text = "Efficiency: +" + String.num(efficiency * 100, 1) + "%"
	efficiency_label.add_theme_font_size_override("font_size", _get_ui_theme().get_font_size("sm"))
	efficiency_label.add_theme_color_override("font_color", _get_ui_theme().get_color("text_secondary"))
	vbox.add_child(efficiency_label)
	
	# XP progress bar
	var xp = skill_data.get("xp", 0.0)
	var xp_to_next = skill_data.get("xp_to_next", 100.0)
	var xp_progress = (xp / xp_to_next * 100) if xp_to_next > 0 else 100
	
	var progress_bar = ProgressBar.new()
	progress_bar.value = xp_progress
	progress_bar.max_value = 100
	progress_bar.custom_minimum_size = Vector2(0, 20)
	vbox.add_child(progress_bar)
	
	# XP text
	var xp_label = Label.new()
	xp_label.text = "XP: " + String.num(xp, 0) + "/" + String.num(xp_to_next, 0) + " (" + String.num(xp_progress, 1) + "%)"
	xp_label.add_theme_font_size_override("font_size", _get_ui_theme().get_font_size("xs"))
	xp_label.add_theme_color_override("font_color", _get_ui_theme().get_color("text_muted"))
	vbox.add_child(xp_label)
	
	# Upgrade cost (if available)
	if SkillManager and SkillManager.can_upgrade_skill(skill_type):
		var upgrade_cost = SkillManager.get_upgrade_cost(skill_type)
		var cost_label = Label.new()
		cost_label.text = "Upgrade: " + str(upgrade_cost) + " Gold"
		cost_label.add_theme_font_size_override("font_size", _get_ui_theme().get_font_size("xs"))
		cost_label.add_theme_color_override("font_color", _get_ui_theme().get_resource_color("gold"))
		vbox.add_child(cost_label)
	
	# Category-based styling
	var bg_color = _get_ui_theme().get_color("bg_secondary")
	if SkillManager and SkillManager.can_upgrade_skill(skill_type):
		bg_color = _get_ui_theme().get_color("status_success").darkened(0.6)
	
	var styles = _get_ui_theme().create_button_style(
		bg_color,
		bg_color.lightened(0.15),
		bg_color.darkened(0.1),
		_get_ui_theme().get_color("accent_primary")
	)
	
	card.add_theme_stylebox_override("normal", styles.normal)
	card.add_theme_stylebox_override("hover", styles.hover)
	card.add_theme_stylebox_override("pressed", styles.pressed)
	
	# Store skill_type in metadata
	card.set_meta("skill_type", skill_type)
	
	return card

func create_event_card(event_data: Dictionary, parent: Node, _is_history: bool = false) -> Control:
	"""Create a card for a single event"""
	var card = Panel.new()
	card.name = "EventCard_" + str(Time.get_ticks_msec())
	card.custom_minimum_size = Vector2(0, 60)
	parent.add_child(card)
	
	# Color code by event type
	var event_type = event_data.get("type", "")
	var border_color = _get_ui_theme().get_color("border_primary")
	var bg_color = _get_ui_theme().get_color("bg_surface")
	
	match event_type:
		"resource_bonus":
			border_color = _get_ui_theme().get_color("status_success")
			bg_color = _get_ui_theme().get_color("status_success").darkened(0.7)
		"resource_shortage":
			border_color = _get_ui_theme().get_color("status_warning")
			bg_color = _get_ui_theme().get_color("status_warning").darkened(0.7)
		"visitor":
			border_color = _get_ui_theme().get_color("accent_primary")
			bg_color = _get_ui_theme().get_color("accent_primary").darkened(0.7)
		"weather":
			border_color = Color(0.7, 0.7, 1.0)
			bg_color = Color(0.5, 0.5, 0.7)
	
	# Apply theme styling
	var style_box = _get_ui_theme().create_style_box(bg_color, border_color, 2, 6)
	card.add_theme_stylebox_override("panel", style_box)
	
	# Create layout container
	var hbox = HBoxContainer.new()
	hbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	hbox.add_theme_constant_override("separation", 8)
	hbox.add_theme_constant_override("margin_left", 12)
	hbox.add_theme_constant_override("margin_right", 12)
	hbox.add_theme_constant_override("margin_top", 8)
	hbox.add_theme_constant_override("margin_bottom", 8)
	card.add_child(hbox)
	
	# Event type icon
	var icon_label = Label.new()
	match event_type:
		"resource_bonus":
			icon_label.text = "✓"
			icon_label.add_theme_color_override("font_color", _get_ui_theme().get_color("status_success"))
		"resource_shortage":
			icon_label.text = "⚠"
			icon_label.add_theme_color_override("font_color", _get_ui_theme().get_color("status_warning"))
		"visitor":
			icon_label.text = "👤"
		"weather":
			icon_label.text = "🌤"
		_:
			icon_label.text = "•"
	icon_label.add_theme_font_size_override("font_size", _get_ui_theme().get_font_size("md"))
	hbox.add_child(icon_label)
	
	# Event text container
	var text_vbox = VBoxContainer.new()
	text_vbox.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	text_vbox.add_theme_constant_override("separation", 2)
	hbox.add_child(text_vbox)
	
	# Event title
	var title_label = Label.new()
	title_label.text = event_data.get("title", "Event")
	title_label.add_theme_font_size_override("font_size", _get_ui_theme().get_font_size("sm"))
	title_label.add_theme_color_override("font_color", _get_ui_theme().get_color("text_primary"))
	text_vbox.add_child(title_label)
	
	# Event message
	var message_label = Label.new()
	message_label.text = event_data.get("message", "")
	message_label.add_theme_font_size_override("font_size", _get_ui_theme().get_font_size("xs"))
	message_label.add_theme_color_override("font_color", _get_ui_theme().get_color("text_secondary"))
	message_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	text_vbox.add_child(message_label)
	
	return card

# Panel Container Functions

func create_research_panel(parent: Node, viewport_size: Vector2) -> Control:
	"""Create the full research panel with all sections"""
	# Landscape-optimized sizing (1920×1080 base)
	var base_height = 1080.0
	var ui_scale = viewport_size.y / base_height
	# Panel scales with viewport, max 90% width, 80% height
	var panel_width = min(int(640 * ui_scale), int(viewport_size.x * 0.9))
	var panel_height = min(int(480 * ui_scale), int(viewport_size.y * 0.8))
	var panel = create_panel(
		parent,
		Vector2(panel_width, panel_height),
		Vector2(viewport_size.x / 2.0 - panel_width / 2.0, viewport_size.y / 2.0 - panel_height / 2.0)
	)
	panel.name = "ResearchPanel"
	
	# Apply panel styling
	var style_box = _get_ui_theme().create_style_box(
		_get_ui_theme().get_color("bg_surface"),
		_get_ui_theme().get_color("border_primary"),
		2, 8
	)
	style_box.shadow_color = Color(0, 0, 0, 0.5)
	style_box.shadow_offset = Vector2(0, 4)
	style_box.shadow_size = 8
	panel.add_theme_stylebox_override("panel", style_box)
	
	# Main container
	var vbox = VBoxContainer.new()
	vbox.name = "MainVBox"
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Scale margins based on UI scale (24px at 1080p base)
	var margin = int(24 * ui_scale)
	vbox.add_theme_constant_override("separation", margin)
	vbox.add_theme_constant_override("margin_left", margin)
	vbox.add_theme_constant_override("margin_right", margin)
	vbox.add_theme_constant_override("margin_top", margin)
	vbox.add_theme_constant_override("margin_bottom", margin)
	panel.add_child(vbox)
	
	# Title
	var title = create_label("Research Center", "2xl", "text_primary", vbox)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Research speed bonus
	if ResearchManager:
		var bonuses = ResearchManager.current_research_bonuses
		var bonuses_label = create_label(
			"Research Speed: " + String.num(bonuses, 2) + "x",
			"base",
			"accent_primary",
			vbox
		)
		bonuses_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		bonuses_label.name = "BonusesLabel"
	
	# Scroll container for research list
	var scroll = ScrollContainer.new()
	scroll.name = "ResearchScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	
	var research_vbox = VBoxContainer.new()
	research_vbox.name = "ResearchVBox"
	research_vbox.add_theme_constant_override("separation", 8)
	scroll.add_child(research_vbox)
	
	# Populate research sections (pass panel reference for refresh callbacks)
	_populate_research_panel(research_vbox, panel)
	
	# Close button
	var close_btn = create_button("Close", vbox, Vector2(0, 44), false)
	close_btn.name = "CloseButton"
	
	return panel

func _populate_research_panel(research_vbox: VBoxContainer, panel: Control) -> void:
	"""Populate research panel with active, available, and completed research"""
	if not ResearchManager:
		return
	
	# Active research section
	var active_research = ResearchManager.get_active_research()
	if not active_research.is_empty():
		var active_title = create_label("Active Research:", "md", "status_warning", research_vbox)
		active_title.name = "ActiveTitle"
		
		for research_id in active_research:
			var research_data = ResearchManager.available_research.get(research_id, {})
			var progress = ResearchManager.get_research_progress(research_id)
			var time_remaining = ResearchManager.get_research_time_remaining(research_id)
			
			var card = create_research_card(research_id, research_data, research_vbox, true, progress, time_remaining)
			
			# Add stop button to card's vbox
			var card_vbox = card.find_child("CardVBox", true, false)
			if card_vbox:
				var stop_btn = create_button("Stop", card_vbox, Vector2(0, 36), false)
				stop_btn.custom_minimum_size = Vector2(80, 36)
				stop_btn.pressed.connect(func(): ResearchManager.stop_research(research_id); refresh_research_panel(panel))
	
	# Available research section
	var available_research = ResearchManager.get_available_research()
	if not available_research.is_empty():
		var available_title = create_label("Available Research:", "md", "status_success", research_vbox)
		available_title.name = "AvailableTitle"
		
		for research_id in available_research:
			var research_data = ResearchManager.available_research.get(research_id, {})
			var card = create_research_card(research_id, research_data, research_vbox, false)
			
			# Add start button to card's vbox
			var card_vbox = card.find_child("CardVBox", true, false)
			if card_vbox:
				var start_btn = create_button("Start", card_vbox, Vector2(0, 36), false)
				start_btn.custom_minimum_size = Vector2(80, 36)
				start_btn.pressed.connect(func(): ResearchManager.start_research(research_id); refresh_research_panel(panel))
	
	# Completed research section
	var completed_research = ResearchManager.get_completed_research()
	if not completed_research.is_empty():
		var completed_title = create_label("Completed Research:", "md", "accent_primary", research_vbox)
		completed_title.name = "CompletedTitle"
		
		for research_id in completed_research:
			var research_data = ResearchManager.available_research.get(research_id, {})
			var _completed_label = create_label("✓ " + research_data.get("name", research_id), "sm", "status_success", research_vbox)

func create_skills_panel(parent: Node, viewport_size: Vector2) -> Control:
	"""Create the full skills panel with all skill cards"""
	# Landscape-optimized sizing (1920×1080 base)
	var base_height = 1080.0
	var ui_scale = viewport_size.y / base_height
	# Panel scales with viewport, max 90% width, 80% height
	var panel_width = min(int(500 * ui_scale), int(viewport_size.x * 0.9))
	var panel_height = min(int(600 * ui_scale), int(viewport_size.y * 0.8))
	var panel = create_panel(
		parent,
		Vector2(panel_width, panel_height),
		Vector2(viewport_size.x / 2.0 - panel_width / 2.0, viewport_size.y / 2.0 - panel_height / 2.0)
	)
	panel.name = "SkillsPanel"
	
	# Apply panel styling
	var style_box = _get_ui_theme().create_style_box(
		_get_ui_theme().get_color("bg_surface"),
		_get_ui_theme().get_color("border_primary"),
		2, 8
	)
	style_box.shadow_color = Color(0, 0, 0, 0.5)
	style_box.shadow_offset = Vector2(0, 4)
	style_box.shadow_size = 8
	panel.add_theme_stylebox_override("panel", style_box)
	
	# Add entrance animation
	animate_panel_entrance(panel)
	
	# Main container
	var vbox = VBoxContainer.new()
	vbox.name = "MainVBox"
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Scale margins based on UI scale (24px at 1080p base)
	var margin = int(24 * ui_scale)
	vbox.add_theme_constant_override("separation", margin)
	vbox.add_theme_constant_override("margin_left", margin)
	vbox.add_theme_constant_override("margin_right", margin)
	vbox.add_theme_constant_override("margin_top", margin)
	vbox.add_theme_constant_override("margin_bottom", margin)
	panel.add_child(vbox)
	
	# Title
	var title = create_label("Village Skills", "2xl", "text_primary", vbox)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Scroll container for skills
	var scroll = ScrollContainer.new()
	scroll.name = "SkillsScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	
	var skills_vbox = VBoxContainer.new()
	skills_vbox.name = "SkillsVBox"
	skills_vbox.add_theme_constant_override("separation", 8)
	scroll.add_child(skills_vbox)
	
	# Populate skills (pass panel reference for refresh callbacks)
	_populate_skills_panel(skills_vbox, panel)
	
	# Close button
	var close_btn = create_button("Close", vbox, Vector2(0, 44), false)
	close_btn.name = "CloseButton"
	
	return panel

func _populate_skills_panel(skills_vbox: VBoxContainer, panel: Control) -> void:
	"""Populate skills panel with all skill cards"""
	if not SkillManager:
		return
	
	var all_skills = SkillManager.get_all_skills()
	for skill_type in SkillManager.SkillType.values():
		if skill_type in all_skills:
			var skill_data = all_skills[skill_type]
			var card = create_skill_card(skill_type, skill_data, skills_vbox)
			card.pressed.connect(func(st = skill_type, p = panel): _on_skill_upgrade_pressed(st, p))

func _on_skill_upgrade_pressed(skill_type: int, panel: Control) -> void:
	"""Handle skill upgrade button press"""
	if SkillManager and SkillManager.can_upgrade_skill(skill_type):
		var success = SkillManager.upgrade_skill(skill_type)
		if success:
			# Refresh the skills panel
			refresh_skills_panel(panel)

func create_events_panel(parent: Node, viewport_size: Vector2, event_history: Array) -> Control:
	"""Create the full events panel with active events and history"""
	# Landscape-optimized sizing (1920×1080 base)
	var base_height = 1080.0
	var ui_scale = viewport_size.y / base_height
	# Panel scales with viewport, max 90% width, 80% height
	var panel_width = min(int(640 * ui_scale), int(viewport_size.x * 0.9))
	var panel_height = min(int(480 * ui_scale), int(viewport_size.y * 0.8))
	var panel = create_panel(
		parent,
		Vector2(panel_width, panel_height),
		Vector2(viewport_size.x / 2.0 - panel_width / 2.0, viewport_size.y / 2.0 - panel_height / 2.0)
	)
	panel.name = "EventsPanel"
	
	# Apply panel styling
	var style_box = _get_ui_theme().create_style_box(
		_get_ui_theme().get_color("bg_surface"),
		_get_ui_theme().get_color("border_primary"),
		2, 8
	)
	style_box.shadow_color = Color(0, 0, 0, 0.5)
	style_box.shadow_offset = Vector2(0, 4)
	style_box.shadow_size = 8
	panel.add_theme_stylebox_override("panel", style_box)
	
	# Add entrance animation
	animate_panel_entrance(panel)
	
	# Main container
	var vbox = VBoxContainer.new()
	vbox.name = "MainVBox"
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Scale margins based on UI scale (24px at 1080p base)
	var margin = int(24 * ui_scale)
	vbox.add_theme_constant_override("separation", margin)
	vbox.add_theme_constant_override("margin_left", margin)
	vbox.add_theme_constant_override("margin_right", margin)
	vbox.add_theme_constant_override("margin_top", margin)
	vbox.add_theme_constant_override("margin_bottom", margin)
	panel.add_child(vbox)
	
	# Title
	var title = create_label("Event Log", "2xl", "text_primary", vbox)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Active events section
	if EventManager:
		var active_events = EventManager.get_active_events()
		if not active_events.is_empty():
			var active_title = create_label("Active Events:", "md", "status_warning", vbox)
			active_title.name = "ActiveEventsTitle"
			
			for event_data in active_events:
				create_event_card(event_data, vbox, false)
	
	# Event history section
	var history_title = create_label("Event History:", "md", "accent_primary", vbox)
	history_title.name = "HistoryTitle"
	
	# Scroll container for history
	var scroll = ScrollContainer.new()
	scroll.name = "EventsScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	
	var history_vbox = VBoxContainer.new()
	history_vbox.name = "HistoryVBox"
	history_vbox.add_theme_constant_override("separation", 8)
	scroll.add_child(history_vbox)
	
	# Populate event history
	_populate_events_history(history_vbox, event_history)
	
	# Close button
	var close_btn = create_button("Close", vbox, Vector2(0, 44), false)
	close_btn.name = "CloseButton"
	
	return panel

func _populate_events_history(history_vbox: VBoxContainer, event_history: Array) -> void:
	"""Populate event history section"""
	if event_history.size() > 0:
		# Display most recent first
		for i in range(event_history.size() - 1, -1, -1):
			var event_entry = event_history[i]
			var event_data = event_entry.get("data", {})
			create_event_card(event_data, history_vbox, true)
	else:
		var _no_events_label = create_label(
			"No events yet. Events will appear here as they occur.",
			"sm",
			"text_muted",
			history_vbox
		)

# Panel Refresh Methods

func refresh_research_panel(panel: Control) -> void:
	"""Refresh research panel content without recreating the entire panel"""
	if not panel or not ResearchManager:
		return
	
	var scroll = panel.find_child("ResearchScroll", true, false)
	if not scroll:
		return
	
	var research_vbox = scroll.find_child("ResearchVBox", true, false)
	if not research_vbox:
		return
	
	# Clear existing content (remove and free immediately)
	for child in research_vbox.get_children():
		research_vbox.remove_child(child)
		child.queue_free()
	
	# Repopulate (pass panel reference)
	_populate_research_panel(research_vbox, panel)
	
	# Update bonuses label
	var bonuses_label = panel.find_child("BonusesLabel", true, false)
	if bonuses_label and ResearchManager:
		var bonuses = ResearchManager.current_research_bonuses
		bonuses_label.text = "Research Speed: " + String.num(bonuses, 2) + "x"

func refresh_skills_panel(panel: Control) -> void:
	"""Refresh skills panel content"""
	if not panel or not SkillManager:
		return
	
	var scroll = panel.find_child("SkillsScroll", true, false)
	if not scroll:
		return
	
	var skills_vbox = scroll.find_child("SkillsVBox", true, false)
	if not skills_vbox:
		return
	
	# Clear existing content (remove and free immediately)
	for child in skills_vbox.get_children():
		skills_vbox.remove_child(child)
		child.queue_free()
	
	# Repopulate (pass panel reference)
	_populate_skills_panel(skills_vbox, panel)

func refresh_events_panel(panel: Control, event_history: Array) -> void:
	"""Refresh events panel content"""
	if not panel:
		return
	
	# Find main vbox container
	var main_vbox = panel.find_child("MainVBox", true, false)
	if not main_vbox:
		return
	
	# Refresh active events section
	var active_events_title = panel.find_child("ActiveEventsTitle", true, false)
	
	# Remove existing active event cards
	if active_events_title:
		var parent = active_events_title.get_parent()
		var title_index = active_events_title.get_index()
		# Remove all event cards after the title (before HistoryTitle)
		for i in range(parent.get_child_count() - 1, title_index, -1):
			var child = parent.get_child(i)
			if child.name.begins_with("EventCard_"):
				parent.remove_child(child)
				child.queue_free()
	
	# Add new active events
	if EventManager:
		var active_events = EventManager.get_active_events()
		if not active_events.is_empty():
			# Create title if it doesn't exist
			if not active_events_title:
				active_events_title = create_label("Active Events:", "md", "status_warning", main_vbox)
				active_events_title.name = "ActiveEventsTitle"
				# Insert before HistoryTitle
				var history_title = panel.find_child("HistoryTitle", true, false)
				if history_title:
					var history_index = history_title.get_index()
					main_vbox.move_child(active_events_title, history_index)
			
			# Add active event cards
			var insert_index = active_events_title.get_index() + 1
			for event_data in active_events:
				var card = create_event_card(event_data, main_vbox, false)
				main_vbox.move_child(card, insert_index)
				insert_index += 1
		else:
			# Remove title if no active events
			if active_events_title:
				var title_parent = active_events_title.get_parent()
				if title_parent:
					title_parent.remove_child(active_events_title)
				active_events_title.queue_free()
	
	# Refresh history section
	var history_vbox = panel.find_child("HistoryVBox", true, false)
	if history_vbox:
		# Clear existing content (remove and free immediately)
		for child in history_vbox.get_children():
			history_vbox.remove_child(child)
			child.queue_free()
		
		# Repopulate
		_populate_events_history(history_vbox, event_history)

# Goals/Progression Panel

func create_goals_panel(parent: Node, viewport_size: Vector2) -> Control:
	"""Create the full goals/progression panel with active goals, completed goals, and unlocks"""
	# Landscape-optimized sizing (1920×1080 base)
	var base_height = 1080.0
	var ui_scale = viewport_size.y / base_height
	# Panel scales with viewport, max 90% width, 80% height
	var panel_width = min(int(500 * ui_scale), int(viewport_size.x * 0.9))
	var panel_height = min(int(600 * ui_scale), int(viewport_size.y * 0.8))
	var panel = create_panel(
		parent,
		Vector2(panel_width, panel_height),
		Vector2(viewport_size.x / 2.0 - panel_width / 2.0, viewport_size.y / 2.0 - panel_height / 2.0)
	)
	panel.name = "GoalsPanel"
	
	# Apply panel styling
	var style_box = _get_ui_theme().create_style_box(
		_get_ui_theme().get_color("bg_surface"),
		_get_ui_theme().get_color("border_primary"),
		2, 8
	)
	style_box.shadow_color = Color(0, 0, 0, 0.5)
	style_box.shadow_offset = Vector2(0, 4)
	style_box.shadow_size = 8
	panel.add_theme_stylebox_override("panel", style_box)
	
	# Add entrance animation
	animate_panel_entrance(panel)
	
	# Main container
	var vbox = VBoxContainer.new()
	vbox.name = "MainVBox"
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Scale margins based on UI scale (24px at 1080p base)
	var margin = int(24 * ui_scale)
	vbox.add_theme_constant_override("separation", margin)
	vbox.add_theme_constant_override("margin_left", margin)
	vbox.add_theme_constant_override("margin_right", margin)
	vbox.add_theme_constant_override("margin_top", margin)
	vbox.add_theme_constant_override("margin_bottom", margin)
	panel.add_child(vbox)
	
	# Title
	var title = create_label("Goals & Progression", "2xl", "text_primary", vbox)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Scroll container for content
	var scroll = ScrollContainer.new()
	scroll.name = "GoalsScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)
	
	var goals_vbox = VBoxContainer.new()
	goals_vbox.name = "GoalsVBox"
	goals_vbox.add_theme_constant_override("separation", 8)
	scroll.add_child(goals_vbox)
	
	# Populate goals (pass panel reference for refresh callbacks)
	_populate_goals_panel(goals_vbox, panel)
	
	# Close button
	var close_btn = create_button("Close", vbox, Vector2(0, 44), false)
	close_btn.name = "CloseButton"
	
	return panel

func _populate_goals_panel(goals_vbox: VBoxContainer, _panel: Control) -> void:
	"""Populate goals panel with active goals, completed goals, and unlocked buildings"""
	if not ProgressionSystem:
		return
	
	# Active goals section
	var active_goals = []
	for goal_id in ProgressionSystem.goals.keys():
		var goal = ProgressionSystem.goals[goal_id]
		if not goal.get("completed", false):
			active_goals.append(goal)
	
	if not active_goals.is_empty():
		var active_title = create_label("Active Goals:", "md", "status_warning", goals_vbox)
		active_title.name = "ActiveGoalsTitle"
		
		for goal in active_goals:
			create_goal_card(goal, goals_vbox, false)
	
	# Completed goals section
	var completed_goals = []
	for goal_id in ProgressionSystem.completed_goals:
		if ProgressionSystem.goals.has(goal_id):
			completed_goals.append(ProgressionSystem.goals[goal_id])
	
	if not completed_goals.is_empty():
		var completed_title = create_label("Completed Goals:", "md", "status_success", goals_vbox)
		completed_title.name = "CompletedGoalsTitle"
		
		for goal in completed_goals:
			create_goal_card(goal, goals_vbox, true)
	
	# Unlocked buildings section
	var unlocked_buildings = ProgressionSystem.unlocked_buildings
	if not unlocked_buildings.is_empty():
		var unlocks_title = create_label("Unlocked Buildings:", "md", "accent_primary", goals_vbox)
		unlocks_title.name = "UnlocksTitle"
		
		# Get building data for display
		var buildings_data = _get_data_manager().get_data("buildings")
		if buildings_data:
			var buildings_dict = buildings_data.get("buildings", buildings_data)
			for building_id in unlocked_buildings:
				if buildings_dict.has(building_id):
					var building_data = buildings_dict[building_id]
					var unlock_label = create_label(
						"✓ " + building_data.get("name", building_id),
						"sm",
						"text_secondary",
						goals_vbox
					)
					unlock_label.add_theme_constant_override("margin_left", 16)

func create_goal_card(goal: Dictionary, parent: Node, is_completed: bool) -> Control:
	"""Create a card for a single goal"""
	var card = Panel.new()
	card.name = "GoalCard_" + goal.get("id", "")
	card.custom_minimum_size = Vector2(0, 80)
	parent.add_child(card)
	
	# Category-based styling
	var bg_color = _get_ui_theme().get_color("bg_secondary")
	var border_color = _get_ui_theme().get_color("border_primary")
	if is_completed:
		bg_color = _get_ui_theme().get_color("status_success").darkened(0.7)
		border_color = _get_ui_theme().get_color("status_success")
	else:
		bg_color = _get_ui_theme().get_color("status_warning").darkened(0.7)
		border_color = _get_ui_theme().get_color("status_warning")
	
	var style_box = _get_ui_theme().create_style_box(bg_color, border_color, 2, 6)
	card.add_theme_stylebox_override("panel", style_box)
	
	# Create layout container
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 4)
	vbox.add_theme_constant_override("margin_left", 12)
	vbox.add_theme_constant_override("margin_right", 12)
	vbox.add_theme_constant_override("margin_top", 8)
	vbox.add_theme_constant_override("margin_bottom", 8)
	card.add_child(vbox)
	
	# Goal name
	var name_label = Label.new()
	name_label.text = goal.get("name", "")
	name_label.add_theme_font_size_override("font_size", _get_ui_theme().get_font_size("md"))
	name_label.add_theme_color_override("font_color", _get_ui_theme().get_color("text_primary"))
	vbox.add_child(name_label)
	
	# Goal description
	var desc_label = Label.new()
	desc_label.text = goal.get("description", "")
	desc_label.add_theme_font_size_override("font_size", _get_ui_theme().get_font_size("sm"))
	desc_label.add_theme_color_override("font_color", _get_ui_theme().get_color("text_secondary"))
	vbox.add_child(desc_label)
	
	# Progress bar (for active goals)
	if not is_completed:
		var goal_type = goal.get("type", "")
		var progress = 0.0
		var max_value = 100.0
		
		match goal_type:
			"build_building":
				var current = goal.get("current_count", 0)
				var target = goal.get("target_count", 1)
				progress = (current / float(target)) * 100.0 if target > 0 else 0.0
				max_value = 100.0
			"harvest_resource", "accumulate_resource":
				var current = goal.get("current_amount", 0.0)
				var target = goal.get("target_amount", 100.0)
				progress = (current / target) * 100.0 if target > 0 else 0.0
				max_value = 100.0
			"reach_population":
				var current = goal.get("current", 0)
				var target = goal.get("target", 100)
				progress = (current / float(target)) * 100.0 if target > 0 else 0.0
				max_value = 100.0
			"complete_research":
				var research_id = goal.get("target", "")
				progress = 100.0 if ResearchManager and research_id in ResearchManager.completed_research else 0.0
				max_value = 100.0
		
		var progress_bar = ProgressBar.new()
		progress_bar.value = progress
		progress_bar.max_value = max_value
		progress_bar.custom_minimum_size = Vector2(0, 20)
		vbox.add_child(progress_bar)
		
		# Progress text
		var progress_text = String.num(progress, 1) + "%"
		var progress_label = Label.new()
		progress_label.text = "Progress: " + progress_text
		progress_label.add_theme_font_size_override("font_size", _get_ui_theme().get_font_size("xs"))
		progress_label.add_theme_color_override("font_color", _get_ui_theme().get_color("text_muted"))
		vbox.add_child(progress_label)
	else:
		# Completed indicator
		var completed_label = Label.new()
		completed_label.text = "✓ Completed"
		completed_label.add_theme_font_size_override("font_size", _get_ui_theme().get_font_size("sm"))
		completed_label.add_theme_color_override("font_color", _get_ui_theme().get_color("status_success"))
		vbox.add_child(completed_label)
	
	return card

func refresh_goals_panel(panel: Control) -> void:
	"""Refresh goals panel content"""
	if not panel or not ProgressionSystem:
		return
	
	var scroll = panel.find_child("GoalsScroll", true, false)
	if not scroll:
		return
	
	var goals_vbox = scroll.find_child("GoalsVBox", true, false)
	if not goals_vbox:
		return
	
	# Clear existing content
	for child in goals_vbox.get_children():
		goals_vbox.remove_child(child)
		child.queue_free()
	
	# Repopulate
	_populate_goals_panel(goals_vbox, panel)

# Resource Detail Panel

func create_resource_detail_panel(parent: Node, viewport_size: Vector2, resource_id: String) -> Control:
	"""Create detailed resource information panel"""
	# Landscape-optimized sizing (1920×1080 base)
	var base_height = 1080.0
	var ui_scale = viewport_size.y / base_height
	# Panel scales with viewport, max 90% width, 70% height
	var panel_width = min(int(500 * ui_scale), int(viewport_size.x * 0.9))
	var panel_height = min(int(400 * ui_scale), int(viewport_size.y * 0.7))
	var panel = create_panel(
		parent,
		Vector2(panel_width, panel_height),
		Vector2(viewport_size.x / 2.0 - panel_width / 2.0, viewport_size.y / 2.0 - panel_height / 2.0)
	)
	panel.name = "ResourceDetailPanel"
	
	# Apply panel styling
	var style_box = _get_ui_theme().create_style_box(
		_get_ui_theme().get_color("bg_surface"),
		_get_ui_theme().get_color("border_primary"),
		2, 8
	)
	style_box.shadow_color = Color(0, 0, 0, 0.5)
	style_box.shadow_offset = Vector2(0, 4)
	style_box.shadow_size = 8
	panel.add_theme_stylebox_override("panel", style_box)
	
	# Main container
	var vbox = VBoxContainer.new()
	vbox.name = "MainVBox"
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	# Scale margins based on UI scale (24px at 1080p base)
	var margin = int(24 * ui_scale)
	vbox.add_theme_constant_override("separation", margin)
	vbox.add_theme_constant_override("margin_left", margin)
	vbox.add_theme_constant_override("margin_right", margin)
	vbox.add_theme_constant_override("margin_top", margin)
	vbox.add_theme_constant_override("margin_bottom", margin)
	panel.add_child(vbox)
	
	# Get resource data
	var resources_data = _get_data_manager().get_resources_data()
	var resource_data = {}
	if resources_data and resources_data.has("resources"):
		resource_data = resources_data["resources"].get(resource_id, {})
	
	var resource_name = resource_data.get("name", resource_id.capitalize())
	
	# Title
	var title = create_label(resource_name, "2xl", "text_primary", vbox)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	
	# Description
	if resource_data.has("description"):
		var desc_label = create_label(resource_data["description"], "sm", "text_secondary", vbox)
		desc_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		desc_label.autowrap_mode = TextServer.AUTOWRAP_WORD_SMART
	
	# Current amount and capacity
	var resource_manager = _get_resource_manager()
	if resource_manager:
		var current_amount = resource_manager.get_resource(resource_id)
		var capacity = resource_manager.get_storage_capacity(resource_id)
		
		var amount_label = create_label(
			"Amount: " + str(int(current_amount)) + " / " + str(capacity),
			"lg",
			"text_primary",
			vbox
		)
		amount_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		
		# Capacity utilization bar
		if capacity > 0:
			var utilization = current_amount / float(capacity)
			var progress_bar = ProgressBar.new()
			progress_bar.value = utilization * 100
			progress_bar.max_value = 100
			progress_bar.custom_minimum_size = Vector2(0, 24)
			vbox.add_child(progress_bar)
			
			# Color-code based on utilization
			if utilization >= 1.0:
				progress_bar.modulate = _get_ui_theme().get_color("status_error")
			elif utilization >= 0.8:
				progress_bar.modulate = _get_ui_theme().get_color("status_warning")
			else:
				progress_bar.modulate = _get_ui_theme().get_color("status_success")
	
	# Production/Consumption info (if available)
	var production_sources = _get_resource_sources(resource_id)
	var consumption_uses = _get_resource_uses(resource_id)
	
	if not production_sources.is_empty():
		var _sources_title = create_label("Produced by:", "md", "accent_primary", vbox)
		for source in production_sources:
			var _source_label = create_label("  • " + source, "sm", "text_secondary", vbox)
	
	if not consumption_uses.is_empty():
		var _uses_title = create_label("Used by:", "md", "status_warning", vbox)
		for use in consumption_uses:
			var _use_label = create_label("  • " + use, "sm", "text_secondary", vbox)
	
	# Close button
	var close_btn = create_button("Close", vbox, Vector2(0, 44), false)
	close_btn.name = "CloseButton"
	
	return panel

func _get_resource_sources(resource_id: String) -> Array:
	"""Get list of buildings that produce this resource"""
	var sources = []
	if not BuildingManager:
		return sources
	
	var all_buildings = BuildingManager.placed_buildings
	for building_id in all_buildings:
		var building = all_buildings[building_id]
		var building_data = building.get("building_data", {})
		var effects = building_data.get("effects", {})
		
		if effects.has("gathers") and effects.gathers.has(resource_id):
			var building_name = building_data.get("name", building_id)
			sources.append(building_name)
	
	return sources

func _get_resource_uses(resource_id: String) -> Array:
	"""Get list of buildings that consume this resource"""
	var uses = []
	if not BuildingManager:
		return uses
	
	var all_buildings = BuildingManager.placed_buildings
	for building_id in all_buildings:
		var building = all_buildings[building_id]
		var building_data = building.get("building_data", {})
		var effects = building_data.get("effects", {})
		
		if effects.has("consumes") and effects.consumes.has(resource_id):
			var building_name = building_data.get("name", building_id)
			uses.append(building_name)
		
		# Also check building costs
		var cost = building_data.get("cost", {})
		if cost.has(resource_id):
			var building_name = building_data.get("name", building_id)
			if building_name not in uses:
				uses.append(building_name + " (construction)")
	
	return uses

# Bottom Navigation Bar & FAB

func create_bottom_navigation_bar(parent: Node, viewport_size: Vector2) -> Control:
	"""Create bottom navigation bar for primary actions (landscape-optimized)"""
	var nav_bar = Panel.new()
	nav_bar.name = "BottomNavBar"
	# Landscape: Scale nav bar height based on UI scale (56px at 1080p base)
	var base_height = 1080.0
	var ui_scale = viewport_size.y / base_height
	var nav_height = int(56 * ui_scale)
	nav_bar.custom_minimum_size = Vector2(viewport_size.x, nav_height)
	nav_bar.position = Vector2(0, viewport_size.y - nav_height)
	nav_bar.mouse_filter = Control.MOUSE_FILTER_STOP  # Block input to world behind nav bar
	parent.add_child(nav_bar)
	
	# Apply styling
	var style_box = _get_ui_theme().create_style_box(
		_get_ui_theme().get_color("bg_surface"),
		_get_ui_theme().get_color("border_primary"),
		2, 0
	)
	style_box.shadow_color = Color(0, 0, 0, 0.3)
	style_box.shadow_offset = Vector2(0, -2)
	style_box.shadow_size = 4
	nav_bar.add_theme_stylebox_override("panel", style_box)
	
	# Navigation buttons container
	var nav_container = HBoxContainer.new()
	nav_container.name = "NavContainer"
	nav_container.set_anchors_preset(Control.PRESET_FULL_RECT)
	nav_container.add_theme_constant_override("separation", 8)
	nav_container.add_theme_constant_override("margin_left", 12)
	nav_container.add_theme_constant_override("margin_right", 12)
	nav_container.add_theme_constant_override("margin_top", 8)
	nav_container.add_theme_constant_override("margin_bottom", 8)
	nav_container.alignment = BoxContainer.ALIGNMENT_CENTER
	nav_bar.add_child(nav_container)
	
	return nav_bar

func create_floating_action_button(parent: Node, viewport_size: Vector2, icon_text: String, callback: Callable) -> Button:
	"""Create Floating Action Button (FAB) at bottom-right for primary action"""
	# Landscape: Scale FAB size based on UI scale (64px at 1080p base)
	var base_height = 1080.0
	var ui_scale = viewport_size.y / base_height
	var fab_size = int(64 * ui_scale)
	var fab = Button.new()
	fab.name = "FAB"
	fab.text = icon_text
	fab.custom_minimum_size = Vector2(fab_size, fab_size)
	# Position above bottom nav bar (scale spacing with UI scale)
	var nav_height = int(56 * ui_scale)
	var spacing = int(16 * ui_scale)
	fab.position = Vector2(viewport_size.x - fab_size - spacing, viewport_size.y - fab_size - nav_height - spacing)
	fab.flat = false
	parent.add_child(fab)
	
	# Circular button styling
	var fab_color = _get_ui_theme().get_color("accent_primary")
	var styles = _get_ui_theme().create_button_style(
		fab_color,
		fab_color.lightened(0.2),
		fab_color.darkened(0.15),
		fab_color
	)
	fab.add_theme_stylebox_override("normal", styles.normal)
	fab.add_theme_stylebox_override("hover", styles.hover)
	fab.add_theme_stylebox_override("pressed", styles.pressed)
	
	# Make it circular (rounded corners)
	var normal_style = fab.get_theme_stylebox("normal")
	if normal_style is StyleBoxFlat:
		normal_style.corner_radius_top_left = fab_size / 2.0
		normal_style.corner_radius_top_right = fab_size / 2.0
		normal_style.corner_radius_bottom_left = fab_size / 2.0
		normal_style.corner_radius_bottom_right = fab_size / 2.0
	
	# Connect callback
	fab.pressed.connect(callback)

	return fab

func create_save_load_panel(parent: Node, viewport_size: Vector2) -> Control:
	"""Create the save/load panel with save slots and manual save options"""
	# Landscape-optimized sizing (1920×1080 base)
	var base_height = 1080.0
	var ui_scale = viewport_size.y / base_height
	# Panel scales with viewport, max 90% width, 80% height
	var panel_width = min(int(500 * ui_scale), int(viewport_size.x * 0.8))
	var panel_height = min(int(600 * ui_scale), int(viewport_size.y * 0.8))
	var panel = create_panel(
		parent,
		Vector2(panel_width, panel_height),
		Vector2(viewport_size.x / 2.0 - panel_width / 2.0, viewport_size.y / 2.0 - panel_height / 2.0)
	)
	panel.name = "SaveLoadPanel"

	# Apply panel styling
	var style_box = _get_ui_theme().create_style_box(
		_get_ui_theme().get_color("bg_surface"),
		_get_ui_theme().get_color("border_primary"),
		2, 8
	)
	style_box.shadow_color = Color(0, 0, 0, 0.5)
	style_box.shadow_offset = Vector2(0, 4)
	style_box.shadow_size = 8
	panel.add_theme_stylebox_override("panel", style_box)

	# Main container
	var vbox = VBoxContainer.new()
	vbox.name = "MainVBox"
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	var margin = int(24 * ui_scale)
	vbox.add_theme_constant_override("separation", margin)
	vbox.add_theme_constant_override("margin_left", margin)
	vbox.add_theme_constant_override("margin_right", margin)
	vbox.add_theme_constant_override("margin_top", margin)
	vbox.add_theme_constant_override("margin_bottom", margin)
	panel.add_child(vbox)

	# Title
	var title = create_label("Save / Load Game", "2xl", "text_primary", vbox)
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Save section
	var save_title = create_label("Save Game", "lg", "text_primary", vbox)
	save_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Save name input
	var save_hbox = HBoxContainer.new()
	save_hbox.add_theme_constant_override("separation", 12)
	vbox.add_child(save_hbox)

	var save_label = create_label("Save Name:", "base", "text_secondary", save_hbox)
	var save_input = LineEdit.new()
	save_input.name = "SaveNameInput"
	save_input.placeholder_text = "Enter save name..."
	save_input.size_flags_horizontal = Control.SIZE_EXPAND_FILL
	save_input.custom_minimum_size = Vector2(200, 40)
	save_hbox.add_child(save_input)

	var save_btn = create_button("💾 Save", save_hbox, Vector2(100, 40), false)
	save_btn.custom_minimum_size = Vector2(100, 40)

	# Load section
	var load_title = create_label("Load Game", "lg", "text_primary", vbox)
	load_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER

	# Save files list
	var scroll = ScrollContainer.new()
	scroll.name = "SaveScroll"
	scroll.size_flags_vertical = Control.SIZE_EXPAND_FILL
	vbox.add_child(scroll)

	var save_list_vbox = VBoxContainer.new()
	save_list_vbox.name = "SaveListVBox"
	save_list_vbox.add_theme_constant_override("separation", 8)
	scroll.add_child(save_list_vbox)

	# Populate save list
	_populate_save_list(save_list_vbox, panel)

	# Close button
	var close_btn = create_button("Close", vbox, Vector2(0, 44), false)
	close_btn.name = "CloseButton"

	return panel

func _populate_save_list(save_list_vbox: VBoxContainer, panel: Control) -> void:
	"""Populate the save files list with load buttons"""
	if not SaveManager:
		return

	var saves = SaveManager.list_saves()
	if saves.is_empty():
		var no_saves_label = create_label("No saved games found", "base", "text_secondary", save_list_vbox)
		no_saves_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		return

	for save_name in saves:
		var save_hbox = HBoxContainer.new()
		save_hbox.add_theme_constant_override("separation", 12)
		save_list_vbox.add_child(save_hbox)

		# Save name
		var name_label = create_label(save_name, "base", "text_primary", save_hbox)
		name_label.size_flags_horizontal = Control.SIZE_EXPAND_FILL

		# Load button
		var load_btn = create_button("📂 Load", save_hbox, Vector2(80, 36), false)
		load_btn.custom_minimum_size = Vector2(80, 36)

		# Connect load button (closure to capture save_name)
		load_btn.pressed.connect(func(): _on_save_load_clicked(save_name, panel))

func _on_save_load_clicked(save_name: String, panel: Control) -> void:
	"""Handle save file load button click"""
	if SaveManager and SaveManager.load_game(save_name):
		# Close panel after successful load
		if panel and panel.get_parent():
			panel.get_parent().remove_child(panel)
			panel.queue_free()
