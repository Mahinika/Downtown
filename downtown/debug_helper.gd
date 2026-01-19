extends Node

## Debug Helper - Runtime Error Detection and Logging
##
## This script provides comprehensive runtime debugging capabilities
## to help identify issues that occur during gameplay.

var _error_log = []
var _warning_log = []
var _performance_log = []
var _start_time = 0

func _ready() -> void:
	# Connect to Godot's built-in error signals
	var error_handler = func(message): _on_error(message)
	var warning_handler = func(message): _on_warning(message)

	# Note: In Godot 4, error handling is done differently
	# We'll use custom logging instead

	_start_time = Time.get_unix_time_from_system()
	print("🐛 Debug Helper initialized - monitoring for runtime errors...")

	# Test basic manager availability
	_test_manager_availability()

func _process(_delta: float) -> void:
	# Periodic health checks
	if Engine.get_frames_drawn() % 300 == 0:  # Every 5 seconds at 60 FPS
		_perform_health_check()

func _test_manager_availability() -> void:
	"""Test if all expected managers are available"""
	print("🔍 Testing manager availability...")

	var managers = [
		["GameServices", GameServices],
		["GameWorld", GameWorld],
		["EconomySystem", EconomySystem],
		["SeasonalManager", SeasonalManager],
		["JobSystem", JobSystem],
		["ResourceManager", ResourceManager],
		["BuildingManager", BuildingManager],
		["VillagerManager", VillagerManager],
		["DataManager", DataManager],
		["UIManager", UIManager]
	]

	var missing_managers = []
	for manager_info in managers:
		var name = manager_info[0]
		var instance = manager_info[1]
		if instance == null:
			missing_managers.append(name)
			_error_log.append("Missing manager: " + name)
		else:
			print("✅ " + name + " available")

	if not missing_managers.is_empty():
		print("❌ Missing managers: " + str(missing_managers))
		_show_error_report()
	else:
		print("✅ All managers available!")

func _perform_health_check() -> void:
	"""Perform periodic health checks"""
	var current_time = Time.get_unix_time_from_system()
	var uptime = current_time - _start_time

	# Check for memory issues
	var memory_usage = Performance.get_monitor(Performance.MEMORY_STATIC)
	if memory_usage > 100000000:  # 100MB
		_warning_log.append("High memory usage: %.1f MB" % (memory_usage / 1000000.0))

	# Check for performance issues
	var fps = Performance.get_monitor(Performance.TIME_FPS)
	if fps < 30:
		_warning_log.append("Low FPS: %.1f" % fps)

	# Log periodic status
	if uptime > 0 and int(uptime) % 60 == 0:  # Every minute
		print("⏱️  Uptime: %d minutes | FPS: %.1f | Memory: %.1f MB" %
			  [int(uptime) / 60, fps, memory_usage / 1000000.0])

func _on_error(message: String) -> void:
	"""Handle runtime errors"""
	_error_log.append("ERROR: " + message + " (at " + Time.get_datetime_string_from_system() + ")")
	print("❌ RUNTIME ERROR: " + message)

func _on_warning(message: String) -> void:
	"""Handle runtime warnings"""
	_warning_log.append("WARNING: " + message + " (at " + Time.get_datetime_string_from_system() + ")")
	print("⚠️  RUNTIME WARNING: " + message)

func log_performance_event(event_name: String, duration: float) -> void:
	"""Log performance events"""
	_performance_log.append({
		"event": event_name,
		"duration": duration,
		"timestamp": Time.get_unix_time_from_system()
	})

func get_error_report() -> Dictionary:
	"""Get a comprehensive error report"""
	return {
		"errors": _error_log,
		"warnings": _warning_log,
		"performance": _performance_log,
		"uptime": Time.get_unix_time_from_system() - _start_time,
		"memory_usage": Performance.get_monitor(Performance.MEMORY_STATIC),
		"fps": Performance.get_monitor(Performance.TIME_FPS)
	}

func _show_error_report() -> void:
	"""Display error report in console"""
	var separator = ""
	for i in range(60):
		separator += "═"
	print("\n" + separator)
	print("🐛 DEBUG HELPER ERROR REPORT")
	print(separator)

	if not _error_log.is_empty():
		print("❌ ERRORS:")
		for error in _error_log:
			print("   " + error)

	if not _warning_log.is_empty():
		print("⚠️  WARNINGS:")
		for warning in _warning_log:
			print("   " + warning)

	if not _performance_log.is_empty():
		print("📊 PERFORMANCE ISSUES:")
		for perf in _performance_log:
			print("   %s: %.3f seconds" % [perf.event, perf.duration])

	print("📈 STATS:")
	print("   Memory: %.1f MB" % (Performance.get_monitor(Performance.MEMORY_STATIC) / 1000000.0))
	print("   FPS: %.1f" % Performance.get_monitor(Performance.TIME_FPS))
	print("   Uptime: %.1f minutes" % ((Time.get_unix_time_from_system() - _start_time) / 60.0))

	var separator2 = ""
	for i in range(60):
		separator2 += "═"
	print(separator2)

func force_error_test() -> void:
	"""Force some test errors to verify error handling"""
	print("🧪 Testing error handling...")

	# Test null reference
	var test_var = null
	if test_var and test_var.some_method():
		pass  # This should not execute

	# Test invalid array access
	var test_array = [1, 2, 3]
	var invalid_access = test_array[10]  # This will cause an error

	print("✅ Error testing complete")

# Static helper functions for easy debugging
static func assert_not_null(value, context: String = "") -> bool:
	"""Assert that a value is not null"""
	if value == null:
		print("❌ ASSERT FAILED: " + context + " is null")
		return false
	return true

static func assert_true(condition: bool, context: String = "") -> bool:
	"""Assert that a condition is true"""
	if not condition:
		print("❌ ASSERT FAILED: " + context + " is false")
		return false
	return true

static func log(message: String, level: String = "INFO") -> void:
	"""Log a message with timestamp"""
	var timestamp = Time.get_datetime_string_from_system()
	print("[%s] %s: %s" % [timestamp, level, message])
