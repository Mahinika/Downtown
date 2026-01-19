#!/usr/bin/env node

/**
 * Building Sprite Generator for Downtown
 * Generates Stone Age pixel art building sprites (32x32 pixels)
 * Uses pure JavaScript PNG generation (no native dependencies)
 */

import { PNG } from 'pngjs';
import { writeFileSync, mkdirSync } from 'fs';
import { dirname, join } from 'path';
import { fileURLToPath } from 'url';
import { generateWoodTexture, generateStoneTexture, generateThatchTexture, generateGrassTexture, applyTextureToColor } from './generators/texture-generator.js';
import { ditherColor, BAYER_MATRIX_4X4 } from './utils/dithering.js';
import { shadeSphere, shadeBox, applyShading, DEFAULT_LIGHT } from './utils/shading.js';

const __filename = fileURLToPath(import.meta.url);
const __dirname = dirname(__filename);
const PROJECT_ROOT = join(__dirname, '..');
const OUTPUT_DIR = join(PROJECT_ROOT, 'downtown', 'assets', 'buildings');

// Stone Age color palette (RGB values)
const COLORS = {
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
 * Create a new 32x32 PNG image
 */
function createImage() {
	const png = new PNG({ width: 32, height: 32 });
	// Fill with background color
	for (let y = 0; y < 32; y++) {
		for (let x = 0; x < 32; x++) {
			const idx = (32 * y + x) << 2;
			png.data[idx] = COLORS.bg[0];     // R
			png.data[idx + 1] = COLORS.bg[1]; // G
			png.data[idx + 2] = COLORS.bg[2]; // B
			png.data[idx + 3] = 255;          // A
		}
	}
	return png;
}

/**
 * Set pixel color
 */
function setPixel(png, x, y, color) {
	if (x < 0 || x >= 32 || y < 0 || y >= 32) return;
	const idx = (32 * y + x) << 2;
	png.data[idx] = color[0];
	png.data[idx + 1] = color[1];
	png.data[idx + 2] = color[2];
	png.data[idx + 3] = 255;
}

/**
 * Draw filled rectangle
 */
function drawRect(png, x, y, w, h, color) {
	for (let py = y; py < y + h; py++) {
		for (let px = x; px < x + w; px++) {
			setPixel(png, px, py, color);
		}
	}
}

/**
 * Draw filled circle
 */
function drawCircle(png, cx, cy, radius, color) {
	for (let y = cy - radius; y <= cy + radius; y++) {
		for (let x = cx - radius; x <= cx + radius; x++) {
			const dx = x - cx;
			const dy = y - cy;
			if (dx * dx + dy * dy <= radius * radius) {
				setPixel(png, x, y, color);
			}
		}
	}
}

/**
 * Draw outline rectangle
 */
function drawOutline(png, x, y, w, h, color) {
	// Top and bottom
	for (let px = x; px < x + w; px++) {
		setPixel(png, px, y, color);
		setPixel(png, px, y + h - 1, color);
	}
	// Left and right
	for (let py = y; py < y + h; py++) {
		setPixel(png, x, py, color);
		setPixel(png, x + w - 1, py, color);
	}
}

/**
 * Draw rectangle with texture and shading
 */
function drawTexturedRect(png, x, y, w, h, baseColor, textureType = 'wood', seed = 0) {
	// Generate texture
	let texture;
	if (textureType === 'wood') {
		texture = generateWoodTexture(w, h, { seed, grainScale: 0.5 });
	} else if (textureType === 'stone') {
		texture = generateStoneTexture(w, h, { seed, scale: 0.2 });
	} else {
		texture = generateWoodTexture(w, h, { seed });
	}
	
	// Draw with texture and shading
	for (let py = y; py < y + h; py++) {
		for (let px = x; px < x + w; px++) {
			if (px < 0 || px >= 32 || py < 0 || py >= 32) continue;
			
			const tx = px - x;
			const ty = py - y;
			const textureValue = texture[ty][tx];
			
			// Apply texture to base color
			let color = applyTextureToColor(baseColor, textureValue, 0.2);
			
			// Apply shading
			const brightness = shadeBox(px, py, x, y, w, h, 1, DEFAULT_LIGHT, 0.3);
			color = applyShading(color, brightness);
			
			// Apply dithering
			color = ditherColor(color, px, py, BAYER_MATRIX_4X4, 0.2);
			
			setPixel(png, px, py, color);
		}
	}
}

/**
 * Draw circle with texture and shading
 */
function drawTexturedCircle(png, cx, cy, radius, baseColor, textureType = 'stone', seed = 0) {
	// Generate texture
	const texture = textureType === 'stone' 
		? generateStoneTexture(radius * 2, radius * 2, { seed, scale: 0.2 })
		: generateWoodTexture(radius * 2, radius * 2, { seed });
	
	for (let y = cy - radius; y <= cy + radius; y++) {
		for (let x = cx - radius; x <= cx + radius; x++) {
			if (x < 0 || x >= 32 || y < 0 || y >= 32) continue;
			
			const dx = x - cx;
			const dy = y - cy;
			const distSq = dx * dx + dy * dy;
			
			if (distSq <= radius * radius) {
				const tx = Math.max(0, Math.min(radius * 2 - 1, dx + radius));
				const ty = Math.max(0, Math.min(radius * 2 - 1, dy + radius));
				const textureValue = texture[ty][tx];
				
				// Apply texture
				let color = applyTextureToColor(baseColor, textureValue, 0.2);
				
				// Apply shading
				const brightness = shadeSphere(cx, cy, x, y, radius, DEFAULT_LIGHT, 0.3);
				color = applyShading(color, brightness);
				
				// Apply dithering
				color = ditherColor(color, x, y, BAYER_MATRIX_4X4, 0.2);
				
				setPixel(png, x, y, color);
			}
		}
	}
}

/**
 * Generate Hut sprite (circular/rounded shape) - Enhanced with texture and shading
 */
function generateHut() {
	const png = createImage();
	const centerX = 16;
	const centerY = 18;
	const radius = 10;
	
	// Main hut body (dome) with texture and shading
	drawTexturedCircle(png, centerX, centerY, radius, COLORS.earth, 'stone', 100);
	
	// Door opening
	drawRect(png, centerX - 3, centerY + 2, 6, 6, COLORS.woodDark);
	
	// Outline
	drawCircle(png, centerX, centerY, radius, COLORS.outline);
	
	return png;
}

/**
 * Generate Fire Pit sprite - Enhanced with texture and shading
 */
function generateFirePit() {
	const png = createImage();
	const centerX = 16;
	const centerY = 20;
	const outerRadius = 8;
	const innerRadius = 5;
	
	// Stone ring base with texture and shading
	drawTexturedCircle(png, centerX, centerY, outerRadius, COLORS.stone, 'stone', 1000);
	
	// Inner pit (darker)
	drawCircle(png, centerX, centerY, innerRadius, COLORS.earthDark);
	
	// Flame (bright, animated-like effect)
	drawCircle(png, centerX, centerY - 6, 3, COLORS.fire);
	drawCircle(png, centerX, centerY - 7, 2, COLORS.fireBright);
	// Flame highlight
	setPixel(png, centerX, centerY - 7, COLORS.fireBright);
	setPixel(png, centerX, centerY - 8, COLORS.fireBright);
	
	// Outline
	drawCircle(png, centerX, centerY, outerRadius, COLORS.outline);
	
	return png;
}

/**
 * Generate Storage Pit sprite (hexagonal) - Enhanced with texture and shading
 */
function generateStoragePit() {
	const png = createImage();
	const centerX = 16;
	const centerY = 16;
	const radius = 9;
	
	// Hexagonal shape with stone texture and shading
	drawTexturedCircle(png, centerX, centerY, radius, COLORS.storage, 'stone', 2000);
	
	// Inner detail (darker center)
	drawCircle(png, centerX, centerY, Math.floor(radius * 0.6), COLORS.storageDark);
	
	return png;
}

/**
 * Generate Tool Workshop sprite - Enhanced with texture and shading
 */
function generateToolWorkshop() {
	const png = createImage();
	const margin = 4;
	
	// Main building with wood texture and shading
	drawTexturedRect(png, margin, margin + 6, 24, 18, COLORS.wood, 'wood', 200);
	
	// Roof (triangular - simplified as rectangle) with thatch texture
	const roofTexture = generateThatchTexture(24, 6, { seed: 300 });
	for (let py = margin; py < margin + 6; py++) {
		for (let px = margin; px < margin + 24; px++) {
			if (px < 0 || px >= 32 || py < 0 || py >= 32) continue;
			const tx = px - margin;
			const ty = py - margin;
			const textureValue = roofTexture[ty][tx];
			let color = applyTextureToColor(COLORS.roof, textureValue, 0.25);
			const brightness = shadeBox(px, py, margin, margin, 24, 6, 0.5, DEFAULT_LIGHT, 0.3);
			color = applyShading(color, brightness);
			color = ditherColor(color, px, py, BAYER_MATRIX_4X4, 0.2);
			setPixel(png, px, py, color);
		}
	}
	
	// Door
	drawRect(png, 12, 18, 8, 6, COLORS.woodDark);
	
	// Window with light
	drawRect(png, 6, 10, 4, 4, COLORS.fireBright);
	
	// Outline
	drawOutline(png, margin, margin + 6, 24, 18, COLORS.outline);
	
	return png;
}

/**
 * Generate Lumber Hut sprite - Enhanced with texture and shading
 */
function generateLumberHut() {
	const png = createImage();
	const margin = 4;
	
	// Base rectangle with wood texture and shading
	drawTexturedRect(png, margin, 14, 24, 14, COLORS.wood, 'wood', 300);
	
	// Peaked roof with thatch texture
	const roofTexture = generateThatchTexture(24, 8, { seed: 350 });
	for (let py = margin; py < margin + 8; py++) {
		for (let px = margin; px < margin + 24; px++) {
			if (px < 0 || px >= 32 || py < 0 || py >= 32) continue;
			const tx = px - margin;
			const ty = py - margin;
			if (ty < roofTexture.length && tx < roofTexture[0].length) {
				const textureValue = roofTexture[ty][tx];
				let color = applyTextureToColor(COLORS.roof, textureValue, 0.25);
				const brightness = shadeBox(px, py, margin, margin, 24, 8, 0.5, DEFAULT_LIGHT, 0.3);
				color = applyShading(color, brightness);
				color = ditherColor(color, px, py, BAYER_MATRIX_4X4, 0.2);
				setPixel(png, px, py, color);
			}
		}
	}
	
	// Door
	drawRect(png, 13, 20, 6, 8, COLORS.woodDark);
	
	// Outline
	drawOutline(png, margin, 14, 24, 14, COLORS.outline);
	
	return png;
}

/**
 * Generate Stockpile sprite - Enhanced with texture and shading
 */
function generateStockpile() {
	const png = createImage();
	const margin = 5;
	
	// Bottom layer with wood texture and shading
	drawTexturedRect(png, margin, 18, 22, 10, COLORS.wood, 'wood', 600);
	
	// Top layer (stacked) with texture
	drawTexturedRect(png, margin + 3, 10, 18, 8, COLORS.woodLight, 'wood', 601);
	
	// Outline
	drawOutline(png, margin, 18, 22, 10, COLORS.outline);
	drawOutline(png, margin + 3, 10, 18, 8, COLORS.outline);
	
	return png;
}

/**
 * Generate Stone Quarry sprite - Enhanced with texture and shading
 */
function generateStoneQuarry() {
	const png = createImage();
	const centerX = 16;
	const centerY = 16;
	const radius = 10;
	
	// Hexagonal quarry with stone texture and shading
	drawTexturedCircle(png, centerX, centerY, radius, COLORS.stone, 'stone', 400);
	
	// Inner detail
	drawCircle(png, centerX, centerY, Math.floor(radius * 0.6), COLORS.stoneDark);
	
	// Stone texture highlights
	for (let i = 0; i < 8; i++) {
		const angle = (i / 8.0) * Math.PI * 2;
		const dist = radius * 0.7;
		const x = Math.floor(centerX + Math.cos(angle) * dist);
		const y = Math.floor(centerY + Math.sin(angle) * dist);
		const brightness = shadeSphere(centerX, centerY, x, y, radius, DEFAULT_LIGHT, 0.4);
		const color = applyShading(COLORS.stoneLight, brightness);
		setPixel(png, x, y, color);
	}
	
	// Outline
	drawCircle(png, centerX, centerY, radius, COLORS.outline);
	
	return png;
}

/**
 * Generate Farm sprite (2x2 field with rows) - Enhanced with grass texture
 */
function generateFarm() {
	const png = createImage();
	
	// Fill with grass texture
	const grassTexture = generateGrassTexture(32, 32, { seed: 3000, scale: 0.3 });
	for (let y = 0; y < 32; y++) {
		for (let x = 0; x < 32; x++) {
			const textureValue = grassTexture[y][x];
			let color = applyTextureToColor(COLORS.grass, textureValue, 0.2);
			const brightness = 0.8 + textureValue * 0.2; // Slight brightness variation
			color = applyShading(color, brightness);
			color = ditherColor(color, x, y, BAYER_MATRIX_4X4, 0.15);
			setPixel(png, x, y, color);
		}
	}
	
	// Field rows (horizontal lines)
	for (let i = 0; i < 4; i++) {
		const y = 4 + i * 6;
		drawRect(png, 2, y, 28, 3, COLORS.grassDark);
	}
	
	// Border
	drawOutline(png, 1, 1, 30, 30, COLORS.outline);
	
	return png;
}

/**
 * Generate Market sprite (2x2 building with stalls)
 */
function generateMarket() {
	const png = createImage();
	
	// Central market structure (wood texture)
	drawTexturedRect(png, 4, 12, 24, 12, COLORS.wood, 'wood', 500);
	
	// Market stalls around edges (smaller structures)
	drawTexturedRect(png, 2, 6, 6, 4, COLORS.woodLight, 'wood', 501);
	drawTexturedRect(png, 24, 6, 6, 4, COLORS.woodLight, 'wood', 502);
	drawTexturedRect(png, 2, 22, 6, 4, COLORS.woodLight, 'wood', 503);
	drawTexturedRect(png, 24, 22, 6, 4, COLORS.woodLight, 'wood', 504);
	
	// Central counter
	drawRect(png, 12, 8, 8, 2, COLORS.woodDark);
	
	// Roof with thatch texture
	const roofTexture = generateThatchTexture(28, 6, { seed: 600 });
	for (let py = 4; py < 10; py++) {
		for (let px = 2; px < 30; px++) {
			if (px < 0 || px >= 32 || py < 0 || py >= 32) continue;
			const tx = px - 2;
			const ty = py - 4;
			if (ty < roofTexture.length && tx < roofTexture[0].length) {
				const textureValue = roofTexture[ty][tx];
				let color = applyTextureToColor(COLORS.roof, textureValue, 0.25);
				const brightness = shadeBox(px, py, 2, 4, 28, 6, 0.5, DEFAULT_LIGHT, 0.3);
				color = applyShading(color, brightness);
				color = ditherColor(color, px, py, BAYER_MATRIX_4X4, 0.2);
				setPixel(png, px, py, color);
			}
		}
	}
	
	return png;
}

/**
 * Generate Well sprite
 */
function generateWell() {
	const png = createImage();
	const centerX = 16;
	const centerY = 20;
	
	// Stone base (circular with texture)
	drawTexturedCircle(png, centerX, centerY, 8, COLORS.stone, 'stone', 700);
	
	// Well opening (darker center)
	drawCircle(png, centerX, centerY, 4, COLORS.stoneDark);
	
	// Water (blue tint in center)
	drawCircle(png, centerX, centerY - 1, 3, [40, 90, 150]);
	
	// Well rim (wooden structure)
	drawTexturedRect(png, centerX - 6, centerY - 8, 12, 4, COLORS.wood, 'wood', 701);
	
	// Rope/bucket detail
	drawRect(png, centerX - 1, centerY - 12, 2, 4, COLORS.woodDark);
	drawCircle(png, centerX, centerY - 14, 2, COLORS.woodDark);
	
	// Outline
	drawCircle(png, centerX, centerY, 8, COLORS.outline);
	
	return png;
}

/**
 * Generate Shrine sprite
 */
function generateShrine() {
	const png = createImage();
	const centerX = 16;
	const centerY = 18;
	
	// Base platform (stone texture)
	drawTexturedRect(png, 10, 20, 12, 4, COLORS.stone, 'stone', 800);
	
	// Central altar (stone with texture)
	drawTexturedRect(png, 14, 16, 4, 4, COLORS.stoneLight, 'stone', 801);
	
	// Symbolic elements (decorative)
	drawCircle(png, centerX, centerY - 4, 2, COLORS.stoneLight);
	drawRect(png, 14, 8, 4, 2, COLORS.stoneLight);
	
	// Pillars/supports
	drawTexturedRect(png, 10, 12, 2, 8, COLORS.stone, 'stone', 802);
	drawTexturedRect(png, 20, 12, 2, 8, COLORS.stone, 'stone', 803);
	
	// Decorative top
	drawTexturedRect(png, 8, 6, 16, 4, COLORS.roof, 'stone', 804);
	
	return png;
}

/**
 * Generate Advanced Workshop sprite (2x2 building)
 */
function generateAdvancedWorkshop() {
	const png = createImage();
	const margin = 4;
	
	// Main building structure (stone texture)
	drawTexturedRect(png, margin, margin + 6, 24, 18, COLORS.stone, 'stone', 900);
	
	// Roof with stone texture
	const roofTexture = generateStoneTexture(24, 6, { seed: 950, scale: 0.3 });
	for (let py = margin; py < margin + 6; py++) {
		for (let px = margin; px < margin + 24; px++) {
			if (px < 0 || px >= 32 || py < 0 || py >= 32) continue;
			const tx = px - margin;
			const ty = py - margin;
			if (ty < roofTexture.length && tx < roofTexture[0].length) {
				const textureValue = roofTexture[ty][tx];
				let color = applyTextureToColor(COLORS.stoneDark, textureValue, 0.25);
				const brightness = shadeBox(px, py, margin, margin, 24, 6, 0.5, DEFAULT_LIGHT, 0.3);
				color = applyShading(color, brightness);
				color = ditherColor(color, px, py, BAYER_MATRIX_4X4, 0.2);
				setPixel(png, px, py, color);
			}
		}
	}
	
	// Workshop equipment/machines (dark rectangular shapes)
	drawTexturedRect(png, 8, 10, 4, 4, COLORS.stoneDark, 'stone', 901);
	drawTexturedRect(png, 20, 10, 4, 4, COLORS.stoneDark, 'stone', 902);
	
	// Windows/details
	drawRect(png, 6, 14, 2, 2, COLORS.fireBright);
	drawRect(png, 24, 14, 2, 2, COLORS.fireBright);
	
	// Door
	drawRect(png, 14, 22, 4, 6, COLORS.woodDark);
	
	// Outline
	drawOutline(png, margin, margin + 6, 24, 18, COLORS.outline);
	
	return png;
}

/**
 * Generate House sprite (2x2 residential building)
 */
function generateHouse() {
	const png = createImage();

	// Base structure
	drawRect(png, 4, 16, 24, 12, COLORS.wood); // Main walls
	drawRect(png, 6, 14, 20, 4, COLORS.roof); // Roof
	drawRect(png, 2, 12, 28, 2, COLORS.roof); // Roof overhang

	// Windows
	drawRect(png, 8, 18, 4, 4, COLORS.woodDark);
	drawRect(png, 20, 18, 4, 4, COLORS.woodDark);

	// Door
	drawRect(png, 14, 22, 4, 6, COLORS.woodDark);

	// Outline
	drawOutline(png, 2, 12, 28, 16, COLORS.outline);

	return png;
}

/**
 * Generate Mill sprite (processing building)
 */
function generateMill() {
	const png = createImage();

	// Base structure
	drawRect(png, 6, 18, 20, 10, COLORS.stone);
	drawRect(png, 8, 16, 16, 4, COLORS.wood); // Roof base

	// Water wheel
	drawRect(png, 2, 20, 2, 6, COLORS.wood); // Wheel support
	drawCircle(png, 3, 23, 3, COLORS.wood); // Wheel

	// Mill mechanism
	drawRect(png, 10, 8, 12, 8, COLORS.wood); // Mill body
	drawRect(png, 14, 4, 4, 12, COLORS.wood); // Shaft

	// Outline
	drawOutline(png, 6, 16, 20, 12, COLORS.outline);

	return png;
}

/**
 * Generate Smokehouse sprite (processing building)
 */
function generateSmokehouse() {
	const png = createImage();

	// Base structure
	drawRect(png, 6, 18, 20, 10, COLORS.stone);

	// Smoke stacks
	drawRect(png, 8, 12, 4, 6, COLORS.stoneDark);
	drawRect(png, 20, 12, 4, 6, COLORS.stoneDark);

	// Smoke
	for (let i = 0; i < 3; i++) {
		drawRect(png, 9 + i * 2, 10 - i * 2, 2, 2, [200, 200, 200, 150]);
		drawRect(png, 21 + i * 2, 10 - i * 2, 2, 2, [200, 200, 200, 150]);
	}

	// Door
	drawRect(png, 14, 22, 4, 6, COLORS.wood);

	// Outline
	drawOutline(png, 6, 18, 20, 10, COLORS.outline);

	return png;
}

/**
 * Generate Brewery sprite (processing building)
 */
function generateBrewery() {
	const png = createImage();

	// Base structure
	drawRect(png, 6, 18, 20, 10, COLORS.stone);

	// Barrels
	drawRect(png, 8, 20, 6, 6, COLORS.wood);
	drawRect(png, 16, 20, 6, 6, COLORS.wood);

	// Brewery equipment
	drawRect(png, 10, 14, 12, 4, COLORS.stone); // Boiler
	drawRect(png, 14, 10, 4, 8, COLORS.stone); // Chimney

	// Pipes/connections
	drawRect(png, 12, 18, 8, 2, COLORS.stoneDark);

	// Outline
	drawOutline(png, 6, 18, 20, 10, COLORS.outline);

	return png;
}

/**
 * Generate Blacksmith sprite (processing building)
 */
function generateBlacksmith() {
	const png = createImage();

	// Base structure
	drawRect(png, 6, 18, 20, 10, COLORS.stone);

	// Forge/fire pit
	drawRect(png, 10, 22, 6, 4, COLORS.stoneDark);
	drawRect(png, 12, 20, 2, 2, COLORS.fire);

	// Anvil
	drawRect(png, 18, 24, 4, 2, COLORS.stoneDark);

	// Tools hanging
	drawRect(png, 8, 14, 2, 6, COLORS.stone); // Hammer
	drawRect(png, 22, 16, 2, 4, COLORS.stone); // Tongs

	// Roof
	drawRect(png, 4, 14, 24, 4, COLORS.wood);

	// Outline
	drawOutline(png, 6, 18, 20, 10, COLORS.outline);

	return png;
}

/**
 * Generate Apple Orchard sprite (farm building)
 */
function generateAppleOrchard() {
	const png = createImage();

	// Trees
	for (let i = 0; i < 3; i++) {
		const x = 6 + i * 8;
		// Trunk
		drawRect(png, x + 2, 20, 2, 6, COLORS.wood);
		// Leaves
		drawCircle(png, x + 3, 18, 4, COLORS.grass);
		// Apples
		drawCircle(png, x + 1, 17, 1, [255, 0, 0]);
		drawCircle(png, x + 5, 19, 1, [255, 0, 0]);
	}

	// Ground
	drawRect(png, 0, 26, 32, 6, COLORS.earth);

	return png;
}

/**
 * Generate Hops Farm sprite (farm building)
 */
function generateHopsFarm() {
	const png = createImage();

	// Trellises
	for (let i = 0; i < 4; i++) {
		const x = 4 + i * 6;
		drawRect(png, x, 16, 2, 12, COLORS.wood); // Posts
		drawRect(png, x - 2, 14, 6, 2, COLORS.wood); // Crossbars
		// Vines
		for (let j = 0; j < 3; j++) {
			drawRect(png, x + 1, 16 + j * 3, 1, 3, COLORS.grass);
		}
	}

	// Ground
	drawRect(png, 0, 26, 32, 6, COLORS.earth);

	return png;
}

/**
 * Generate Bakery sprite (processing building)
 */
function generateBakery() {
	const png = createImage();

	// Base structure
	drawRect(png, 6, 18, 20, 10, COLORS.stone);

	// Oven
	drawRect(png, 10, 20, 8, 6, COLORS.stoneDark);
	drawRect(png, 12, 18, 4, 2, COLORS.fire); // Fire

	// Chimney
	drawRect(png, 16, 12, 4, 8, COLORS.stone);

	// Bread/loaves (stylized)
	drawRect(png, 8, 24, 3, 2, COLORS.woodLight);
	drawRect(png, 12, 24, 3, 2, COLORS.woodLight);
	drawRect(png, 16, 24, 3, 2, COLORS.woodLight);

	// Outline
	drawOutline(png, 6, 18, 20, 10, COLORS.outline);

	return png;
}

/**
 * Generate Inn sprite (service building)
 */
function generateInn() {
	const png = createImage();

	// Base structure
	drawRect(png, 4, 16, 24, 12, COLORS.wood);

	// Sign
	drawRect(png, 12, 10, 8, 6, COLORS.wood); // Sign post
	drawRect(png, 10, 8, 12, 4, COLORS.woodLight); // Sign

	// Windows
	drawRect(png, 6, 18, 4, 4, COLORS.woodDark);
	drawRect(png, 22, 18, 4, 4, COLORS.woodDark);

	// Door
	drawRect(png, 14, 22, 4, 6, COLORS.woodDark);

	// Beer mugs on sign (stylized)
	drawCircle(png, 13, 10, 1, COLORS.stone);
	drawCircle(png, 19, 10, 1, COLORS.stone);

	// Outline
	drawOutline(png, 4, 16, 24, 12, COLORS.outline);

	return png;
}

/**
 * Generate Gallows sprite (fear building)
 */
function generateGallows() {
	const png = createImage();

	// Main structure
	drawRect(png, 12, 20, 2, 8, COLORS.wood); // Post
	drawRect(png, 8, 12, 16, 2, COLORS.wood); // Crossbeam
	drawRect(png, 6, 10, 2, 4, COLORS.wood); // Support

	// Rope/noose
	drawRect(png, 14, 14, 1, 6, COLORS.roof); // Rope
	drawCircle(png, 14, 20, 2, COLORS.roof); // Noose

	// Steps
	drawRect(png, 10, 26, 6, 2, COLORS.wood);

	// Outline
	drawOutline(png, 6, 10, 20, 18, COLORS.outline);

	return png;
}

/**
 * Generate Dungeon sprite (fear building)
 */
function generateDungeon() {
	const png = createImage();

	// Underground structure (partially visible)
	drawRect(png, 4, 20, 24, 8, COLORS.stone);

	// Bars/grate
	for (let i = 0; i < 5; i++) {
		drawRect(png, 6 + i * 4, 18, 2, 10, COLORS.stoneDark);
	}

	// Door
	drawRect(png, 14, 22, 4, 6, COLORS.wood);

	// Chains
	drawRect(png, 8, 16, 1, 4, COLORS.stone);
	drawRect(png, 24, 16, 1, 4, COLORS.stone);

	// Outline
	drawOutline(png, 4, 20, 24, 8, COLORS.outline);

	return png;
}

/**
 * Generate Garden sprite (good building)
 */
function generateGarden() {
	const png = createImage();

	// Garden beds
	drawRect(png, 4, 20, 8, 8, COLORS.earth);
	drawRect(png, 14, 20, 8, 8, COLORS.earth);
	drawRect(png, 24, 20, 4, 8, COLORS.earth);

	// Plants/flowers
	for (let i = 0; i < 6; i++) {
		const x = 6 + i * 3;
		const y = 18 + (i % 2) * 2;
		if (x < 30) {
			drawCircle(png, x, y, 1, COLORS.grass);
		}
	}

	// Path
	drawRect(png, 12, 24, 8, 4, COLORS.earthLight);

	// Fence
	for (let i = 0; i < 8; i++) {
		drawRect(png, 2 + i * 3, 28, 2, 2, COLORS.wood);
	}

	return png;
}

/**
 * Generate Church sprite (good building)
 */
function generateChurch() {
	const png = createImage();

	// Base structure
	drawRect(png, 6, 20, 20, 8, COLORS.stone);

	// Steeple
	drawRect(png, 14, 8, 4, 12, COLORS.stone);

	// Cross
	drawRect(png, 15, 6, 2, 6, COLORS.stone);
	drawRect(png, 13, 8, 6, 2, COLORS.stone);

	// Windows
	drawRect(png, 8, 22, 4, 4, COLORS.stoneDark);
	drawRect(png, 20, 22, 4, 4, COLORS.stoneDark);

	// Door
	drawRect(png, 14, 24, 4, 4, COLORS.stoneDark);

	// Bell
	drawCircle(png, 16, 12, 2, COLORS.stoneLight);

	// Outline
	drawOutline(png, 6, 20, 20, 8, COLORS.outline);

	return png;
}

/**
 * Save PNG to file
 */
function savePNG(png, filepath) {
	const buffer = PNG.sync.write(png);
	writeFileSync(filepath, buffer);
	console.log(`Generated: ${filepath}`);
}

/**
 * Main generation function
 */
function generateAllBuildings() {
	console.log('Generating building sprites...');
	
	// Ensure output directory exists
	try {
		mkdirSync(OUTPUT_DIR, { recursive: true });
	} catch (err) {
		// Directory might already exist
	}
	
	// Generate all building sprites
	const buildings = {
		'hut': generateHut,
		'fire_pit': generateFirePit,
		'storage_pit': generateStoragePit,
		'tool_workshop': generateToolWorkshop,
		'lumber_hut': generateLumberHut,
		'stockpile': generateStockpile,
		'stone_quarry': generateStoneQuarry,
		'farm': generateFarm,
		'market': generateMarket,
		'well': generateWell,
		'shrine': generateShrine,
		'advanced_workshop': generateAdvancedWorkshop,
		'house': generateHouse,
		'mill': generateMill,
		'smokehouse': generateSmokehouse,
		'brewery': generateBrewery,
		'blacksmith': generateBlacksmith,
		'apple_orchard': generateAppleOrchard,
		'hops_farm': generateHopsFarm,
		'bakery': generateBakery,
		'inn': generateInn,
		'gallows': generateGallows,
		'dungeon': generateDungeon,
		'garden': generateGarden,
		'church': generateChurch
	};
	
	for (const [buildingId, generator] of Object.entries(buildings)) {
		const png = generator();
		const filepath = join(OUTPUT_DIR, `${buildingId}.png`);
		savePNG(png, filepath);
	}
	
	console.log(`\n✓ Generated ${Object.keys(buildings).length} building sprites in ${OUTPUT_DIR}`);
}

// Run if called directly
generateAllBuildings();

export { generateAllBuildings };
