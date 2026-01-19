# Downtown Game - Complete Pipeline Analysis

## Overview
This document traces the complete game pipeline from initialization through all gameplay systems, data flows, and update loops.

---

## 1. INITIALIZATION PHASE

### 1.1 Autoload Managers (Singleton Initialization)
**Order of Initialization:**
1. **DataManager** - Loads all JSON data (resources, buildings, research, etc.)
2. **CityManager** - Initializes grid system and world coordinates
3. **ResourceManager** - Initializes resource tracking with starting amounts
4. **ResourceNodeManager** - Manages harvestable resource nodes (trees, stone)
5. **BuildingManager** - Sets up building system, caches data, starts resource timer
6. **VillagerManager** - Initializes villager tracking
7. **JobSystem** - Sets up job assignment system
8. **ProgressionManager** - Initializes goals, achievements, unlocked buildings
9. **SkillManager** - Initializes skill system
10. **ResearchManager** - Loads research data
11. **EventManager** - Sets up event system
12. **SeasonalManager** - Initializes seasons and weather
13. **SaveManager** - Sets up save/load system
14. **UITheme** - Loads UI styling
15. **UIBuilder** - UI creation utilities
16. **AssetGenerator** - Asset generation system

### 1.2 Main Scene (_ready())
**File:** `downtown/scenes/main.gd`

**Initialization Steps:**
1. Initialize Camera2D (center on world)
2. Create GridContainer for game objects
3. Create UI (resource HUD, building panel, bottom nav)
4. Connect manager signals
5. Connect seasonal events
6. Update resource displays
7. Load existing buildings (from save)
8. Generate world (resource nodes) - *currently disabled*
9. Spawn initial villagers - *currently disabled*

**Signal Connections:**
- `ResourceManager.resource_changed` → `_on_resource_changed()`
- `ProgressionManager.building_unlocked` → `_on_building_unlocked()`
- `ProgressionManager.goal_completed` → `_on_goal_completed()`
- `SeasonalManager.season_changed` → `_on_season_changed()`
- `SeasonalManager.weather_changed` → `_on_weather_changed()`
- `SeasonalManager.seasonal_event_triggered` → `_on_seasonal_event()`
- `EventManager.event_triggered` → `_on_event_triggered()`
- `ResearchManager.research_completed` → `_on_research_completed()`
- `ResearchManager.technology_unlocked` → `_on_technology_unlocked()`
- `SaveManager.game_saved` → `_on_game_saved()`
- `SaveManager.game_loaded` → `_on_game_loaded()`

---

## 2. MAIN GAME LOOP

### 2.1 Update Loop (_process)
**File:** `downtown/scenes/main.gd:2776`

**Update Frequency:** Every frame (~60 FPS)

**Update Tasks:**
1. **Villager Count Display** - Update population counter
2. **Seasonal Display** - Update season/weather badge
3. **Research Display** - Update research progress indicator
4. **Resource Displays** - Throttled update (every 500ms)
5. **Building Preview** - Update placement preview position/color

### 2.2 Physics Loop (_physics_process)
**File:** `downtown/scripts/Villager.gd`

**Update Frequency:** Physics rate (default 60 Hz)

**Villager Updates:**
- Movement (CharacterBody2D physics)
- Pathfinding updates
- State machine transitions
- Work cycle execution
- Needs system (hunger/happiness)

### 2.3 Resource Production Timer
**File:** `downtown/scripts/BuildingManager.gd:141`

**Update Frequency:** Every 1.0 second (represents 1 game minute)

**Timer Callback:** `_on_resource_tick()`

**Process:**
1. Iterate through all placed buildings
2. Check building state (operational, needs workers, etc.)
3. Apply production effects (gathers resources)
4. Apply consumption effects (consumes resources)
5. Handle processing chains (mills, workshops)
6. Update building states

---

## 3. RESOURCE PRODUCTION/CONSUMPTION PIPELINE

### 3.1 Production Flow

```
BuildingManager._on_resource_tick()
  ↓
For each building:
  ↓
Check building state (OPERATIONAL?)
  ↓
Get building effects (production_rate)
  ↓
Calculate production amount (rate * workers * efficiency)
  ↓
Accumulate in production_accumulation[building_id]
  ↓
When whole units accumulated:
  ↓
ResourceManager.add_resource(resource_id, amount)
  ↓
ResourceManager emits resource_changed signal
  ↓
main.gd._on_resource_changed() updates UI
```

### 3.2 Consumption Flow

```
BuildingManager._on_resource_tick()
  ↓
For each building:
  ↓
Get consumption_rate from building data
  ↓
ResourceManager.consume_resource(resource_id, amount)
  ↓
If insufficient resources:
  ↓
Set building state to NEEDS_RESOURCES
  ↓
ResourceManager emits resource_changed signal
  ↓
UI updates
```

### 3.3 Processing Chains (Advanced Buildings)

**Example: Mill (Wheat → Flour)**

```
BuildingManager._on_resource_tick()
  ↓
Check if building is processing type
  ↓
Check if input resources available (wheat)
  ↓
Accumulate processing time
  ↓
When processing complete:
  ↓
Consume input (wheat)
  ↓
Produce output (flour)
  ↓
ResourceManager updates both resources
```

---

## 4. BUILDING SYSTEM PIPELINE

### 4.1 Building Placement Flow

```
User clicks building card
  ↓
main.gd.select_building(building_type)
  ↓
Set selected_building_type
  ↓
Enter UIState.PLACEMENT
  ↓
Hide building panel
  ↓
User clicks on grid
  ↓
main.gd.handle_building_placement()
  ↓
Convert screen → world → grid position
  ↓
BuildingManager.can_place_building()
  ├─ Check building unlocked
  ├─ Check resources available
  └─ Check grid position valid
  ↓
BuildingManager.place_building()
  ├─ Pay costs (ResourceManager.pay_costs())
  ├─ Register building in placed_buildings
  ├─ Create building visual
  ├─ Apply building effects
  ├─ Assign workers (if needed)
  └─ Emit building_created signal
  ↓
main.gd updates UI
  ↓
Exit UIState.PLACEMENT
```

### 4.2 Building Production Flow

```
BuildingManager._on_resource_tick() (every 1 second)
  ↓
For each building:
  ↓
Check building state
  ↓
If OPERATIONAL:
  ↓
Get assigned workers
  ↓
Calculate production = rate * workers * efficiency
  ↓
Apply production effects
  ↓
If needs workers:
  ↓
JobSystem.assign_villager_to_building()
  ↓
Villager assigned to work
```

### 4.3 Building Upgrade Flow

```
User clicks upgrade button
  ↓
main.gd._on_building_upgrade_pressed()
  ↓
BuildingManager.start_building_upgrade()
  ├─ Check upgrade requirements
  ├─ Pay upgrade costs
  ├─ Set building state to CONSTRUCTION
  └─ Start upgrade timer
  ↓
BuildingManager._process() (upgrade timer)
  ↓
When timer completes:
  ├─ Increase building level
  ├─ Update building data
  ├─ Set state to OPERATIONAL
  └─ Apply upgrade bonuses
```

---

## 5. VILLAGER SYSTEM PIPELINE

### 5.1 Villager Spawning

```
BuildingManager detects housing capacity
  OR
ProgressionManager goal completion
  ↓
VillagerManager.spawn_villager()
  ├─ Create unique villager_id
  ├─ Instantiate villager scene
  ├─ Set position
  ├─ Initialize needs (hunger, happiness)
  └─ Add to villagers dictionary
  ↓
Villager._ready()
  ├─ Setup visual (sprite or Polygon2D)
  ├─ Setup collision
  └─ Initialize state machine
  ↓
VillagerManager emits villager_spawned signal
```

### 5.2 Job Assignment Flow

```
Building placed with worker_capacity
  ↓
BuildingManager.apply_building_effects()
  ↓
JobSystem.assign_villager_to_building()
  ├─ Find available villager
  ├─ Check building capacity
  ├─ Assign villager to building
  ├─ Create work cycle tasks
  └─ Emit job_assigned signal
  ↓
Villager receives work tasks
  ↓
Villager state → WORKING
```

### 5.3 Work Cycle Execution

**Example: Lumberjack**

```
Villager._physics_process()
  ↓
Check current task
  ↓
Task 1: MOVE_TO (tree location)
  ├─ Pathfind to tree
  ├─ Move using CharacterBody2D
  └─ When reached → Next task
  ↓
Task 2: HARVEST_RESOURCE (wood)
  ├─ Wait at tree (harvest time)
  ├─ Add wood to carrying_resource
  └─ When complete → Next task
  ↓
Task 3: MOVE_TO (stockpile)
  ├─ Find nearest stockpile
  ├─ Pathfind to stockpile
  └─ When reached → Next task
  ↓
Task 4: DEPOSIT_RESOURCE
  ├─ ResourceManager.add_resource("wood", amount)
  ├─ Clear carrying_resource
  └─ When complete → Next task
  ↓
Task 5: RETURN_TO_WORKPLACE
  ├─ Pathfind to lumber hut
  └─ When reached → Cycle complete
  ↓
JobSystem.create_lumberjack_work_cycle() (new cycle)
```

### 5.4 Villager Needs System

```
Villager._physics_process() (every frame)
  ↓
Update hunger (decreases over time)
  ↓
If hunger < threshold:
  ├─ Decrease happiness
  ├─ Find food source
  └─ Move to food
  ↓
When at food source:
  ├─ Consume food
  ├─ Increase hunger
  └─ Increase happiness
  ↓
Calculate total happiness:
  ├─ Housing quality
  ├─ Job satisfaction
  ├─ Food status
  ├─ Public services
  └─ Overcrowding penalty
```

---

## 6. UI UPDATE PIPELINE

### 6.1 Resource Display Updates

```
ResourceManager.resource_changed signal
  ↓
main.gd._on_resource_changed()
  ↓
update_resource_display(resource_id)
  ├─ Get current amount
  ├─ Find resource card in UI
  └─ Update card value label
  ↓
Throttled update (every 500ms in _process)
  ↓
update_all_resource_displays()
  ├─ Update all resource cards
  ├─ Update building card affordability colors
  └─ Update resource rate tracking
```

### 6.2 Building Panel Updates

```
Building unlocked
  ↓
ProgressionManager.building_unlocked signal
  ↓
main.gd._on_building_unlocked()
  ↓
populate_buildings_menu()
  ├─ Get unlocked buildings
  ├─ Filter by category/search
  ├─ Sort favorites first
  └─ Create building cards
  ↓
User clicks building card
  ↓
select_building()
  ↓
Enter placement mode
```

### 6.3 Panel Refresh Flow

```
Research completed
  ↓
ResearchManager.research_completed signal
  ↓
main.gd._on_research_completed()
  ↓
UIBuilder.refresh_research_panel()
  ├─ Clear existing cards
  ├─ Get updated research data
  └─ Repopulate cards
```

---

## 7. EVENT SYSTEM PIPELINE

### 7.1 Event Triggering

```
EventManager._process() (periodic checks)
  OR
BuildingManager (resource shortage)
  OR
SeasonalManager (weather events)
  ↓
EventManager.trigger_event()
  ├─ Select event type
  ├─ Generate event data
  └─ Emit event_triggered signal
  ↓
main.gd._on_event_triggered()
  ├─ Add to event_history
  ├─ Refresh events panel (if open)
  └─ Show toast notification
```

### 7.2 Event Effects

```
Event triggered
  ↓
Event type determines effect:
  ├─ resource_bonus → Add resources
  ├─ resource_shortage → Consume resources
  ├─ visitor → Temporary bonus
  └─ weather → Seasonal effects
  ↓
Apply effects immediately
  ↓
Update UI
```

---

## 8. RESEARCH SYSTEM PIPELINE

### 8.1 Research Activation

```
User opens research panel
  ↓
User clicks research card
  ↓
ResearchManager.start_research()
  ├─ Check prerequisites
  ├─ Check resources available
  ├─ Pay research costs
  ├─ Set research as active
  └─ Start research timer
  ↓
ResearchManager._process()
  ├─ Update research progress
  └─ Check completion
  ↓
When complete:
  ├─ Apply research bonuses
  ├─ Unlock technologies
  ├─ Emit research_completed signal
  └─ Update UI
```

### 8.2 Research Bonuses

```
Research completed
  ↓
ResearchManager applies bonuses
  ├─ Production speed bonuses
  ├─ Efficiency bonuses
  └─ Unlock new buildings
  ↓
BuildingManager.update_research_bonuses()
  ├─ Update building efficiency
  └─ Apply speed multipliers
```

---

## 9. SAVE/LOAD PIPELINE

### 9.1 Save Flow

```
User presses F5 or clicks Save
  ↓
SaveManager.save_game()
  ├─ Serialize all managers:
  │  ├─ ResourceManager (resources, capacities)
  │  ├─ BuildingManager (placed buildings, states)
  │  ├─ VillagerManager (villagers, jobs)
  │  ├─ ProgressionManager (goals, unlocks)
  │  ├─ ResearchManager (completed research)
  │  ├─ SkillManager (skill levels)
  │  └─ SeasonalManager (current season)
  ├─ Write to JSON file
  └─ Emit game_saved signal
```

### 9.2 Load Flow

```
User presses F9 or clicks Load
  ↓
SaveManager.load_game()
  ├─ Read JSON file
  ├─ Deserialize data
  ├─ Restore all managers:
  │  ├─ ResourceManager.set_resource()
  │  ├─ BuildingManager (recreate buildings)
  │  ├─ VillagerManager (respawn villagers)
  │  └─ Other managers restore state
  └─ Emit game_loaded signal
  ↓
main.gd._on_game_loaded()
  ├─ Reload building visuals
  ├─ Reload villager visuals
  ├─ Reload resource node visuals
  └─ Update all UI displays
```

---

## 10. DATA FLOW SUMMARY

### 10.1 Resource Flow
```
Resource Nodes → Villagers Harvest → Carrying → Deposit → ResourceManager
                                                              ↓
                                                         Building Production
                                                              ↓
                                                         Building Consumption
                                                              ↓
                                                         UI Display
```

### 10.2 Building Flow
```
User Selection → Validation → Cost Payment → Placement → Visual Creation
                                                              ↓
                                                         Effect Application
                                                              ↓
                                                         Worker Assignment
                                                              ↓
                                                         Production Start
```

### 10.3 Villager Flow
```
Spawn → Needs System → Job Assignment → Work Cycle → Resource Gathering
                                                              ↓
                                                         Deposit Resources
                                                              ↓
                                                         Return to Work
```

---

## 11. PERFORMANCE OPTIMIZATIONS

### 11.1 Caching
- **BuildingManager**: Caches buildings_data and resources_data
- **DataManager**: Caches loaded JSON files
- **Work cycles**: Cached in JobSystem

### 11.2 Throttling
- **Resource UI updates**: 500ms throttle
- **Resource production**: 1 second timer (not per-frame)
- **Event checks**: Periodic, not every frame

### 11.3 Signal-Based Updates
- UI updates only when data changes (signals)
- No polling in most systems
- Event-driven architecture

---

## 12. KEY DEPENDENCIES

### 12.1 Manager Dependencies
```
DataManager (foundation)
  ↓
ResourceManager, BuildingManager, ProgressionManager
  ↓
VillagerManager, JobSystem
  ↓
UI Systems (UIBuilder, UITheme)
```

### 12.2 Critical Paths
1. **Resource Production**: BuildingManager → ResourceManager → UI
2. **Building Placement**: UI → BuildingManager → ResourceManager → Visuals
3. **Villager Work**: JobSystem → Villager → ResourceManager → BuildingManager

---

## 13. POTENTIAL ISSUES & RECOMMENDATIONS

### 13.1 Current Issues
1. **World Generation Disabled**: `generate_world()` commented out
2. **Initial Villagers Disabled**: `spawn_initial_villagers()` commented out
3. **No _physics_process in main.gd**: Villager updates handled in Villager.gd

### 13.2 Recommendations
1. Enable world generation for new games
2. Add initial villager spawning
3. Consider centralizing update loops
4. Add performance profiling
5. Implement object pooling for frequent operations

---

## 14. TESTING CHECKLIST

### 14.1 Core Systems
- [ ] Resource production works
- [ ] Resource consumption works
- [ ] Building placement works
- [ ] Building upgrades work
- [ ] Villager spawning works
- [ ] Job assignment works
- [ ] Work cycles complete
- [ ] Save/load works

### 14.2 UI Systems
- [ ] Resource display updates
- [ ] Building panel updates
- [ ] Research panel works
- [ ] Skills panel works
- [ ] Events panel works
- [ ] Notifications show

### 14.3 Integration
- [ ] Signals connect properly
- [ ] Managers communicate correctly
- [ ] Data flows correctly
- [ ] No memory leaks
- [ ] Performance acceptable

---

**Last Updated:** 2026-01-15
**Game Version:** Stone Age Prototype
**Status:** Complete pipeline documented
