/**
 * Sprite Sheet Generator - Generate animation frames and sprite sheets
 * Creates sprite sheets from frame sequences for Godot
 */

import { PNG } from 'pngjs';
import { writeFileSync, mkdirSync } from 'fs';
import { dirname, join } from 'path';
import { fileURLToPath } from 'url';
import { colorsToPNG, savePNG } from '../utils/export.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);

/**
 * Create sprite sheet from frame array
 * @param {Array<Array<Array<Array<number>>>>} frames - Array of frames (each frame is 2D array of RGB colors)
 * @param {number} framesPerRow - Number of frames per row (default: auto-calculate)
 * @param {number} spacing - Spacing between frames (default: 0)
 * @returns {PNG} - Sprite sheet PNG
 */
export function createSpriteSheet(frames, framesPerRow = null, spacing = 0) {
	if (frames.length === 0) {
		throw new Error('No frames provided');
	}
	
	const frameWidth = frames[0][0].length;
	const frameHeight = frames[0].length;
	
	// Auto-calculate frames per row if not specified
	if (!framesPerRow) {
		framesPerRow = Math.ceil(Math.sqrt(frames.length));
	}
	
	const rows = Math.ceil(frames.length / framesPerRow);
	const sheetWidth = framesPerRow * frameWidth + (framesPerRow - 1) * spacing;
	const sheetHeight = rows * frameHeight + (rows - 1) * spacing;
	
	// Create sprite sheet PNG
	const sheet = new PNG({ width: sheetWidth, height: sheetHeight });
	
	// Fill with transparent background
	for (let y = 0; y < sheetHeight; y++) {
		for (let x = 0; x < sheetWidth; x++) {
			const idx = (sheetWidth * y + x) << 2;
			sheet.data[idx] = 0;     // R
			sheet.data[idx + 1] = 0; // G
			sheet.data[idx + 2] = 0; // B
			sheet.data[idx + 3] = 0; // A (transparent)
		}
	}
	
	// Draw frames onto sheet
	for (let i = 0; i < frames.length; i++) {
		const row = Math.floor(i / framesPerRow);
		const col = i % framesPerRow;
		
		const offsetX = col * (frameWidth + spacing);
		const offsetY = row * (frameHeight + spacing);
		
		const frame = frames[i];
		
		// Draw frame
		for (let y = 0; y < frameHeight; y++) {
			for (let x = 0; x < frameWidth; x++) {
				const sheetX = offsetX + x;
				const sheetY = offsetY + y;
				
				if (sheetX >= 0 && sheetX < sheetWidth && sheetY >= 0 && sheetY < sheetHeight) {
					const sheetIdx = (sheetWidth * sheetY + sheetX) << 2;
					const color = frame[y][x];
					
					sheet.data[sheetIdx] = color[0];     // R
					sheet.data[sheetIdx + 1] = color[1]; // G
					sheet.data[sheetIdx + 2] = color[2]; // B
					sheet.data[sheetIdx + 3] = 255;      // A (opaque)
				}
			}
		}
	}
	
	return sheet;
}

/**
 * Generate walking animation frames
 * @param {Function} frameGenerator - Function that generates a frame (frameIndex, frameCount, options) => 2D array of colors
 * @param {number} frameCount - Number of frames (default: 4)
 * @param {number} width - Frame width (default: 24)
 * @param {number} height - Frame height (default: 32)
 * @param {Object} options - Generation options
 * @returns {Array<Array<Array<Array<number>>>>} - Array of frame arrays
 */
export function generateWalkingFrames(frameGenerator, frameCount = 4, width = 24, height = 32, options = {}) {
	const frames = [];
	
	for (let i = 0; i < frameCount; i++) {
		const frameOptions = {
			...options,
			animationFrame: i,
			animationType: 'walking',
			animationProgress: i / frameCount // 0 to 1
		};
		
		const frame = frameGenerator(width, height, frameOptions);
		frames.push(frame);
	}
	
	return frames;
}

/**
 * Generate working animation frames
 * @param {Function} frameGenerator - Function that generates a frame (frameIndex, frameCount, options) => 2D array of colors
 * @param {number} frameCount - Number of frames (default: 4)
 * @param {number} width - Frame width (default: 24)
 * @param {number} height - Frame height (default: 32)
 * @param {Object} options - Generation options
 * @returns {Array<Array<Array<Array<number>>>>} - Array of frame arrays
 */
export function generateWorkingFrames(frameGenerator, frameCount = 4, width = 24, height = 32, options = {}) {
	const frames = [];
	
	for (let i = 0; i < frameCount; i++) {
		const frameOptions = {
			...options,
			animationFrame: i,
			animationType: 'working',
			animationProgress: i / frameCount
		};
		
		const frame = frameGenerator(width, height, frameOptions);
		frames.push(frame);
	}
	
	return frames;
}

/**
 * Export sprite sheet to file
 * @param {PNG} sheet - Sprite sheet PNG
 * @param {string} filepath - Output file path
 * @param {Object} metadata - Metadata about the sprite sheet (optional)
 */
export function exportSpriteSheet(sheet, filepath, metadata = null) {
	savePNG(sheet, filepath);
	
	// Save metadata if provided
	if (metadata) {
		const metadataPath = filepath.replace('.png', '.json');
		const metadataJSON = {
			...metadata,
			generatedAt: new Date().toISOString(),
			sheetWidth: sheet.width,
			sheetHeight: sheet.height,
			frameWidth: metadata.frameWidth || 0,
			frameHeight: metadata.frameHeight || 0,
			framesPerRow: metadata.framesPerRow || 0
		};
		writeFileSync(metadataPath, JSON.stringify(metadataJSON, null, 2), 'utf8');
	}
}

/**
 * Export frames as individual PNG files
 * @param {Array<Array<Array<Array<number>>>>} frames - Array of frame arrays
 * @param {string} outputDir - Output directory
 * @param {string} baseName - Base filename (without extension)
 * @param {Object} options - Export options
 */
export function exportFramesAsFiles(frames, outputDir, baseName, options = {}) {
	const {
		format = '{name}_{index:02d}.png' // Format: villager_walking_00.png
	} = options;
	
	// Ensure directory exists
	try {
		mkdirSync(outputDir, { recursive: true });
	} catch (err) {
		// Directory might already exist
	}
	
	for (let i = 0; i < frames.length; i++) {
		const filename = format.replace('{name}', baseName).replace('{index:02d}', String(i).padStart(2, '0'));
		const filepath = join(outputDir, filename);
		
		const png = colorsToPNG(frames[i]);
		savePNG(png, filepath);
	}
}

/**
 * Generate and export animation sprite sheet
 * @param {Function} frameGenerator - Frame generator function
 * @param {string} animationType - Animation type ('walking', 'working', etc.)
 * @param {number} frameCount - Number of frames
 * @param {number} width - Frame width
 * @param {number} height - Frame height
 * @param {string} outputPath - Output file path
 * @param {Object} options - Generation and export options
 */
export function generateAndExportAnimation(frameGenerator, animationType, frameCount, width, height, outputPath, options = {}) {
	let frames;
	
	if (animationType === 'walking') {
		frames = generateWalkingFrames(frameGenerator, frameCount, width, height, options);
	} else if (animationType === 'working') {
		frames = generateWorkingFrames(frameGenerator, frameCount, width, height, options);
	} else {
		// Generic animation
		frames = [];
		for (let i = 0; i < frameCount; i++) {
			const frameOptions = {
				...options,
				animationFrame: i,
				animationType: animationType,
				animationProgress: i / frameCount
			};
			frames.push(frameGenerator(width, height, frameOptions));
		}
	}
	
	// Create sprite sheet
	const framesPerRow = options.framesPerRow || Math.ceil(Math.sqrt(frameCount));
	const spacing = options.spacing || 0;
	const sheet = createSpriteSheet(frames, framesPerRow, spacing);
	
	// Export
	const metadata = {
		animationType,
		frameCount,
		frameWidth: width,
		frameHeight: height,
		framesPerRow,
		spacing
	};
	
	exportSpriteSheet(sheet, outputPath, metadata);
	
	return { sheet, frames, metadata };
}
