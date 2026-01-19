extends Node

## AssetGenerator - Simple asset generation for visual identity
##
## Creates basic pixel art sprites programmatically for buildings, villagers, and resources.
## Generates placeholder graphics when actual assets are not available, ensuring the game
## can run with generated visuals during development and prototyping.
##
## Key Features:
## - Procedural building sprite generation
## - Villager state sprites (idle, walking, working, carrying)
## - Resource node sprites (trees, stones, berry bushes)
## - Color-coded building types
## - Automatic asset checking and generation
##
## Usage:
##   AssetGenerator.generate_all_assets()  # Called automatically if assets missing

## Size of each tile/sprite in pixels.
const TILE_SIZE: int = 32

## Base path where generated assets are saved.
const ASSET_PATH: String = "res://assets/"

## FastNoiseLite instance for procedural texture generation
var noise: FastNoiseLite

func _ready() -> void:
	print("[AssetGenerator] Initialized")
	# Initialize noise for texture generation
	noise = FastNoiseLite.new()
	noise.seed = 12345
	noise.noise_type = FastNoiseLite.TYPE_PERLIN
	noise.frequency = 0.1
	# Check if assets exist, generate if missing
	check_and_generate_assets()

func generate_all_assets() -> void:
	"""Generate all basic assets for the game"""
	print("[AssetGenerator] Generating all assets...")
	
	# Create directories
	ensure_directory(ASSET_PATH + "buildings/")
	ensure_directory(ASSET_PATH + "villagers/")
	ensure_directory(ASSET_PATH + "resources/")
	
	# Generate building sprites
	generate_building_sprites()
	
	# Generate villager sprites
	generate_villager_sprites()
	
	# Generate resource node sprites
	generate_resource_node_sprites()
	
	print("[AssetGenerator] Asset generation complete!")

func generate_building_sprites() -> void:
	"""Generate sprites for all buildings"""
	print("[AssetGenerator] Generating building sprites...")
	
	var buildings = ["hut", "fire_pit", "storage_pit", "tool_workshop", "lumber_hut", "stockpile", "stone_quarry", "farm", "market", "well", "shrine", "advanced_workshop"]
	
	for building_id in buildings:
		var sprite = generate_building_sprite(building_id)
		if sprite:
			save_sprite(sprite, ASSET_PATH + "buildings/" + building_id + ".png")
			print("[AssetGenerator] Generated building sprite: " + building_id)

func generate_villager_sprites() -> void:
	"""Generate villager sprites with different states"""
	print("[AssetGenerator] Generating villager sprites...")
	
	var states = ["idle", "walking", "working", "carrying"]
	
	for state in states:
		var sprite = generate_villager_sprite(state)
		if sprite:
			save_sprite(sprite, ASSET_PATH + "villagers/villager_" + state + ".png")
			print("[AssetGenerator] Generated villager sprite: " + state)

func generate_resource_node_sprites() -> void:
	"""Generate resource node sprites"""
	print("[AssetGenerator] Generating resource node sprites...")
	
	var nodes = ["tree", "stone", "berry_bush"]
	
	for node_type in nodes:
		var sprite = generate_resource_node_sprite(node_type)
		if sprite:
			save_sprite(sprite, ASSET_PATH + "resources/" + node_type + ".png")
			print("[AssetGenerator] Generated resource node sprite: " + node_type)

func generate_building_sprite(building_id: String) -> Image:
	"""Generate a simple pixel art sprite for a building"""
	var img = Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))  # Transparent background
	
	var colors = get_building_colors(building_id)
	
	match building_id:
		"hut":
			# Simple hut shape
			draw_rect(img, 4, 8, 24, 16, colors.main)  # Base
			draw_rect(img, 8, 4, 16, 12, colors.roof)  # Roof
			draw_pixel(img, 16, 12, colors.door)      # Door
		"fire_pit":
			# Circular fire pit
			draw_circle(img, 16, 16, 8, colors.main)
			draw_circle(img, 16, 16, 4, colors.fire)
		"storage_pit":
			# Diamond shape
			draw_rect(img, 12, 8, 8, 16, colors.main)   # Vertical
			draw_rect(img, 8, 12, 16, 8, colors.main)   # Horizontal
		"tool_workshop":
			# Rectangular building
			draw_rect(img, 4, 8, 24, 16, colors.main)
			draw_rect(img, 8, 4, 16, 4, colors.roof)
		"lumber_hut":
			# House with peaked roof
			draw_rect(img, 4, 12, 24, 12, colors.main)
			draw_triangle(img, 4, 12, 16, 4, colors.roof)
		"stockpile":
			# Stacked boxes
			draw_rect(img, 6, 14, 20, 8, colors.main)   # Bottom
			draw_rect(img, 8, 8, 16, 6, colors.accent)  # Middle
			draw_rect(img, 10, 4, 12, 4, colors.main)   # Top
		"stone_quarry":
			# Hexagonal quarry
			draw_hexagon(img, 16, 16, 10, colors.main)
		"farm":
			# Farm field (2x2 building size, but we'll make a 32x32 sprite)
			# Draw a simple field pattern
			for x in range(4, 28, 4):
				for y in range(4, 28, 4):
					if (x + y) % 8 == 0:
						draw_rect(img, x, y, 2, 2, colors.main)
		"market":
			# Market stalls (2x2 building)
			# Central market structure
			draw_rect(img, 8, 12, 16, 8, colors.main)
			# Market stalls around the edges
			draw_rect(img, 2, 6, 6, 4, colors.accent)
			draw_rect(img, 24, 6, 6, 4, colors.accent)
			draw_rect(img, 2, 22, 6, 4, colors.accent)
			draw_rect(img, 24, 22, 6, 4, colors.accent)
			# Central counter
			draw_rect(img, 12, 8, 8, 2, colors.accent)
		"well":
			# Well structure
			# Stone base
			draw_rect(img, 12, 20, 8, 8, colors.main)
			# Well opening
			draw_rect(img, 14, 16, 4, 4, colors.water)
			# Bucket/rope
			draw_pixel(img, 16, 14, Color(0.3, 0.2, 0.1))
			draw_rect(img, 15, 10, 2, 4, Color(0.3, 0.2, 0.1))
		"shrine":
			# Shrine structure
			# Base platform
			draw_rect(img, 10, 20, 12, 4, colors.main)
			# Central altar
			draw_rect(img, 14, 16, 4, 4, colors.accent)
			# Symbolic elements
			draw_pixel(img, 16, 12, colors.accent)
			draw_rect(img, 14, 8, 4, 2, colors.accent)
		"advanced_workshop":
			# Advanced workshop (2x2 building)
			# Main building structure
			draw_rect(img, 4, 12, 24, 12, colors.main)
			# Workshop equipment/details
			draw_rect(img, 8, 8, 4, 4, colors.accent)  # Machine/tool
			draw_rect(img, 20, 8, 4, 4, colors.accent) # Another machine
			# Windows/details
			draw_rect(img, 6, 14, 2, 2, colors.accent)
			draw_rect(img, 24, 14, 2, 2, colors.accent)

	return img

func generate_villager_sprite(state: String) -> Image:
	"""Generate a simple pixel art sprite for a villager"""
	var img = Image.create(24, 32, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))  # Transparent background
	
	var colors = {
		"skin": Color(0.9, 0.7, 0.5),
		"shirt": Color(0.4, 0.6, 0.8),
		"pants": Color(0.3, 0.3, 0.6),
		"hair": Color(0.3, 0.2, 0.1)
	}
	
	# Basic human shape
	match state:
		"idle":
			# Head
			draw_circle(img, 12, 8, 4, colors.skin)
			# Hair
			draw_pixel(img, 10, 6, colors.hair)
			draw_pixel(img, 11, 5, colors.hair)
			draw_pixel(img, 12, 5, colors.hair)
			draw_pixel(img, 13, 5, colors.hair)
			draw_pixel(img, 14, 6, colors.hair)
			# Body
			draw_rect(img, 10, 12, 4, 8, colors.shirt)
			# Arms
			draw_rect(img, 8, 14, 2, 4, colors.skin)
			draw_rect(img, 14, 14, 2, 4, colors.skin)
			# Legs
			draw_rect(img, 10, 20, 2, 6, colors.pants)
			draw_rect(img, 12, 20, 2, 6, colors.pants)
		"walking":
			# Similar to idle but with slight movement
			draw_circle(img, 12, 8, 4, colors.skin)
			draw_rect(img, 10, 12, 4, 8, colors.shirt)
			draw_rect(img, 8, 14, 2, 4, colors.skin)
			draw_rect(img, 14, 14, 2, 4, colors.skin)
			# Walking legs (slightly offset)
			draw_rect(img, 9, 20, 2, 6, colors.pants)
			draw_rect(img, 13, 20, 2, 6, colors.pants)
		"working":
			# Similar to idle but with tool
			draw_circle(img, 12, 8, 4, colors.skin)
			draw_rect(img, 10, 12, 4, 8, colors.shirt)
			draw_rect(img, 8, 14, 2, 4, colors.skin)
			# Working arm extended
			draw_rect(img, 14, 14, 4, 2, colors.skin)
			draw_rect(img, 10, 20, 2, 6, colors.pants)
			draw_rect(img, 12, 20, 2, 6, colors.pants)
		"carrying":
			# Similar to idle but with item
			draw_circle(img, 12, 8, 4, colors.skin)
			draw_rect(img, 10, 12, 4, 8, colors.shirt)
			draw_rect(img, 8, 14, 2, 4, colors.skin)
			draw_rect(img, 14, 14, 2, 4, colors.skin)
			draw_rect(img, 10, 20, 2, 6, colors.pants)
			draw_rect(img, 12, 20, 2, 6, colors.pants)
			# Carrying item
			draw_rect(img, 16, 12, 4, 4, Color(0.6, 0.4, 0.2))
	
	return img

func generate_resource_node_sprite(node_type: String) -> Image:
	"""Generate a simple sprite for a resource node"""
	var img = Image.create(TILE_SIZE, TILE_SIZE, false, Image.FORMAT_RGBA8)
	img.fill(Color(0, 0, 0, 0))  # Transparent background
	
	match node_type:
		"tree":
			# Simple tree shape
			draw_rect(img, 14, 20, 4, 8, Color(0.4, 0.2, 0.1))  # Trunk
			draw_circle(img, 16, 12, 8, Color(0.2, 0.5, 0.2))  # Foliage
		"stone":
			# Rock shape
			draw_circle(img, 12, 20, 6, Color(0.5, 0.5, 0.5))
			draw_circle(img, 20, 18, 5, Color(0.6, 0.6, 0.6))
			draw_circle(img, 16, 24, 4, Color(0.4, 0.4, 0.4))
		"berry_bush":
			# Bush with berries
			draw_circle(img, 16, 20, 6, Color(0.2, 0.5, 0.2))  # Bush
			draw_pixel(img, 12, 18, Color(0.8, 0.2, 0.2))       # Berries
			draw_pixel(img, 18, 16, Color(0.8, 0.2, 0.2))
			draw_pixel(img, 20, 22, Color(0.8, 0.2, 0.2))
	
	return img

func get_building_colors(building_id: String) -> Dictionary:
	"""Get color palette for a building type"""
	var palettes = {
		"hut": {
			"main": Color(0.6, 0.4, 0.2),
			"roof": Color(0.4, 0.2, 0.1),
			"door": Color(0.3, 0.15, 0.05)
		},
		"fire_pit": {
			"main": Color(0.4, 0.2, 0.1),
			"fire": Color(1.0, 0.5, 0.0)
		},
		"storage_pit": {
			"main": Color(0.5, 0.3, 0.2)
		},
		"tool_workshop": {
			"main": Color(0.4, 0.3, 0.2),
			"roof": Color(0.3, 0.2, 0.1)
		},
		"lumber_hut": {
			"main": Color(0.6, 0.4, 0.2),
			"roof": Color(0.4, 0.2, 0.1)
		},
		"stockpile": {
			"main": Color(0.5, 0.3, 0.2),
			"accent": Color(0.6, 0.4, 0.3)
		},
		"stone_quarry": {
			"main": Color(0.5, 0.5, 0.5)
		},
		"farm": {
			"main": Color(0.3, 0.6, 0.2)
		},
		"market": {
			"main": Color(0.8, 0.6, 0.4),
			"accent": Color(0.9, 0.8, 0.6)
		},
		"well": {
			"main": Color(0.4, 0.4, 0.8),
			"water": Color(0.2, 0.4, 0.9)
		},
		"shrine": {
			"main": Color(0.6, 0.4, 0.8),
			"accent": Color(0.8, 0.6, 0.9)
		},
		"advanced_workshop": {
			"main": Color(0.5, 0.5, 0.5),
			"accent": Color(0.3, 0.3, 0.3)
		}
	}

	return palettes.get(building_id, {"main": Color(0.5, 0.5, 0.5)})

# Drawing utilities
func draw_pixel(img: Image, x: int, y: int, color: Color) -> void:
	if x >= 0 and x < img.get_width() and y >= 0 and y < img.get_height():
		img.set_pixel(x, y, color)

func draw_rect(img: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
	for px in range(x, x + w):
		for py in range(y, y + h):
			draw_pixel(img, px, py, color)

func draw_circle(img: Image, center_x: int, center_y: int, radius: int, color: Color) -> void:
	for x in range(center_x - radius, center_x + radius + 1):
		for y in range(center_y - radius, center_y + radius + 1):
			var dx = x - center_x
			var dy = y - center_y
			if dx * dx + dy * dy <= radius * radius:
				draw_pixel(img, x, y, color)

func draw_triangle(img: Image, x: int, y: int, w: int, h: int, color: Color) -> void:
	for py in range(y, y + h):
		var width_at_y = int((py - y) * w / float(h))
		var start_x = x + int((w - width_at_y) / 2.0)
		for px in range(start_x, start_x + width_at_y):
			draw_pixel(img, px, py, color)

func draw_hexagon(img: Image, center_x: int, center_y: int, radius: int, color: Color) -> void:
	for x in range(center_x - radius, center_x + radius + 1):
		for y in range(center_y - radius, center_y + radius + 1):
			var dx = abs(x - center_x)
			var dy = abs(y - center_y)
			if dx * 0.5 + dy <= radius * 0.8:  # Hexagon approximation
				draw_pixel(img, x, y, color)

func save_sprite(img: Image, path: String) -> void:
	"""Save an image as PNG"""
	var err = img.save_png(path)
	if err != OK:
		push_error("[AssetGenerator] Failed to save sprite: " + path)
	else:
		print("[AssetGenerator] Saved sprite: " + path)

func check_and_generate_assets() -> void:
	"""Check if assets exist, generate if missing"""
	print("[AssetGenerator] Checking for existing assets...")
	
	# Check for a few key assets
	var check_files = [
		ASSET_PATH + "buildings/hut.png",
		ASSET_PATH + "villagers/villager_idle.png",
		ASSET_PATH + "resources/tree.png"
	]
	
	var assets_exist = true
	for file_path in check_files:
		if not FileAccess.file_exists(file_path):
			assets_exist = false
			break
	
	if not assets_exist:
		print("[AssetGenerator] Assets missing, generating...")
		generate_all_assets()
	else:
		print("[AssetGenerator] Assets already exist, skipping generation")

func ensure_directory(path: String) -> void:
	"""Ensure a directory exists"""
	var dir = DirAccess.open("res://")
	if dir:
		var full_path = path.replace("res://", "")
		if not dir.dir_exists(full_path):
			dir.make_dir_recursive(full_path)

# Procedural texture and detail functions using FastNoiseLite

func get_noise_value(x: float, y: float, noise_type: FastNoiseLite.NoiseType = FastNoiseLite.TYPE_PERLIN, frequency: float = 0.1, octaves: int = 2) -> float:
	"""Get noise value for texture generation"""
	var old_type = noise.noise_type
	var old_freq = noise.frequency
	
	noise.noise_type = noise_type
	noise.frequency = frequency
	
	var value: float = 0.0
	var amplitude: float = 1.0
	var max_value: float = 0.0
	
	for i in range(octaves):
		value += noise.get_noise_2d(x * frequency, y * frequency) * amplitude
		max_value += amplitude
		amplitude *= 0.5
		frequency *= 2.0
	
	noise.noise_type = old_type
	noise.frequency = old_freq
	
	# Normalize to 0-1 range
	return (value / max_value + 1.0) * 0.5

func apply_texture_to_color(base_color: Color, texture_value: float, strength: float = 0.2) -> Color:
	"""Apply texture variation to a color"""
	var variation = (texture_value - 0.5) * 2.0 * strength  # -strength to +strength
	return Color(
		clamp(base_color.r + variation, 0.0, 1.0),
		clamp(base_color.g + variation, 0.0, 1.0),
		clamp(base_color.b + variation, 0.0, 1.0),
		base_color.a
	)

func calculate_shading(x: float, y: float, center_x: float, center_y: float, light_x: float = -0.707, light_y: float = -0.707, ambient: float = 0.3) -> float:
	"""Calculate shading value based on surface normal and light direction"""
	var dx = x - center_x
	var dy = y - center_y
	var _dist = sqrt(dx * dx + dy * dy)
	
	if _dist < 0.001:
		return 1.0 - ambient
	
	# Normalize
	var normal_x = dx / _dist
	var normal_y = dy / _dist
	
	# Dot product with light direction
	var dot = normal_x * light_x + normal_y * light_y
	
	# Clamp and add ambient
	return clamp(dot * (1.0 - ambient) + ambient, 0.0, 1.0)

func draw_textured_rect(img: Image, x: int, y: int, w: int, h: int, base_color: Color, texture_type: String = "wood", seed_offset: int = 0) -> void:
	"""Draw rectangle with procedural texture"""
	noise.seed = 12345 + seed_offset
	
	for py in range(y, y + h):
		for px in range(x, x + w):
			if px < 0 or px >= img.get_width() or py < 0 or py >= img.get_height():
				continue
			
			var tx = px - x
			var ty = py - y
			
			var texture_value: float = 0.0
			if texture_type == "wood":
				texture_value = get_noise_value(tx * 0.5, ty * 0.5, FastNoiseLite.TYPE_PERLIN, 0.5, 2)
			elif texture_type == "stone":
				texture_value = get_noise_value(tx * 0.2, ty * 0.2, FastNoiseLite.TYPE_PERLIN, 0.2, 3)
			else:
				texture_value = get_noise_value(tx * 0.3, ty * 0.3, FastNoiseLite.TYPE_PERLIN, 0.3, 2)
			
			# Apply texture
			var color = apply_texture_to_color(base_color, texture_value, 0.2)
			
			# Apply shading
			var brightness = calculate_shading(px, py, x + w/2.0, y + h/2.0)
			color = color * brightness
			
			draw_pixel(img, px, py, color)

func draw_shaded_circle(img: Image, cx: int, cy: int, radius: int, base_color: Color, texture_type: String = "stone", seed_offset: int = 0) -> void:
	"""Draw circle with procedural texture and shading"""
	noise.seed = 12345 + seed_offset
	
	for y in range(cy - radius, cy + radius + 1):
		for x in range(cx - radius, cx + radius + 1):
			if x < 0 or x >= img.get_width() or y < 0 or y >= img.get_height():
				continue
			
			var dx = x - cx
			var dy = y - cy
			var dist_sq = dx * dx + dy * dy
			
			if dist_sq <= radius * radius:
				var tx = dx + radius
				var ty = dy + radius
				
				var texture_value: float = 0.0
				if texture_type == "stone":
					texture_value = get_noise_value(tx * 0.2, ty * 0.2, FastNoiseLite.TYPE_PERLIN, 0.2, 3)
				else:
					texture_value = get_noise_value(tx * 0.3, ty * 0.3, FastNoiseLite.TYPE_PERLIN, 0.3, 2)
				
				# Apply texture
				var color = apply_texture_to_color(base_color, texture_value, 0.2)
				
				# Apply shading (sphere shading)
				var brightness = calculate_shading(x, y, cx, cy)
				color = color * brightness
				
				draw_pixel(img, x, y, color)

func draw_pattern(img: Image, x: int, y: int, w: int, h: int, pattern_type: String, base_color: Color, pattern_color: Color, seed_offset: int = 0) -> void:
	"""Draw repeating pattern (brick, wood grain, etc.)"""
	noise.seed = 12345 + seed_offset
	
	match pattern_type:
		"brick":
			var brick_w = 8
			var brick_h = 4
			var mortar_w = 1
			
			for py in range(y, y + h):
				var row_index = (py - y) / float(brick_h + mortar_w)
				var col_offset = 0 if int(row_index) % 2 == 0 else (brick_w + mortar_w) / 2.0
				
				for px in range(x, x + w):
					var local_x = (px - x - col_offset) % (brick_w + mortar_w)
					var local_y = (py - y) % (brick_h + mortar_w)
					
					if local_x < brick_w and local_y < brick_h:
						draw_pixel(img, px, py, base_color)
					else:
						draw_pixel(img, px, py, pattern_color)  # Mortar
		"wood_grain":
			for py in range(y, y + h):
				for px in range(x, x + w):
					var tx = px - x
					var ty = py - y
					var grain = get_noise_value(tx * 0.5, ty * 0.5, FastNoiseLite.TYPE_PERLIN, 0.5, 2)
					var color = apply_texture_to_color(base_color, grain, 0.3)
					draw_pixel(img, px, py, color)

# Static method to generate assets (call this from a tool or main scene)
static func generate_assets() -> void:
	var generator = AssetGenerator.new()
	generator.generate_all_assets()
	generator.queue_free()
