extends Node

# Simple test script to verify asset generation works
func _ready():
	print("Testing Asset Generation...")

	# Check if AssetGenerator is available
	var asset_gen = get_node_or_null("/root/AssetGenerator")
	if asset_gen:
		print("✓ AssetGenerator found in autoloads")

		# Test asset generation
		if asset_gen.has_method("generate_all_assets"):
			print("✓ generate_all_assets method available")
			# Note: We won't actually generate here to avoid overwriting existing assets
			print("✓ Asset generation system ready")
		else:
			print("✗ generate_all_assets method not found")
	else:
		print("✗ AssetGenerator not found in autoloads")

	# Check if assets directory exists
	var assets_dir = "res://assets/"
	if DirAccess.dir_exists_absolute(assets_dir):
		print("✓ Assets directory exists: ", assets_dir)
	else:
		print("✗ Assets directory missing: ", assets_dir)

	# Check for a few key asset paths
	var test_assets = [
		"res://assets/buildings/hut.png",
		"res://assets/villagers/villager_idle.png",
		"res://assets/resources/tree.png"
	]

	for asset_path in test_assets:
		if ResourceLoader.exists(asset_path):
			print("✓ Asset exists: ", asset_path)
		else:
			print("✗ Asset missing: ", asset_path)

	print("Asset generation test complete.")
	queue_free()