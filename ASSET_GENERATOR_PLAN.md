# Asset Generator Architecture Plan

## Overview

Create a unified asset generation system for Downtown city management game, starting with worldmap/terrain tiles. The system will generate all game assets (sprites, icons, tiles) using Node.js and Canvas 2D API, following the proven pattern from Road of War project.

**Art Style**: Pixel art, minimalistic, top-down view  
**Primary Target**: Stone Age prototype  
**Generation Type**: Fully procedural  
**Platform**: Node.js build-time generation (assets created before runtime)

---

## Architecture Design

### Core Principles

1. **Unified Entry Point**: Single `unified-asset-generator.js` - all asset generation routes through this
2. **Base Class Pattern**: All generators extend `BaseGenerator` for consistency
3. **Shared Utilities**: Common utilities (canvas, color) shared across generators
4. **Data-Driven**: JSON configuration for asset definitions and parameters
5. **Extensible**: Easy to add new asset types by creating new generator classes

### File Structure

```
Downtown/
├── tools/
│   ├── unified-asset-generator.js       # Single entry point (ORCHESTRATOR)
│   ├── generators/
│   │   ├── base-generator.js            # Base class with shared functionality
│   │   ├── worldmap-generator.js        # Phase 1: Terrain tiles
│   │   ├── building-sprite-generator.js # Phase 2: Building sprites
│   │   └── resource-icon-generator.js   # Phase 3: Resource icons
│   ├── utils/
│   │   ├── canvas-utils.js              # Canvas operations
│   │   └── color-utils.js               # Color manipulation & palettes
│   └── README.md                        # Usage documentation
├── downtown/
│   └── assets/
│       ├── tiles/                       # Generated terrain tiles
│       ├── buildings/                   # Generated building sprites
│       └── icons/                       # Generated resource icons
├── package.json                         # Node.js dependencies
└── ASSET_GENERATOR_PLAN.md             # This document
```

---

## Phase 1: Foundation & Worldmap Generator

### Step 1.1: Node.js Project Setup

**Tasks**:
- Create `tools/` directory structure
- Create `package.json` with dependencies
- Set up ES modules (type: "module")
- Create basic directory structure

**Dependencies**:
- `canvas` (node-canvas) - Canvas 2D API for image generation
- `fs-extra` - Enhanced file system operations (optional, can use built-in `fs`)

**Output**: Working Node.js project structure

### Step 1.2: Base Generator Class

**File**: `tools/generators/base-generator.js`

**Purpose**: Shared base class that all generators extend

**Key Features**:
- Canvas initialization helpers
- File I/O utilities (save PNG, create directories)
- Common pixel art drawing functions
- Error handling and logging
- Base `generate()` method signature

**Methods**:
- `setupCanvas(width, height)` - Create canvas context
- `savePNG(canvas, filepath)` - Save canvas to PNG file
- `ensureDirectory(dirpath)` - Create directory if missing
- `generate(data, options)` - Abstract method (override in subclasses)

**Output**: Reusable base class for all generators

### Step 1.3: Color Utilities

**File**: `tools/utils/color-utils.js`

**Purpose**: Color manipulation and palette management

**Key Features**:
- Stone Age earth tone palette definitions
- Color conversion (hex ↔ rgb)
- Color manipulation (lighten, darken, mix, adjust saturation)
- Procedural color variation functions
- Palette-specific color selection

**Stone Age Palette**:
```javascript
const STONE_AGE_PALETTE = {
  grass: ['#6B7A4F', '#5A6B44', '#4A5A38', '#7A8A5F'],
  dirt: ['#8B6F47', '#7A5F3A', '#6A4F2F', '#9B7F57'],
  stone: ['#7A7A7A', '#6A6A6A', '#5A5A5A', '#8A8A8A'],
  water: ['#5A7A8A', '#4A6A7A', '#6A8A9A', '#3A5A6A']
};
```

**Functions**:
- `hexToRgb(hex)` - Convert hex to RGB
- `rgbToHex(r, g, b)` - Convert RGB to hex
- `lightenHex(hex, amount)` - Lighten color
- `darkenHex(hex, amount)` - Darken color
- `mixHex(hex1, hex2, ratio)` - Mix two colors
- `getPaletteColor(palette, index)` - Get color from palette
- `randomVariation(baseColor, variance)` - Procedural color variation

**Output**: Reusable color utilities

### Step 1.4: Canvas Utilities

**File**: `tools/utils/canvas-utils.js`

**Purpose**: Canvas operations and drawing helpers

**Key Features**:
- Canvas context setup with pixel-perfect rendering
- Pixel art drawing functions (pixel, line, rect, circle)
- Pattern/texture generation helpers
- Batch processing utilities

**Functions**:
- `setupCanvasContext(canvas)` - Configure for pixel art (imageSmoothingEnabled: false)
- `drawPixel(ctx, x, y, color)` - Draw single pixel
- `drawRect(ctx, x, y, w, h, color)` - Draw rectangle
- `drawCircle(ctx, x, y, radius, color)` - Draw circle
- `fillPattern(ctx, patternFn, bounds)` - Fill area with pattern
- `resolveResPath(path)` - Convert res:// paths to file system paths

**Output**: Reusable canvas utilities

### Step 1.5: Unified Asset Generator Entry Point

**File**: `tools/unified-asset-generator.js`

**Purpose**: Single entry point for all asset generation

**Key Features**:
- Routes generation requests to appropriate generators
- Batch generation support
- Command-line interface
- Generator registry

**Structure**:
```javascript
class UnifiedAssetGenerator {
  constructor() {
    this.generators = {
      'worldmap': WorldmapGenerator,
      'building': BuildingSpriteGenerator, // Future
      'resource': ResourceIconGenerator    // Future
    };
  }
  
  async generate(type, data, options) {
    // Route to appropriate generator
  }
  
  async generateAll(config) {
    // Batch generate all assets
  }
}
```

**Usage**:
- Command line: `node tools/unified-asset-generator.js worldmap`
- Programmatic: `await generator.generate('worldmap', config, options)`

**Output**: Unified entry point system

### Step 1.6: Worldmap Generator

**File**: `tools/generators/worldmap-generator.js`

**Purpose**: Generate terrain tiles for Stone Age worldmap

**Terrain Types**:
1. **Grass** - Base terrain (4-5 variations)
2. **Dirt** - Paths/cleared areas (3-4 variations)
3. **Stone** - Rock/hard terrain (3-4 variations)
4. **Water** - Rivers/lakes (3-4 variations)

**Tile Specifications**:
- Size: 32x32 pixels
- Format: PNG with transparency support
- Style: Pixel art, minimalistic, top-down view
- Variations: 3-5 per terrain type (procedurally generated)
- Seamless: Tiles should tile seamlessly

**Generation Approach**:
1. **Base Pattern Generation**:
   - Grass: Dotted/textured pattern with color variation
   - Dirt: Grainy texture with earth tones
   - Stone: Rock-like patterns with gray tones
   - Water: Wave/ripple patterns with blue-green tones

2. **Procedural Variation System**:
   - Random seed for uniqueness
   - Color shifts within palette
   - Pattern density variations
   - Texture variations (noise, patterns)

3. **Top-Down Rendering**:
   - Flat appearance (no perspective)
   - Clear tile boundaries
   - Seamless edges for tiling
   - High contrast for readability

**Output Structure**:
```
downtown/assets/tiles/
├── grass_0.png
├── grass_1.png
├── grass_2.png
├── grass_3.png
├── dirt_0.png
├── dirt_1.png
├── dirt_2.png
├── stone_0.png
├── stone_1.png
├── stone_2.png
├── water_0.png
├── water_1.png
├── water_2.png
└── tileset.json              # Metadata for Godot TileSet
```

**Tileset JSON Format**:
```json
{
  "tileset_name": "stone_age_terrain",
  "tile_size": 32,
  "tiles": {
    "grass": [
      {"file": "grass_0.png", "id": 0},
      {"file": "grass_1.png", "id": 1},
      {"file": "grass_2.png", "id": 2},
      {"file": "grass_3.png", "id": 3}
    ],
    "dirt": [
      {"file": "dirt_0.png", "id": 4},
      {"file": "dirt_1.png", "id": 5},
      {"file": "dirt_2.png", "id": 6}
    ],
    "stone": [...],
    "water": [...]
  }
}
```

**Methods**:
- `generateGrassTile(seed)` - Generate grass tile variation
- `generateDirtTile(seed)` - Generate dirt tile variation
- `generateStoneTile(seed)` - Generate stone tile variation
- `generateWaterTile(seed)` - Generate water tile variation
- `generateAllTiles(options)` - Generate all terrain tiles
- `generateTilesetJSON()` - Generate TileSet metadata

**Output**: Complete terrain tile set (12-16 tiles) + metadata

---

## Implementation Order

### Phase 1: Foundation (Day 1)
1. ✅ Node.js project setup (package.json, dependencies)
2. ✅ Base generator class (`base-generator.js`)
3. ✅ Color utilities (`color-utils.js`)
4. ✅ Canvas utilities (`canvas-utils.js`)

### Phase 2: Worldmap Generator (Day 1-2)
5. ✅ Unified asset generator entry point (`unified-asset-generator.js`)
6. ✅ Worldmap generator (`worldmap-generator.js`)
7. ✅ Generate all terrain tiles
8. ✅ Generate TileSet JSON metadata

### Phase 3: Integration & Testing (Day 2)
9. ✅ npm scripts for running generators
10. ✅ Documentation (README.md)
11. ✅ Test generation and verify output
12. ✅ Verify tiles work in Godot TileSet

---

## Technical Specifications

### Node.js Setup

**package.json**:
```json
{
  "name": "downtown-asset-generator",
  "version": "1.0.0",
  "type": "module",
  "scripts": {
    "generate:worldmap": "node tools/unified-asset-generator.js worldmap",
    "generate:all": "node tools/unified-asset-generator.js all"
  },
  "dependencies": {
    "canvas": "^2.11.2",
    "fs-extra": "^11.2.0"
  }
}
```

### Canvas Configuration

- **Pixel Art Mode**: `imageSmoothingEnabled: false`
- **Antialiasing**: Disabled for crisp pixels
- **Transparency**: Supported (PNG with alpha channel)
- **Color Depth**: 32-bit RGBA

### File Naming Conventions

- Tiles: `{terrain_type}_{variation_index}.png` (e.g., `grass_0.png`)
- Buildings: `{building_id}.png` (e.g., `hut.png`)
- Icons: `{resource_id}_icon.png` (e.g., `food_icon.png`)

### Output Directory Structure

- All generated assets go to `downtown/assets/`
- Organized by type: `tiles/`, `buildings/`, `icons/`
- JSON metadata alongside assets
- Godot `.import` files generated automatically

---

## Design Decisions

### 1. Why Node.js/Canvas over Godot-based generation?
- **Build-time generation**: Assets created once, not at runtime
- **Better performance**: Pre-generated assets = smaller runtime overhead
- **Easier automation**: Can run as build step, CI/CD friendly
- **Proven pattern**: Road of War uses this successfully

### 2. Why Unified Architecture?
- **Consistency**: All generators follow same patterns
- **Maintainability**: Shared utilities reduce duplication
- **Extensibility**: Easy to add new asset types
- **Single entry point**: Simple to use and document

### 3. Why 32x32 Tile Size?
- **Standard**: Common size for grid-based games
- **Performance**: Good balance of detail vs. performance
- **Mobile-friendly**: Readable on small screens
- **Scalable**: Can create higher-res versions later if needed

### 4. Why Fully Procedural?
- **Variety**: Generate many variations without manual work
- **Consistency**: Same algorithm ensures consistent style
- **Flexibility**: Easy to adjust parameters and regenerate
- **Scalability**: Can generate new variations on demand

### 5. Why Pixel Art Style?
- **Performance**: Small file sizes, fast rendering
- **Mobile-friendly**: Works well on Android devices
- **Timeless**: Pixel art doesn't age as quickly
- **Clear**: Simple, readable visuals for city management

---

## Success Criteria

### Phase 1 Complete When:
- ✅ Node.js project structure in place
- ✅ Base generator class working
- ✅ Color and canvas utilities functional
- ✅ Unified asset generator routing working
- ✅ Worldmap generator creates all terrain tiles
- ✅ Tiles are 32x32 PNG files
- ✅ Tiles use Stone Age earth tone palette
- ✅ Tiles are seamless (tile properly)
- ✅ TileSet JSON metadata generated
- ✅ npm scripts work (`npm run generate:worldmap`)
- ✅ Tiles can be imported into Godot TileSet

### Quality Checks:
- All tiles are pixel-perfect (no anti-aliasing artifacts)
- Color palette is consistent across all tiles
- Tiles tile seamlessly (no visible seams when repeated)
- File sizes are reasonable (< 5KB per tile)
- Tiles are readable and distinguishable
- Metadata JSON is valid and complete

---

## Future Phases (Not in Current Scope)

### Phase 2: Building Sprite Generator
- Generate building sprites (Hut, Fire Pit, Storage Pit, Tool Workshop)
- 64x64 pixel sprites
- Stone Age style, top-down view
- Variations for building upgrades (future)

### Phase 3: Resource Icon Generator
- Generate resource icons (Food, Wood, Stone, Population)
- 48x48 pixel icons
- Simple, recognizable symbols
- Consistent with game style

### Phase 4: UI Icon Generator
- Generate UI icons (buttons, panels, etc.)
- Various sizes as needed
- Consistent style guide

---

## Documentation Requirements

### README.md (tools/README.md)
- Overview of asset generation system
- Installation instructions
- Usage examples
- Generator documentation
- Troubleshooting

### Code Documentation
- JSDoc comments for all public methods
- Inline comments for complex algorithms
- Examples in code comments

---

## Testing Strategy

### Manual Testing
- Generate tiles and visually inspect
- Verify seamless tiling
- Check color consistency
- Verify file sizes and formats
- Test Godot TileSet import

### Automated Testing (Future)
- Unit tests for color utilities
- Unit tests for canvas utilities
- Integration tests for generators
- Validation tests for output files

---

## Notes

- **Development Workflow**: Run generators during development, commit generated assets to git
- **Version Control**: Generated assets are committed (not gitignored) for consistency
- **Regeneration**: Can regenerate assets anytime by running generators
- **Hot Reload**: Godot will auto-reimport assets when files change
- **Performance**: Pre-generated assets = zero runtime generation cost

---

## Next Steps After Plan Approval

1. Review and approve this plan
2. Create Node.js project structure
3. Implement base generator architecture
4. Implement worldmap generator
5. Test and iterate
6. Document usage
7. Move to Phase 2 (building sprites) or start game implementation

---

**Plan Created**: January 2026  
**Status**: Awaiting approval  
**Next Step**: Implementation (after plan approval)
