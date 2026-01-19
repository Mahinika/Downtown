# Population and Housing System Rework Plan
**Date**: January 2026  
**Status**: Planning → Implementation

## Overview

Rework the population and housing system to make population growth meaningful, housing-constrained, and more realistic.

## Current State Analysis

### Current Implementation

1. **Population**:
   - Treated as abstract resource (ResourceManager)
   - Starting: 10, Max: 100 (hard limit)
   - Growth: +2 per minute per hut (via `production_rate`)
   - No connection to actual villagers
   - No connection to housing capacity

2. **Housing**:
   - Huts have `housing_capacity: 4`
   - `housing_residents` dictionary exists but is never populated
   - Housing capacity tracked but not enforced
   - No population limit based on housing

3. **Current Issues**:
   - Population can grow infinitely (up to max_storage: 100)
   - Housing capacity is ignored
   - Population growth not constrained by housing
   - Population consumption is per-building, not per-person
   - No relationship between population and villager count
   - Abstract population vs actual villagers (confusing)

## Planned Improvements

### Phase 1: Housing-Based Population Limits

#### 1.1 Population Limit Based on Housing
**Goal**: Population can only grow up to total housing capacity

**Implementation**:
- Calculate total housing capacity from all residential buildings
- Population growth stops when at capacity
- Population cannot exceed total housing capacity
- Update population growth logic in BuildingManager

**Changes**:
- BuildingManager: Add `get_total_housing_capacity()` function
- BuildingManager: Modify population production to check housing capacity
- ResourceManager: Clamp population to housing capacity when adding

#### 1.2 Housing Assignment System
**Goal**: Track which buildings house population

**Implementation**:
- Track population per housing building (not individuals, just capacity usage)
- When population grows, assign to available housing
- When housing is removed, handle population overflow

**Changes**:
- BuildingManager: Use `housing_residents` to track capacity usage
- BuildingManager: Add housing assignment logic
- BuildingManager: Handle housing removal and population overflow

#### 1.3 Population Growth Rate
**Goal**: Make population growth more realistic

**Implementation**:
- Population growth should be per available housing, not per hut
- Growth rate based on housing capacity utilization
- Growth stops when all housing is full

**Changes**:
- BuildingManager: Update population production logic
- Huts: Growth rate based on available housing capacity

### Phase 2: Per-Person Consumption

#### 2.1 Food Consumption Per Person
**Goal**: Food consumption should be per-person, not per-building

**Implementation**:
- Calculate food consumption based on actual population
- Not per-building, but per-person
- Update consumption rates

**Changes**:
- BuildingManager: Calculate consumption based on population
- Buildings: Remove per-building food consumption
- ResourceManager: Track per-person consumption

#### 2.2 Population Display
**Goal**: Show population vs housing capacity in UI

**Implementation**:
- Display "Population: X / Y" (X = current, Y = housing capacity)
- Show housing utilization
- Warn when population is at capacity

**Changes**:
- main.gd: Update resource display to show population/housing
- Building info panel: Show housing usage

### Phase 3: Population and Villagers (Future)

#### 3.1 Population vs Villagers
**Goal**: Decide relationship between population and actual villagers

**Options**:
- **Option A**: Keep population abstract, villagers independent
  - Population = abstract number (workers, families, etc.)
  - Villagers = actual game entities
  - Population affects consumption, villagers do work

- **Option B**: Link population to villager count
  - Population = total villager count
  - Villagers spawn/despawn based on population
  - More realistic but more complex

**Recommendation**: Option A (keep separate for now)
- Simpler implementation
- Allows abstract population (families, children, elderly)
- Villagers are the "working population"
- Population is total settlement size

## Implementation Priority

1. **High Priority**:
   - Housing-based population limits (Phase 1.1)
   - Population growth constrained by housing (Phase 1.3)
   - UI updates (Phase 2.2)

2. **Medium Priority**:
   - Housing assignment tracking (Phase 1.2)
   - Per-person consumption (Phase 2.1)

3. **Low Priority** (Future):
   - Population-villager relationship (Phase 3)

## Files to Modify

- `downtown/scripts/BuildingManager.gd` - Housing/population logic
- `downtown/scripts/ResourceManager.gd` - Population limits
- `downtown/scenes/main.gd` - UI updates
- `downtown/data/buildings.json` - Housing definitions (if needed)

## Success Criteria

1. ✅ Population cannot exceed total housing capacity
2. ✅ Population growth stops when housing is full
3. ✅ Population display shows X / Y (current / capacity)
4. ✅ Housing utilization is visible in UI
5. ✅ Food consumption is per-person (or at least realistic)
