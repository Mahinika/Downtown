extends Node

## PerformanceRegressionTest - Automated performance regression testing system
##
## Runs comprehensive performance tests and compares results against baselines
## to detect performance regressions. Can be integrated into automated testing.
##
## Key Features:
## - Automated performance scenario testing
## - Baseline comparison and regression detection
## - Comprehensive test coverage (pathfinding, building, AI, rendering)
## - Statistical analysis and reporting
## - Integration with PerformanceMonitor system
##
## Usage:
##   PerformanceRegressionTest.run_regression_tests()
##   var results = PerformanceRegressionTest.get_regression_report()

## Test results storage
var test_results: Dictionary = {}
var baseline_results: Dictionary = {}
var regression_threshold: float = 1.2  # 20% degradation threshold

## Test scenarios configuration
var test_scenarios = {
	"pathfinding_stress": {
		"name": "Pathfinding Stress Test",
		"description": "Tests pathfinding performance with multiple concurrent path requests",
		"test_count": 50,
		"expected_time": 100.0  # ms
	},
	"building_placement_stress": {
		"name": "Building Placement Stress Test",
		"description": "Tests building placement performance with multiple buildings",
		"test_count": 20,
		"expected_time": 200.0  # ms
	},
	"ai_simulation": {
		"name": "AI Simulation Test",
		"description": "Tests villager AI performance over simulation period",
		"duration": 5.0,  # seconds
		"expected_fps": 50.0
	},
	"rendering_stress": {
		"name": "Rendering Stress Test",
		"description": "Tests rendering performance with maximum visual elements",
		"expected_fps": 40.0,
		"duration": 3.0
	}
}

func _ready() -> void:
	print("[PerformanceRegressionTest] Initialized - Automated performance regression testing ready")
	load_baselines()

func run_regression_tests() -> Dictionary:
	"""Run all performance regression tests and return results"""
	print("\n" + "=".repeat(60))
	print("PERFORMANCE REGRESSION TESTING")
	print("=".repeat(60))

	test_results.clear()
	var results = {
		"passed": 0,
		"failed": 0,
		"regressions": [],
		"improvements": [],
		"test_results": {}
	}

	# Run each test scenario
	for scenario_id in test_scenarios:
		var scenario = test_scenarios[scenario_id]
		print("\n[TEST] Running: " + scenario.name)
		print("Description: " + scenario.description)

		var test_result = run_scenario_test(scenario_id, scenario)
		test_results[scenario_id] = test_result
		results.test_results[scenario_id] = test_result

		# Check for regressions
		var regression_result = check_regression(scenario_id, test_result)
		if regression_result.has_regression:
			results.regressions.append(regression_result)
			results.failed += 1
			print("❌ REGRESSION DETECTED: " + regression_result.message)
		else:
			results.passed += 1
			if regression_result.has_improvement:
				results.improvements.append(regression_result)
				print("✅ IMPROVEMENT: " + regression_result.message)
			else:
				print("✅ PASSED: Within acceptable performance range")

	# Save current results as new baseline if all tests pass
	if results.failed == 0:
		save_baselines()
		print("\n✅ All tests passed - Updated performance baselines")

	# Generate report
	print("\n" + "=".repeat(60))
	print("REGRESSION TEST RESULTS")
	print("=".repeat(60))
	print("Total Tests: " + str(test_scenarios.size()))
	print("Passed: " + str(results.passed))
	print("Failed: " + str(results.failed))
	print("Regressions: " + str(results.regressions.size()))
	print("Improvements: " + str(results.improvements.size()))

	return results

func run_scenario_test(scenario_id: String, scenario: Dictionary) -> Dictionary:
	"""Run a specific test scenario and return performance metrics"""
	var result = {
		"scenario_id": scenario_id,
		"scenario_name": scenario.name,
		"start_time": Time.get_ticks_usec(),
		"metrics": {},
		"success": false,
		"error": ""
	}

	# Run test synchronously without await
	match scenario_id:
		"pathfinding_stress":
			result = run_pathfinding_stress_test(scenario)
		"building_placement_stress":
			result = run_building_placement_stress_test(scenario)
		"ai_simulation":
			result = run_ai_simulation_test_sync(scenario)
		"rendering_stress":
			result = run_rendering_stress_test_sync(scenario)
		_:
			result.error = "Unknown scenario: " + scenario_id

	result.end_time = Time.get_ticks_usec()
	result.total_time = (result.end_time - result.start_time) / 1000.0  # Convert to ms

	return result

func run_pathfinding_stress_test(scenario: Dictionary) -> Dictionary:
	"""Run pathfinding stress test with multiple concurrent path requests"""
	var result = {
		"metrics": {},
		"success": true,
		"paths_calculated": 0,
		"total_path_time": 0.0
	}

	if not CityManager:
		result.success = false
		result.error = "CityManager not available"
		return result

	# Generate random pathfinding requests
	var test_count = scenario.test_count
	for i in range(test_count):
		# Generate random start and end positions
		var start_pos = Vector2i(randi() % 90 + 5, randi() % 90 + 5)  # Avoid edges
		var end_pos = Vector2i(randi() % 90 + 5, randi() % 90 + 5)

		if PerformanceMonitor:
			PerformanceMonitor.start_benchmark("stress_path_" + str(i))

		var path = CityManager.get_navigation_path(start_pos, end_pos)

		if PerformanceMonitor:
			var path_time = PerformanceMonitor.end_benchmark("stress_path_" + str(i))
			result.total_path_time += path_time

		if not path.is_empty():
			result.paths_calculated += 1

	result.metrics = {
		"paths_calculated": result.paths_calculated,
		"total_path_time": result.total_path_time,
		"average_path_time": result.total_path_time / max(1, result.paths_calculated),
		"success_rate": float(result.paths_calculated) / test_count * 100.0
	}

	return result

func run_building_placement_stress_test(scenario: Dictionary) -> Dictionary:
	"""Run building placement stress test"""
	var result = {
		"metrics": {},
		"success": true,
		"buildings_placed": 0,
		"total_placement_time": 0.0
	}

	if not BuildingManager or not CityManager:
		result.success = false
		result.error = "Required managers not available"
		return result

	# Test building placement performance
	var test_count = scenario.test_count
	var building_types = ["hut", "fire_pit", "stockpile"]  # Simple buildings for testing

	for i in range(test_count):
		var building_type = building_types[i % building_types.size()]
		var grid_pos = Vector2i(10 + i, 10 + i)  # Spread out positions

		if PerformanceMonitor:
			PerformanceMonitor.start_benchmark("stress_building_" + str(i))

		var building_id = BuildingManager.place_building(building_type, grid_pos)

		if PerformanceMonitor:
			var placement_time = PerformanceMonitor.end_benchmark("stress_building_" + str(i))
			result.total_placement_time += placement_time

		if not building_id.is_empty():
			result.buildings_placed += 1

	result.metrics = {
		"buildings_placed": result.buildings_placed,
		"total_placement_time": result.total_placement_time,
		"average_placement_time": result.total_placement_time / max(1, result.buildings_placed),
		"success_rate": float(result.buildings_placed) / test_count * 100.0
	}

	return result

func run_ai_simulation_test_sync(scenario: Dictionary) -> Dictionary:
	"""Run AI simulation test over a time period (synchronous version)"""
	var result = {
		"metrics": {},
		"success": true,
		"simulation_time": scenario.duration,
		"fps_samples": [],
		"average_fps": 0.0
	}

	# For synchronous testing, we'll simulate by taking samples at regular intervals
	# instead of using await. This gives us performance data without async complexity.
	var sample_count = int(scenario.duration * 10)  # 10 samples per second
	var sample_interval = 1.0 / 10.0  # 100ms intervals

	for i in range(sample_count):
		# Force a frame update by calling process_frame manually (if possible)
		# For synchronous testing, we'll just sample current performance
		if PerformanceMonitor:
			result.fps_samples.append(PerformanceMonitor.current_fps)

		# Simulate time passing (very basic approximation)
		OS.delay_msec(int(sample_interval * 1000))

	# Calculate average FPS
	if not result.fps_samples.is_empty():
		var sum_fps = 0.0
		for fps in result.fps_samples:
			sum_fps += fps
		result.average_fps = sum_fps / result.fps_samples.size()

	result.metrics = {
		"simulation_duration": scenario.duration,
		"fps_samples_count": result.fps_samples.size(),
		"average_fps": result.average_fps,
		"min_fps": result.fps_samples.min() if not result.fps_samples.is_empty() else 0,
		"max_fps": result.fps_samples.max() if not result.fps_samples.is_empty() else 0
	}

	return result

func run_rendering_stress_test_sync(scenario: Dictionary) -> Dictionary:
	"""Run rendering stress test (synchronous version)"""
	var result = {
		"metrics": {},
		"success": true,
		"test_duration": scenario.duration,
		"fps_samples": [],
		"average_fps": 0.0
	}

	# For synchronous testing, enable mini-map if possible and take performance samples
	var parent = get_parent()
	if parent and parent.has_method("toggle_minimap") and not parent.minimap_visible:
		parent.toggle_minimap()

	# Take multiple performance samples over the duration
	var sample_count = int(scenario.duration * 10)  # 10 samples per second
	var sample_interval = 1.0 / 10.0  # 100ms intervals

	for i in range(sample_count):
		if PerformanceMonitor:
			result.fps_samples.append(PerformanceMonitor.current_fps)

		# Basic delay to simulate time passing
		OS.delay_msec(int(sample_interval * 1000))

	# Calculate average FPS
	if not result.fps_samples.is_empty():
		var sum_fps = 0.0
		for fps in result.fps_samples:
			sum_fps += fps
		result.average_fps = sum_fps / result.fps_samples.size()

	result.metrics = {
		"test_duration": scenario.duration,
		"fps_samples_count": result.fps_samples.size(),
		"average_fps": result.average_fps,
		"min_fps": result.fps_samples.min() if not result.fps_samples.is_empty() else 0,
		"max_fps": result.fps_samples.max() if not result.fps_samples.is_empty() else 0
	}

	return result

# Async versions for potential future use
func run_ai_simulation_test_async(scenario: Dictionary) -> Dictionary:
	"""Run AI simulation test over a time period (async version)"""
	var result = {
		"metrics": {},
		"success": true,
		"simulation_time": scenario.duration,
		"fps_samples": [],
		"average_fps": 0.0
	}

	# Run simulation for specified duration
	var start_time = Time.get_ticks_msec()
	var end_time = start_time + (scenario.duration * 1000)

	while Time.get_ticks_msec() < end_time:
		await get_tree().process_frame
		if PerformanceMonitor:
			result.fps_samples.append(PerformanceMonitor.current_fps)

	# Calculate average FPS
	if not result.fps_samples.is_empty():
		var sum_fps = 0.0
		for fps in result.fps_samples:
			sum_fps += fps
		result.average_fps = sum_fps / result.fps_samples.size()

	result.metrics = {
		"simulation_duration": scenario.duration,
		"fps_samples_count": result.fps_samples.size(),
		"average_fps": result.average_fps,
		"min_fps": result.fps_samples.min() if not result.fps_samples.is_empty() else 0,
		"max_fps": result.fps_samples.max() if not result.fps_samples.is_empty() else 0
	}

	return result

func run_rendering_stress_test_async(scenario: Dictionary) -> Dictionary:
	"""Run rendering stress test (async version)"""
	var result = {
		"metrics": {},
		"success": true,
		"test_duration": scenario.duration,
		"fps_samples": [],
		"average_fps": 0.0
	}

	# Enable mini-map for additional rendering load
	if get_parent().has_method("toggle_minimap") and not get_parent().minimap_visible:
		get_parent().toggle_minimap()

	# Run test for specified duration
	var start_time = Time.get_ticks_msec()
	var end_time = start_time + (scenario.duration * 1000)

	while Time.get_ticks_msec() < end_time:
		await get_tree().process_frame
		if PerformanceMonitor:
			result.fps_samples.append(PerformanceMonitor.current_fps)

	# Calculate average FPS
	if not result.fps_samples.is_empty():
		var sum_fps = 0.0
		for fps in result.fps_samples:
			sum_fps += fps
		result.average_fps = sum_fps / result.fps_samples.size()

	result.metrics = {
		"test_duration": scenario.duration,
		"fps_samples_count": result.fps_samples.size(),
		"average_fps": result.average_fps,
		"min_fps": result.fps_samples.min() if not result.fps_samples.is_empty() else 0,
		"max_fps": result.fps_samples.max() if not result.fps_samples.is_empty() else 0
	}

	return result

func check_regression(scenario_id: String, current_result: Dictionary) -> Dictionary:
	"""Check if current results show regression compared to baseline"""
	var result = {
		"scenario_id": scenario_id,
		"has_regression": false,
		"has_improvement": false,
		"message": "",
		"baseline_value": 0.0,
		"current_value": 0.0,
		"degradation_percent": 0.0
	}

	if not baseline_results.has(scenario_id):
		result.message = "No baseline available for " + scenario_id
		return result

	var baseline = baseline_results[scenario_id]
	var current = current_result

	# Check different metrics based on scenario type
	match scenario_id:
		"pathfinding_stress":
			# Check average path time - lower is better
			var baseline_time = baseline.metrics.get("average_path_time", 0.0)
			var current_time = current.metrics.get("average_path_time", 0.0)

			if current_time > baseline_time * regression_threshold:
				result.has_regression = true
				result.degradation_percent = ((current_time - baseline_time) / baseline_time) * 100.0
				result.message = "Pathfinding %.1f%% slower (%.2fms vs %.2fms)" % [result.degradation_percent, current_time, baseline_time]
			elif current_time < baseline_time * 0.9:  # 10% improvement
				result.has_improvement = true
				result.message = "Pathfinding improved by %.1f%%" % [((baseline_time - current_time) / baseline_time) * 100.0]

		"building_placement_stress":
			# Check average placement time - lower is better
			var baseline_time = baseline.metrics.get("average_placement_time", 0.0)
			var current_time = current.metrics.get("average_placement_time", 0.0)

			if current_time > baseline_time * regression_threshold:
				result.has_regression = true
				result.degradation_percent = ((current_time - baseline_time) / baseline_time) * 100.0
				result.message = "Building placement %.1f%% slower (%.2fms vs %.2fms)" % [result.degradation_percent, current_time, baseline_time]

		"ai_simulation", "rendering_stress":
			# Check average FPS - higher is better
			var baseline_fps = baseline.metrics.get("average_fps", 0.0)
			var current_fps = current.metrics.get("average_fps", 0.0)

			if current_fps < baseline_fps / regression_threshold:
				result.has_regression = true
				result.degradation_percent = ((baseline_fps - current_fps) / baseline_fps) * 100.0
				result.message = "FPS %.1f%% lower (%.1f vs %.1f)" % [result.degradation_percent, current_fps, baseline_fps]
			elif current_fps > baseline_fps * 1.1:  # 10% improvement
				result.has_improvement = true
				result.message = "FPS improved by %.1f%%" % [((current_fps - baseline_fps) / baseline_fps) * 100.0]

	return result

func save_baselines() -> void:
	"""Save current test results as performance baselines"""
	var baseline_file = "user://performance_baselines.json"

	baseline_results = test_results.duplicate(true)

	var json_data = JSON.stringify(baseline_results)
	var file = FileAccess.open(baseline_file, FileAccess.WRITE)
	if file:
		file.store_string(json_data)
		file.close()
		print("[PerformanceRegressionTest] Performance baselines saved")
	else:
		print("[PerformanceRegressionTest] Failed to save performance baselines")

func load_baselines() -> void:
	"""Load performance baselines from file"""
	var baseline_file = "user://performance_baselines.json"

	if not FileAccess.file_exists(baseline_file):
		print("[PerformanceRegressionTest] No performance baselines found - will create after first test run")
		return

	var file = FileAccess.open(baseline_file, FileAccess.READ)
	if file:
		var json_data = file.get_as_text()
		file.close()

		var json = JSON.new()
		var parse_result = json.parse(json_data)
		if parse_result == OK:
			baseline_results = json.get_data()
			print("[PerformanceRegressionTest] Loaded performance baselines")
		else:
			print("[PerformanceRegressionTest] Failed to parse performance baselines")
	else:
		print("[PerformanceRegressionTest] Failed to load performance baselines")

func get_regression_report() -> Dictionary:
	"""Get comprehensive regression test report"""
	return {
		"test_results": test_results,
		"baseline_results": baseline_results,
		"regression_threshold": regression_threshold,
		"scenarios": test_scenarios,
		"summary": {
			"total_scenarios": test_scenarios.size(),
			"baseline_scenarios": baseline_results.size(),
			"has_baselines": not baseline_results.is_empty()
		}
	}

# Debug functions
func run_single_test(scenario_id: String) -> Dictionary:
	"""Run a single test scenario for debugging"""
	if not test_scenarios.has(scenario_id):
		return {"error": "Unknown scenario: " + scenario_id}

	var scenario = test_scenarios[scenario_id]
	return run_scenario_test(scenario_id, scenario)

func print_detailed_report() -> void:
	"""Print detailed regression test report"""
	var report = get_regression_report()

	print("\n" + "=".repeat(80))
	print("DETAILED PERFORMANCE REGRESSION REPORT")
	print("=".repeat(80))
	print("Regression Threshold: %.1f%%" % ((regression_threshold - 1.0) * 100.0))
	print("Has Baselines: " + str(report.summary.has_baselines))
	print("")

	for scenario_id in test_scenarios:
		var scenario = test_scenarios[scenario_id]
		print("SCENARIO: " + scenario.name)
		print("  Description: " + scenario.description)

		if test_results.has(scenario_id):
			var result = test_results[scenario_id]
			print("  Status: " + ("SUCCESS" if result.success else "FAILED"))
			print("  Total Time: %.2f ms" % result.total_time)

			# Print metrics
			for metric_key in result.metrics:
				var metric_value = result.metrics[metric_key]
				if metric_value is float:
					print("  %s: %.2f" % [metric_key.capitalize(), metric_value])
				else:
					print("  %s: %s" % [metric_key.capitalize(), str(metric_value)])
		else:
			print("  Status: NOT RUN")

		if baseline_results.has(scenario_id):
			print("  Baseline: Available")
		else:
			print("  Baseline: Not Available")

		print("")
