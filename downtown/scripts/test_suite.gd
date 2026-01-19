## Test Suite - Downtown City Management Game
##
## Automated test suite for validating core game systems
## Run this with: godot --headless --script res://scripts/test_suite.gd
##
## This script tests:
## - Core system initialization
## - Resource management
## - Basic game logic
## - Data loading

extends SceneTree

var test_results = {
	"passed": 0,
	"failed": 0,
	"errors": []
}

func _init():
	print("=========================================")
	print("🧪 Downtown Test Suite Starting")
	print("=========================================")

	run_all_tests()

	print("\n=========================================")
	print("📊 Test Results")
	print("=========================================")
	print("Passed: ", test_results.passed)
	print("Failed: ", test_results.failed)
	print("Total: ", test_results.passed + test_results.failed)

	if test_results.failed > 0:
		print("\n❌ FAILED TESTS:")
		for error in test_results.errors:
			print("  - " + error)
		print("\n❌ Test suite failed with ", test_results.failed, " failures")
	else:
		print("\n✅ All tests passed!")

	quit(test_results.failed)

func run_all_tests():
	test_core_systems()
	test_resource_system()
	test_data_loading()
	test_validation_system()

func test_core_systems():
	print("\n🔧 Testing Core Systems...")

	# Test GameServices - try different access methods for SceneTree
	var game_services = null

	# Try Node context (in-game testing)
	if has_method("get_node_or_null"):
		game_services = get_node_or_null("/root/GameServices")

	if game_services:
		test_results.passed += 1
		print("✅ GameServices autoload present")
	else:
		test_results.failed += 1
		test_results.errors.append("GameServices autoload missing")
		return

	# Test GameWorld
	var game_world = GameServices.get_world() if game_services else null
	if game_world:
		test_results.passed += 1
		print("✅ GameWorld accessible")
	else:
		test_results.failed += 1
		test_results.errors.append("GameWorld not accessible")

func test_resource_system():
	print("\n💰 Testing Resource System...")

	var economy = null

	# Try to access resource system
	if has_method("get_node_or_null"):
		economy = get_node_or_null("/root/EconomySystem")
		if not economy:
			economy = get_node_or_null("/root/ResourceManager")

	if not economy:
		test_results.failed += 1
		test_results.errors.append("No resource system found")
		return

	# Test basic resource operations
	var test_resource = "wood"
	var initial_amount = economy.get_resource(test_resource) if economy.has_method("get_resource") else 0

	# Try to add resources
	if economy.has_method("add_resource"):
		economy.add_resource(test_resource, 10)
		var new_amount = economy.get_resource(test_resource) if economy.has_method("get_resource") else 0

		if new_amount == initial_amount + 10:
			test_results.passed += 1
			print("✅ Resource addition works")
		else:
			test_results.failed += 1
			test_results.errors.append("Resource addition failed")
	else:
		test_results.failed += 1
		test_results.errors.append("Resource system missing add_resource method")

func test_data_loading():
	print("\n📁 Testing Data Loading...")

	var data_manager = null

	# Try to access DataManager
	if has_method("get_node_or_null"):
		data_manager = get_node_or_null("/root/DataManager")

	if not data_manager:
		test_results.failed += 1
		test_results.errors.append("DataManager not available")
		return

	# Test buildings data
	var buildings_data = data_manager.get_data("buildings") if data_manager.has_method("get_data") else null
	if buildings_data and buildings_data.has("buildings"):
		test_results.passed += 1
		print("✅ Buildings data loaded")
	else:
		test_results.failed += 1
		test_results.errors.append("Buildings data not loaded properly")

	# Test resources data
	var resources_data = data_manager.get_data("resources") if data_manager.has_method("get_data") else null
	if resources_data and resources_data.has("resources"):
		test_results.passed += 1
		print("✅ Resources data loaded")
	else:
		test_results.failed += 1
		test_results.errors.append("Resources data not loaded properly")

func test_validation_system():
	print("\n🔍 Testing Validation System...")

	# Try to load and run validation
	var validation_script = load("res://scripts/validation.gd")
	if validation_script:
		var validator = validation_script.new()
		# Only run basic validation that doesn't require scene tree access
		var summary = validator.get_validation_summary()

		test_results.passed += 1
		print("✅ Validation system loads and initializes")
		print("   Status: " + summary.get("overall_status", "unknown"))
		print("   Errors: " + str(summary.get("error_count", 0)))
		print("   Warnings: " + str(summary.get("warning_count", 0)))
	else:
		test_results.failed += 1
		test_results.errors.append("Validation script could not be loaded")