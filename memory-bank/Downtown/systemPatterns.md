# System Patterns - Downtown City Management Game

## Current Managers (16 Autoloads)

The Downtown project uses a comprehensive manager-based architecture with 16 autoload singletons that handle all major game systems.

### Core Game Systems (6)
1. **DataManager** - JSON data loading and caching for buildings, resources, and configuration
2. **CityManager** - Grid-based city layout, pathfinding, and spatial management
3. **ResourceManager** - Resource tracking and production/consumption calculations
4. **BuildingManager** - Building placement, upgrades, and production management
5. **VillagerManager** - Villager entity management and job assignment
6. **ResourceNodeManager** - Natural resource nodes (trees, stone, berry bushes) placement and harvesting

### Specialized Systems (5)
7. **JobSystem** - Work cycle management and task assignment for villagers
8. **SkillManager** - Villager skill progression and experience tracking
9. **SaveManager** - Game state serialization and save/load functionality
10. **ProgressionManager** - Goal tracking, research unlocks, and building availability
11. **ResearchManager** - Research projects and technology progression

### Simulation & Events (3)
12. **SeasonalManager** - Seasonal effects, weather, and environmental changes
13. **EventManager** - Random events and story-driven occurrences
14. **PopularityManager** - Population growth, happiness, and migration mechanics

### UI & Assets (2)
15. **UITheme** - Centralized UI theme tokens and color system
16. **UIBuilder** - Comprehensive UI component creation and management

## Architecture Overview

### Service Locator Pattern
The project uses a Service Locator pattern implemented through the `GameServices` singleton, which provides centralized access to all manager systems. This replaces the previous direct autoload dependencies and provides better decoupling and testability.

### Event-Driven Communication
Systems communicate primarily through Godot signals, enabling loose coupling between managers. Key signal connections:
- Resource changes trigger UI updates
- Building placement affects pathfinding and resource calculations
- Population growth triggers villager spawning
- Seasonal changes affect resource production and villager behavior

### Data-Driven Design
Game configuration uses JSON files for:
- Building definitions (buildings.json)
- Resource definitions (resources.json)
- Research trees and progression
- Balance values and game constants

## Job Types (8 Complete)

All 8 job types are fully implemented with complete work cycles:

1. **Lumberjack** - Harvests wood from trees with full pathfinding
2. **Miner** - Extracts stone from rock deposits
3. **Farmer** - Produces food at farms (stationary work cycle)
4. **Miller** - Processes wheat into flour
5. **Brewer** - Converts wheat into beer
6. **Smoker** - Preserves food for long-term storage
7. **Blacksmith** - Crafts stone into tools
8. **Engineer** - Research and technology advancement

## Building Types (12+)

Current building roster includes:
- Housing: Hut, House, Apartment, Tenement, Manor
- Production: Farm, Lumber Hut, Quarry, Mill, Brewery, Smokehouse, Blacksmith, Advanced Workshop
- Infrastructure: Stockpile, Well, Market
- Special: Town Hall, Research Center

## Technical Specifications

### Performance Optimizations
- Object pooling for villager entities
- Spatial partitioning for collision detection
- Cached pathfinding results
- Lazy loading of assets and data

### Mobile Optimization
- Touch-friendly UI controls
- Optimized rendering for mobile GPUs
- Battery-efficient background processing
- Compressed asset formats

### Testing Framework
- Comprehensive automated test suite
- Integration tests for system interactions
- Performance regression testing
- GDScript syntax validation

## Development Status

### Completed Systems ✅
- Core gameplay loop (resource production, population management)
- Advanced AI with pathfinding and work cycles
- Comprehensive UI/UX with tooltips and tutorials
- Save/load system with full state persistence
- Research and progression systems
- Seasonal simulation and events

### Current Architecture ✅
- Service Locator pattern implementation
- Event-driven communication
- Data-driven configuration
- Mobile-optimized performance
- Comprehensive testing coverage

### Quality Assurance ✅
- Zero critical GDScript errors
- All 41 pipeline tests passing
- Mobile deployment configuration verified
- Asset generation pipeline operational