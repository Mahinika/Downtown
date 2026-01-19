extends Node2D

func _ready():
	print("Test scene started successfully!")
	print("If you see this message and the label on screen,")
	print("then the Godot project is working fine.")
	print("The issue must be with your main scene or autoload configuration.")

	# Make sure the label is visible
	var label = $Label
	if label:
		label.text = "SUCCESS: Godot project is working!\nThe issue is with your main scene.\nCheck autoloads or main.gd script."
		print("Label updated successfully")
	else:
		print("ERROR: Could not find label node!")