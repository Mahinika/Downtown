# Stronghold: Definitive Edition Economy Adaptation Plan

## Overview
This document outlines how to adapt Stronghold: Definitive Edition's economy and city management systems into the Downtown game, creating a deep, interconnected economic system with meaningful trade-offs.

---

## Key Systems from Stronghold

### 1. **Popularity System (0-100)**
**Core Mechanic**: Popularity determines population growth and stability
- **Above 50**: Population grows (if housing available)
- **Below 50**: Peasants leave (population decreases)
- **At 100**: Maximum growth rate, high stability
- **At 0**: Mass exodus, economic collapse

**Factors Affecting Popularity**:
- Food variety & quality (rations)
- Ale coverage (inns)
- Tax rates
- Entertainment buildings (Good Things)
- Fear buildings (Bad Things)
- Housing quality & overcrowding
- Public services (wells, shrines, gardens)

---

### 2. **Tax System**
**Mechanic**: Generate gold income but reduce popularity

**Tax Levels**:
- **No Tax**: 0 gold/month, 0 popularity penalty
- **Low Tax**: +X gold/month, -5 popularity
- **Average Tax**: +2X gold/month, -10 popularity
- **Mean Tax**: +3X gold/month, -20 popularity
- **Extortionate Tax**: +4X gold/month, -35 popularity

**Strategy**: Balance taxes with ale, food variety, and entertainment to maintain popularity > 50

---

### 3. **Food Variety & Rations**
**Mechanic**: Different food sources provide different bonuses

**Food Types**:
- **Basic Food** (fire pit, hunting): +0 popularity bonus
- **Wheat/Bread** (farm → mill → bakery): +2 popularity per variety
- **Preserved Food** (smokehouse): +1 popularity (storage bonus)
- **Meat** (hunting, animals): +1 popularity
- **Cheese** (dairy, if added): +1 popularity

**Ration Levels**:
- **Low Rations**: 0.1 food/peasant/month, -10 popularity
- **Normal Rations**: 0.2 food/peasant/month, +0 popularity
- **Double Rations**: 0.4 food/peasant/month, +15 popularity

**Food Variety Bonus**: +2 popularity per unique food type (max +8 for 4+ varieties)

---

### 4. **Ale System**
**Production Chain**: Hops Farm → Brewery → Inn

**Mechanics**:
- **Hops Farm**: Produces hops (resource)
- **Brewery**: Converts hops → ale (or wheat → ale)
- **Inn**: Serves ale, provides +4 happiness per covered peasant
- **Coverage**: One inn supports ~30 peasants

**Benefits**:
- Offsets tax penalties
- Offsets low ration penalties
- Can offset fear building penalties
- Critical for high-tax strategies

**Market Option**: Can buy ale directly from market instead of producing

---

### 5. **Travel Distance System**
**Core Mechanic**: Production efficiency based on distance to storage

**Calculation**:
- Worker travels: Home → Workplace → Storage → Home
- Distance penalty: `efficiency = 1.0 - (distance / max_distance) * penalty_factor`
- **Max Distance**: 500 pixels (no penalty up to this)
- **Penalty Factor**: 0.3 (30% max efficiency loss)

**Optimization Strategy**:
- Place production buildings near stockpiles
- Place housing near workplaces
- Cluster related buildings (farm → mill → bakery chain)

---

### 6. **Fear Factor System (Good Things vs Bad Things)**

#### **Bad Things** (Fear Buildings)
**Buildings**: Gallows, Dungeons, Torture Devices, etc.
**Effects**:
- **Level 1**: -2 popularity, +10% worker production
- **Level 2**: -4 popularity, +25% worker production
- **Level 3**: -6 popularity, +50% worker production
- **Level 4**: -8 popularity, +100% worker production
- **Level 5**: -10 popularity, +150% worker production

**Health Penalty**: -5% villager health per level (max -25%)

**Use Case**: High-production strategies with ale/taxes to offset unhappiness

#### **Good Things** (Entertainment Buildings)
**Buildings**: Gardens, Churches, Shrines, Statues, etc.
**Effects**:
- **Level 1**: +5 popularity, -5% worker production
- **Level 2**: +10 popularity, -10% worker production
- **Level 3**: +15 popularity, -20% worker production
- **Level 4**: +20 popularity, -35% worker production
- **Level 5**: +25 popularity, -50% worker production

**Health Bonus**: +5% villager health per level (max +25%)
**Damage Bonus**: +5% unit damage per level (max +25%)

**Use Case**: High-popularity strategies with lower production output

**Trade-off**: Quality vs Quantity - choose production speed or happiness/health

---

### 7. **Population & Labor System**
**Mechanic**: Housing limits population, jobs employ workers

**Key Rules**:
- **Idle Peasants**: Maximum 24 idle peasants (unless no jobs available)
- **Housing Growth**: Population grows when popularity > 50 AND housing available
- **Job Assignment**: Peasants auto-assign to available jobs
- **Unemployment**: Too many idle peasants reduce popularity (-1 per idle over 24)

**Population Consumption**:
- Each peasant consumes food based on ration level
- Soldiers don't consume food (only peasants)

---

### 8. **Building Chains & Dependencies**
**Mechanic**: Sequential unlocks and processing chains

**Food Chains**:
1. **Simple Chain** (Early Game):
   - Apple Orchard → Food (direct)

2. **Bread Chain** (Mid Game):
   - Wheat Farm → Mill → Bakery → Bread
   - Requires: Mill unlocked, Bakery unlocked

3. **Ale Chain**:
   - Hops Farm → Brewery → Inn → Ale Coverage
   - OR: Wheat → Brewery → Inn

4. **Preservation Chain**:
   - Farm/Source → Smokehouse → Preserved Food

**Processing Chains**:
- Stone → Blacksmith → Tools
- Wheat → Brewery → Beer
- Food → Smokehouse → Preserved Food

**Unlock Requirements**:
- Must build prerequisite buildings first
- Research/technology gates for advanced chains

---

### 9. **Market & Trade System**
**Mechanic**: Buy/sell resources to balance economy

**Functions**:
- **Sell Resources**: Convert surplus resources to gold
- **Buy Resources**: Purchase needed resources with gold
- **Auto-Trade**: Set automatic trades when resources hit thresholds

**Trade Rates** (example):
- Sell Food: 0.1 gold per food
- Buy Wood: 5 gold per wood
- Buy Stone: 8 gold per stone
- Buy Ale: 0.096 gold per peasant/month (market ale)

**Use Cases**:
- Sell surplus food for gold
- Buy missing resources for production chains
- Balance economy without micromanaging

---

### 10. **Storage & Stockpile System**
**Mechanic**: Central storage with expansion

**Current System**: Stockpile increases capacity
**Stronghold Adaptation**:
- Main Stockpile: Central storage hub
- Adjacent Stockpiles: Must be placed next to main stockpile
- Storage Efficiency: Distance from production to stockpile affects efficiency
- Storage Limits: Per-resource capacity limits

---

## Implementation Plan for Downtown

### Phase 1: Core Systems (Foundation)

#### 1.1 Popularity System
**New Manager**: `PopularityManager` (or extend existing managers)

**Core Features**:
- Track popularity (0-100)
- Calculate popularity from factors:
  - Food variety bonus
  - Ration level
  - Tax penalty
  - Ale coverage
  - Fear/Good Things balance
  - Housing quality
  - Public services
- Population growth based on popularity
- Emit signals when popularity changes significantly

**Integration**:
- Connect to VillagerManager for population growth
- Connect to ResourceManager for food consumption
- Connect to BuildingManager for building bonuses

#### 1.2 Tax System
**Implementation**: Add to ResourceManager or new EconomyManager

**Features**:
- Tax rate setting (No Tax, Low, Average, Mean, Extortionate)
- Gold generation from taxes (based on population)
- Popularity penalty based on tax level
- Tax income display in UI

**UI Changes**:
- Add tax rate selector to settings/economic panel
- Show tax income and popularity penalty
- Visual indicator of current tax level

#### 1.3 Food Variety System
**Enhancement**: Extend existing food system

**Changes**:
- Track active food types (food, bread, preserved_food, meat, cheese)
- Calculate variety bonus (+2 per unique type)
- Display food variety in UI
- Ration level setting (Low/Normal/Double)

**Consumption**:
- Per-peasant food consumption based on ration level
- Calculate total consumption from population

---

### Phase 2: Production Chains

#### 2.1 Enhanced Building Chains
**Implementation**: Update buildings.json and BuildingManager

**New Buildings** (from Stronghold):
- **Apple Orchard**: Fast food source (early game)
- **Hops Farm**: Produces hops for ale
- **Bakery**: Converts flour → bread
- **Inn**: Serves ale, provides happiness coverage

**Processing Enhancements**:
- Require input resources (wheat → mill → flour)
- Chain dependencies (can't build bakery without mill)
- Unlock gates (research or progression)

#### 2.2 Travel Distance System
**New System**: Distance calculation affecting production

**Implementation**:
- Calculate distance from building to nearest stockpile
- Apply efficiency penalty based on distance
- Visual indicators (overlay showing efficiency)
- Pathfinding-based distance (use existing CityManager)

**Efficiency Formula**:
```
base_efficiency = 1.0
distance = pathfinding_distance(building, nearest_stockpile)
max_distance = 500.0  # pixels
penalty_factor = 0.3  # 30% max loss
efficiency = base_efficiency - (min(distance, max_distance) / max_distance) * penalty_factor
```

---

### Phase 3: Advanced Systems

#### 3.1 Fear Factor System
**New Building Category**: "fear" and "entertainment"

**Fear Buildings** (Bad Things):
- Gallows: +production, -popularity
- Dungeon: +production, -popularity
- Torture Device: +production, -popularity

**Entertainment Buildings** (Good Things):
- Garden: +popularity, -production
- Church: +popularity, -production, +health
- Shrine: +popularity, +research (existing)

**Level System**:
- Buildings provide levels
- Total level = sum of building levels
- Effects scale with total level (1-5)

#### 3.2 Ale Coverage System
**Implementation**: Distance-based coverage

**Inn Coverage**:
- Each inn has coverage radius (e.g., 300 pixels)
- Peasants within radius get ale happiness bonus
- Visual overlay showing coverage areas
- Coverage calculation: `peasants_covered = count_peasants_in_radius(inn_position, radius)`

**Brewery Chain**:
- Option 1: Hops Farm → Brewery → Ale
- Option 2: Wheat → Brewery → Ale (current system)
- Ale consumed by inns (resource consumption)

---

### Phase 4: Economy & Trade

#### 4.1 Market System
**New Building**: Enhanced Market

**Features**:
- Buy/sell interface
- Trade rates (configurable)
- Auto-trade settings
- Trade history/log

**Auto-Trade**:
- Set thresholds (e.g., "Buy wood if < 50")
- Set thresholds (e.g., "Sell food if > 200")
- Automatic resource balancing

#### 4.2 Idle Peasant System
**Enhancement**: Track idle villagers

**Implementation**:
- Count villagers without jobs
- Maximum idle limit (24 by default)
- Popularity penalty for excess idle
- Visual indicator of idle count

---

## Data Structure Changes

### buildings.json Additions

```json
{
  "buildings": {
    "apple_orchard": {
      "id": "apple_orchard",
      "name": "Apple Orchard",
      "category": "production",
      "cost": {"wood": 20, "stone": 10},
      "effects": {
        "gathers": {"food": 2},
        "food_type": "apples",
        "production_rate": {"food": 2.0}
      }
    },
    "hops_farm": {
      "id": "hops_farm",
      "name": "Hops Farm",
      "category": "production",
      "cost": {"wood": 25, "stone": 15},
      "effects": {
        "gathers": {"hops": 3},
        "production_rate": {"hops": 3.0}
      }
    },
    "bakery": {
      "id": "bakery",
      "name": "Bakery",
      "category": "production",
      "requires": ["mill"],
      "cost": {"wood": 30, "stone": 20, "flour": 5},
      "effects": {
        "processes": {
          "flour": {
            "output": "bread",
            "rate": 1.0,
            "input_rate": 1.0
          }
        }
      }
    },
    "inn": {
      "id": "inn",
      "name": "Inn",
      "category": "public",
      "cost": {"wood": 40, "stone": 30},
      "effects": {
        "ale_coverage": 30,
        "happiness_bonus": 4,
        "consumes": {"beer": 1}
      }
    },
    "gallows": {
      "id": "gallows",
      "name": "Gallows",
      "category": "fear",
      "fear_level": 1,
      "cost": {"wood": 15, "stone": 10},
      "effects": {
        "popularity_penalty": -2,
        "production_bonus": 0.10,
        "health_penalty": -0.05
      }
    },
    "garden": {
      "id": "garden",
      "name": "Garden",
      "category": "entertainment",
      "good_level": 1,
      "cost": {"wood": 10, "stone": 5},
      "effects": {
        "popularity_bonus": 5,
        "production_penalty": -0.05,
        "health_bonus": 0.05
      }
    }
  }
}
```

### resources.json Additions

```json
{
  "resources": {
    "hops": {
      "id": "hops",
      "name": "Hops",
      "description": "Crop used for brewing ale"
    },
    "bread": {
      "id": "bread",
      "name": "Bread",
      "description": "Baked bread from flour, provides food variety bonus"
    },
    "meat": {
      "id": "meat",
      "name": "Meat",
      "description": "Meat from hunting or animals, provides food variety"
    }
  }
}
```

---

## Code Implementation Priority

### High Priority (Core Gameplay)
1. ✅ **Popularity System** - Foundation for all other systems
2. ✅ **Tax System** - Core economic mechanic
3. ✅ **Food Variety** - Early-game depth
4. ✅ **Population Growth** - Based on popularity

### Medium Priority (Depth)
5. ⚠️ **Travel Distance** - Strategic placement
6. ⚠️ **Building Chains** - Sequential unlocks
7. ⚠️ **Ale System** - Happiness management

### Lower Priority (Polish)
8. ⬜ **Fear Factor** - Advanced strategies
9. ⬜ **Market/Trade** - Economic optimization
10. ⬜ **Idle Peasant Limits** - Balance tuning

---

## UI/UX Changes Needed

### New UI Elements
1. **Popularity Display**: Large gauge (0-100) in top HUD
2. **Tax Rate Selector**: Dropdown in settings/economic panel
3. **Food Variety Indicator**: Show active food types and bonus
4. **Ale Coverage Overlay**: Visual radius around inns
5. **Travel Distance Overlay**: Efficiency indicators on buildings
6. **Fear/Good Things Display**: Current level and effects

### Enhanced UI
- **Economic Panel**: Central hub for tax, rations, trade
- **Building Info**: Show chain dependencies and requirements
- **Population Breakdown**: Active workers, idle peasants, unemployed

---

## Migration Strategy

### Step 1: Add Core Systems (Popularity, Taxes)
- Create PopularityManager or extend existing
- Add tax system to EconomyManager
- Update UI to display popularity
- Test population growth based on popularity

### Step 2: Enhance Food System
- Add food variety tracking
- Add ration levels
- Update consumption calculations
- Add food variety bonus to popularity

### Step 3: Add Travel Distance
- Calculate distances in BuildingManager
- Apply efficiency penalties
- Visual feedback for efficiency

### Step 4: Building Chains
- Add sequential unlock requirements
- Enhance processing chains
- Add new buildings (apple orchard, bakery, inn, etc.)

### Step 5: Advanced Features
- Fear Factor system
- Ale coverage
- Market enhancements
- Idle peasant limits

---

## Testing & Balance

### Key Metrics to Tune
- Popularity growth/decay rates
- Tax income vs popularity penalty
- Food consumption per peasant
- Travel distance penalty
- Fear/Good Things effects
- Ale coverage radius and happiness bonus

### Target Balance
- **Early Game**: Focus on food and housing, low taxes
- **Mid Game**: Introduce food variety, ale, moderate taxes
- **Late Game**: High taxes with ale/entertainment offset, or fear-based production boost

---

## Next Steps

1. **Review this plan** - Ensure it aligns with game vision
2. **Prioritize features** - Decide which to implement first
3. **Create detailed specs** - For each system (data structures, algorithms)
4. **Implement incrementally** - One system at a time with testing
5. **Balance and tune** - Adjust values based on gameplay

---

## References
- Stronghold: Definitive Edition Economy Guide
- Stronghold Crusader: Definitive Edition mechanics
- Gameplay analysis and community guides
