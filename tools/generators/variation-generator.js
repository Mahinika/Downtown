/**
 * Variation Generator - Parameter-based generation for asset variations
 * Generates 3-5 variations per asset type with controlled randomization
 */

/**
 * Generate variations for an asset
 * @param {Function} generator - Asset generator function (x, y, options) => color
 * @param {number} width - Asset width
 * @param {number} height - Asset height
 * @param {number} count - Number of variations (3-5)
 * @param {Object} baseOptions - Base generation options
 * @returns {Array<Array<Array<Array<number>>>>} - Array of variations (each is 2D array of RGB colors)
 */
export function generateVariations(generator, width, height, count = 3, baseOptions = {}) {
	const variations = [];
	
	for (let i = 0; i < count; i++) {
		const seed = baseOptions.seed ? baseOptions.seed + i * 1000 : i * 1000;
		
		// Create variation options with slight modifications
		const variationOptions = {
			...baseOptions,
			seed,
			colorShift: (i / count - 0.5) * 0.2, // Slight color shift across variations
			detailLevel: 0.8 + (i / count) * 0.4 // Varying detail levels
		};
		
		const variation = generator(width, height, variationOptions);
		variations.push(variation);
	}
	
	return variations;
}

/**
 * Create color shift options for variations
 * @param {number} index - Variation index (0-based)
 * @param {number} total - Total variations
 * @param {Object} baseColor - Base color {r, g, b}
 * @returns {Object} - Color shift {r, g, b}
 */
export function createColorShift(index, total, baseColor) {
	// Create subtle color variations
	const shiftRange = 0.15; // ±15% variation
	const t = (index / (total - 1)) - 0.5; // -0.5 to 0.5
	
	return {
		r: t * shiftRange * baseColor.r / 255,
		g: t * shiftRange * baseColor.g / 255,
		b: t * shiftRange * baseColor.b / 255
	};
}

/**
 * Generate seed-based random variations
 * @param {number} baseSeed - Base random seed
 * @param {number} variationIndex - Variation index
 * @returns {number} - Unique seed for this variation
 */
export function generateVariationSeed(baseSeed, variationIndex) {
	return baseSeed + variationIndex * 7919; // Prime multiplier for better distribution
}

/**
 * Apply controlled randomization to options
 * @param {Object} baseOptions - Base options
 * @param {number} variationIndex - Variation index
 * @param {number} totalVariations - Total number of variations
 * @returns {Object} - Randomized options
 */
export function randomizeOptions(baseOptions, variationIndex, totalVariations) {
	const seed = generateVariationSeed(
		baseOptions.seed || 0,
		variationIndex
	);
	
	const rng = simpleRNG(seed);
	
	return {
		...baseOptions,
		seed,
		// Slight scale variation
		scale: (baseOptions.scale || 1.0) * (0.9 + rng() * 0.2),
		// Slight rotation variation (if applicable)
		rotation: (baseOptions.rotation || 0) + (rng() - 0.5) * 0.1,
		// Variation strength
		variation: baseOptions.variation || 0.1 + rng() * 0.1
	};
}

/**
 * Generate building variations with different styles
 * @param {Function} baseGenerator - Base building generator
 * @param {string} buildingType - Building type identifier
 * @param {number} width - Sprite width
 * @param {number} height - Sprite height
 * @param {number} variationCount - Number of variations (default: 3)
 * @param {Object} baseOptions - Base generation options
 * @returns {Array<Object>} - Array of variation objects {image, metadata}
 */
export function generateBuildingVariations(baseGenerator, buildingType, width, height, variationCount = 3, baseOptions = {}) {
	const variations = [];
	
	for (let i = 0; i < variationCount; i++) {
		const variationOptions = randomizeOptions(baseOptions, i, variationCount);
		variationOptions.buildingType = buildingType;
		variationOptions.variationIndex = i;
		
		const variation = baseGenerator(width, height, variationOptions);
		
		variations.push({
			image: variation,
			metadata: {
				buildingType,
				variationIndex: i,
				seed: variationOptions.seed,
				options: variationOptions
			}
		});
	}
	
	return variations;
}

/**
 * Generate villager state variations
 * @param {Function} baseGenerator - Base villager generator
 * @param {string} state - Villager state ('idle', 'walking', 'working', 'carrying')
 * @param {number} width - Sprite width
 * @param {number} height - Sprite height
 * @param {number} variationCount - Number of variations (default: 3)
 * @param {Object} baseOptions - Base generation options
 * @returns {Array<Object>} - Array of variation objects
 */
export function generateVillagerVariations(baseGenerator, state, width, height, variationCount = 3, baseOptions = {}) {
	const variations = [];
	
	for (let i = 0; i < variationCount; i++) {
		const variationOptions = randomizeOptions(baseOptions, i, variationCount);
		variationOptions.state = state;
		variationOptions.variationIndex = i;
		
		const variation = baseGenerator(width, height, variationOptions);
		
		variations.push({
			image: variation,
			metadata: {
				state,
				variationIndex: i,
				seed: variationOptions.seed,
				options: variationOptions
			}
		});
	}
	
	return variations;
}

/**
 * Generate resource node variations
 * @param {Function} baseGenerator - Base resource generator
 * @param {string} resourceType - Resource type ('tree', 'stone', 'berry_bush')
 * @param {number} width - Sprite width
 * @param {number} height - Sprite height
 * @param {number} variationCount - Number of variations (default: 4)
 * @param {Object} baseOptions - Base generation options
 * @returns {Array<Object>} - Array of variation objects
 */
export function generateResourceVariations(baseGenerator, resourceType, width, height, variationCount = 4, baseOptions = {}) {
	const variations = [];
	
	for (let i = 0; i < variationCount; i++) {
		const variationOptions = randomizeOptions(baseOptions, i, variationCount);
		variationOptions.resourceType = resourceType;
		variationOptions.variationIndex = i;
		
		const variation = baseGenerator(width, height, variationOptions);
		
		variations.push({
			image: variation,
			metadata: {
				resourceType,
				variationIndex: i,
				seed: variationOptions.seed,
				options: variationOptions
			}
		});
	}
	
	return variations;
}

/**
 * Simple RNG for seed-based randomness
 */
function simpleRNG(seed) {
	let state = seed;
	return function() {
		state = (state * 1103515245 + 12345) & 0x7fffffff;
		return state / 0x7fffffff;
	};
}
