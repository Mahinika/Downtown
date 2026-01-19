extends Node

class_name GameplayLoopTest

signal test_complete

var _food_before = null
var _food_after = null
var _wood_before = null
var _wood_after = null
var _pop_before = null
var _pop_after = null

func _ready():
    # Begin a staged gameplay loop validation sequence
    validate_loop()

func validate_loop():
    # Stage 1: setup minimal scenario
    _setup_scenario()
    # Stage 2: progress a few cycles (safely) - simulate without async
    _simulate_cycles(3)
    # Stage 3: evaluate results (scaffold)
    _evaluate_results()

func _setup_scenario():
    print("GameplayLoopTest: setting up minimal scenario (3 villagers, 2 buildings) if possible")
    # Skip city reset for now - method may not exist
    # var city = get_node_or_null("/root/CityManager")
    # if city and city.has_method("reset_state"):
    #     city.call("reset_state")
    var resMan = get_node_or_null("/root/ResourceManager")
    if resMan and resMan.has_method("get_resource"):
        _food_before = resMan.call("get_resource", "food")
        _wood_before = resMan.call("get_resource", "wood")
        _pop_before = resMan.call("get_resource", "population")
    # Skip villager spawning for now - requires proper parameters
    # var villager = get_node_or_null("/root/VillagerManager")
    # if villager and villager.has_method("spawn_villager"):
    #     for i in range(3):
    #         villager.call("spawn_villager", Vector2(10, 10), get_tree().root)
    # Skip building placement for now - requires proper building IDs
    # var building = get_node_or_null("/root/BuildingManager")
    # if building and building.has_method("place_building"):
    #     building.call("place_building", "hut", Vector2i(0, 0))
    #     building.call("place_building", "fire_pit", Vector2i(1, 0))

func _simulate_cycles(count: int):
    for i in range(count):
        # Try to tick all major managers if they expose a tick/step method
        for name in ["CityManager", "VillagerManager", "ResourceManager", "BuildingManager", "ProgressionManager"]:
            var m = get_node_or_null("/root/"+name)
            if m and m.has_method("step"):
                m.call("step", 0.3)
            elif m and m.has_method("tick"):
                m.call("tick", 0.3)
            # else skip if no known hook
        # After stepping, attempt to capture post-cycle metrics if available
        var resMan = get_node_or_null("/root/ResourceManager")
        if resMan and resMan.has_method("get_resource"):
            _food_after = resMan.call("get_resource", "food")
            _wood_after = resMan.call("get_resource", "wood")
            _pop_after = resMan.call("get_resource", "population")

func _evaluate_results():
    print("GameplayLoopTest: evaluating results (scaffold)")
    # Build metrics payload when available
    var metrics = {
        "food_before": _food_before,
        "food_after": _food_after,
        "wood_before": _wood_before,
        "wood_after": _wood_after,
        "population_before": _pop_before,
        "population_after": _pop_after
    }
    var success = false
    if _food_before != null and _food_after != null:
        if _food_after > _food_before:
            success = true
    if _wood_before != null and _wood_after != null:
        if _wood_after > _wood_before:
            success = true or success
    var payload = {
        "success": success,
        "metrics": metrics,
        "notes": "Concrete assertions to be added progressively."
    }
    emit_signal("test_complete", payload)
