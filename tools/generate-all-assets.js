#!/usr/bin/env node

/**
 * Unified Asset Generator - Entry point for all asset generation
 * Configuration-driven asset generation with progress tracking
 */

import { readFileSync, writeFileSync, mkdirSync, existsSync } from 'fs';
import { dirname, join } from 'path';
import { fileURLToPath } from 'url';
import { generateAllBuildings } from './generate-buildings.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const PROJECT_ROOT = join(__dirname, '..');

/**
 * Default configuration for asset generation
 */
const DEFAULT_CONFIG = {
	buildings: {
		enabled: true,
		outputDir: 'downtown/assets/buildings',
		variations: 1, // Number of variations per building
		options: {
			useTexture: true,
			useShading: true,
			useDithering: true
		}
	},
	villagers: {
		enabled: false, // Not implemented yet
		outputDir: 'downtown/assets/villagers',
		animations: ['idle', 'walking', 'working', 'carrying'],
		options: {}
	},
	resources: {
		enabled: false, // Not implemented yet
		outputDir: 'downtown/assets/resources',
		variations: 1,
		options: {}
	}
};

/**
 * Load configuration from file or use default
 * @param {string} configPath - Path to config JSON file (optional)
 * @returns {Object} - Configuration object
 */
function loadConfig(configPath = null) {
	if (configPath && existsSync(configPath)) {
		try {
			const configText = readFileSync(configPath, 'utf8');
			const config = JSON.parse(configText);
			// Merge with defaults
			return mergeConfig(DEFAULT_CONFIG, config);
		} catch (err) {
			console.warn(`Warning: Could not load config from ${configPath}, using defaults:`, err.message);
			return DEFAULT_CONFIG;
		}
	}
	return DEFAULT_CONFIG;
}

/**
 * Merge configuration objects (deep merge)
 */
function mergeConfig(defaultConfig, userConfig) {
	const merged = { ...defaultConfig };
	
	for (const [key, value] of Object.entries(userConfig)) {
		if (typeof value === 'object' && value !== null && !Array.isArray(value)) {
			merged[key] = mergeConfig(merged[key] || {}, value);
		} else {
			merged[key] = value;
		}
	}
	
	return merged;
}

/**
 * Generate all assets based on configuration
 * @param {Object} config - Configuration object
 * @returns {Object} - Generation results
 */
async function generateAllAssets(config) {
	const results = {
		startTime: Date.now(),
		buildings: { generated: 0, errors: [] },
		villagers: { generated: 0, errors: [] },
		resources: { generated: 0, errors: [] }
	};
	
	console.log('Starting asset generation...\n');
	
	// Generate buildings
	if (config.buildings.enabled) {
		console.log('Generating buildings...');
		try {
			const outputDir = join(PROJECT_ROOT, config.buildings.outputDir);
			mkdirSync(outputDir, { recursive: true });
			
			generateAllBuildings();
			results.buildings.generated = 12; // Current number of building types
			console.log(`✓ Generated ${results.buildings.generated} building sprites\n`);
		} catch (err) {
			results.buildings.errors.push(err.message);
			console.error(`✗ Error generating buildings:`, err.message);
		}
	} else {
		console.log('Skipping buildings (disabled in config)\n');
	}
	
	// Generate villagers (placeholder for future implementation)
	if (config.villagers.enabled) {
		console.log('Generating villagers...');
		// TODO: Implement villager generation
		console.log('⚠ Villager generation not yet implemented\n');
	} else {
		console.log('Skipping villagers (disabled in config)\n');
	}
	
	// Generate resources (placeholder for future implementation)
	if (config.resources.enabled) {
		console.log('Generating resources...');
		// TODO: Implement resource generation
		console.log('⚠ Resource generation not yet implemented\n');
	} else {
		console.log('Skipping resources (disabled in config)\n');
	}
	
	results.endTime = Date.now();
	results.duration = results.endTime - results.startTime;
	
	return results;
}

/**
 * Print generation summary
 * @param {Object} results - Generation results
 */
function printSummary(results) {
	console.log('\n' + '='.repeat(50));
	console.log('Asset Generation Summary');
	console.log('='.repeat(50));
	
	console.log(`\nDuration: ${(results.duration / 1000).toFixed(2)}s`);
	
	if (results.buildings.generated > 0) {
		console.log(`\nBuildings: ${results.buildings.generated} generated`);
		if (results.buildings.errors.length > 0) {
			console.log(`  Errors: ${results.buildings.errors.length}`);
			results.buildings.errors.forEach(err => console.log(`    - ${err}`));
		}
	}
	
	if (results.villagers.generated > 0) {
		console.log(`\nVillagers: ${results.villagers.generated} generated`);
		if (results.villagers.errors.length > 0) {
			console.log(`  Errors: ${results.villagers.errors.length}`);
			results.villagers.errors.forEach(err => console.log(`    - ${err}`));
		}
	}
	
	if (results.resources.generated > 0) {
		console.log(`\nResources: ${results.resources.generated} generated`);
		if (results.resources.errors.length > 0) {
			console.log(`  Errors: ${results.resources.errors.length}`);
			results.resources.errors.forEach(err => console.log(`    - ${err}`));
		}
	}
	
	const totalErrors = results.buildings.errors.length + results.villagers.errors.length + results.resources.errors.length;
	if (totalErrors === 0) {
		console.log('\n✓ All assets generated successfully!');
	} else {
		console.log(`\n⚠ Generated with ${totalErrors} error(s)`);
	}
	
	console.log('='.repeat(50) + '\n');
}

/**
 * Main function
 */
async function main() {
	const args = process.argv.slice(2);
	
	// Parse command line arguments
	let configPath = null;
	for (let i = 0; i < args.length; i++) {
		if (args[i] === '--config' && i + 1 < args.length) {
			configPath = args[i + 1];
			i++;
		} else if (args[i] === '--help' || args[i] === '-h') {
			console.log(`
Usage: node tools/generate-all-assets.js [options]

Options:
  --config <path>    Path to configuration JSON file
  --help, -h         Show this help message

Examples:
  node tools/generate-all-assets.js
  node tools/generate-all-assets.js --config config/asset-config.json
			`);
			process.exit(0);
		}
	}
	
	// Load configuration
	const config = loadConfig(configPath);
	
	// Generate assets
	const results = await generateAllAssets(config);
	
	// Print summary
	printSummary(results);
	
	// Exit with error code if there were errors
	const totalErrors = results.buildings.errors.length + results.villagers.errors.length + results.resources.errors.length;
	process.exit(totalErrors > 0 ? 1 : 0);
}

// Run if called directly
if (import.meta.url === `file://${process.argv[1]}`) {
	main().catch(err => {
		console.error('Fatal error:', err);
		process.exit(1);
	});
}

export { generateAllAssets, loadConfig };
