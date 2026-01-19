/**
 * Shading Utilities - Simple 3D lighting simulation for 2D pixel art
 * Provides depth perception through lighting and shadow casting
 */

/**
 * Calculate shading based on surface normal and light direction
 * @param {number} normalX - Surface normal X component (-1 to 1)
 * @param {number} normalY - Surface normal Y component (-1 to 1)
 * @param {number} normalZ - Surface normal Z component (0 to 1, for depth)
 * @param {Object} light - Light direction {x, y, z}
 * @param {number} ambient - Ambient light level (0-1)
 * @returns {number} - Brightness value (0-1)
 */
export function calculateShading(normalX, normalY, normalZ, light = {x: -0.707, y: -0.707, z: 0.5}, ambient = 0.3) {
	// Normalize light direction
	const lightLen = Math.sqrt(light.x * light.x + light.y * light.y + light.z * light.z);
	const lightNorm = {
		x: light.x / lightLen,
		y: light.y / lightLen,
		z: light.z / lightLen
	};
	
	// Normalize surface normal
	const normalLen = Math.sqrt(normalX * normalX + normalY * normalY + normalZ * normalZ);
	const normal = {
		x: normalX / normalLen,
		y: normalY / normalLen,
		z: normalZ / normalLen
	};
	
	// Dot product (cosine of angle between normal and light)
	const dot = normal.x * lightNorm.x + normal.y * lightNorm.y + normal.z * lightNorm.z;
	
	// Clamp and add ambient
	const brightness = Math.max(0, Math.min(1, dot * (1 - ambient) + ambient));
	
	return brightness;
}

/**
 * Calculate shading for a sphere/circle
 * @param {number} centerX - Circle center X
 * @param {number} centerY - Circle center Y
 * @param {number} x - Current X position
 * @param {number} y - Current Y position
 * @param {number} radius - Circle radius
 * @param {Object} light - Light direction {x, y, z}
 * @param {number} ambient - Ambient light level (0-1)
 * @returns {number} - Brightness value (0-1)
 */
export function shadeSphere(centerX, centerY, x, y, radius, light = {x: -0.707, y: -0.707, z: 0.5}, ambient = 0.3) {
	const dx = x - centerX;
	const dy = y - centerY;
	const dist = Math.sqrt(dx * dx + dy * dy);
	
	if (dist > radius) {
		return 0; // Outside circle
	}
	
	// Calculate surface normal from sphere equation
	// For a sphere at origin, normal at (x,y) is (x/r, y/r, z/r) where z = sqrt(r² - x² - y²)
	const z = Math.sqrt(Math.max(0, radius * radius - dist * dist));
	const normalX = dx / radius;
	const normalY = dy / radius;
	const normalZ = z / radius;
	
	return calculateShading(normalX, normalY, normalZ, light, ambient);
}

/**
 * Calculate shading for a cylinder (top-down view)
 * @param {number} centerX - Cylinder center X
 * @param {number} centerY - Cylinder center Y
 * @param {number} x - Current X position
 * @param {number} y - Current Y position
 * @param {number} radius - Cylinder radius
 * @param {Object} light - Light direction {x, y, z}
 * @param {number} ambient - Ambient light level (0-1)
 * @returns {number} - Brightness value (0-1)
 */
export function shadeCylinder(centerX, centerY, x, y, radius, light = {x: -0.707, y: -0.707, z: 0.5}, ambient = 0.3) {
	const dx = x - centerX;
	const dy = y - centerY;
	const dist = Math.sqrt(dx * dx + dy * dy);
	
	if (dist > radius) {
		return 0; // Outside cylinder
	}
	
	// For top-down cylinder, normal is horizontal from center
	const normalX = dx / radius;
	const normalY = dy / radius;
	const normalZ = 0; // No vertical component in top-down view
	
	return calculateShading(normalX, normalY, normalZ, light, ambient);
}

/**
 * Calculate shading for a box/rectangle (top-down view with height)
 * @param {number} x - Current X position
 * @param {number} y - Current Y position
 * @param {number} boxX - Box left X
 * @param {number} boxY - Box top Y
 * @param {number} boxWidth - Box width
 * @param {number} boxHeight - Box height
 * @param {number} height - Box 3D height (for depth shading)
 * @param {Object} light - Light direction {x, y, z}
 * @param {number} ambient - Ambient light level (0-1)
 * @returns {number} - Brightness value (0-1)
 */
export function shadeBox(x, y, boxX, boxY, boxWidth, boxHeight, height = 1, light = {x: -0.707, y: -0.707, z: 0.5}, ambient = 0.3) {
	// Determine which face we're on (top or sides)
	const centerX = boxX + boxWidth / 2;
	const centerY = boxY + boxHeight / 2;
	
	// Top face (inside box)
	if (x >= boxX && x < boxX + boxWidth && y >= boxY && y < boxY + boxHeight) {
		// Top face gets more light
		const normalX = 0;
		const normalY = 0;
		const normalZ = 1;
		return calculateShading(normalX, normalY, normalZ, light, ambient);
	}
	
	// Sides (outside box but near edges)
	const margin = 2; // Pixels for side shading
	let normalX = 0;
	let normalY = 0;
	let normalZ = 0;
	
	if (x < boxX && x >= boxX - margin) {
		// Left side
		normalX = -1;
		normalY = 0;
		normalZ = 0.3;
	} else if (x >= boxX + boxWidth && x < boxX + boxWidth + margin) {
		// Right side
		normalX = 1;
		normalY = 0;
		normalZ = 0.3;
	} else if (y < boxY && y >= boxY - margin) {
		// Top side
		normalX = 0;
		normalY = -1;
		normalZ = 0.3;
	} else if (y >= boxY + boxHeight && y < boxY + boxHeight + margin) {
		// Bottom side
		normalX = 0;
		normalY = 1;
		normalZ = 0.3;
	} else {
		return 0; // Too far from box
	}
	
	return calculateShading(normalX, normalY, normalZ, light, ambient);
}

/**
 * Apply shading to a color
 * @param {Array<number>} color - RGB color [r, g, b]
 * @param {number} brightness - Brightness value (0-1)
 * @returns {Array<number>} - Shaded RGB color
 */
export function applyShading(color, brightness) {
	return [
		Math.floor(color[0] * brightness),
		Math.floor(color[1] * brightness),
		Math.floor(color[2] * brightness)
	];
}

/**
 * Calculate shadow for an object
 * @param {number} objectX - Object X position
 * @param {number} objectY - Object Y position
 * @param {number} shadowX - Shadow point X
 * @param {number} shadowY - Shadow point Y
 * @param {number} shadowRadius - Shadow radius/blur
 * @param {Object} light - Light direction {x, y, z}
 * @returns {number} - Shadow opacity (0-1)
 */
export function calculateShadow(objectX, objectY, shadowX, shadowY, shadowRadius, light = {x: -0.707, y: -0.707, z: 0.5}) {
	// Project shadow based on light direction
	const dx = shadowX - objectX;
	const dy = shadowY - objectY;
	
	// Distance from object center
	const dist = Math.sqrt(dx * dx + dy * dy);
	
	// Shadow is elliptical based on light angle
	// Light direction affects shadow shape
	const lightAngle = Math.atan2(light.y, light.x);
	const projectedDist = dist * Math.cos(lightAngle);
	
	// Soft shadow (fade with distance)
	if (projectedDist > shadowRadius) {
		return 0;
	}
	
	const shadowOpacity = 1 - (projectedDist / shadowRadius);
	return Math.max(0, Math.min(1, shadowOpacity * 0.6)); // Max 60% opacity
}

/**
 * Create a drop shadow for an object
 * @param {number} width - Image width
 * @param {number} height - Image height
 * @param {Function} isObjectPixel - Function(x, y) returns true if pixel is part of object
 * @param {Object} light - Light direction {x, y, z}
 * @param {number} shadowOffset - Shadow offset distance
 * @param {number} shadowBlur - Shadow blur radius
 * @returns {Array<Array<number>>} - 2D array of shadow opacity values (0-1)
 */
export function createDropShadow(width, height, isObjectPixel, light = {x: -0.707, y: -0.707, z: 0.5}, shadowOffset = 3, shadowBlur = 2) {
	const shadow = Array(height).fill(null).map(() => Array(width).fill(0));
	
	// Calculate shadow direction
	const shadowDirX = light.x * shadowOffset;
	const shadowDirY = light.y * shadowOffset;
	
	for (let y = 0; y < height; y++) {
		for (let x = 0; x < width; x++) {
			// Check if this pixel would cast a shadow
			const sourceX = x - shadowDirX;
			const sourceY = y - shadowDirY;
			
			if (sourceX >= 0 && sourceX < width && sourceY >= 0 && sourceY < height) {
				if (isObjectPixel(Math.floor(sourceX), Math.floor(sourceY))) {
					// Apply blur to shadow
					let shadowValue = 0.6; // Base shadow opacity
					
					// Simple blur (average nearby shadow pixels)
					let blurCount = 0;
					for (let by = -shadowBlur; by <= shadowBlur; by++) {
						for (let bx = -shadowBlur; bx <= shadowBlur; bx++) {
							const blurX = sourceX + bx;
							const blurY = sourceY + by;
							if (blurX >= 0 && blurX < width && blurY >= 0 && blurY < height) {
								if (isObjectPixel(Math.floor(blurX), Math.floor(blurY))) {
									blurCount++;
								}
							}
						}
					}
					
					const blurFactor = blurCount / ((shadowBlur * 2 + 1) * (shadowBlur * 2 + 1));
					shadowValue *= blurFactor;
					
					shadow[y][x] = Math.max(shadow[y][x], shadowValue);
				}
			}
		}
	}
	
	return shadow;
}

/**
 * Default light source (top-left, angled down)
 */
export const DEFAULT_LIGHT = {
	x: -0.707, // Left
	y: -0.707, // Up (screen coordinates)
	z: 0.5     // Slight angle down
};
