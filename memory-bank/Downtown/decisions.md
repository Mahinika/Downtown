# Architectural Decisions - Downtown City Management Game

**Project**: Downtown - Mobile City Management Game
**Engine**: Godot 4.5.1
**Platform**: Android (Primary), Cross-platform compatible
**Date**: January 2026

## Core Architecture Decisions

### 1. Manager-Based Architecture with Service Locator Pattern

**Decision**: Use 16 autoload singletons with centralized Service Locator access
**Rationale**:
- Clear separation of concerns
- Easy testing and mocking
- Centralized system coordination
- Mobile performance optimization

**Implementation**: `GameServices` singleton provides access to all managers
```gdscript
# Instead of direct autoload access:
ResourceManager.add_resource("wood", 10)

# Use service locator:
GameServices.get_economy().add_resource("wood", 10)
```

### 2. Event-Driven Communication

**Decision**: Signal-based inter-system communication
**Rationale**:
- Loose coupling between systems
- Easy to add/remove system connections
- Debuggable event flow
- Godot-native pattern

**Key Signals**:
- `resource_changed` - Resource updates trigger UI
- `building_placed` - Updates pathfinding and economy
- `population_grew` - Triggers villager spawning
- `season_changed` - Affects production and behavior

### 3. Data-Driven Game Configuration

**Decision**: JSON-based configuration for all game content
**Rationale**:
- Easy balancing and content updates
- No code changes for balance tweaks
- Mobile-friendly file format
- Human-readable and editable

**Configuration Files**:
- `buildings.json` - Building definitions, costs, production
- `resources.json` - Resource types and properties
- Research trees and progression data

### 4. Mobile-First Design Philosophy

**Decision**: Optimize for mobile from the ground up
**Rationale**:
- Target platform constraints
- Touch-friendly UI
- Performance limitations
- Battery and thermal considerations

**Mobile Optimizations**:
- Object pooling for entities
- Spatial partitioning for performance
- Compressed assets
- Efficient rendering

## Technical Implementation Decisions

### 5. GDScript with Selective C# Integration

**Decision**: Primary GDScript with C# for performance-critical systems
**Rationale**:
- GDScript ecosystem maturity
- Godot integration advantages
- C# for complex algorithms if needed
- Team familiarity and maintenance

### 6. Comprehensive Testing Strategy

**Decision**: Automated testing for all core systems
**Rationale**:
- Regression prevention
- Refactoring confidence
- Mobile deployment reliability
- Code quality assurance

**Test Coverage**:
- 41 automated pipeline tests
- Integration testing for system interactions
- Performance regression detection
- GDScript validation

### 7. Procedural Asset Generation

**Decision**: Code-generated pixel art assets
**Rationale**:
- No external art dependencies
- Consistent style across all assets
- Easy to modify and extend
- Mobile-friendly file sizes

**Asset Pipeline**:
- Godot-based sprite generation
- Node.js enhancement capabilities
- Template-based variation system

## Gameplay Design Decisions

### 8. Needs-Based Villager System

**Decision**: Hunger, happiness, health with work efficiency modifiers
**Rationale**:
- Strategic depth in resource allocation
- Emergent gameplay from villager needs
- Tutorial opportunities
- Realistic population simulation

**Need Effects**:
- **Hunger**: Reduces efficiency by up to 50%
- **Happiness**: ±20% efficiency based on satisfaction
- **Health**: -30% penalty when poor

### 9. Multi-Step Work Cycles

**Decision**: Complex job execution with pathfinding and resource management
**Rationale**:
- Realistic villager behavior
- Strategic building placement decisions
- Emergent gameplay from work cycles
- Tutorial and learning opportunities

**Work Cycle Example (Lumberjack)**:
1. Move to nearest tree
2. Harvest wood
3. Return to stockpile
4. Deposit resources
5. Repeat cycle

### 10. Research-Driven Progression

**Decision**: Technology tree unlocks buildings and improvements
**Rationale**:
- Long-term progression goals
- Replay value through different strategies
- Content pacing and discovery
- Achievement satisfaction

## UI/UX Design Decisions

### 11. Progressive Tutorial System

**Decision**: Context-aware tutorials with auto-dismiss
**Rationale**:
- New player accessibility
- Non-intrusive learning
- Automatic progression
- Retention optimization

**Tutorial Triggers**:
- First villager spawn
- First building placement
- Villager hunger warnings
- Resource production milestones

### 12. Rich Tooltip System

**Decision**: Detailed hover information for all interactive elements
**Rationale**:
- Information accessibility
- Reduced need for external documentation
- Enhanced strategic decision making
- Professional polish

**Tooltip Content**:
- Building costs, production rates, upgrade paths
- Villager status, job, efficiency modifiers
- Resource production/consumption rates

## Performance Decisions

### 13. Object Pooling for Entities

**Decision**: Pool villager and building instances
**Rationale**:
- Mobile memory constraints
- Instantiation performance
- Garbage collection reduction
- Smooth scaling to large populations

### 14. Spatial Partitioning

**Decision**: Grid-based spatial queries
**Rationale**:
- Efficient collision detection
- Fast neighbor queries
- Scalable to large cities
- Mobile CPU optimization

### 15. Cached Pathfinding

**Decision**: Cache navigation paths with invalidation
**Rationale**:
- Expensive A* calculations
- Building placement changes paths
- Mobile CPU limitations
- Smooth villager movement

## Content Design Decisions

### 16. 8 Specialized Job Types

**Decision**: Unique professions with distinct work cycles
**Rationale**:
- Strategic specialization choices
- Resource diversity requirements
- Building interdependence
- Economic complexity

**Job Specializations**:
- **Lumberjack**: Tree harvesting
- **Miner**: Stone extraction
- **Farmer**: Food production
- **Miller/Brewer/Smoker**: Food processing
- **Blacksmith**: Tool production
- **Engineer**: Research acceleration

### 17. Housing-Driven Population Growth

**Decision**: Population limited by housing capacity
**Rationale**:
- Clear progression requirements
- Strategic building placement
- Resource allocation decisions
- Natural growth pacing

## Future-Proofing Decisions

### 18. Modular System Design

**Decision**: Systems designed for easy extension
**Rationale**:
- New content addition simplicity
- Feature flag capabilities
- Mod support foundation
- Maintenance ease

### 19. Comprehensive Save System

**Decision**: Full state persistence with migration support
**Rationale**:
- Player progress protection
- Cross-session continuity
- Update compatibility
- Mobile app expectations

### 20. Cross-Platform Architecture

**Decision**: Design for multiple platforms from start
**Rationale**:
- Future platform expansion ease
- Code reusability
- Testing across platforms
- Market reach maximization

## Risk Mitigation Decisions

### 21. Automated Testing Pipeline

**Decision**: Comprehensive CI/CD with automated testing
**Rationale**:
- Regression prevention
- Deployment confidence
- Code quality maintenance
- Team scaling support

### 22. Incremental Architecture Evolution

**Decision**: Phased refactoring with backward compatibility
**Rationale**:
- Risk reduction for large changes
- Working system maintenance
- User experience continuity
- Technical debt management

### 23. Mobile Performance First

**Decision**: Performance testing on target hardware
**Rationale**:
- Mobile platform constraints
- User experience criticality
- App store requirements
- Battery life considerations

## Conclusion

These architectural decisions provide a solid foundation for Downtown as a mobile city management game. The manager-based architecture with Service Locator pattern, combined with comprehensive testing and mobile-first design, ensures a maintainable, scalable, and performant codebase.

The data-driven approach and event-driven communication enable rapid iteration and content expansion, while the focus on user experience through progressive tutorials and rich tooltips ensures accessibility for new players.

---

**Review Date**: January 2026
**Status**: All decisions implemented and validated
**Next Review**: Content expansion phase