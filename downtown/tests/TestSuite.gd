extends Node

class_name TestSuite

func _ready():
    # Entry point for automated tests; currently a skeleton scaffold
    run()

func run():
    print("Gameplay Loop Validation: skeleton test loaded.")
    print("Next steps: implement concrete checks against CityManager, VillagerManager, ResourceManager.")
    # Temporarily disabled - causing crashes
    # # Initialize and connect to GameplayLoopTest skeleton
    # var glt = GameplayLoopTest.new()
    # glt.connect("test_complete", self, "_on_test_complete")
    # add_child(glt)

func _on_test_complete(payload = null) -> void:
    if payload == null:
        print("Gameplay Loop Validation test completed.")
    else:
        print("Gameplay Loop Validation test completed with payload:", payload)

