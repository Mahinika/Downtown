#!/usr/bin/env node

/**
 * Pipeline Validation Script
 * Validates game pipeline by checking code structure and dependencies
 */

import fs from 'fs';
import path from 'path';
import { fileURLToPath } from 'url';

const __filename = fileURLToPath(import.meta.url);
const __dirname = path.dirname(__filename);

const PROJECT_ROOT = path.join(__dirname, '..');
const DOWNTOWN_DIR = path.join(PROJECT_ROOT, 'downtown');
const SCRIPTS_DIR = path.join(DOWNTOWN_DIR, 'scripts');

const results = {
    passed: 0,
    failed: 0,
    tests: []
};

function test(name, condition, message) {
    const passed = condition;
    results.tests.push({ name, passed, message });
    if (passed) {
        results.passed++;
        console.log(`  ✓ ${name}: ${message}`);
    } else {
        results.failed++;
        console.log(`  ✗ ${name}: ${message}`);
    }
}

function checkFileExists(filePath, description) {
    const fullPath = path.join(DOWNTOWN_DIR, filePath);
    return fs.existsSync(fullPath);
}

function checkFileContains(filePath, searchString, description) {
    const fullPath = path.join(DOWNTOWN_DIR, filePath);
    if (!fs.existsSync(fullPath)) {
        return false;
    }
    const content = fs.readFileSync(fullPath, 'utf-8');
    return content.includes(searchString);
}

console.log('='.repeat(60));
console.log('PIPELINE VALIDATION');
console.log('='.repeat(60));
console.log('');

// 1. Manager Files Exist
console.log('[TEST] Manager Files...');
const managers = [
    'DataManager.gd',
    'ResourceManager.gd',
    'BuildingManager.gd',
    'VillagerManager.gd',
    'JobSystem.gd',
    'CityManager.gd',
    'ProgressionManager.gd',
    'ResearchManager.gd',
    'EventManager.gd',
    'SeasonalManager.gd',
    'SaveManager.gd',
    'SkillManager.gd',
    'ResourceNodeManager.gd'
];

managers.forEach(manager => {
    test(`Manager_${manager}`, checkFileExists(`scripts/${manager}`, manager), 
        manager + ' exists');
});

// 2. Core Systems
console.log('\n[TEST] Core System Files...');
const coreSystems = [
    { file: 'scripts/Villager.gd', name: 'Villager' },
    { file: 'scripts/UIBuilder.gd', name: 'UIBuilder' },
    { file: 'scripts/UITheme.gd', name: 'UITheme' },
    { file: 'scenes/main.gd', name: 'Main Scene' }
];

coreSystems.forEach(system => {
    test(`System_${system.name}`, checkFileExists(system.file, system.name),
        system.name + ' exists');
});

// 3. Data Files
console.log('\n[TEST] Data Files...');
const dataFiles = [
    'data/resources.json',
    'data/buildings.json'
];

dataFiles.forEach(dataFile => {
    test(`Data_${path.basename(dataFile)}`, checkFileExists(dataFile, dataFile),
        path.basename(dataFile) + ' exists');
});

// 4. Signal Connections
console.log('\n[TEST] Signal Connections...');
test('MainScene_Signals', checkFileContains('scenes/main.gd', 'connect_manager_signals', 'Signal connections'),
    'Main scene has signal connection method');

test('ResourceManager_Signals', checkFileContains('scripts/ResourceManager.gd', 'signal resource_changed', 'Resource changed signal'),
    'ResourceManager emits resource_changed signal');

test('BuildingManager_Signals', checkFileContains('scripts/BuildingManager.gd', 'signal building_created', 'Building created signal'),
    'BuildingManager emits building_created signal');

// 5. Update Loops
console.log('\n[TEST] Update Loops...');
test('MainScene_Process', checkFileContains('scenes/main.gd', 'func _process', 'Process loop'),
    'Main scene has _process loop');

test('BuildingManager_Timer', checkFileContains('scripts/BuildingManager.gd', 'resource_timer', 'Resource timer'),
    'BuildingManager has resource timer');

test('Villager_PhysicsProcess', checkFileContains('scripts/Villager.gd', '_physics_process', 'Physics process'),
    'Villager has _physics_process');

// 6. Key Methods
console.log('\n[TEST] Key Methods...');
test('ResourceManager_AddResource', checkFileContains('scripts/ResourceManager.gd', 'func add_resource', 'Add resource method'),
    'ResourceManager has add_resource method');

test('ResourceManager_ConsumeResource', checkFileContains('scripts/ResourceManager.gd', 'func consume_resource', 'Consume resource method'),
    'ResourceManager has consume_resource method');

test('BuildingManager_PlaceBuilding', checkFileContains('scripts/BuildingManager.gd', 'func place_building', 'Place building method'),
    'BuildingManager has place_building method');

test('VillagerManager_SpawnVillager', checkFileContains('scripts/VillagerManager.gd', 'func spawn_villager', 'Spawn villager method'),
    'VillagerManager has spawn_villager method');

test('JobSystem_AssignVillager', checkFileContains('scripts/JobSystem.gd', 'func assign_villager_to_building', 'Assign villager method'),
    'JobSystem has assign_villager_to_building method');

// 7. UI System
console.log('\n[TEST] UI System...');
test('UIBuilder_CreatePanel', checkFileContains('scripts/UIBuilder.gd', 'func create_panel', 'Create panel method'),
    'UIBuilder has create_panel method');

test('UIBuilder_CreateButton', checkFileContains('scripts/UIBuilder.gd', 'func create_button', 'Create button method'),
    'UIBuilder has create_button method');

test('MainScene_CreateUI', checkFileContains('scenes/main.gd', 'func create_ui', 'Create UI method'),
    'Main scene has create_ui method');

// 8. Save/Load
console.log('\n[TEST] Save/Load System...');
test('SaveManager_SaveGame', checkFileContains('scripts/SaveManager.gd', 'func save_game', 'Save game method'),
    'SaveManager has save_game method');

test('SaveManager_LoadGame', checkFileContains('scripts/SaveManager.gd', 'func load_game', 'Load game method'),
    'SaveManager has load_game method');

// 9. Integration Points
console.log('\n[TEST] Integration Points...');
test('MainScene_ResourceChanged', checkFileContains('scenes/main.gd', '_on_resource_changed', 'Resource changed handler'),
    'Main scene handles resource_changed signal');

test('MainScene_BuildingUnlocked', checkFileContains('scenes/main.gd', '_on_building_unlocked', 'Building unlocked handler'),
    'Main scene handles building_unlocked signal');

test('BuildingManager_ResourceTick', checkFileContains('scripts/BuildingManager.gd', '_on_resource_tick', 'Resource tick handler'),
    'BuildingManager handles resource timer');

// 10. Data Flow
console.log('\n[TEST] Data Flow...');
test('ResourceManager_Initialization', checkFileContains('scripts/ResourceManager.gd', 'initialize_resources', 'Resource initialization'),
    'ResourceManager initializes resources');

test('BuildingManager_DataCache', checkFileContains('scripts/BuildingManager.gd', 'buildings_data_cache', 'Buildings data cache'),
    'BuildingManager caches building data');

test('DataManager_GetData', checkFileContains('scripts/DataManager.gd', 'func get_data', 'Get data method'),
    'DataManager has get_data method');

// Print Results
console.log('\n' + '='.repeat(60));
console.log('VALIDATION RESULTS');
console.log('='.repeat(60));
console.log(`Total Tests: ${results.tests.length}`);
console.log(`Passed: ${results.passed}`);
console.log(`Failed: ${results.failed}`);
console.log(`Success Rate: ${((results.passed / results.tests.length) * 100).toFixed(1)}%`);
console.log('='.repeat(60));

if (results.failed === 0) {
    console.log('✓ ALL VALIDATIONS PASSED!');
    console.log('='.repeat(60));
    process.exit(0);
} else {
    console.log('✗ SOME VALIDATIONS FAILED');
    console.log('='.repeat(60));
    process.exit(1);
}
