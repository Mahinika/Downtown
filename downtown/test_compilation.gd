extends Node

## Compilation Test Suite - Comprehensive Error Detection
##
## This script systematically tests all GDScript files for compilation errors,
## missing dependencies, and other issues that might not be caught by the linter.
##
## Usage: Run this scene to get a complete error report.

func _ready() -> void:
	print("🔍 STARTING COMPREHENSIVE COMPILATION TEST")
	print("=" * 60)

	var total_files = 0
	var error_files = 0
	var errors_found = []

	# Test all script files
	var script_paths = _get_all_script_files()
	total_files = script_paths.size()

	print("📁 Testing " + str(total_files) + " script files...")

	for script_path in script_paths:
		var errors = _test_script_compilation(script_path)
		if not errors.is_empty():
			error_files += 1
			errors_found.append({
				"file": script_path,
				"errors": errors
			})
			print("❌ " + script_path + " - " + str(errors.size()) + " errors")

	# Test all scene files
	var scene_paths = _get_all_scene_files()
	print("🎭 Testing " + str(scene_paths.size()) + " scene files...")

	for scene_path in scene_paths:
		var errors = _test_scene_compilation(scene_path)
		if not errors.is_empty():
			error_files += 1
			errors_found.append({
				"file": scene_path,
				"errors": errors
			})
			print("❌ " + scene_path + " - " + str(errors.size()) + " errors")

	# Report results
	print("\n" + "=" * 60)
	print("📊 COMPILATION TEST RESULTS")
	print("=" * 60)

	if errors_found.is_empty():
		print("✅ SUCCESS: All files compiled without errors!")
		print("🎉 Your project is ready for production!")
	else:
		print("❌ FOUND ERRORS: " + str(error_files) + " files with issues")
		print("📋 Detailed Error Report:")
		print("-" * 40)

		for error_info in errors_found:
			print("📄 " + error_info.file)
			for error in error_info.errors:
				print("   🔴 " + error)
			print("")

	print("📈 Summary:")
	print("   Total files tested: " + str(total_files + scene_paths.size()))
	print("   Files with errors: " + str(error_files))
	print("   Clean files: " + str((total_files + scene_paths.size()) - error_files))

	if not errors_found.is_empty():
		print("\n💡 Next Steps:")
		print("   1. Fix the errors listed above")
		print("   2. Run this test again to verify")
		print("   3. Consider adding missing autoloads or dependencies")

	print("=" * 60)
	print("🏁 COMPILATION TEST COMPLETE")

func _get_all_script_files() -> Array:
	"""Get all GDScript files in the project"""
	var files = []
	var dir = DirAccess.open("res://")

	if dir:
		_scan_directory(dir, "res://", files, ".gd")

	return files

func _get_all_scene_files() -> Array:
	"""Get all scene files in the project"""
	var files = []
	var dir = DirAccess.open("res://")

	if dir:
		_scan_directory(dir, "res://", files, ".tscn")

	return files

func _scan_directory(dir: DirAccess, path: String, files: Array, extension: String) -> void:
	"""Recursively scan directory for files with specific extension"""
	dir.list_dir_begin()

	var file_name = dir.get_next()
	while file_name != "":
		if not file_name.begins_with("."):
			var full_path = path + "/" + file_name
			if dir.current_is_dir():
				var sub_dir = DirAccess.open(full_path)
				if sub_dir:
					_scan_directory(sub_dir, full_path, files, extension)
			elif file_name.ends_with(extension):
				files.append(full_path)

		file_name = dir.get_next()

	dir.list_dir_end()

func _test_script_compilation(script_path: String) -> Array:
	"""Test if a script compiles without errors"""
	var errors = []

	# Try to load the script
	var script = load(script_path)
	if not script:
		errors.append("Failed to load script")
		return errors

	# Check if it's a valid GDScript
	if not (script is GDScript):
		errors.append("Not a valid GDScript file")
		return errors

	# Try to create an instance to catch runtime compilation errors
	var test_instance = script.new()
	if not test_instance:
		errors.append("Failed to instantiate script (compilation error)")
	else:
		# Clean up the instance
		test_instance.queue_free()

	return errors

func _test_scene_compilation(scene_path: String) -> Array:
	"""Test if a scene loads without errors"""
	var errors = []

	# Try to load the scene
	var scene = load(scene_path)
	if not scene:
		errors.append("Failed to load scene")
		return errors

	# Try to instantiate the scene
	var instance = scene.instantiate()
	if not instance:
		errors.append("Failed to instantiate scene")
	else:
		# Clean up the instance
		instance.queue_free()

	return errors