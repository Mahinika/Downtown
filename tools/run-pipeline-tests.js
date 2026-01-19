#!/usr/bin/env node

/**
 * Pipeline Test Runner
 * Runs comprehensive pipeline tests via Godot CLI
 */

const { execSync } = require('child_process');
const path = require('path');
const fs = require('fs');

const GODOT_PATH = process.env.GODOT_PATH || 'godot';
const PROJECT_PATH = path.join(__dirname, '..', 'downtown');
const TEST_SCENE = 'res://tests/PipelineTest.tscn';

console.log('='.repeat(60));
console.log('PIPELINE TEST RUNNER');
console.log('='.repeat(60));
console.log('Project:', PROJECT_PATH);
console.log('Godot:', GODOT_PATH);
console.log('');

// Check if Godot is available
try {
    execSync(`${GODOT_PATH} --version`, { stdio: 'pipe' });
} catch (error) {
    console.error('ERROR: Godot not found. Please set GODOT_PATH environment variable.');
    console.error('Example: export GODOT_PATH="/path/to/godot"');
    process.exit(1);
}

// Create test scene if it doesn't exist
const testScenePath = path.join(PROJECT_PATH, 'tests', 'PipelineTest.tscn');
if (!fs.existsSync(testScenePath)) {
    console.log('Creating test scene...');
    const testSceneContent = `[gd_scene load_steps=2 format=3]

[ext_resource type="Script" path="res://tests/PipelineTest.gd" id="1"]

[node name="PipelineTest" type="Node"]
script = ExtResource("1")
`;
    fs.writeFileSync(testScenePath, testSceneContent);
    console.log('✓ Test scene created');
}

// Run tests
console.log('Running pipeline tests...');
console.log('');

try {
    const command = `${GODOT_PATH} --headless --path "${PROJECT_PATH}" --script "${TEST_SCENE}"`;
    console.log('Command:', command);
    console.log('');
    
    const output = execSync(command, { 
        encoding: 'utf-8',
        cwd: PROJECT_PATH,
        stdio: 'inherit'
    });
    
    console.log('');
    console.log('='.repeat(60));
    console.log('Tests completed');
    console.log('='.repeat(60));
    
} catch (error) {
    console.error('');
    console.error('ERROR: Test execution failed');
    console.error(error.message);
    process.exit(1);
}
