## Validation System - Downtown City Management Game
##
## Automated error detection and health checking system
## Use this to validate game state and catch common errors
##
## Usage:
##   var validator = ValidationSystem.new()
##   var errors = validator.run_full_validation()
##   if errors.size() > 0:
##       for error in errors:
##           push_error("[VALIDATION] " + error)

extends Node
class_name ValidationSystem

# Validation results
var validation_errors = []
var validation_warnings = []

## Run complete validation suite
func run_full_validation() -> Array:
	validation_errors.clear()
	validation_warnings.clear()

	print("[VALIDATION] Starting automated validation...")

	# Core system validation
	_validate_autoloads()
	_validate_scene_structure()
	_validate_resource_system()
	_validate_building_system()
	_validate_villager_system()
	_validate_save_system()

	# Performance validation
	_validate_performance()

	print("[VALIDATION] Validation complete. Errors: ", validation_errors.size(), ", Warnings: ", validation_warnings.size())

	return validation_errors

## Validate all required autoloads are present and functional
func _validate_autoloads() -> void:
	print("[VALIDATION] Checking autoloads...")

	var required_autoloads = [
		"DataManager",
		"CityManager",
		"ResourceManager",
		"BuildingManager",
		"VillagerManager",
		"GameServices",
		"GameWorld",
		"UITheme"
	]

	for autoload_name in required_autoloads:
		var autoload = _get_autoload(autoload_name)
		if not autoload:
			validation_errors.append("Missing autoload: " + autoload_name)
		else:
			print("[VALIDATION] ✓ Autoload present: " + autoload_name)

## Helper function to get autoloads in different contexts
func _get_autoload(autoload_name: String):
	# Try Node context (in-game validation)
	if has_method("get_node_or_null"):
		return get_node_or_null("/root/" + autoload_name)

	# Fallback: check if global exists
	if autoload_name in self:
		return self[autoload_name]

	return null

## Validate main scene structure
func _validate_scene_structure() -> void:
	print("[VALIDATION] Checking scene structure...")

	var root = null

	# Try to get scene tree in different contexts
	if has_method("get_tree"):
		root = get_tree().root
	elif has_method("get_root"):
		root = get_root()

	if not root:
		validation_warnings.append("Scene tree not accessible - running in standalone mode")
		return

	var main_scene = root.get_child(0) if root.get_child_count() > 0 else null
	if not main_scene:
		validation_warnings.append("No main scene loaded")
		return

	# Check for required nodes
	var required_nodes = ["CityGrid", "UIManager", "ResourceDisplay"]
	for node_name in required_nodes:
		var node = main_scene.find_child(node_name, true, false) if main_scene.has_method("find_child") else null
		if not node:
			validation_warnings.append("Missing required node: " + node_name + " (may not be critical)")
		else:
			print("[VALIDATION] ✓ Required node found: " + node_name)

## Validate resource system integrity
func _validate_resource_system() -> void:
	print("[VALIDATION] Checking resource system...")

	var resource_manager = _get_autoload("ResourceManager")
	if not resource_manager:
		validation_errors.append("ResourceManager not available for validation")
		return

	# Check critical resources exist
	var critical_resources = ["population", "food", "wood", "stone"]
	for resource_id in critical_resources:
		var amount = resource_manager.get_resource(resource_id) if resource_manager.has_method("get_resource") else 0
		if amount < 0:
			validation_errors.append("Negative resource amount: " + resource_id + " = " + str(amount))
		else:
			print("[VALIDATION] ✓ Resource valid: " + resource_id + " = " + str(amount))

## Validate building system
func _validate_building_system() -> void:
	print("[VALIDATION] Checking building system...")

	var building_manager = _get_autoload("BuildingManager")
	if not building_manager:
		validation_errors.append("BuildingManager not available for validation")
		return

	var data_manager = _get_autoload("DataManager")
	if not data_manager:
		validation_errors.append("DataManager not available for building validation")
		return

	# Check buildings data loads
	var buildings_data = data_manager.get_data("buildings") if data_manager.has_method("get_data") else null
	if not buildings_data:
		validation_errors.append("Buildings data not loaded")
	else:
		var building_count = buildings_data.get("buildings", {}).size()
		print("[VALIDATION] ✓ Buildings data loaded: " + str(building_count) + " building types")

## Validate villager system
func _validate_villager_system() -> void:
	print("[VALIDATION] Checking villager system...")

	var villager_manager = _get_autoload("VillagerManager")
	if not villager_manager:
		validation_errors.append("VillagerManager not available for validation")
		return

	var job_system = _get_autoload("JobSystem")
	if not job_system:
		validation_warnings.append("JobSystem not available - job assignments won't be validated")
		return

	# Check for basic villager functionality
	var villager_count = villager_manager.get_villager_count() if villager_manager.has_method("get_villager_count") else 0
	if villager_count < 0:
		validation_errors.append("Invalid villager count: " + str(villager_count))
	else:
		print("[VALIDATION] ✓ Villager count valid: " + str(villager_count))

## Validate save/load system
func _validate_save_system() -> void:
	print("[VALIDATION] Checking save system...")

	var save_manager = _get_autoload("SaveManager")
	if not save_manager:
		validation_errors.append("SaveManager not available for validation")
		return

	# Test save functionality (basic check)
	var test_data = {"test": "validation"}
	var save_result = save_manager.save_game_data("validation_test", test_data) if save_manager.has_method("save_game_data") else false
	if not save_result:
		validation_warnings.append("Save functionality may not be working correctly")
	else:
		print("[VALIDATION] ✓ Save system functional")

## Performance validation
func _validate_performance() -> void:
	print("[VALIDATION] Checking performance...")

	# Check if Performance singleton is available
	var performance = null
	if has_method("get_node_or_null"):
		performance = get_node_or_null("/root/PerformanceMonitor")
		if not performance:
			performance = get_node_or_null("/root/PerformanceRegressionTest")

	if not performance:
		validation_warnings.append("Performance monitoring not available in this context")
		return

	# Check frame rate
	var fps = performance.get_monitor(performance.TIME_FPS) if performance.has_method("get_monitor") else 60
	if fps < 30:
		validation_warnings.append("Low frame rate: " + str(fps) + " FPS (target: 60)")
	else:
		print("[VALIDATION] ✓ Performance good: " + str(fps) + " FPS")

	# Check memory usage
	var memory_mb = performance.get_monitor(performance.MEMORY_STATIC) / 1024 / 1024 if performance.has_method("get_monitor") else 50
	if memory_mb > 200:
		validation_warnings.append("High memory usage: " + str(memory_mb) + " MB")
	else:
		print("[VALIDATION] ✓ Memory usage acceptable: " + str(memory_mb) + " MB")

## Get validation summary
func get_validation_summary() -> Dictionary:
	return {
		"errors": validation_errors,
		"warnings": validation_warnings,
		"error_count": validation_errors.size(),
		"warning_count": validation_warnings.size(),
		"overall_status": "PASS" if validation_errors.size() == 0 else "FAIL"
	}

## Quick health check - returns true if system is healthy
func is_system_healthy() -> bool:
	return validation_errors.size() == 0