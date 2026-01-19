#!/usr/bin/env -S godot --headless --script
## Simple validation runner for Downtown City Management Game
## Run with: godot --headless --script run_validation.gd

extends SceneTree

func _init():
	print("=========================================")
	print("🏗️  Downtown Validation Runner")
	print("=========================================")

	# Try to load and run validation
	var validation_script = load("res://scripts/validation.gd")
	if not validation_script:
		print("❌ Could not load validation script")
		quit(1)
		return

	var validator = validation_script.new()
	var summary = validator.get_validation_summary()

	print("Validation Summary:")
	print("  Status: " + summary.get("overall_status", "unknown"))
	print("  Errors: " + str(summary.get("error_count", 0)))
	print("  Warnings: " + str(summary.get("warning_count", 0)))

	if summary.get("error_count", 0) > 0:
		print("\n❌ ERRORS:")
		for error in validator.validation_errors:
			print("  - " + error)

	if summary.get("warning_count", 0) > 0:
		print("\n⚠️  WARNINGS:")
		for warning in validator.validation_warnings:
			print("  - " + warning)

	print("\n=========================================")

	var exit_code = 0 if summary.get("overall_status") == "PASS" else 1
	quit(exit_code)