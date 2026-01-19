/**
 * Pattern Library - Reusable procedural patterns for asset generation
 * Provides patterns: brick, wood grain, stone, thatch, cellular automata
 */

import { generateWoodTexture, generateStoneTexture, generateThatchTexture } from '../generators/texture-generator.js';

/**
 * Generate brick pattern
 * @param {number} width - Pattern width
 * @param {number} height - Pattern height
 * @param {Object} options - Pattern options
 * @returns {Array<Array<Array<number>>>} - 2D array of RGB colors
 */
export function generateBrickPattern(width, height, options = {}) {
	const {
		brickWidth = 8,
		brickHeight = 4,
		mortarWidth = 1,
		mortarColor = [100, 100, 100],
		brickColor = [150, 100, 80],
		variation = 0.2
	} = options;

	const pattern = [];
	
	for (let y = 0; y < height; y++) {
		const row = [];
		for (let x = 0; x < width; x++) {
			// Calculate brick position (offset every other row)
			const rowIndex = Math.floor(y / (brickHeight + mortarWidth));
			const colIndex = Math.floor(x / (brickWidth + mortarWidth));
			const offset = (rowIndex % 2 === 1) ? (brickWidth + mortarWidth) / 2 : 0;
			const localX = (x - offset) % (brickWidth + mortarWidth);
			const localY = y % (brickHeight + mortarWidth);
			
			// Check if we're on mortar
			if (localX < brickWidth && localY < brickHeight) {
				// Inside brick - add variation
				const varX = Math.sin(x * 0.3) * variation;
				const varY = Math.sin(y * 0.2) * variation;
				const variationValue = (varX + varY) / 2;
				
				const color = [
					Math.floor(brickColor[0] + variationValue * 30),
					Math.floor(brickColor[1] + variationValue * 20),
					Math.floor(brickColor[2] + variationValue * 20)
				];
				row.push(color);
			} else {
				// Mortar
				row.push(mortarColor);
			}
		}
		pattern.push(row);
	}
	
	return pattern;
}

/**
 * Generate wood grain pattern
 * @param {number} width - Pattern width
 * @param {number} height - Pattern height
 * @param {Object} options - Pattern options
 * @returns {Array<Array<Array<number>>>} - 2D array of RGB colors
 */
export function generateWoodGrainPattern(width, height, options = {}) {
	const {
		baseColor = [139, 111, 71],
		grainScale = 0.5,
		seed = 0
	} = options;

	// Use texture generator for wood grain
	const texture = generateWoodTexture(width, height, { seed, grainScale });
	const pattern = [];
	
	for (let y = 0; y < height; y++) {
		const row = [];
		for (let x = 0; x < width; x++) {
			const textureValue = texture[y][x];
			const variation = (textureValue - 0.5) * 40; // -20 to +20
			
			const color = [
				Math.max(0, Math.min(255, Math.floor(baseColor[0] + variation))),
				Math.max(0, Math.min(255, Math.floor(baseColor[1] + variation))),
				Math.max(0, Math.min(255, Math.floor(baseColor[2] + variation)))
			];
			row.push(color);
		}
		pattern.push(row);
	}
	
	return pattern;
}

/**
 * Generate stone pattern
 * @param {number} width - Pattern width
 * @param {number} height - Pattern height
 * @param {Object} options - Pattern options
 * @returns {Array<Array<Array<number>>>} - 2D array of RGB colors
 */
export function generateStonePattern(width, height, options = {}) {
	const {
		baseColor = [122, 122, 122],
		scale = 0.2,
		seed = 0
	} = options;

	// Use texture generator for stone
	const texture = generateStoneTexture(width, height, { seed, scale });
	const pattern = [];
	
	for (let y = 0; y < height; y++) {
		const row = [];
		for (let x = 0; x < width; x++) {
			const textureValue = texture[y][x];
			const variation = (textureValue - 0.5) * 50; // -25 to +25
			
			const color = [
				Math.max(0, Math.min(255, Math.floor(baseColor[0] + variation))),
				Math.max(0, Math.min(255, Math.floor(baseColor[1] + variation))),
				Math.max(0, Math.min(255, Math.floor(baseColor[2] + variation)))
			];
			row.push(color);
		}
		pattern.push(row);
	}
	
	return pattern;
}

/**
 * Generate thatch pattern (for roofs)
 * @param {number} width - Pattern width
 * @param {number} height - Pattern height
 * @param {Object} options - Pattern options
 * @returns {Array<Array<Array<number>>>} - 2D array of RGB colors
 */
export function generateThatchPattern(width, height, options = {}) {
	const {
		baseColor = [90, 74, 58],
		seed = 0
	} = options;

	// Use texture generator for thatch
	const texture = generateThatchTexture(width, height, { seed });
	const pattern = [];
	
	for (let y = 0; y < height; y++) {
		const row = [];
		for (let x = 0; x < width; x++) {
			const textureValue = texture[y][x];
			const variation = (textureValue - 0.5) * 30; // -15 to +15
			
			const color = [
				Math.max(0, Math.min(255, Math.floor(baseColor[0] + variation))),
				Math.max(0, Math.min(255, Math.floor(baseColor[1] + variation))),
				Math.max(0, Math.min(255, Math.floor(baseColor[2] + variation)))
			];
			row.push(color);
		}
		pattern.push(row);
	}
	
	return pattern;
}

/**
 * Generate cellular automata pattern (for natural formations)
 * @param {number} width - Pattern width
 * @param {number} height - Pattern height
 * @param {Object} options - Pattern options
 * @returns {Array<Array<Array<number>>>} - 2D array of RGB colors
 */
export function generateCellularPattern(width, height, options = {}) {
	const {
		baseColor = [107, 122, 79],
		darkColor = [74, 90, 56],
		density = 0.3,
		iterations = 3,
		seed = 0
	} = options;

	// Initialize random cells
	const rng = simpleRNG(seed);
	const cells = Array(height).fill(null).map(() => 
		Array(width).fill(null).map(() => rng() < density ? 1 : 0)
	);
	
	// Apply cellular automata rules (Conway's Game of Life variant)
	for (let iter = 0; iter < iterations; iter++) {
		const next = Array(height).fill(null).map(() => Array(width).fill(0));
		
		for (let y = 0; y < height; y++) {
			for (let x = 0; x < width; x++) {
				// Count neighbors
				let neighbors = 0;
				for (let dy = -1; dy <= 1; dy++) {
					for (let dx = -1; dx <= 1; dx++) {
						if (dx === 0 && dy === 0) continue;
						const ny = (y + dy + height) % height;
						const nx = (x + dx + width) % width;
						neighbors += cells[ny][nx];
					}
				}
				
				// Apply rules
				if (cells[y][x] === 1) {
					// Live cell: survives with 2-3 neighbors
					next[y][x] = (neighbors === 2 || neighbors === 3) ? 1 : 0;
				} else {
					// Dead cell: becomes alive with 3 neighbors
					next[y][x] = (neighbors === 3) ? 1 : 0;
				}
			}
		}
		
			// Copy next to cells
		for (let y = 0; y < height; y++) {
			for (let x = 0; x < width; x++) {
				cells[y][x] = next[y][x];
			}
		}
	}
	
	// Convert to color pattern
	const resultPattern = [];
	for (let y = 0; y < height; y++) {
		const row = [];
		for (let x = 0; x < width; x++) {
			row.push(cells[y][x] === 1 ? darkColor : baseColor);
		}
		resultPattern.push(row);
	}
	
	return resultPattern;
}

/**
 * Generate checkerboard pattern
 * @param {number} width - Pattern width
 * @param {number} height - Pattern height
 * @param {Object} options - Pattern options
 * @returns {Array<Array<Array<number>>>} - 2D array of RGB colors
 */
export function generateCheckerboardPattern(width, height, options = {}) {
	const {
		tileSize = 4,
		color1 = [200, 200, 200],
		color2 = [100, 100, 100]
	} = options;

	const pattern = [];
	
	for (let y = 0; y < height; y++) {
		const row = [];
		for (let x = 0; x < width; x++) {
			const tileX = Math.floor(x / tileSize);
			const tileY = Math.floor(y / tileSize);
			const color = ((tileX + tileY) % 2 === 0) ? color1 : color2;
			row.push(color);
		}
		pattern.push(row);
	}
	
	return pattern;
}

/**
 * Generate dot pattern
 * @param {number} width - Pattern width
 * @param {number} height - Pattern height
 * @param {Object} options - Pattern options
 * @returns {Array<Array<Array<number>>>} - 2D array of RGB colors
 */
export function generateDotPattern(width, height, options = {}) {
	const {
		spacing = 4,
		dotSize = 2,
		dotColor = [100, 100, 100],
		backgroundColor = [200, 200, 200]
	} = options;

	const pattern = [];
	
	for (let y = 0; y < height; y++) {
		const row = [];
		for (let x = 0; x < width; x++) {
			const gridX = (x % spacing);
			const gridY = (y % spacing);
			const dist = Math.sqrt(
				Math.pow(gridX - spacing / 2, 2) +
				Math.pow(gridY - spacing / 2, 2)
			);
			
			const color = (dist <= dotSize) ? dotColor : backgroundColor;
			row.push(color);
		}
		pattern.push(row);
	}
	
	return pattern;
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
