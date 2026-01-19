extends Node

var resource_cards := {}

## Helper function to safely access ResourceManager autoload
func _get_resource_manager():
	if has_method("get_node_or_null"):
		return get_node_or_null("/root/ResourceManager")
	return null

## Helper function to safely access DataManager autoload
func _get_data_manager():
	if has_method("get_node_or_null"):
		return get_node_or_null("/root/DataManager")
	return null

func _ready():
	var root_ui = get_tree().get_root().find_node("UILayer", true, false)
	if not root_ui:
		push_warning("HUD: UILayer not found; aborting HUD initialization")
		return
	
	var viewport_size = get_viewport().get_visible_rect().size
	var hud_panel = UIBuilder.create_panel(root_ui, Vector2(viewport_size.x, 72), Vector2(0, 0))
	hud_panel.name = "HUDPanel"
	
	var hbox = HBoxContainer.new()
	hbox.add_theme_constant_override("separation", 12)
	hbox.add_theme_constant_override("margin_left", 8)
	hbox.add_theme_constant_override("margin_right", 8)
	hud_panel.add_child(hbox)
	
	# Create resource cards for each known resource
	var resource_manager = _get_resource_manager()
	if resource_manager and resource_manager.has_method("get_resource"):
		var resource_ids = ["food", "wood", "stone", "population"]
		for resource_id in resource_ids:
			var card = _create_resource_card(resource_id, hbox)
			resource_cards[resource_id] = card
		_update_resource_values()

		# Connect to resource changes if signal exists
		if resource_manager.has_signal("resource_changed"):
			resource_manager.resource_changed.connect(_on_resource_changed)

func _create_resource_card(resource_id: String, parent: Node) -> Control:
	# Get current resource amount and max capacity
	var current_amount = 0
	var max_amount = 0

	var resource_manager = _get_resource_manager()
	if resource_manager and resource_manager.has_method("get_resource"):
		current_amount = int(resource_manager.get_resource(resource_id))

		# Get max storage from resource data if available
		var resources_data = null
		var data_manager = _get_data_manager()
		if data_manager:
			resources_data = data_manager.get_resources_data()
		var resource_data = {}
		if resources_data and resources_data.has("resources"):
			resource_data = resources_data["resources"].get(resource_id, {})
		if not resource_data.is_empty() and resource_data.has("max_storage"):
			max_amount = resource_data["max_storage"]

	# Use the new data-driven template
	var card = UIBuilder.create_resource_card(resource_id, current_amount, max_amount, parent)

	return card

func _update_resource_values():
	var resource_manager = _get_resource_manager()
	if not resource_manager or not resource_manager.has_method("get_resource"):
		return

	for resource_id in resource_cards:
		var card = resource_cards[resource_id]
		if not card or not is_instance_valid(card):
			continue

		# Update the value display using the new card structure
		var value_label = card.get_node("VBoxContainer/ValueLabel")
		if value_label:
			var amount = resource_manager.get_resource(resource_id)
			value_label.text = str(int(amount))

		# Update max display if it exists
		var max_label = card.get_node("VBoxContainer/MaxLabel")
		if max_label:
			var data_manager = _get_data_manager()
			var resources_data = data_manager.get_resources_data() if data_manager else null
			var resource_data = {}
			if resources_data and resources_data.has("resources"):
				resource_data = resources_data["resources"].get(resource_id, {})
			if not resource_data.is_empty() and resource_data.has("max_storage"):
				max_label.text = str(resource_data["max_storage"])

func _on_resource_changed(resource_id: String, amount: float) -> void:
	if not resource_cards.has(resource_id):
		return

	var card = resource_cards[resource_id]
	if not card or not is_instance_valid(card):
		return

	# Update value using new card structure
	var value_label = card.get_node("VBoxContainer/ValueLabel")
	if value_label:
		value_label.text = str(int(amount))
