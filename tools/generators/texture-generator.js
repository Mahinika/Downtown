/**
 * Texture Generator - Procedural texture generation using noise
 * Generates wood, stone, grass, and other organic textures using Perlin noise
 */

/**
 * Simple Perlin noise implementation (pure JavaScript, no dependencies)
 * Based on improved Perlin noise algorithm
 */
class PerlinNoise {
	constructor(seed = 0) {
		this.seed = seed;
		// Permutation table for gradient lookup
		this.permutation = this._generatePermutation(seed);
	}

	_generatePermutation(seed) {
		const p = Array.from({ length: 256 }, (_, i) => i);
		// Shuffle using seed
		let rng = this._simpleRNG(seed);
		for (let i = p.length - 1; i > 0; i--) {
			const j = Math.floor(rng() * (i + 1));
			[p[i], p[j]] = [p[j], p[i]];
		}
		// Duplicate for wrapping
		return [...p, ...p];
	}

	_simpleRNG(seed) {
		let state = seed;
		return function() {
			state = (state * 1103515245 + 12345) & 0x7fffffff;
			return state / 0x7fffffff;
		};
	}

	_fade(t) {
		return t * t * t * (t * (t * 6 - 15) + 10);
	}

	_lerp(a, b, t) {
		return a + t * (b - a);
	}

	_grad(hash, x, y) {
		const h = hash & 15;
		const u = h < 8 ? x : y;
		const v = h < 4 ? y : h === 12 || h === 14 ? x : 0;
		return ((h & 1) === 0 ? u : -u) + ((h & 2) === 0 ? v : -v);
	}

	noise(x, y, octaves = 1, persistence = 0.5, scale = 1.0) {
		let value = 0;
		let amplitude = 1;
		let frequency = scale;
		let maxValue = 0;

		for (let i = 0; i < octaves; i++) {
			value += this._noise2D(x * frequency, y * frequency) * amplitude;
			maxValue += amplitude;
			amplitude *= persistence;
			frequency *= 2;
		}

		return value / maxValue; // Normalize to 0-1
	}

	_noise2D(x, y) {
		const X = Math.floor(x) & 255;
		const Y = Math.floor(y) & 255;

		const xf = x - Math.floor(x);
		const yf = y - Math.floor(y);

		const u = this._fade(xf);
		const v = this._fade(yf);

		const a = this.permutation[X] + Y;
		const aa = this.permutation[a];
		const ab = this.permutation[a + 1];
		const b = this.permutation[X + 1] + Y;
		const ba = this.permutation[b];
		const bb = this.permutation[b + 1];

		return this._lerp(
			this._lerp(
				this._grad(this.permutation[aa], xf, yf),
				this._grad(this.permutation[ba], xf - 1, yf),
				u
			),
			this._lerp(
				this._grad(this.permutation[ab], xf, yf - 1),
				this._grad(this.permutation[bb], xf - 1, yf - 1),
				u
			),
			v
		);
	}
}

/**
 * Generate wood grain texture
 * @param {number} width - Texture width
 * @param {number} height - Texture height
 * @param {Object} options - Generation options
 * @returns {Array<Array<number>>} - 2D array of noise values (0-1)
 */
export function generateWoodTexture(width, height, options = {}) {
	const {
		seed = 0,
		grainScale = 0.5,
		grainFrequency = 4.0,
		grainStrength = 0.3,
		ringsScale = 0.3
	} = options;

	const noise = new PerlinNoise(seed);
	const texture = [];

	for (let y = 0; y < height; y++) {
		const row = [];
		for (let x = 0; x < width; x++) {
			// Vertical grain (primary noise)
			const grain = noise.noise(x * grainScale, y * grainScale, 2, 0.6, grainFrequency);
			
			// Horizontal rings (secondary noise)
			const rings = Math.abs(noise.noise(x * ringsScale, 0, 1, 0.5, 1.0)) * 0.5;
			
			// Combine grain and rings
			let value = grain * (1 + grainStrength) + rings;
			
			// Add some vertical lines for wood grain effect
			const verticalLine = Math.sin(y * 0.2) * 0.1;
			value += verticalLine;
			
			// Normalize to 0-1
			value = Math.max(0, Math.min(1, (value + 1) * 0.5));
			row.push(value);
		}
		texture.push(row);
	}

	return texture;
}

/**
 * Generate stone texture
 * @param {number} width - Texture width
 * @param {number} height - Texture height
 * @param {Object} options - Generation options
 * @returns {Array<Array<number>>} - 2D array of noise values (0-1)
 */
export function generateStoneTexture(width, height, options = {}) {
	const {
		seed = 0,
		scale = 0.2,
		roughness = 3,
		roughnessStrength = 0.4
	} = options;

	const noise = new PerlinNoise(seed);
	const texture = [];

	for (let y = 0; y < height; y++) {
		const row = [];
		for (let x = 0; x < width; x++) {
			// Multiple octaves for rocky surface
			const base = noise.noise(x * scale, y * scale, roughness, 0.5, 1.0);
			
			// Add fine details
			const detail = noise.noise(x * scale * 4, y * scale * 4, 1, 0.3, 2.0) * roughnessStrength;
			
			// Combine base and detail
			let value = base + detail;
			
			// Normalize to 0-1
			value = Math.max(0, Math.min(1, (value + 1) * 0.5));
			row.push(value);
		}
		texture.push(row);
	}

	return texture;
}

/**
 * Generate grass texture
 * @param {number} width - Texture width
 * @param {number} height - Texture height
 * @param {Object} options - Generation options
 * @returns {Array<Array<number>>} - 2D array of noise values (0-1)
 */
export function generateGrassTexture(width, height, options = {}) {
	const {
		seed = 0,
		scale = 0.3,
		clumpSize = 2.0,
		clumpStrength = 0.5
	} = options;

	const noise = new PerlinNoise(seed);
	const texture = [];

	for (let y = 0; y < height; y++) {
		const row = [];
		for (let x = 0; x < width; x++) {
			// Base grass pattern
			const base = noise.noise(x * scale, y * scale, 2, 0.6, 1.0);
			
			// Clumps (larger patterns)
			const clumps = noise.noise(x * scale / clumpSize, y * scale / clumpSize, 1, 0.5, 1.0) * clumpStrength;
			
			// Fine detail (smaller patterns)
			const detail = noise.noise(x * scale * 3, y * scale * 3, 1, 0.3, 2.0) * 0.2;
			
			// Combine all layers
			let value = base * 0.6 + clumps * 0.3 + detail;
			
			// Normalize to 0-1
			value = Math.max(0, Math.min(1, (value + 1) * 0.5));
			row.push(value);
		}
		texture.push(row);
	}

	return texture;
}

/**
 * Generate thatch texture (for roofs)
 * @param {number} width - Texture width
 * @param {number} height - Texture height
 * @param {Object} options - Generation options
 * @returns {Array<Array<number>>} - 2D array of noise values (0-1)
 */
export function generateThatchTexture(width, height, options = {}) {
	const {
		seed = 0,
		strawScale = 0.4,
		strawFrequency = 3.0
	} = options;

	const noise = new PerlinNoise(seed);
	const texture = [];

	for (let y = 0; y < height; y++) {
		const row = [];
		for (let x = 0; x < width; x++) {
			// Horizontal straw-like lines
			const straw = Math.abs(noise.noise(x * strawScale, y * strawScale * strawFrequency, 2, 0.5, 1.0));
			
			// Add some vertical variation
			const variation = noise.noise(x * strawScale * 2, y * strawScale, 1, 0.3, 1.5) * 0.2;
			
			let value = straw + variation;
			
			// Normalize to 0-1
			value = Math.max(0, Math.min(1, value));
			row.push(value);
		}
		texture.push(row);
	}

	return texture;
}

/**
 * Generate dirt/earth texture
 * @param {number} width - Texture width
 * @param {number} height - Texture height
 * @param {Object} options - Generation options
 * @returns {Array<Array<number>>} - 2D array of noise values (0-1)
 */
export function generateDirtTexture(width, height, options = {}) {
	const {
		seed = 0,
		scale = 0.25,
		roughness = 2
	} = options;

	const noise = new PerlinNoise(seed);
	const texture = [];

	for (let y = 0; y < height; y++) {
		const row = [];
		for (let x = 0; x < width; x++) {
			// Grainy dirt pattern
			const base = noise.noise(x * scale, y * scale, roughness, 0.5, 1.0);
			
			// Fine grain
			const grain = noise.noise(x * scale * 5, y * scale * 5, 1, 0.2, 3.0) * 0.3;
			
			let value = base + grain;
			
			// Normalize to 0-1
			value = Math.max(0, Math.min(1, (value + 1) * 0.5));
			row.push(value);
		}
		texture.push(row);
	}

	return texture;
}

/**
 * Apply texture to color with variation
 * @param {Array<number>} baseColor - RGB color [r, g, b]
 * @param {number} textureValue - Texture noise value (0-1)
 * @param {number} strength - Texture strength (0-1)
 * @returns {Array<number>} - Modified RGB color
 */
export function applyTextureToColor(baseColor, textureValue, strength = 0.3) {
	const variation = (textureValue - 0.5) * 2 * strength; // -strength to +strength
	
	return [
		Math.max(0, Math.min(255, Math.floor(baseColor[0] + variation * 255))),
		Math.max(0, Math.min(255, Math.floor(baseColor[1] + variation * 255))),
		Math.max(0, Math.min(255, Math.floor(baseColor[2] + variation * 255)))
	];
}

export { PerlinNoise };
