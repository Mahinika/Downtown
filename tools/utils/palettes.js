/**
 * Color Palette System - Cohesive color palettes for Stone Age aesthetic
 * Provides color quantization and palette management
 */

/**
 * Stone Age color palette (RGB values)
 */
export const STONE_AGE_PALETTE = {
	earth: [139, 111, 71],
	earthDark: [106, 79, 47],
	earthLight: [155, 127, 87],
	stone: [122, 122, 122],
	stoneDark: [90, 90, 90],
	stoneLight: [138, 138, 138],
	wood: [107, 79, 58],
	woodDark: [74, 47, 26],
	woodLight: [139, 111, 90],
	fire: [255, 107, 53],
	fireBright: [255, 140, 90],
	fireDark: [204, 74, 26],
	grass: [107, 122, 79],
	grassDark: [74, 90, 56],
	roof: [90, 74, 58],
	roofDark: [58, 42, 26],
	storage: [90, 90, 90],
	storageDark: [58, 58, 58],
	outline: [42, 42, 42],
	bg: [74, 90, 56]
};

/**
 * Seasonal color palette variants
 */
export const SEASONAL_PALETTES = {
	spring: {
		...STONE_AGE_PALETTE,
		grass: [120, 150, 90],
		grassDark: [90, 120, 70]
	},
	summer: {
		...STONE_AGE_PALETTE,
		grass: [100, 130, 75],
		grassDark: [70, 100, 55]
	},
	fall: {
		...STONE_AGE_PALETTE,
		grass: [130, 110, 60],
		grassDark: [100, 85, 45],
		earth: [150, 100, 50],
		earthDark: [120, 75, 35]
	},
	winter: {
		...STONE_AGE_PALETTE,
		grass: [180, 180, 180],
		grassDark: [150, 150, 150],
		stone: [200, 200, 200],
		stoneDark: [170, 170, 170]
	}
};

/**
 * Get palette for a season
 * @param {string} season - Season name ('spring', 'summer', 'fall', 'winter')
 * @returns {Object} - Color palette object
 */
export function getSeasonalPalette(season) {
	return SEASONAL_PALETTES[season] || STONE_AGE_PALETTE;
}

/**
 * Get palette as array of RGB colors
 * @param {Object} palette - Palette object
 * @returns {Array<Array<number>>} - Array of RGB color arrays
 */
export function paletteToArray(palette) {
	return Object.values(palette);
}

/**
 * Quantize color to nearest palette color
 * @param {Array<number>} color - RGB color [r, g, b]
 * @param {Object|Array} palette - Palette object or array of RGB colors
 * @returns {Array<number>} - Nearest palette color
 */
export function quantizeToPalette(color, palette) {
	const paletteArray = Array.isArray(palette) ? palette : paletteToArray(palette);
	
	let nearestColor = paletteArray[0];
	let nearestDist = Infinity;
	
	for (const paletteColor of paletteArray) {
		const dist = Math.sqrt(
			Math.pow(color[0] - paletteColor[0], 2) +
			Math.pow(color[1] - paletteColor[1], 2) +
			Math.pow(color[2] - paletteColor[2], 2)
		);
		
		if (dist < nearestDist) {
			nearestDist = dist;
			nearestColor = paletteColor;
		}
	}
	
	return nearestColor;
}

/**
 * Apply color shift to palette
 * @param {Object} palette - Base palette
 * @param {Object} shift - RGB shift {r, g, b} (-1 to 1)
 * @returns {Object} - Shifted palette
 */
export function shiftPalette(palette, shift) {
	const shifted = {};
	
	for (const [key, color] of Object.entries(palette)) {
		shifted[key] = [
			Math.max(0, Math.min(255, Math.floor(color[0] + shift.r * 255))),
			Math.max(0, Math.min(255, Math.floor(color[1] + shift.g * 255))),
			Math.max(0, Math.min(255, Math.floor(color[2] + shift.b * 255)))
		];
	}
	
	return shifted;
}

/**
 * Create color variation within palette
 * @param {Array<number>} baseColor - Base RGB color [r, g, b]
 * @param {number} variation - Variation amount (0-1)
 * @param {number} seed - Random seed
 * @returns {Array<number>} - Varied color
 */
export function varyColor(baseColor, variation = 0.1, seed = 0) {
	const rng = simpleRNG(seed);
	const rShift = (rng() - 0.5) * 2 * variation * 255;
	const gShift = (rng() - 0.5) * 2 * variation * 255;
	const bShift = (rng() - 0.5) * 2 * variation * 255;
	
	return [
		Math.max(0, Math.min(255, Math.floor(baseColor[0] + rShift))),
		Math.max(0, Math.min(255, Math.floor(baseColor[1] + gShift))),
		Math.max(0, Math.min(255, Math.floor(baseColor[2] + bShift)))
	];
}

/**
 * Interpolate between two colors
 * @param {Array<number>} color1 - First RGB color [r, g, b]
 * @param {Array<number>} color2 - Second RGB color [r, g, b]
 * @param {number} t - Interpolation factor (0-1)
 * @returns {Array<number>} - Interpolated color
 */
export function lerpColor(color1, color2, t) {
	return [
		Math.floor(color1[0] + (color2[0] - color1[0]) * t),
		Math.floor(color1[1] + (color2[1] - color1[1]) * t),
		Math.floor(color1[2] + (color2[2] - color1[2]) * t)
	];
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
