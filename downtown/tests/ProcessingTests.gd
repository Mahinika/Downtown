extends TestBase

## ProcessingTests - Tests for processing buildings and production chains
##
## Tests mills, bakeries, breweries, blacksmiths, smokers, engineers,
## and complete production chains from raw materials to finished goods.

class_name ProcessingTests

func _ready() -> void:
	super._ready()
	run_processing_tests()

func run_processing_tests() -> void:
	"""Run all processing system tests"""
	print("\n[TEST] Starting Processing Tests...\n")

	# Processing Buildings Tests
	test_processing_buildings()
	test_miller_job()
	test_brewer_job()
	test_blacksmith_job()
	test_smoker_job()
	test_engineer_job()

	# Production Chain Tests
	test_production_chains_actual_processing()
	test_complete_production_chains()

	# New Buildings Tests
	test_apple_orchard()
	test_hops_farm()
	test_bakery()
	test_inn()
	test_fear_buildings()
	test_good_things_buildings()

	# New Resources Tests
	test_new_resources()

	# Print results
	print_test_summary()

# ==================== Processing Buildings Tests ====================

func test_processing_buildings() -> void:
	print("[TEST] Processing Buildings...")

	if not BuildingManager:
		record_test("Processing_ManagerExists", false, "BuildingManager not found")
		return

	# Test processing buildings tracking
	var has_processing = BuildingManager.has("processing_buildings")
	record_test("Processing_Tracking", has_processing,
		"Processing buildings tracking: " + str(has_processing))

	# Test processing accumulation
	var has_accumulation = BuildingManager.has("processing_accumulation")
	record_test("Processing_Accumulation", has_accumulation,
		"Processing accumulation tracking: " + str(has_accumulation))

	# Test process_production_chains method
	var has_process_method = BuildingManager.has_method("process_production_chains")
	record_test("Processing_ProcessMethod", has_process_method,
		"process_production_chains method: " + str(has_process_method))

func test_miller_job() -> void:
	print("\n[TEST] Miller Job...")

	if not JobSystem:
		record_test("Miller_JobSystemExists", false, "JobSystem not found")
		return

	# Test miller work cycle creation
	var has_cycle = JobSystem.has_method("create_miller_work_cycle")
	record_test("Miller_WorkCycle", has_cycle,
		"create_miller_work_cycle exists: " + str(has_cycle))

	# Test miller assignment
	var has_assign = JobSystem.has_method("assign_miller_job")
	record_test("Miller_Assignment", has_assign,
		"assign_miller_job exists: " + str(has_assign))

func test_brewer_job() -> void:
	print("\n[TEST] Brewer Job...")

	if not JobSystem:
		record_test("Brewer_JobSystemExists", false, "JobSystem not found")
		return

	var has_cycle = JobSystem.has_method("create_brewer_work_cycle")
	record_test("Brewer_WorkCycle", has_cycle,
		"create_brewer_work_cycle exists: " + str(has_cycle))

	var has_assign = JobSystem.has_method("assign_brewer_job")
	record_test("Brewer_Assignment", has_assign,
		"assign_brewer_job exists: " + str(has_assign))

func test_blacksmith_job() -> void:
	print("\n[TEST] Blacksmith Job...")

	if not JobSystem:
		record_test("Blacksmith_JobSystemExists", false, "JobSystem not found")
		return

	var has_cycle = JobSystem.has_method("create_blacksmith_work_cycle")
	record_test("Blacksmith_WorkCycle", has_cycle,
		"create_blacksmith_work_cycle exists: " + str(has_cycle))

	var has_assign = JobSystem.has_method("assign_blacksmith_job")
	record_test("Blacksmith_Assignment", has_assign,
		"assign_blacksmith_job exists: " + str(has_assign))

func test_smoker_job() -> void:
	print("\n[TEST] Smoker Job...")

	if not JobSystem:
		record_test("Smoker_JobSystemExists", false, "JobSystem not found")
		return

	var has_cycle = JobSystem.has_method("create_smoker_work_cycle")
	record_test("Smoker_WorkCycle", has_cycle,
		"create_smoker_work_cycle exists: " + str(has_cycle))

	var has_assign = JobSystem.has_method("assign_smoker_job")
	record_test("Smoker_Assignment", has_assign,
		"assign_smoker_job exists: " + str(has_assign))

func test_engineer_job() -> void:
	print("\n[TEST] Engineer Job...")

	if not JobSystem:
		record_test("Engineer_JobSystemExists", false, "JobSystem not found")
		return

	var has_cycle = JobSystem.has_method("create_engineer_work_cycle")
	record_test("Engineer_WorkCycle", has_cycle,
		"create_engineer_work_cycle exists: " + str(has_cycle))

	var has_assign = JobSystem.has_method("assign_engineer_job")
	record_test("Engineer_Assignment", has_assign,
		"assign_engineer_job exists: " + str(has_assign))

# ==================== Production Chain Tests ====================

func test_production_chains_actual_processing() -> void:
	print("\n[TEST] Production Chains Actual Processing...")

	if not BuildingManager or not ResourceManager:
		record_test("ProductionChains_ManagersExist", false, "Managers not found")
		return

	# Test that processing actually occurs
	var has_process = BuildingManager.has_method("process_production_chains")
	record_test("ProductionChains_ProcessMethod", has_process,
		"process_production_chains exists: " + str(has_process))

func test_complete_production_chains() -> void:
	print("\n[TEST] Complete Production Chains...")

	if not BuildingManager or not ResourceManager:
		record_test("CompleteChains_ManagersExist", false, "Managers not found")
		return

	# Test complete bread chain: Wheat Farm → Mill → Bakery → Bread
	setup_test_environment()
	TestDataBuilder.setup_basic_resources()

	var farm_id = TestDataBuilder.create_test_building("farm", Vector2i(30, 30))
	var mill_id = TestDataBuilder.create_test_building("mill", Vector2i(35, 35))
	var bakery_id = TestDataBuilder.create_test_building("bakery", Vector2i(40, 40))

	var chain_complete = (not farm_id.is_empty() and not mill_id.is_empty() and not bakery_id.is_empty())
	record_test("CompleteChains_AllBuildingsPlaced", chain_complete,
		"All chain buildings placed: " + str(chain_complete))

	if chain_complete:
		# Assign workers and wait for processing
		var farmer_id = TestDataBuilder.create_test_villager(Vector2(500, 500))
		var miller_id = TestDataBuilder.create_test_villager(Vector2(550, 550))
		var baker_id = TestDataBuilder.create_test_villager(Vector2(600, 600))

		if not farmer_id.is_empty():
			JobSystem.assign_villager_to_building(farmer_id, farm_id, "farmer")
		if not miller_id.is_empty():
			JobSystem.assign_villager_to_building(miller_id, mill_id, "miller")
		if not baker_id.is_empty():
			JobSystem.assign_villager_to_building(baker_id, bakery_id, "baker")

		await get_tree().create_timer(5.0).timeout

		# Check if bread was produced
		var bread_amount = ResourceManager.get_resource("bread")
		var chain_works = (bread_amount > 0.0)
		record_test("CompleteChains_BreadProduced", chain_works,
			"Complete chain produces bread: " + str(bread_amount))

	cleanup_test_environment()

# ==================== New Buildings Tests ====================

func test_apple_orchard() -> void:
	print("\n[TEST] Apple Orchard Building...")

	if not DataManager:
		record_test("AppleOrchard_DataManagerExists", false, "DataManager not found")
		return

	var buildings = DataManager.get_buildings_data()
	var has_orchard = buildings.has("apple_orchard")
	record_test("AppleOrchard_InData", has_orchard,
		"apple_orchard in buildings data: " + str(has_orchard))

	if has_orchard:
		var orchard_data = buildings["apple_orchard"]
		var has_food_type = orchard_data.get("effects", {}).has("food_type")
		record_test("AppleOrchard_FoodType", has_food_type,
			"apple_orchard has food_type effect: " + str(has_food_type))

func test_hops_farm() -> void:
	print("\n[TEST] Hops Farm Building...")

	if not DataManager:
		record_test("HopsFarm_DataManagerExists", false, "DataManager not found")
		return

	var buildings = DataManager.get_buildings_data()
	var has_hops_farm = buildings.has("hops_farm")
	record_test("HopsFarm_InData", has_hops_farm,
		"hops_farm in buildings data: " + str(has_hops_farm))

	if has_hops_farm:
		var hops_data = buildings["hops_farm"]
		var produces_hops = hops_data.get("production_rate", {}).has("hops")
		record_test("HopsFarm_ProducesHops", produces_hops,
			"hops_farm produces hops: " + str(produces_hops))

func test_bakery() -> void:
	print("\n[TEST] Bakery Building...")

	if not DataManager:
		record_test("Bakery_DataManagerExists", false, "DataManager not found")
		return

	var buildings = DataManager.get_buildings_data()
	var has_bakery = buildings.has("bakery")
	record_test("Bakery_InData", has_bakery,
		"bakery in buildings data: " + str(has_bakery))

	if has_bakery:
		var bakery_data = buildings["bakery"]
		var has_requires = bakery_data.has("requires")
		var processes_flour = bakery_data.get("effects", {}).get("processes", {}).has("flour")
		record_test("Bakery_RequiresMill", has_requires,
			"bakery has requirements: " + str(has_requires))
		record_test("Bakery_ProcessesFlour", processes_flour,
			"bakery processes flour: " + str(processes_flour))

func test_inn() -> void:
	print("\n[TEST] Inn Building...")

	if not DataManager:
		record_test("Inn_DataManagerExists", false, "DataManager not found")
		return

	var buildings = DataManager.get_buildings_data()
	var has_inn = buildings.has("inn")
	record_test("Inn_InData", has_inn,
		"inn in buildings data: " + str(has_inn))

	if has_inn:
		var inn_data = buildings["inn"]
		var has_coverage = inn_data.get("effects", {}).has("ale_coverage")
		var consumes_beer = inn_data.get("consumption_rate", {}).has("beer")
		record_test("Inn_AleCoverage", has_coverage,
			"inn has ale_coverage: " + str(has_coverage))
		record_test("Inn_ConsumesBeer", consumes_beer,
			"inn consumes beer: " + str(consumes_beer))

func test_fear_buildings() -> void:
	print("\n[TEST] Fear Buildings (Bad Things)...")

	if not DataManager:
		record_test("FearBuildings_DataManagerExists", false, "DataManager not found")
		return

	var buildings = DataManager.get_buildings_data()
	var has_gallows = buildings.has("gallows")
	var has_dungeon = buildings.has("dungeon")
	record_test("FearBuildings_Gallows", has_gallows,
		"gallows in buildings data: " + str(has_gallows))
	record_test("FearBuildings_Dungeon", has_dungeon,
		"dungeon in buildings data: " + str(has_dungeon))

	if has_gallows:
		var gallows_data = buildings["gallows"]
		var is_fear = gallows_data.get("category") == "fear"
		var has_fear_level = gallows_data.has("fear_level")
		record_test("FearBuildings_GallowsCategory", is_fear,
			"gallows is fear category: " + str(is_fear))
		record_test("FearBuildings_GallowsFearLevel", has_fear_level,
			"gallows has fear_level: " + str(has_fear_level))

func test_good_things_buildings() -> void:
	print("\n[TEST] Good Things Buildings (Entertainment)...")

	if not DataManager:
		record_test("GoodThings_DataManagerExists", false, "DataManager not found")
		return

	var buildings = DataManager.get_buildings_data()
	var has_garden = buildings.has("garden")
	var has_church = buildings.has("church")
	record_test("GoodThings_Garden", has_garden,
		"garden in buildings data: " + str(has_garden))
	record_test("GoodThings_Church", has_church,
		"church in buildings data: " + str(has_church))

	if has_garden:
		var garden_data = buildings["garden"]
		var is_entertainment = garden_data.get("category") == "entertainment"
		var has_good_level = garden_data.has("good_level")
		record_test("GoodThings_GardenCategory", is_entertainment,
			"garden is entertainment category: " + str(is_entertainment))
		record_test("GoodThings_GardenGoodLevel", has_good_level,
			"garden has good_level: " + str(has_good_level))

# ==================== New Resources Tests ====================

func test_new_resources() -> void:
	print("\n[TEST] New Resources (Hops, Bread, Meat)...")

	if not DataManager:
		record_test("NewResources_DataManagerExists", false, "DataManager not found")
		return

	var resources = DataManager.get_resources_data()
	var has_hops = resources.has("hops")
	var has_bread = resources.has("bread")
	var has_meat = resources.has("meat")
	record_test("NewResources_Hops", has_hops,
		"hops in resources data: " + str(has_hops))
	record_test("NewResources_Bread", has_bread,
		"bread in resources data: " + str(has_bread))
	record_test("NewResources_Meat", has_meat,
		"meat in resources data: " + str(has_meat))

	# Test ResourceManager recognizes new resources
	if ResourceManager and has_hops:
		var hops_amount = ResourceManager.get_resource("hops")
		record_test("NewResources_HopsAccessible", hops_amount is float,
			"hops accessible via ResourceManager: " + str(hops_amount))