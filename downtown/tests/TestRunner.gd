extends Node

## TestRunner - Automated test execution and reporting
##
## Runs all test suites and generates a comprehensive report
## Can be run from command line or in-editor

class_name TestRunner

signal all_tests_complete(results: Dictionary)

var all_results: Dictionary = {}
var total_tests: int = 0
var total_passed: int = 0
var total_failed: int = 0

func _ready() -> void:
	print("============================================================")
	print("TEST RUNNER - Starting automated test execution")
	print("============================================================")
	
	# Wait for managers to initialize
	await get_tree().process_frame
	await get_tree().process_frame
	
	run_all_test_suites()

func run_all_test_suites() -> void:
	"""Run all available test suites"""
	all_results.clear()
	total_tests = 0
	total_passed = 0
	total_failed = 0
	
	# Run Comprehensive Test Suite
	run_comprehensive_tests()
	
	# Wait for tests to complete
	await get_tree().create_timer(0.5).timeout
	
	# Print final summary
	print_final_summary()

func run_comprehensive_tests() -> void:
	"""Run the comprehensive test suite"""
	print("\n[TEST RUNNER] Running Comprehensive Test Suite...\n")
	
	var test_suite = ComprehensiveTestSuite.new()
	add_child(test_suite)
	
	test_suite.all_tests_complete.connect(_on_comprehensive_tests_complete)
	
	# Wait for completion
	await test_suite.all_tests_complete
	
	all_results["ComprehensiveTestSuite"] = test_suite.test_results
	total_tests += test_suite.test_results.size()
	total_passed += test_suite.tests_passed
	total_failed += test_suite.tests_failed

func _on_comprehensive_tests_complete(results: Dictionary) -> void:
	"""Handle comprehensive test suite completion"""
	print("\n[TEST RUNNER] Comprehensive Test Suite completed")
	print("  Results: " + str(results.size()) + " tests")

func print_final_summary() -> void:
	"""Print final test execution summary"""
	print("\n============================================================")
	print("FINAL TEST EXECUTION SUMMARY")
	print("============================================================")
	print("Total Test Suites: " + str(all_results.size()))
	print("Total Tests Executed: " + str(total_tests))
	print("Total Passed: " + str(total_passed))
	print("Total Failed: " + str(total_failed))
	
	if total_tests > 0:
		var overall_success_rate = (float(total_passed) / float(total_tests)) * 100.0
		print("Overall Success Rate: " + String.num(overall_success_rate, 2) + "%")
	
	print("\nTest Suite Breakdown:")
	for suite_name in all_results:
		var suite_results = all_results[suite_name]
		var suite_passed = 0
		var suite_failed = 0
		
		for test_name in suite_results:
			if suite_results[test_name].passed:
				suite_passed += 1
			else:
				suite_failed += 1
		
		var suite_total = suite_passed + suite_failed
		var suite_rate = (float(suite_passed) / float(suite_total)) * 100.0 if suite_total > 0 else 0.0
		
		print("  " + suite_name + ": " + str(suite_passed) + "/" + str(suite_total) + 
		      " (" + String.num(suite_rate, 1) + "%)")
	
	print("\n============================================================")
	
	if total_failed == 0:
		print("✓ ALL TESTS PASSED!")
		print("✓ System is fully validated and ready for deployment")
	else:
		print("✗ SOME TESTS FAILED")
		print("✗ Review failed tests above and fix issues")
	
	print("============================================================")
	
	# Emit completion signal
	all_tests_complete.emit(all_results)
	
	# Exit after a delay (for command-line execution)
	await get_tree().create_timer(2.0).timeout
	get_tree().quit(0 if total_failed == 0 else 1)
