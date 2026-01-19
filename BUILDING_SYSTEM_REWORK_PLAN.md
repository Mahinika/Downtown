# Building System Comprehensive Rework Plan
**Date**: January 2026  
**Status**: Planning → Implementation

## Overview

This document outlines a comprehensive rework of the building system for Downtown, focusing on making buildings more realistic, interactive, and strategically meaningful.

## Current State Analysis

### Existing Features ✅
- 8 building types (hut, fire_pit, storage_pit, tool_workshop, lumber_hut, stockpile, stone_quarry, farm)
- Basic placement and validation
- Timer-based resource effects (gathers/consumes per second)
- Visual representation with Polygon2D shapes
- Unlock system integration
- Auto-villager assignment for workplaces

### Limitations & Issues
1. **No Capacity System**: Buildings don't have capacity limits (housing, workers)
2. **Instant Production**: Resources are produced instantly every second (60x speed for testing)
3. **No Building States**: Buildings are always operational (no construction, maintenance, needs)
4. **No Worker Tracking**: Workplaces don't track assigned workers or capacity
5. **Storage System**: Storage buildings just increase capacity, don't actually store resources
6. **No Efficiency**: All buildings operate at 100% efficiency regardless of workers
7. **Simple Effects**: Only basic gather/consume effects, no ranges, bonuses, or modifiers
8. **No Prerequisites**: Only unlock system, no building prerequisites or dependencies

## Planned Improvements

### Phase 1: Foundation (Critical Features)

#### 1.1 Enhanced Building Data Structure
**Goal**: Expand building definitions with capacity, rates, and metadata

**Changes to buildings.json**:
```json
{
  "housing_capacity": 4,              // For residential buildings
  "worker_capacity": 1,               // For workplace buildings
  "production_rate": 2.0,             // Per-minute production rate
  "production_per_worker": 1.0,       // Production per assigned worker
  "storage_capacity": 100,            // For storage buildings
  "construction_time": 5.0,           // Seconds to build
  "efficiency": 1.0,                  // Base efficiency multiplier
  "prerequisites": {                  // Building requirements
    "buildings": ["hut"],
    "research": []
  }
}
```

#### 1.2 Building Capacity System
**Goal**: Implement capacity limits for housing and workers

**Features**:
- Residential buildings have `housing_capacity` (max population they support)
- Workplace buildings have `worker_capacity` (max workers they can employ)
- Track assigned workers per building
- Track population housed per building
- Prevent over-assignment

**Implementation**:
- Add capacity tracking to BuildingManager
- Update VillagerManager to respect housing capacity
- Update JobSystem to respect worker capacity
- Add capacity validation when assigning workers/residents

#### 1.3 Production Rate System
**Goal**: Implement proper per-minute production rates with accumulation

**Features**:
- Production rates defined per-minute (not per-second)
- Production accumulates over time
- Production scales with assigned workers
- Production affected by efficiency modifiers
- Update ResourceManager every second with accumulated production

**Implementation**:
- Track production accumulation per building
- Calculate production based on: `base_rate * workers_assigned * efficiency`
- Apply accumulated production to ResourceManager
- Update resource display in real-time

#### 1.4 Building State Management
**Goal**: Track building operational states

**States**:
- `OPERATIONAL`: Building is working normally
- `NEEDS_WORKERS`: Workplace needs more workers (has capacity)
- `NEEDS_RESOURCES`: Building needs resources to operate
- `FULL_CAPACITY`: Building at capacity (housing/workplace)
- `CONSTRUCTION`: Building is being built (future)

**Implementation**:
- Add state tracking to BuildingManager
- Calculate state based on workers, resources, capacity
- Emit state change signals
- Update UI to show building state

### Phase 2: Advanced Features

#### 2.1 Worker Assignment Tracking
**Goal**: Track which workers are assigned to which buildings

**Features**:
- Track assigned worker IDs per building
- Update assignment when workers are assigned/reassigned
- Update production based on actual workers assigned
- Handle worker death/reassignment

#### 2.2 Storage Building System
**Goal**: Make storage buildings actually store resources

**Features**:
- Storage buildings have storage capacity
- Resources can be stored in specific buildings
- Resource distribution system
- Storage visualization (show stored amounts)

#### 2.3 Efficiency System
**Goal**: Buildings operate at variable efficiency

**Factors**:
- Worker assignment (more workers = more efficient, up to capacity)
- Resource availability (needs resources to operate)
- Building upgrades (future)
- Location bonuses (future)

### Phase 3: Polish & Expansion

#### 3.1 Building Prerequisites
**Goal**: Buildings require other buildings or research

**Features**:
- Building prerequisites in JSON
- Validation before placement
- UI shows prerequisites

#### 3.2 Building Upgrades
**Goal**: Buildings can be upgraded for better stats

**Features**:
- Upgrade system
- Upgrade costs
- Upgrade effects

#### 3.3 Building Construction
**Goal**: Buildings take time to build

**Features**:
- Construction time
- Construction progress
- Construction state visuals

#### 3.4 Building Connections
**Goal**: Buildings interact with nearby buildings

**Features**:
- Range-based effects
- Connection bonuses
- Resource flow between buildings

## Implementation Priority

### Priority 1 (Immediate):
1. ✅ Enhanced building data structure (capacity fields)
2. ✅ Building capacity system (housing, workers)
3. ✅ Production rate system (proper per-minute rates)
4. ✅ Worker assignment tracking

### Priority 2 (Next):
5. Building state management
6. Storage building system
7. Efficiency system
8. UI updates for capacity/state

### Priority 3 (Future):
9. Building prerequisites
10. Building upgrades
11. Construction system
12. Building connections

## Files to Modify

### Data Files:
- `downtown/data/buildings.json` - Enhanced building definitions

### Script Files:
- `downtown/scripts/BuildingManager.gd` - Core building logic
- `downtown/scripts/VillagerManager.gd` - Housing capacity integration
- `downtown/scripts/JobSystem.gd` - Worker capacity integration
- `downtown/scripts/ResourceManager.gd` - Production rate integration
- `downtown/scenes/main.gd` - UI updates

### Documentation:
- `downtown/VERIFICATION_REPORT.md` - Update after changes
- `memory-bank/progress.md` - Update progress
- `memory-bank/activeContext.md` - Update current work

## Testing Checklist

- [ ] Buildings respect capacity limits
- [ ] Production rates work correctly (per-minute accumulation)
- [ ] Worker assignment respects capacity
- [ ] Housing capacity limits population growth
- [ ] Building states update correctly
- [ ] UI shows capacity and state information
- [ ] Production scales with workers
- [ ] Storage buildings store resources
- [ ] All existing features still work

## Notes

- Maintain backward compatibility where possible
- Use data-driven approach (JSON config)
- Follow existing manager pattern
- Keep performance in mind (100x100 grid, many buildings)
- Mobile-friendly UI updates
