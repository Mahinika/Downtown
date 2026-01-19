/**
 * Dithering Utilities - Ordered dithering and error diffusion for pixel art
 * Provides smooth color transitions in pixel art using Bayer matrix dithering
 */

/**
 * Bayer 4x4 matrix for ordered dithering
 * Standard matrix for pixel art dithering
 */
export const BAYER_MATRIX_4X4 = [
	[0, 8, 2, 10],
	[12, 4, 14, 6],
	[3, 11, 1, 9],
	[15, 7, 13, 5]
];

/**
 * Bayer 2x2 matrix (smaller, less visible)
 */
export const BAYER_MATRIX_2X2 = [
	[0, 2],
	[3, 1]
];

/**
 * Apply ordered dithering to a color value
 * @param {number} value - Color value (0-255)
 * @param {number} x - X position
 * @param {number} y - Y position
 * @param {Array<Array<number>>} matrix - Dithering matrix
 * @param {number} threshold - Dithering threshold (0-1)
 * @returns {number} - Dithered color value (0-255)
 */
export function applyOrderedDither(value, x, y, matrix = BAYER_MATRIX_4X4, threshold = 0.5) {
	const matrixSize = matrix.length;
	const matrixX = x % matrixSize;
	const matrixY = y % matrixSize;
	const matrixValue = matrix[matrixY][matrixX];
	
	// Normalize matrix value to 0-1
	const normalizedMatrix = matrixValue / (matrixSize * matrixSize);
	
	// Apply dithering threshold
	const thresholdValue = (normalizedMatrix - 0.5) * threshold;
	
	// Adjust value based on dithering
	const dithered = value + thresholdValue * 255;
	
	return Math.max(0, Math.min(255, Math.floor(dithered)));
}

/**
 * Apply ordered dithering to RGB color
 * @param {Array<number>} color - RGB color [r, g, b]
 * @param {number} x - X position
 * @param {number} y - Y position
 * @param {Array<Array<number>>} matrix - Dithering matrix
 * @param {number} threshold - Dithering threshold (0-1)
 * @returns {Array<number>} - Dithered RGB color
 */
export function ditherColor(color, x, y, matrix = BAYER_MATRIX_4X4, threshold = 0.5) {
	return [
		applyOrderedDither(color[0], x, y, matrix, threshold),
		applyOrderedDither(color[1], x, y, matrix, threshold),
		applyOrderedDither(color[2], x, y, matrix, threshold)
	];
}

/**
 * Create a gradient with dithering
 * @param {Array<number>} startColor - Start RGB color [r, g, b]
 * @param {Array<number>} endColor - End RGB color [r, g, b]
 * @param {number} width - Gradient width
 * @param {number} height - Gradient height
 * @param {Object} options - Options
 * @returns {Array<Array<Array<number>>>} - 2D array of RGB colors
 */
export function createDitheredGradient(startColor, endColor, width, height, options = {}) {
	const {
		direction = 'horizontal', // 'horizontal', 'vertical', 'radial'
		matrix = BAYER_MATRIX_4X4,
		threshold = 0.3,
		centerX = width / 2,
		centerY = height / 2
	} = options;

	const gradient = [];

	for (let y = 0; y < height; y++) {
		const row = [];
		for (let x = 0; x < width; x++) {
			let t = 0;
			
			if (direction === 'horizontal') {
				t = x / (width - 1);
			} else if (direction === 'vertical') {
				t = y / (height - 1);
			} else if (direction === 'radial') {
				const dx = x - centerX;
				const dy = y - centerY;
				const dist = Math.sqrt(dx * dx + dy * dy);
				const maxDist = Math.sqrt(centerX * centerX + centerY * centerY);
				t = Math.min(1, dist / maxDist);
			}
			
			// Interpolate color
			const color = [
				Math.floor(startColor[0] + (endColor[0] - startColor[0]) * t),
				Math.floor(startColor[1] + (endColor[1] - startColor[1]) * t),
				Math.floor(startColor[2] + (endColor[2] - startColor[2]) * t)
			];
			
			// Apply dithering
			const dithered = ditherColor(color, x, y, matrix, threshold);
			row.push(dithered);
		}
		gradient.push(row);
	}

	return gradient;
}

/**
 * Apply dithering to a 2D color array (texture)
 * @param {Array<Array<Array<number>>>} colors - 2D array of RGB colors
 * @param {Array<Array<number>>} matrix - Dithering matrix
 * @param {number} threshold - Dithering threshold (0-1)
 * @returns {Array<Array<Array<number>>>} - Dithered 2D array of RGB colors
 */
export function ditherTexture(colors, matrix = BAYER_MATRIX_4X4, threshold = 0.3) {
	const dithered = [];
	
	for (let y = 0; y < colors.length; y++) {
		const row = [];
		for (let x = 0; x < colors[y].length; x++) {
			row.push(ditherColor(colors[y][x], x, y, matrix, threshold));
		}
		dithered.push(row);
	}
	
	return dithered;
}

/**
 * Quantize color to nearest palette color with dithering
 * @param {Array<number>} color - RGB color [r, g, b]
 * @param {Array<Array<number>>} palette - Color palette (array of RGB arrays)
 * @param {number} x - X position for dithering
 * @param {number} y - Y position for dithering
 * @param {Array<Array<number>>} matrix - Dithering matrix
 * @param {number} threshold - Dithering threshold (0-1)
 * @returns {Array<number>} - Quantized RGB color from palette
 */
export function quantizeColorWithDither(color, palette, x, y, matrix = BAYER_MATRIX_4X4, threshold = 0.3) {
	// Find nearest palette color
	let nearestColor = palette[0];
	let nearestDist = Infinity;
	
	for (const paletteColor of palette) {
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
	
	// Apply dithering to help smooth transitions
	const matrixSize = matrix.length;
	const matrixX = x % matrixSize;
	const matrixY = y % matrixSize;
	const matrixValue = matrix[matrixY][matrixX];
	const normalizedMatrix = matrixValue / (matrixSize * matrixSize);
	
	// Dither between nearest color and next nearest
	const ditheredColor = [
		Math.floor(color[0] + (normalizedMatrix - 0.5) * threshold * 255),
		Math.floor(color[1] + (normalizedMatrix - 0.5) * threshold * 255),
		Math.floor(color[2] + (normalizedMatrix - 0.5) * threshold * 255)
	];
	
	// Find nearest after dithering
	nearestDist = Infinity;
	for (const paletteColor of palette) {
		const dist = Math.sqrt(
			Math.pow(ditheredColor[0] - paletteColor[0], 2) +
			Math.pow(ditheredColor[1] - paletteColor[1], 2) +
			Math.pow(ditheredColor[2] - paletteColor[2], 2)
		);
		
		if (dist < nearestDist) {
			nearestDist = dist;
			nearestColor = paletteColor;
		}
	}
	
	return nearestColor;
}
