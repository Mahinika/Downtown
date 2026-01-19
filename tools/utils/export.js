/**
 * Export Utilities - PNG optimization and metadata generation
 * Provides PNG export optimization and asset metadata
 */

import { PNG } from 'pngjs';
import { writeFileSync } from 'fs';

/**
 * Optimize PNG by reducing color depth where possible
 * @param {PNG} png - PNG image object
 * @returns {PNG} - Optimized PNG (or original if optimization not possible)
 */
export function optimizePNG(png) {
	// For now, return original PNG
	// Future: Could analyze colors and reduce palette if possible
	// Could also optimize compression settings
	
	return png;
}

/**
 * Save PNG to file
 * @param {PNG} png - PNG image object
 * @param {string} filepath - Output file path
 * @param {Object} options - Export options
 */
export function savePNG(png, filepath, options = {}) {
	const {
		optimize = false,
		compressionLevel = 9
	} = options;

	let outputPNG = png;
	
	if (optimize) {
		outputPNG = optimizePNG(png);
	}
	
	// Set compression level
	outputPNG.options = {
		...outputPNG.options,
		compressionLevel
	};
	
	// Write PNG
	const buffer = PNG.sync.write(outputPNG, { compressionLevel });
	writeFileSync(filepath, buffer);
}

/**
 * Generate metadata JSON for an asset
 * @param {Object} metadata - Asset metadata
 * @returns {Object} - Metadata object
 */
export function generateMetadata(metadata) {
	return {
		generatedAt: new Date().toISOString(),
		...metadata
	};
}

/**
 * Save metadata JSON to file
 * @param {Object} metadata - Asset metadata
 * @param {string} filepath - Output file path
 */
export function saveMetadata(metadata, filepath) {
	const metadataJSON = generateMetadata(metadata);
	const json = JSON.stringify(metadataJSON, null, 2);
	writeFileSync(filepath, json, 'utf8');
}

/**
 * Convert 2D color array to PNG
 * @param {Array<Array<Array<number>>>} colors - 2D array of RGB colors
 * @returns {PNG} - PNG image object
 */
export function colorsToPNG(colors) {
	const height = colors.length;
	const width = colors[0].length;
	
	const png = new PNG({ width, height });
	
	for (let y = 0; y < height; y++) {
		for (let x = 0; x < width; x++) {
			const idx = (width * y + x) << 2;
			const color = colors[y][x];
			
			png.data[idx] = color[0];     // R
			png.data[idx + 1] = color[1]; // G
			png.data[idx + 2] = color[2]; // B
			png.data[idx + 3] = 255;      // A (opaque)
		}
	}
	
	return png;
}

/**
 * Convert 2D color array with alpha to PNG
 * @param {Array<Array<Array<number>>>} colors - 2D array of RGBA colors
 * @returns {PNG} - PNG image object
 */
export function colorsWithAlphaToPNG(colors) {
	const height = colors.length;
	const width = colors[0].length;
	
	const png = new PNG({ width, height });
	
	for (let y = 0; y < height; y++) {
		for (let x = 0; x < width; x++) {
			const idx = (width * y + x) << 2;
			const color = colors[y][x];
			
			png.data[idx] = color[0];     // R
			png.data[idx + 1] = color[1]; // G
			png.data[idx + 2] = color[2]; // B
			png.data[idx + 3] = color.length > 3 ? color[3] : 255; // A
		}
	}
	
	return png;
}

/**
 * Export asset with metadata
 * @param {Array<Array<Array<number>>>} colors - 2D array of RGB colors
 * @param {string} imagePath - Output image file path
 * @param {string} metadataPath - Output metadata file path (optional)
 * @param {Object} metadata - Asset metadata (optional)
 * @param {Object} options - Export options
 */
export function exportAsset(colors, imagePath, metadataPath = null, metadata = {}, options = {}) {
	// Convert colors to PNG
	const png = colorsToPNG(colors);
	
	// Save PNG
	savePNG(png, imagePath, options);
	
	// Save metadata if path provided
	if (metadataPath) {
		saveMetadata(metadata, metadataPath);
	}
}
