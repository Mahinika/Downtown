extends Node

## ResourceManager - Manages all resource tracking and storage
##
## Singleton Autoload that handles all resource operations including tracking amounts,
## storage capacities, cost/payment validation, and resource consumption/production.
## Provides type-safe interfaces for all resource operations with validation and error handling.
##
## Key Features:
## - Real-time resource tracking with storage capacity limits
## - Cost/payment validation for building construction and upgrades
## - Resource consumption/production with overflow/underflow protection
## - Automatic storage capacity management with bonuses
## - Event-driven architecture with resource_changed signals
##
## Usage:
##   ResourceManager.add_resource("wood", 50.0)
##   ResourceManager.consume_resource("gold", 100.0)
##   var can_afford = ResourceManager.can_afford({"wood": 25, "stone": 10})

## Emitted when a resource amount changes (added or consumed).
## Parameters: resource_id (String), amount_changed (float), new_total (float)
signal resource_changed(resource_id: String, amount: float, new_total: float)

## Emitted when a resource reaches its storage capacity limit.
## Parameters: resource_id (String)
signal storage_full(resource_id: String)

## Current resource amounts: resource_id (String) -> current_amount (float).
## Tracks the current quantity of each resource type.
var resources: Dictionary = {}

## Storage capacity limits: resource_id (String) -> max_capacity (int).
## Maximum amount each resource can store, including bonuses from buildings.
var storage_capacities: Dictionary = {}

## Default storage capacity for resources when no specific capacity is defined.
const DEFAULT_STORAGE_CAPACITY: int = 200

func _ready() -> void:
	print("[ResourceManager] Initialized")
	# Defer initialization until DataManager is available
	call_deferred("initialize_resources")

func initialize_resources() -> void:
	# #region agent log
	var log_data = {
		"sessionId": "debug-session",
		"runId": "autoload-loading",
		"hypothesisId": "H2",
		"location": "ResourceManager.gd:45",
		"message": "ResourceManager initialize_resources() called",
		"data": {
			"data_manager_available": DataManager != null,
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

	if not DataManager:
		push_error("[ResourceManager] DataManager not available!")
		return

	var resources_data = DataManager.get_data("resources")
	if not resources_data:
		push_error("[ResourceManager] Resources data not loaded!")
		return
	
	# Handle nested structure (resources.resources) or flat structure
	var resources_dict = resources_data.get("resources", resources_data)
	
	for resource_id in resources_dict:
		var resource_data = resources_dict[resource_id]
		var starting_amount = resource_data.get("starting_amount", 0)
		var max_storage = resource_data.get("max_storage", DEFAULT_STORAGE_CAPACITY)
		
		resources[resource_id] = float(starting_amount)
		storage_capacities[resource_id] = max_storage
		print("[ResourceManager] Initialized ", resource_id, ": ", starting_amount, " / ", max_storage)

## Gets the current amount of a resource.
##
## Parameters:
##   resource_id: The resource identifier (String)
##
## Returns:
##   Current resource amount (float), 0.0 if resource doesn't exist or ID is empty.
func get_resource(resource_id: String) -> float:
	# Validate input
	if resource_id.is_empty():
		push_warning("[ResourceManager] Empty resource ID")
		return 0.0

	return resources.get(resource_id, 0.0)

## Checks if the player has at least the specified amount of a resource.
##
## Parameters:
##   resource_id: The resource identifier (String)
##   amount: Minimum required amount (float)
##
## Returns:
##   true if player has enough resource, false otherwise.
##
## Note: Returns false for negative amounts or empty resource IDs.
func has_resource(resource_id: String, amount: float) -> bool:
	# Validate inputs
	if resource_id.is_empty():
		return false

	if amount < 0.0:
		push_warning("[ResourceManager] Negative amount for has_resource: ", amount)
		return false

	return get_resource(resource_id) >= amount

## Adds resource amount to the player's stockpile.
##
## Parameters:
##   resource_id: The resource identifier (String)
##   amount: Amount to add (float)
##
## Returns:
##   true if resource was added successfully, false on validation error.
##
## Behavior:
##   - Respects storage capacity limits (clamps to maximum)
##   - Emits resource_changed signal with amount added
##   - Emits storage_full signal when capacity is reached
##   - Returns false for negative amounts, unknown resources, or empty IDs
func add_resource(resource_id: String, amount: float) -> bool:
	# Validate inputs
	if resource_id.is_empty():
		push_warning("[ResourceManager] Empty resource ID")
		return false

	if amount < 0.0:
		push_warning("[ResourceManager] Negative amount for add_resource: ", amount)
		return false

	if not resources.has(resource_id):
		push_warning("[ResourceManager] Unknown resource: ", resource_id)
		return false

	var current = resources[resource_id]
	var capacity = storage_capacities.get(resource_id, DEFAULT_STORAGE_CAPACITY)
	var new_total = min(current + amount, capacity)

	resources[resource_id] = new_total
	resource_changed.emit(resource_id, amount, new_total)

	if new_total >= capacity and current < capacity:
		storage_full.emit(resource_id)

	return true

## Consumes resource amount from the player's stockpile.
##
## Parameters:
##   resource_id: The resource identifier (String)
##   amount: Amount to consume (float)
##   allow_negative: If true, allows resource to go below zero (default: false)
##
## Returns:
##   true if resource was consumed successfully, false if insufficient resources or validation error.
##
## Behavior:
##   - By default prevents negative resource amounts
##   - Emits resource_changed signal with negative amount (consumption)
##   - Clamps to zero if allow_negative is false and amount would go negative
func consume_resource(resource_id: String, amount: float, allow_negative: bool = false) -> bool:
	# Validate inputs
	if resource_id.is_empty():
		push_warning("[ResourceManager] Empty resource ID")
		return false

	if amount < 0.0:
		push_warning("[ResourceManager] Negative amount for consume_resource: ", amount)
		return false

	if not resources.has(resource_id):
		push_warning("[ResourceManager] Unknown resource: ", resource_id)
		return false

	if not allow_negative and not has_resource(resource_id, amount):
		return false

	resources[resource_id] -= amount

	# Clamp to zero if not allowing negative (safety check)
	if not allow_negative and resources[resource_id] < 0.0:
		resources[resource_id] = 0.0

	resource_changed.emit(resource_id, -amount, resources[resource_id])
	return true

## Checks if the player can afford all costs in a cost dictionary.
##
## Parameters:
##   costs: Dictionary of resource_id -> required_amount pairs
##
## Returns:
##   true if player has sufficient resources for all costs, false otherwise.
##
## Example:
##   can_afford({"wood": 25, "stone": 10, "gold": 50})
##
## Note: Returns true for empty cost dictionaries (free).
func can_afford(costs: Dictionary) -> bool:
	# Validate input
	if costs.is_empty():
		return true  # No costs means can afford

	for resource_id in costs:
		if resource_id.is_empty():
			push_warning("[ResourceManager] Empty resource ID in costs")
			continue

		var cost_amount = float(costs[resource_id])
		if cost_amount < 0.0:
			push_warning("[ResourceManager] Negative cost amount for ", resource_id)
			continue

		if not has_resource(resource_id, cost_amount):
			return false
	return true

## Attempts to pay all costs from the player's resources.
##
## Parameters:
##   costs: Dictionary of resource_id -> required_amount pairs
##
## Returns:
##   true if all costs were paid successfully, false if insufficient resources or validation error.
##
## Behavior:
##   - Checks affordability first with can_afford()
##   - Consumes resources atomically (all or nothing)
##   - Returns false and leaves resources unchanged if any cost cannot be paid
func pay_costs(costs: Dictionary) -> bool:
	# Validate input
	if costs.is_empty():
		return true  # No costs means success

	if not can_afford(costs):
		return false

	for resource_id in costs:
		if resource_id.is_empty():
			push_warning("[ResourceManager] Empty resource ID in costs")
			continue

		var cost_amount = float(costs[resource_id])
		if cost_amount < 0.0:
			push_warning("[ResourceManager] Negative cost amount for ", resource_id)
			continue

		if not consume_resource(resource_id, cost_amount):
			return false

	return true

## Increases the storage capacity for a resource.
##
## Parameters:
##   resource_id: The resource identifier (String)
##   amount: Amount to increase capacity by (int)
##
## Behavior:
##   - Adds to existing capacity or creates new capacity at DEFAULT_STORAGE_CAPACITY + amount
##   - Ignores negative amounts
##   - Used by buildings that provide storage bonuses
func increase_storage_capacity(resource_id: String, amount: int) -> void:
	# Validate inputs
	if resource_id.is_empty():
		push_warning("[ResourceManager] Empty resource ID")
		return

	if amount < 0:
		push_warning("[ResourceManager] Negative storage capacity increase: ", amount)
		return

	if storage_capacities.has(resource_id):
		storage_capacities[resource_id] += amount
	else:
		storage_capacities[resource_id] = DEFAULT_STORAGE_CAPACITY + amount

## Gets the storage capacity for a resource.
##
## Parameters:
##   resource_id: The resource identifier (String)
##
## Returns:
##   Storage capacity (int), DEFAULT_STORAGE_CAPACITY if resource not found or ID empty.
func get_storage_capacity(resource_id: String) -> int:
	# Validate input
	if resource_id.is_empty():
		push_warning("[ResourceManager] Empty resource ID")
		return DEFAULT_STORAGE_CAPACITY

	return storage_capacities.get(resource_id, DEFAULT_STORAGE_CAPACITY)

## Gets a copy of all current resource amounts.
##
## Returns:
##   Dictionary copy of resources (resource_id -> amount).
##   Safe to modify without affecting internal state.
func get_all_resources() -> Dictionary:
	return resources.duplicate()

## Directly sets a resource amount (used for save/load operations).
##
## Parameters:
##   resource_id: The resource identifier (String)
##   amount: New resource amount (float, clamped to 0.0 minimum)
##
## Behavior:
##   - Directly overwrites resource amount
##   - Emits resource_changed signal with change_amount = 0.0
##   - Clamps negative amounts to zero
func set_resource(resource_id: String, amount: float) -> void:
	# Validate inputs
	if resource_id.is_empty():
		push_warning("[ResourceManager] Empty resource ID")
		return

	if amount < 0.0:
		push_warning("[ResourceManager] Negative amount for set_resource: ", amount)
		amount = 0.0  # Clamp to zero

	# Directly set resource amount (for save/load)
	if not resources.has(resource_id):
		push_warning("[ResourceManager] Unknown resource: ", resource_id)
		return

	resources[resource_id] = amount
	resource_changed.emit(resource_id, 0.0, amount)

## Directly sets storage capacity for a resource (used for save/load operations).
##
## Parameters:
##   resource_id: The resource identifier (String)
##   capacity: New storage capacity (int, clamped to 0 minimum)
##
## Behavior:
##   - Directly overwrites storage capacity
##   - Clamps negative values to zero
func set_storage_capacity(resource_id: String, capacity: int) -> void:
	# Validate inputs
	if resource_id.is_empty():
		push_warning("[ResourceManager] Empty resource ID")
		return

	if capacity < 0:
		push_warning("[ResourceManager] Negative storage capacity: ", capacity)
		capacity = 0  # Clamp to zero

	# Directly set storage capacity (for save/load)
	storage_capacities[resource_id] = capacity

## Alias for get_resource() for consistency with processing chains.
##
## Parameters:
##   resource_id: The resource identifier (String)
##
## Returns:
##   Current resource amount (float), same as get_resource().
func get_resource_amount(resource_id: String) -> float:
	"""Alias for get_resource() for consistency with processing chains"""
	return get_resource(resource_id)

## Consumes resource amount (alias for consume_resource with allow_negative=false).
##
## Parameters:
##   resource_id: The resource identifier (String)
##   amount: Amount to consume (float)
##
## Returns:
##   true if resource was consumed successfully, false if insufficient resources.
##
## Note: Equivalent to consume_resource(resource_id, amount, false).
func spend_resource(resource_id: String, amount: float) -> bool:
	"""Consume resource (alias for consume_resource with allow_negative=false)"""
	return consume_resource(resource_id, amount, false)
