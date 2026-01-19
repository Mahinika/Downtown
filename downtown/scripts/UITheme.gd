extends Node

## UITheme - Color tokens and typography helpers for a unified design system
##
## Provides centralized color tokens, style boxes, and UI helper functions for consistent
## visual design across the entire game interface. Implements a modern city management
## aesthetic with proper color coding for different resource types and UI states.
##
## Key Features:
## - Comprehensive color palette with semantic naming
## - Resource-specific color theming
## - Style box generation for consistent UI elements
## - Button style templates
## - Typography size helpers
##
## Usage:
##   var food_color = UITheme.get_resource_color("food")
##   var button_style = UITheme.create_button_style()
var COLORS = {
	# Background colors
	"bg": Color(0.12, 0.14, 0.18, 0.95),
	"bg_surface": Color(0.20, 0.22, 0.28, 0.95),
	"bg_primary": Color(0.15, 0.18, 0.28, 0.95),
	"bg_secondary": Color(0.18, 0.20, 0.26, 0.95),
	"bg_hover": Color(0.22, 0.24, 0.32, 0.95),
	"bg_pressed": Color(0.25, 0.27, 0.35, 0.95),

	# Border colors
	"border_primary": Color(0.35, 0.40, 0.50, 0.8),
	"border_secondary": Color(0.45, 0.50, 0.60, 0.6),

	# Text colors
	"text_primary": Color(1, 1, 1),
	"text_secondary": Color(0.85, 0.85, 0.92),
	"text_muted": Color(0.65, 0.65, 0.65),

	# Accent colors
	"accent_primary": Color(0.25, 0.60, 0.95),
	"accent_secondary": Color(0.25, 0.50, 0.90),

	# Status colors
	"status_success": Color(0.20, 0.70, 0.22),
	"status_warning": Color(0.95, 0.65, 0.15),
	"status_error": Color(0.92, 0.20, 0.20),

	# Resource-specific colors
	"resource_food": Color(0.85, 0.60, 0.30),
	"resource_wood": Color(0.45, 0.35, 0.25),
	"resource_stone": Color(0.60, 0.60, 0.65),
	"resource_population": Color(0.70, 0.85, 0.95),
	"resource_gold": Color(0.95, 0.85, 0.20)
}

func get_color(name: String) -> Color:
	if COLORS.has(name):
		return COLORS[name]
	return Color(1, 1, 1)

func get_font_size(key: String) -> int:
	var map = {"xs": 10, "sm": 12, "base": 14, "md": 16, "lg": 18, "xl": 20, "2xl": 24, "3xl": 28, "4xl": 32}
	if map.has(key):
		return map[key]
	return 12

func create_style_box(bg_color: Color, border_color: Color, border_thickness: int, radius: int, shadow: Dictionary = {}) -> StyleBoxFlat:
	var sb = StyleBoxFlat.new()
	sb.bg_color = bg_color
	sb.border_color = border_color
	sb.border_width_left = border_thickness
	sb.border_width_right = border_thickness
	sb.border_width_top = border_thickness
	sb.border_width_bottom = border_thickness
	sb.corner_radius_top_left = radius
	sb.corner_radius_top_right = radius
	sb.corner_radius_bottom_left = radius
	sb.corner_radius_bottom_right = radius
	if not shadow.is_empty():
		sb.shadow_color = shadow.get("color", Color(0,0,0,0.2))
		sb.shadow_offset = shadow.get("offset", Vector2(0,2))
		sb.shadow_size = shadow.get("size", 4)
	return sb

func create_button_style(
	normal_color: Color = get_color("bg_secondary"),
	hover_color: Color = get_color("bg_hover"),
	pressed_color: Color = get_color("bg_pressed"),
	accent_color: Color = get_color("accent_primary")
) -> Dictionary:
	return {
		"normal": create_style_box(normal_color, get_color("border_primary"), 1, 8),
		"hover": create_style_box(hover_color, accent_color, 2, 8),
		"pressed": create_style_box(pressed_color, accent_color, 2, 8),
		"disabled": create_style_box(get_color("bg_secondary").darkened(0.3), get_color("border_primary"), 1, 8)
	}

# Helper function to get resource-specific colors
func get_resource_color(resource_id: String) -> Color:
	var resource_key = "resource_" + resource_id
	if COLORS.has(resource_key):
		return COLORS[resource_key]
	return get_color("text_primary")

# Helper function to get corner radius values
func get_radius(key: String) -> int:
	var radius_map = {
		"none": 0,
		"sm": 4,
		"md": 8,
		"lg": 12,
		"xl": 16,
		"full": 999  # Very large radius for fully rounded (will be clamped by Godot)
	}
	if radius_map.has(key):
		return radius_map[key]
	return 8  # Default medium radius
