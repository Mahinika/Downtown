extends Node

## ObjectPool - Generic object pooling system
##
## Provides efficient object reuse to reduce instantiation overhead.
## Particularly useful for frequently created/destroyed objects like
## particles, projectiles, or UI elements.
##
## Usage:
##   var pool = ObjectPool.new()
##   pool.initialize(VillagerScene, 10)  # Pre-create 10 villagers
##   var villager = pool.get_object()
##   pool.return_object(villager)

class_name ObjectPool

# Pool storage
var available_objects: Array = []
var active_objects: Array = []
var scene_template: PackedScene = null
var max_pool_size: int = 50

func initialize(template_scene: PackedScene, initial_count: int = 5, max_size: int = 50) -> void:
	"""Initialize pool with template scene and initial objects"""
	scene_template = template_scene
	max_pool_size = max_size

	# Pre-create initial objects
	for i in range(initial_count):
		var obj = _create_object()
		if obj:
			available_objects.append(obj)

	print("[ObjectPool] Initialized pool with ", initial_count, " objects (max: ", max_size, ")")

func get_object() -> Node:
	"""Get an available object from the pool"""
	if available_objects.is_empty():
		# Create new object if pool is empty and under limit
		if active_objects.size() < max_pool_size:
			var obj = _create_object()
			if obj:
				active_objects.append(obj)
				_activate_object(obj)
				return obj
		else:
			push_warning("[ObjectPool] Pool limit reached, cannot create more objects")
			return null

	# Get object from available pool
	var obj = available_objects.pop_back()
	active_objects.append(obj)
	_activate_object(obj)
	return obj

func return_object(obj: Node) -> void:
	"""Return an object to the pool"""
	if not obj or not is_instance_valid(obj):
		return

	if active_objects.has(obj):
		active_objects.erase(obj)

		# Check pool size limit
		if available_objects.size() < max_pool_size:
			available_objects.append(obj)
			_deactivate_object(obj)
		else:
			# Pool is full, destroy object
			obj.queue_free()
	else:
		push_warning("[ObjectPool] Attempted to return object not in active pool")

func clear_pool() -> void:
	"""Clear all objects from the pool"""
	for obj in available_objects:
		if is_instance_valid(obj):
			obj.queue_free()

	for obj in active_objects:
		if is_instance_valid(obj):
			obj.queue_free()

	available_objects.clear()
	active_objects.clear()

	print("[ObjectPool] Pool cleared")

func get_pool_stats() -> Dictionary:
	"""Get pool statistics"""
	return {
		"available": available_objects.size(),
		"active": active_objects.size(),
		"total": available_objects.size() + active_objects.size(),
		"max_size": max_pool_size
	}

func _create_object() -> Node:
	"""Create a new object instance"""
	if not scene_template:
		push_error("[ObjectPool] No template scene set!")
		return null

	var obj = scene_template.instantiate()
	if not obj:
		push_error("[ObjectPool] Failed to instantiate object from template!")
		return null

	return obj

func _activate_object(obj: Node) -> void:
	"""Activate an object when taken from pool"""
	# Reset object state
	obj.visible = true
	obj.modulate.a = 1.0

	# Add to scene tree if needed
	if not obj.get_parent():
		add_child(obj)

func _deactivate_object(obj: Node) -> void:
	"""Deactivate an object when returned to pool"""
	# Hide and reset object
	obj.visible = false

	# Remove from scene tree to prevent updates
	if obj.get_parent():
		obj.get_parent().remove_child(obj)