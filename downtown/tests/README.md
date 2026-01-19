# Automated Test Suite

This directory contains comprehensive automated tests for the Downtown game.

## Test Suites

### ComprehensiveTestSuite
The main test suite that validates all game systems:
- All 16 manager systems
- Processing buildings (Mill, Brewery, Blacksmith, Smokehouse, Advanced Workshop)
- All job types (Lumberjack, Miner, Farmer, Miller, Brewer, Blacksmith, Smoker, Engineer)
- UI panels (Research, Skills, Events, Goals)
- Progression system (goals, achievements, unlocks)
- Research system (projects, progress, unlocks)
- Seasonal system
- Complete save/load system
- Integration tests

### PipelineTest
Basic pipeline validation tests for core systems.

### GameplayLoopTest
Gameplay loop validation tests.

## Running Tests

### In Godot Editor
1. Open the project in Godot
2. Open `res://tests/ComprehensiveTestSuite.tscn` or `res://tests/TestRunner.tscn`
3. Run the scene (F5)
4. Check the output console for test results

### From Command Line
```bash
# Run comprehensive tests
godot --headless --script res://tests/TestRunner.gd

# Or run specific test suite
godot --headless --script res://tests/ComprehensiveTestSuite.gd
```

### Using npm
```bash
npm run test:comprehensive
```

## Test Coverage

The comprehensive test suite covers:

### Core Systems
- ✅ All 16 manager initialization
- ✅ Data loading (resources, buildings)
- ✅ Resource operations (add, consume, can_afford, storage)
- ✅ Building placement and validation
- ✅ Villager spawning and management
- ✅ Job system and assignments

### Processing Buildings
- ✅ Processing building registration
- ✅ Processing accumulation tracking
- ✅ All 5 processing job types (Miller, Brewer, Blacksmith, Smoker, Engineer)
- ✅ Work cycle creation for all processing jobs

### UI System
- ✅ UITheme and UIBuilder initialization
- ✅ Research Panel (create, refresh)
- ✅ Skills Panel (create, refresh)
- ✅ Events Panel (create, refresh)
- ✅ Goals Panel (create, refresh)

### Progression System
- ✅ Goals tracking
- ✅ Building unlocks
- ✅ Favorite buildings
- ✅ Goal progress checking

### Research System
- ✅ Research data loading
- ✅ Research progress tracking
- ✅ Technology unlocks
- ✅ Active research management

### Seasonal System
- ✅ Season and weather tracking
- ✅ Seasonal methods

### Save/Load System
- ✅ Save game functionality
- ✅ Load game functionality
- ✅ Data serialization (all systems)
- ✅ Data deserialization (all systems)
- ✅ Vector2i/Vector2 serialization

### Integration Tests
- ✅ Processing chain integration
- ✅ Job assignment integration
- ✅ UI panel integration

## Test Results

Tests output detailed results including:
- Test name and status (✓ passed / ✗ failed)
- Success rate per category
- Overall success rate
- Detailed failure messages

## Adding New Tests

To add new tests to ComprehensiveTestSuite:

1. Add a new test function following the pattern:
```gdscript
func test_new_feature() -> void:
    print("\n[TEST] New Feature...")
    
    if not SomeManager:
        record_test("NewFeature_ManagerExists", false, "SomeManager not found")
        return
    
    # Your test logic here
    var result = SomeManager.some_method()
    record_test("NewFeature_TestName", result == expected,
        "Test description: " + str(result))
```

2. Call your test function in `run_all_tests()`

3. Use `record_test()` to log results:
   - Test name (descriptive, category_prefix)
   - Passed (bool)
   - Message (description of what was tested)

## Continuous Integration

Tests can be integrated into CI/CD pipelines:
- Exit code 0 = all tests passed
- Exit code 1 = some tests failed
- Output is formatted for easy parsing
