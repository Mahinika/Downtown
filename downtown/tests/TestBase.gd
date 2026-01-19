extends Node

## TestBase - Base class for all test suites
##
## Provides common functionality, setup/teardown, and assertion helpers
## for all test classes in the Downtown test suite.

class_name TestBase

signal test_complete(test_name: String, passed: bool, message: String)

# Test tracking
var test_results: Dictionary = {}
var tests_passed: int = 0
var tests_failed: int = 0
var test_execution_times: Dictionary = {}

# Test environment state
var _original_game_state: Dictionary = {}

# Signal waiting state
var _signal_wait_flags: Dictionary = {}
var _signal_wait_data: Dictionary = {}

# Test categorization
enum TestCategory {
	MANAGERS,
	BUILDINGS,
	VILLAGERS,
	UI,
	INTEGRATION,
	PERFORMANCE,
	EDGE_CASES,
	SIGNALS,
	DATA_VALIDATION
}

var test_categories: Dictionary = {}  # Maps test_name -> TestCategory

func _ready() -> void:
	print("============================================================")
	print("TEST SUITE: " + get_class_name())
	print("============================================================")

## Setup test environment before each test
func setup_test_environment() -> void:
	"""Override in subclasses to set up test environment"""
	# Save original state if needed
	_save_game_state()

	# Ensure managers are ready
	await get_tree().process_frame
	await get_tree().process_frame

## Cleanup test environment after each test
func cleanup_test_environment() -> void:
	"""Override in subclasses to clean up test environment"""
	# Reset game state
	_reset_game_state()

## Save current game state for restoration
func _save_game_state() -> void:
	"""Save current game state for potential restoration"""
	if ResourceManager:
		_original_game_state["resources"] = ResourceManager.resources.duplicate(true)

	if BuildingManager:
		_original_game_state["buildings"] = BuildingManager.buildings.duplicate(true)

	var world = GameServices.get_world()
	if world:
		_original_game_state["villagers"] = world.get_all_villagers().duplicate(true)

## Reset game state to clean slate
func _reset_game_state() -> void:
	"""Reset game state between tests"""
	# Clear test buildings
	if BuildingManager and BuildingManager.has("buildings"):
		var buildings_to_remove = []
		for building_id in BuildingManager.buildings:
			var building = BuildingManager.buildings[building_id]
			if building and building.has("test_building") and building.test_building:
				buildings_to_remove.append(building_id)

		for building_id in buildings_to_remove:
			BuildingManager.remove_building(building_id)

	# Clear test villagers
	var world = GameServices.get_world()
	if world:
		var villagers_to_remove = []
		for villager_id in world.get_all_villagers():
			var villager = world.get_villager(villager_id)
			if villager and villager.has("test_villager") and villager.test_villager:
				villagers_to_remove.append(villager_id)

		for villager_id in villagers_to_remove:
			world.remove_villager(villager_id)

	# Reset resources to reasonable levels
	if ResourceManager:
		ResourceManager.set_resource("wood", 100.0)
		ResourceManager.set_resource("stone", 100.0)
		ResourceManager.set_resource("food", 100.0)
		ResourceManager.set_resource("gold", 100.0)

## Assertion Helpers

func assert_manager_exists(manager_name: String) -> bool:
	"""Assert that a manager autoload exists"""
	var manager = get_node_or_null("/root/" + manager_name)
	var exists = (manager != null)
	record_test("ManagerExists_" + manager_name, exists,
		manager_name + " exists: " + str(exists))
	return exists

func assert_method_exists(obj: Object, method_name: String, context: String = "") -> bool:
	"""Assert that an object has a specific method"""
	var has_method = obj and obj.has_method(method_name)
	var test_name = "MethodExists_" + method_name
	if context:
		test_name += "_" + context
	record_test(test_name, has_method,
		method_name + " exists" + ("" if context.is_empty() else " in " + context) + ": " + str(has_method))
	return has_method

func assert_property_exists(obj: Object, property_name: String, context: String = "") -> bool:
	"""Assert that an object has a specific property"""
	var has_property = obj and obj.has(property_name)
	var test_name = "PropertyExists_" + property_name
	if context:
		test_name += "_" + context
	record_test(test_name, has_property,
		property_name + " exists" + ("" if context.is_empty() else " in " + context) + ": " + str(has_property))
	return has_property

func assert_not_null(value, test_name: String, message: String = "") -> bool:
	"""Assert that a value is not null"""
	var not_null = (value != null)
	record_test(test_name, not_null,
		message if not message.is_empty() else "Value is not null: " + str(not_null))
	return not_null

func assert_true(condition: bool, test_name: String, message: String = "") -> bool:
	"""Assert that a condition is true"""
	record_test(test_name, condition,
		message if not message.is_empty() else "Condition is true: " + str(condition))
	return condition

func assert_equal(actual, expected, test_name: String, message: String = "") -> bool:
	"""Assert that two values are equal"""
	var equal = (actual == expected)
	var msg = message
	if msg.is_empty():
		msg = "Expected: " + str(expected) + ", Actual: " + str(actual)
	record_test(test_name, equal, msg)
	return equal

func assert_greater_than(actual, expected, test_name: String, message: String = "") -> bool:
	"""Assert that actual is greater than expected"""
	var greater = (actual > expected)
	var msg = message
	if msg.is_empty():
		msg = str(actual) + " > " + str(expected) + ": " + str(greater)
	record_test(test_name, greater, msg)
	return greater

func assert_greater_than_or_equal(actual, expected, test_name: String, message: String = "") -> bool:
	"""Assert that actual is greater than or equal to expected"""
	var greater_or_equal = (actual >= expected)
	var msg = message
	if msg.is_empty():
		msg = str(actual) + " >= " + str(expected) + ": " + str(greater_or_equal)
	record_test(test_name, greater_or_equal, msg)
	return greater_or_equal

func assert_less_than(actual, expected, test_name: String, message: String = "") -> bool:
	"""Assert that actual is less than expected"""
	var less = (actual < expected)
	var msg = message
	if msg.is_empty():
		msg = str(actual) + " < " + str(expected) + ": " + str(less)
	record_test(test_name, less, msg)
	return less

func assert_less_than_or_equal(actual, expected, test_name: String, message: String = "") -> bool:
	"""Assert that actual is less than or equal to expected"""
	var less_or_equal = (actual <= expected)
	var msg = message
	if msg.is_empty():
		msg = str(actual) + " <= " + str(expected) + ": " + str(less_or_equal)
	record_test(test_name, less_or_equal, msg)
	return less_or_equal

func assert_approximately_equal(actual: float, expected: float, test_name: String, tolerance: float = 0.01, message: String = "") -> bool:
	"""Assert that two float values are approximately equal"""
	var approximately_equal = abs(actual - expected) <= tolerance
	var msg = message
	if msg.is_empty():
		msg = "Expected: " + str(expected) + " ± " + str(tolerance) + ", Actual: " + str(actual)
	record_test(test_name, approximately_equal, msg)
	return approximately_equal

func assert_contains(container, item, test_name: String, message: String = "") -> bool:
	"""Assert that container contains item (works with Array, String, Dictionary)"""
	var contains = false
	if container is Array:
		contains = container.has(item)
	elif container is String:
		contains = container.contains(str(item))
	elif container is Dictionary:
		contains = container.has(item)
	
	var msg = message
	if msg.is_empty():
		msg = str(item) + " in " + str(container) + ": " + str(contains)
	record_test(test_name, contains, msg)
	return contains

func assert_signal_emitted(signal_ref: Signal, test_name: String, timeout: float = 2.0, message: String = "") -> bool:
	"""Assert that a signal was emitted within timeout (uses named method to avoid Pattern 1)"""
	var signal_id = "assert_" + str(signal_ref.get_object_id()) + "_" + test_name
	_signal_wait_flags[signal_id] = false
	
	# Connect with named method (avoids Pattern 1 lambda capture)
	signal_ref.connect(_on_test_signal_received.bind(signal_id))
	
	# Wait for signal or timeout
	var timer = get_tree().create_timer(timeout)
	await timer.timeout
	
	# Clean up
	if signal_ref.is_connected(_on_test_signal_received):
		signal_ref.disconnect(_on_test_signal_received)
	
	var signal_received = _signal_wait_flags.get(signal_id, false)
	_signal_wait_flags.erase(signal_id)
	
	var msg = message
	if msg.is_empty():
		msg = "Signal emitted: " + str(signal_received)
	record_test(test_name, signal_received, msg)
	return signal_received

func _on_test_signal_received(signal_id: String) -> void:
	"""Named method for signal testing (avoids Pattern 1 lambda capture issues)"""
	_signal_wait_flags[signal_id] = true

func assert_signal_emitted_with_data(signal_ref: Signal, test_name: String, timeout: float = 2.0, message: String = "", expected_data = null) -> bool:
	"""Assert that a signal was emitted with specific data"""
	var signal_id = "assert_data_" + str(signal_ref.get_object_id()) + "_" + test_name
	_signal_wait_flags[signal_id] = false
	_signal_wait_data[signal_id] = null
	
	# Connect with named method
	signal_ref.connect(_on_test_signal_with_data.bind(signal_id))
	
	var timer = get_tree().create_timer(timeout)
	await timer.timeout
	
	if signal_ref.is_connected(_on_test_signal_with_data):
		signal_ref.disconnect(_on_test_signal_with_data)
	
	var signal_received = _signal_wait_flags.get(signal_id, false)
	var received_data = _signal_wait_data.get(signal_id, null)
	_signal_wait_flags.erase(signal_id)
	_signal_wait_data.erase(signal_id)
	
	var passed = signal_received
	if expected_data != null:
		passed = passed and (received_data == expected_data)
	
	var msg = message
	if msg.is_empty():
		msg = "Signal emitted: " + str(signal_received) + ", Data: " + str(received_data)
	record_test(test_name, passed, msg)
	return passed

func _on_test_signal_with_data(data, signal_id: String) -> void:
	"""Named method for signal testing with data"""
	_signal_wait_flags[signal_id] = true
	_signal_wait_data[signal_id] = data

## Signal-based waiting (performance improvement)

func wait_for_signal(signal_ref: Signal, timeout: float = 5.0, signal_name: String = "signal") -> bool:
	"""Wait for a signal to be emitted, with timeout (uses named method to avoid Pattern 1)"""
	var signal_id = "wait_" + str(signal_ref.get_object_id()) + "_" + signal_name
	_signal_wait_flags[signal_id] = false
	
	# Use named method to avoid lambda capture issues (Pattern 1)
	signal_ref.connect(_on_wait_for_signal_received.bind(signal_id))
	
	var timer = get_tree().create_timer(timeout)
	await timer.timeout
	
	# Clean up connections
	if signal_ref.is_connected(_on_wait_for_signal_received):
		signal_ref.disconnect(_on_wait_for_signal_received)
	
	var received = _signal_wait_flags.get(signal_id, false)
	_signal_wait_flags.erase(signal_id)
	return received

func _on_wait_for_signal_received(signal_id: String) -> void:
	"""Named method for wait_for_signal (avoids Pattern 1 lambda capture issues)"""
	_signal_wait_flags[signal_id] = true

func wait_for_condition(condition_func: Callable, timeout: float = 5.0, check_interval: float = 0.1) -> bool:
	"""Wait for a condition function to return true"""
	var timer = get_tree().create_timer(timeout)
	var condition_met = false

	while not condition_met and not timer.is_stopped():
		condition_met = condition_func.call()
		if not condition_met:
			await get_tree().create_timer(check_interval).timeout

	return condition_met

## Test Execution Helpers

var _current_test_start_time: float = 0.0

func record_test(test_name: String, passed: bool, message: String, execution_time: float = -1.0) -> void:
	"""Record a test result with optional execution time"""
	var test_data = {
		"passed": passed,
		"message": message,
		"timestamp": Time.get_unix_time_from_system()
	}
	
	if execution_time >= 0.0:
		test_data["execution_time"] = execution_time
		test_execution_times[test_name] = execution_time
	
	test_results[test_name] = test_data

	if passed:
		tests_passed += 1
		print("  ✓ " + test_name + ": " + message)
	else:
		tests_failed += 1
		print("  ✗ " + test_name + ": " + message)

	test_complete.emit(test_name, passed, message)

func start_test_timing() -> void:
	"""Start timing a test execution"""
	_current_test_start_time = Time.get_ticks_msec() / 1000.0

func end_test_timing(test_name: String) -> float:
	"""End timing and record execution time, returns execution time in seconds"""
	var execution_time = (Time.get_ticks_msec() / 1000.0) - _current_test_start_time
	if test_execution_times.has(test_name):
		test_execution_times[test_name] = execution_time
	return execution_time

func print_test_summary() -> void:
	"""Print test results summary"""
	print("\n============================================================")
	print("TEST RESULTS: " + get_class_name())
	print("============================================================")
	print("Total Tests: " + str(test_results.size()))
	print("Passed: " + str(tests_passed))
	print("Failed: " + str(tests_failed))

	if test_results.size() > 0:
		var success_rate = (float(tests_passed) / float(test_results.size())) * 100.0
		print("Success Rate: " + String.num(success_rate, 2) + "%")

	print("============================================================")

	if tests_failed == 0:
		print("✓ ALL TESTS PASSED!")
	else:
		print("✗ SOME TESTS FAILED - Review results above")

	print("============================================================")
	
	# Print performance summary if available
	if not test_execution_times.is_empty():
		print_performance_summary()

func print_performance_summary() -> void:
	"""Print test execution time summary"""
	print("\n[PERFORMANCE] Test Execution Times:")
	var sorted_tests = test_execution_times.keys()
	if sorted_tests.size() > 0:
		# Sort by execution time (descending)
		sorted_tests.sort_custom(func(a, b): return test_execution_times[a] > test_execution_times[b])
		
		var total_time = 0.0
		for test_name in sorted_tests:
			total_time += test_execution_times[test_name]
		
		print("  Total Execution Time: " + String.num(total_time, 3) + "s")
		print("  Average Time per Test: " + String.num(total_time / sorted_tests.size(), 3) + "s")
		
		# Show top 10 slowest tests
		var top_count = min(10, sorted_tests.size())
		print("\n  Top " + str(top_count) + " Slowest Tests:")
		for i in range(top_count):
			var test_name = sorted_tests[i]
			var time = test_execution_times[test_name]
			print("    " + str(i + 1) + ". " + test_name + ": " + String.num(time, 3) + "s")

func categorize_test(test_name: String, category: TestCategory) -> void:
	"""Categorize a test for filtering"""
	test_categories[test_name] = category

func run_tests_by_category(categories: Array[TestCategory]) -> void:
	"""Run only tests in specified categories (to be implemented by subclasses)"""
	# This should be overridden by test suites that want category filtering
	pass

func get_class_name() -> String:
	"""Get the class name for reporting"""
	return get_script().get_class_name() if get_script() else "UnknownTestSuite"