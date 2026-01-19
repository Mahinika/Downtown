extends Node
class_name DebugBridge

var last_dump_path := "res://debug_state.json"

func dump_state(extra := {}):
	var tree := get_tree()
	var scene := tree.current_scene

	var state := {
		"time": Time.get_datetime_string_from_system(),
		"fps": Engine.get_frames_per_second(),
		"scene": scene.name if scene else "none",
		"node_count": scene.get_child_count() if scene else 0,
		"nodes": _dump_nodes(scene),
		"extra": extra
	}

	var file := FileAccess.open(last_dump_path, FileAccess.WRITE)
	file.store_string(JSON.stringify(state, "\t"))
	file.close()

	print("[DebugBridge] State dumped to ", last_dump_path)

func _dump_nodes(root: Node) -> Array:
	if root == null:
		return []

	var result := []
	for child in root.get_children():
		var node_data = {
			"name": child.name,
			"type": child.get_class(),
			"position": child.global_position if child is Node2D else null,
			"visible": child.visible if "visible" in child else null
		}

		# Add script information if available
		if child.get_script():
			node_data["script"] = child.get_script().resource_path

		# Add children recursively (but limit depth to avoid huge dumps)
		if child.get_child_count() > 0 and child.get_child_count() < 10:
			node_data["children"] = _dump_nodes_limited(child, 2)

		result.append(node_data)
	return result

func _dump_nodes_limited(root: Node, max_depth: int) -> Array:
	if root == null or max_depth <= 0:
		return []

	var result := []
	for child in root.get_children():
		result.append({
			"name": child.name,
			"type": child.get_class(),
			"position": child.global_position if child is Node2D else null
		})
	return result

# Error dumping - call this when things go wrong
func dump_error(error_msg: String, extra := {}):
	var error_data = extra.duplicate()
	error_data["error"] = error_msg
	error_data["call_stack"] = get_stack()  # Add call stack info
	dump_state(error_data)

# Performance dumping - useful for profiling
func dump_performance(extra := {}):
	var perf_data = extra.duplicate()
	perf_data["memory"] = Performance.get_monitor(Performance.MEMORY_STATIC)
	perf_data["objects"] = Performance.get_monitor(Performance.OBJECT_COUNT)
	perf_data["render_objects"] = Performance.get_monitor(Performance.RENDER_OBJECTS_IN_FRAME)
	dump_state(perf_data)

# AI-specific state dumping - customize this for your AI logic
func dump_ai_state(ai_node: Node, extra := {}):
	var ai_data = extra.duplicate()
	if ai_node and ai_node.has_method("get_debug_state"):
		ai_data["ai_debug"] = ai_node.get_debug_state()
	else:
		ai_data["ai_node"] = ai_node.name if ai_node else "null"
		ai_data["ai_properties"] = _dump_properties(ai_node) if ai_node else {}
	dump_state(ai_data)

func _dump_properties(node: Node) -> Dictionary:
	if not node:
		return {}

	var props := {}
	for prop in node.get_property_list():
		if prop.usage & PROPERTY_USAGE_SCRIPT_VARIABLE:
			props[prop.name] = node.get(prop.name)
	return props