extends CharacterBody2D

# Villager.gd - Individual villager entity with movement and AI
# CharacterBody2D for physics-based movement

signal state_changed(new_state: String)
signal resource_gathered(resource_id: String, amount: float)
signal work_completed(job_type: String)

enum State {
	IDLE,
	WALKING,
	WORKING,
	CARRYING,
	DEPOSITING
}

var villager_id: String = ""
var current_state: State = State.IDLE
var job_type: int = -1  # GameWorld.JobType
var target_position: Vector2 = Vector2.ZERO  # Public for debug visualization

# Tween tracking to avoid get_target() issues - REMOVED DUE TO COMPILATION ISSUES

# Villager movement and carrying constants
const DEFAULT_MOVE_SPEED: float = 150.0  # pixels per second (increased by 200%)
const DEFAULT_MAX_CARRYING_CAPACITY: float = 5.0  # Maximum total resources that can be carried

var move_speed: float = DEFAULT_MOVE_SPEED
var carrying_resource: Dictionary = {}  # resource_id -> amount
var max_carrying_capacity: float = DEFAULT_MAX_CARRYING_CAPACITY
var harvest_time_accumulator: float = 0.0  # Time spent harvesting since last deposit
const MAX_HARVEST_TIME_BEFORE_DEPOSIT: float = 30.0  # Deposit after 30 seconds of harvesting

# Villager needs system constants
const MAX_NEED_VALUE: float = 100.0  # Maximum value for hunger/happiness (0-100)
const DEFAULT_HUNGER_RATE: float = 0.5  # Hunger decrease per second
const HUNGER_THRESHOLD_LOW: float = 30.0  # Hunger level below which villager needs food
const HUNGER_THRESHOLD_CRITICAL: float = 10.0  # Critical hunger level
const HUNGER_THRESHOLD_HIGH: float = 70.0  # Hunger level above which happiness increases
const HUNGER_RECOVERY_AMOUNT: float = 20.0  # Amount of hunger restored per food consumption
const HAPPINESS_DECREASE_RATE: float = 1.0  # Happiness decrease per second when hungry
const HAPPINESS_INCREASE_RATE: float = 0.5  # Happiness increase per second when well-fed
const HAPPINESS_FOOD_BONUS: float = 5.0  # Happiness bonus from eating food
const STARVING_RECOVERY_THRESHOLD: float = 20.0  # Hunger level above which villager is no longer starving

# Extended Happiness Constants
const HAPPINESS_HOUSING_WEIGHT: float = 0.3  # Weight of housing quality in happiness
const HAPPINESS_JOB_WEIGHT: float = 0.2  # Weight of job satisfaction in happiness
const HAPPINESS_PUBLIC_WEIGHT: float = 0.15  # Weight of public services in happiness
const HAPPINESS_OVERCROWD_WEIGHT: float = 0.1  # Weight of overcrowding penalty in happiness
const HAPPINESS_FOOD_WEIGHT: float = 0.25  # Weight of food status in happiness

const BASE_HOUSING_HAPPINESS: float = 30.0  # Base happiness from having shelter
const PREFERRED_JOB_BONUS: float = 15.0  # Bonus for working preferred job
const OVERCROWD_PENALTY_PER_PERSON: float = 5.0  # Penalty per extra person in housing
const PUBLIC_SERVICE_RANGE: float = 200.0  # Range for public service bonuses (pixels)

# Work efficiency constants
const EFFICIENCY_HUNGER_PENALTY_MULTIPLIER: float = 0.5  # Hunger penalty multiplier
const EFFICIENCY_CRITICAL_HUNGER_PENALTY: float = 0.3  # Severe penalty when critically hungry
const EFFICIENCY_HAPPINESS_MULTIPLIER: float = 0.4  # ±20% based on happiness
const EFFICIENCY_HEALTH_THRESHOLD: float = 50.0  # Health level for penalty calculation
const EFFICIENCY_HEALTH_PENALTY_MULTIPLIER: float = 0.3  # Up to 30% penalty for poor health
const EFFICIENCY_MINIMUM: float = 0.1  # Minimum efficiency (10%)
const EFFICIENCY_MAXIMUM: float = 2.0  # Maximum efficiency (200%)

var hunger: float = MAX_NEED_VALUE  # 0-100, decreases over time
var hunger_rate: float = DEFAULT_HUNGER_RATE
var happiness: float = 50.0  # 0-100, affected by multiple factors
var is_starving: bool = false

# Extended Happiness System (Pixel Tribe inspired)
var housing_quality_bonus: float = 0.0  # Bonus from housing quality
var job_satisfaction_bonus: float = 0.0  # Bonus from preferred job
var overcrowding_penalty: float = 0.0  # Penalty from overcrowding
var public_service_bonus: float = 0.0  # Bonus from nearby public buildings

var collision_shape: CollisionShape2D
var state_label: Label

# Cached visual references for performance
var _cached_visual: Node2D = null
var _cached_body: Polygon2D = null
var _cached_job_container: Node2D = null

# Skill and Experience System
var experience_points: Dictionary = {}  # job_type_string -> experience points
var skill_levels: Dictionary = {}  # job_type_string -> skill level (1-10)
const BASE_EXP_PER_TASK: float = 10.0  # Base experience gained per task completion
const EXP_MULTIPLIER_PER_LEVEL: float = 1.1  # Experience required multiplier per level
const BASE_EXP_FOR_LEVEL_2: float = 100.0  # Base experience needed for level 2
const MAX_SKILL_LEVEL: int = 10  # Maximum skill level
const MIN_SKILL_LEVEL: int = 1  # Minimum skill level

# Skill-based bonuses (calculated dynamically)
# These are multipliers applied based on skill level
var work_speed_bonus: float = 1.0  # Work speed multiplier (higher = faster)
var harvest_bonus: float = 1.0  # Harvest amount multiplier (higher = more resources)
var movement_speed_bonus: float = 1.0  # Movement speed multiplier
var carrying_capacity_bonus: float = 1.0  # Carrying capacity multiplier

# Task execution system
var current_task: Dictionary = {}  # Current task from JobSystem
var task_timer: float = 0.0  # Timer for task execution
var current_path: Array[Vector2] = []  # Pathfinding waypoints
var current_waypoint_index: int = 0  # Current waypoint in path
var target_node_id: String = ""  # Resource node ID for harvesting
var target_building_id: String = ""  # Building ID for deposit
var retry_count: int = 0  # Retry counter for failed tasks
var last_position: Vector2 = Vector2.ZERO  # For stuck detection
var stuck_timer: float = 0.0  # Timer for stuck detection
var needs_food: bool = false  # Flag for eating priority

# Happiness and health system
var health: float = 100.0    # Health level (0-100)
var happiness_decay_rate: float = 0.5  # Points lost per second when unhappy
var health_decay_rate: float = 0.2     # Points lost per second when unhealthy

# Visual constants
const COLLISION_RADIUS: float = 8.0  # Collision shape radius
const HEAD_RADIUS: float = 3.5  # Head visual radius
const HEAD_SEGMENTS: int = 8  # Number of segments for head circle
const HEAD_OFFSET_Y: float = -8.0  # Y offset for head position

# Movement and pathfinding constants
const WAYPOINT_ARRIVAL_DISTANCE: float = 5.0  # Distance threshold for waypoint arrival
const TARGET_ARRIVAL_DISTANCE: float = 5.0  # Distance threshold for target arrival
const NODE_ARRIVAL_DISTANCE: float = 10.0  # Distance threshold for resource node arrival
const BUILDING_ARRIVAL_DISTANCE: float = 10.0  # Distance threshold for building arrival
const WORKPLACE_ARRIVAL_DISTANCE: float = 20.0  # Distance threshold for workplace arrival
const STUCK_DETECTION_DISTANCE: float = 2.0  # Distance threshold for stuck detection
const STUCK_DETECTION_TIME: float = 3.0  # Time in seconds before considering stuck
const DIRECT_MOVEMENT_THRESHOLD: float = 2.0  # Tile multiplier for direct movement (tile_size * 2.0)
const MAX_RETRY_COUNT: int = 3  # Maximum retry attempts for failed tasks
const DEFAULT_SEARCH_DISTANCE: float = 500.0  # Default search distance for resource nodes
const MAX_SEARCH_DISTANCE: float = 999999.0  # Maximum search distance for buildings

# Task duration constants
const FOOD_HARVEST_DURATION: float = 2.0  # Seconds to harvest food at farm
const RESOURCE_HARVEST_DURATION: float = 2.0  # Seconds to harvest from resource node
const DEPOSIT_DURATION: float = 1.0  # Seconds to deposit resources
const DEFAULT_FOOD_AMOUNT: float = 2.0  # Default food amount produced per harvest
const DEFAULT_HARVEST_AMOUNT: float = 1.0  # Default resource amount harvested per cycle

# Logging throttling constants
const TASK_UPDATE_LOG_CHANCE: float = 0.1  # 10% chance to log task updates


func _ready() -> void:
	setup_collision()
	setup_visual()
	setup_label()
	# Initialize skill bonuses
	update_skill_bonuses()

func _process(delta: float) -> void:
	# Apply seasonal modifiers to delta time for movement and work
	var seasonal_delta = apply_seasonal_modifiers(delta)

	# Update happiness and health over time
	update_happiness_health(seasonal_delta)

func setup_collision() -> void:
	# Create collision shape if it doesn't exist
	if not collision_shape:
		collision_shape = CollisionShape2D.new()
		add_child(collision_shape)
	
	# Create circle shape for collision
	var shape = CircleShape2D.new()
	shape.radius = COLLISION_RADIUS
	collision_shape.shape = shape

func setup_visual() -> void:
	# Invalidate cached visual references when recreating visual
	_cached_visual = null
	_cached_body = null
	_cached_job_container = null

	# Try to use sprite first
	var sprite_path = "res://assets/villagers/villager_idle.png"
	if ResourceLoader.exists(sprite_path):
		# Use sprite
		var sprite = Sprite2D.new()
		sprite.name = "VillagerSprite"
		sprite.texture = load(sprite_path)
		add_child(sprite)
		return

	# Fallback to Polygon2D shapes (original implementation)
	# Create improved visual representation with Polygon2D
	# Base villager shape (human-like silhouette)
	var visual_container = Node2D.new()
	visual_container.name = "Visual"
	add_child(visual_container)
	
	# Villager body (torso)
	var body = Polygon2D.new()
	body.name = "Body"
	body.color = Color(0.3, 0.5, 0.7)  # Blue-gray
	body.polygon = PackedVector2Array([
		Vector2(-4, -2),  # Top-left
		Vector2(4, -2),   # Top-right
		Vector2(5, 6),    # Bottom-right
		Vector2(-5, 6)    # Bottom-left
	])
	visual_container.add_child(body)
	
	# Head (circle)
	var head = Polygon2D.new()
	head.name = "Head"
	head.color = Color(0.9, 0.8, 0.7)  # Skin tone
	var head_points = PackedVector2Array()
	var head_radius = HEAD_RADIUS
	for i in range(HEAD_SEGMENTS):
		var angle = (i / float(HEAD_SEGMENTS)) * TAU
		head_points.append(Vector2(cos(angle) * head_radius, HEAD_OFFSET_Y + sin(angle) * head_radius))
	head.polygon = head_points
	visual_container.add_child(head)
	
	# Job indicator container (will be populated by update_job_visual)
	var job_indicator_container = Node2D.new()
	job_indicator_container.name = "JobIndicator"
	visual_container.add_child(job_indicator_container)
	
	# Add shape indicator based on job type (will be updated when job is assigned)
	update_job_visual()

func setup_label() -> void:
	# Create state label if it doesn't exist
	if not state_label:
		state_label = Label.new()
		state_label.name = "StateLabel"
		state_label.position = Vector2(-30, -25)
		state_label.text = "IDLE"
		state_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
		state_label.add_theme_font_size_override("font_size", 12)
		state_label.add_theme_color_override("font_color", Color(1.0, 1.0, 1.0, 1.0))
		state_label.add_theme_color_override("font_outline_color", Color(0.0, 0.0, 0.0, 1.0))
		state_label.add_theme_constant_override("outline_size", 4)
		add_child(state_label)

func initialize(id: String) -> void:
	villager_id = id
	set_state(State.IDLE)

func assign_job(job: int) -> void:
	job_type = job
	print("[Villager ", villager_id, "] Assigned job: ", job)
	update_job_visual()
	# Initialize skill for this job if not exists
	var job_name = _get_job_name(job)
	if job_name != "" and not skill_levels.has(job_name):
		skill_levels[job_name] = MIN_SKILL_LEVEL
		experience_points[job_name] = 0.0
	update_skill_bonuses()

func update_job_visual() -> void:
	# Check if GameWorld is available
	var world = GameServices.get_world()
	if not world:
		return

	# Cache visual references if not already cached
	if not _cached_visual:
		_cached_visual = find_child("Visual", true, false)
	if not _cached_visual:
		return

	if not _cached_job_container:
		_cached_job_container = _cached_visual.find_child("JobIndicator", true, false)
	if not _cached_job_container:
		return

	var job_container = _cached_job_container
	
	# Clear existing indicators
	for child in job_container.get_children():
		child.queue_free()
	
	# Add distinctive job indicator based on job type
	var job_indicator = _create_job_indicator(job_type)
	if job_indicator:
		# Set appropriate name based on job type
		match job_type:
			GameWorld.JobType.LUMBERJACK:
				job_indicator.name = "AxeIndicator"
			GameWorld.JobType.MINER:
				job_indicator.name = "PickaxeIndicator"
			GameWorld.JobType.FARMER:
				job_indicator.name = "ScytheIndicator"
			GameWorld.JobType.MILLER:
				job_indicator.name = "MillIndicator"
			GameWorld.JobType.BREWER:
				job_indicator.name = "BarrelIndicator"
			GameWorld.JobType.BLACKSMITH:
				job_indicator.name = "HammerIndicator"
			GameWorld.JobType.SMOKER:
				job_indicator.name = "SmokeIndicator"
			GameWorld.JobType.ENGINEER:
				job_indicator.name = "WrenchIndicator"
		job_container.add_child(job_indicator)

func set_state(new_state: State) -> void:
	if current_state == new_state:
		return
	
	current_state = new_state
	var state_name = State.keys()[new_state]
	
	if state_label:
		state_label.text = state_name
	
	# Update visual appearance based on state
	update_state_visual()
	
	state_changed.emit(state_name)
	print("[Villager ", villager_id, "] State changed to: ", state_name)

func update_state_visual() -> void:
	"""Update villager visual appearance based on current state"""
	# Cache visual references if not already cached
	if not _cached_visual:
		_cached_visual = find_child("Visual", true, false)
	if not _cached_visual:
		return

	if not _cached_body:
		_cached_body = _cached_visual.find_child("Body", true, false)
	if not _cached_body:
		return

	var body = _cached_body

	# Base color based on state
	var base_color = Color(0.3, 0.5, 0.7)  # Default blue-gray
	match current_state:
		State.IDLE:
			base_color = Color(0.3, 0.5, 0.7)  # Default blue-gray
		State.WALKING:
			base_color = Color(0.4, 0.6, 0.8)  # Lighter blue (active)
		State.WORKING:
			base_color = Color(0.7, 0.5, 0.3)  # Orange-brown (working)
		State.CARRYING:
			base_color = Color(0.5, 0.7, 0.5)  # Green tint (carrying)
		State.DEPOSITING:
			base_color = Color(0.6, 0.6, 0.8)  # Purple tint (depositing)

	# Modify color based on needs status
	var needs_modifier = Color(1, 1, 1)  # Default no modification

	# Hunger effects
	if hunger < HUNGER_THRESHOLD_CRITICAL:
		needs_modifier = Color(0.8, 0.4, 0.4)  # Red tint for critical hunger
	elif hunger < HUNGER_THRESHOLD_LOW:
		needs_modifier = Color(1.0, 0.8, 0.6)  # Orange tint for low hunger

	# Health effects
	if health < 30.0:
		needs_modifier = needs_modifier * Color(0.6, 0.6, 0.6)  # Gray tint for poor health

	# Happiness effects (subtle brightness changes)
	var happiness_factor = clamp(happiness / MAX_NEED_VALUE, 0.7, 1.3)
	needs_modifier = needs_modifier * Color(happiness_factor, happiness_factor, happiness_factor)

	body.color = base_color * needs_modifier

	# Add task-specific visual effects
	update_task_visual_effects()

	# Add pulsing animation for working state
	if current_state == State.WORKING:
		# Stop any existing working animation
		var tweens = get_tree().get_processed_tweens()
		for t in tweens:
			if t and not t.is_queued_for_deletion():
				t.kill()

		# Create new pulsing animation
		var tween = create_tween()
		tween.set_loops(20)  # Pulse for a reasonable duration
		tween.tween_property(body, "modulate:a", 0.7, 0.5)
		tween.tween_property(body, "modulate:a", 1.0, 0.5)
	else:
		# Clear any ongoing working animation
		var tweens = get_tree().get_processed_tweens()
		for t in tweens:
			if t and not t.is_queued_for_deletion():
				t.kill()
		body.modulate.a = 1.0

func _handle_arrival_at_destination() -> void:
	"""Handle what happens when villager arrives at their destination"""
	velocity = Vector2.ZERO

	# Special handling: if carrying resources and at a stockpile, deposit them
	_handle_stockpile_deposit()
	if carrying_resource.is_empty():
		return

	complete_current_task()
	set_state(State.IDLE)

func _handle_pathfinding_movement() -> void:
	"""Handle movement along a pre-calculated path"""
	if current_waypoint_index < current_path.size():
		var waypoint = current_path[current_waypoint_index]
		var direction = (waypoint - position).normalized()
		var waypoint_distance = position.distance_to(waypoint)

		if waypoint_distance < WAYPOINT_ARRIVAL_DISTANCE:  # Reached waypoint
			current_waypoint_index += 1
			if current_waypoint_index >= current_path.size():
				# Path complete
				_handle_arrival_at_destination()
				return
			else:
				# Move to next waypoint
				target_position = current_path[current_waypoint_index]
		else:
			# Move towards current waypoint
			velocity = direction * move_speed
			move_and_slide()
	else:
		# Path complete but shouldn't happen
		_handle_arrival_at_destination()

func _handle_direct_movement() -> void:
	"""Handle direct movement to target without pathfinding"""
	var direction = (target_position - position).normalized()
	var target_distance = position.distance_to(target_position)

	if target_distance < TARGET_ARRIVAL_DISTANCE:  # Reached destination
		_handle_arrival_at_destination()
		return

	# Move towards target
	velocity = direction * move_speed
	move_and_slide()

func _handle_stockpile_deposit() -> void:
	"""Handle depositing resources at a stockpile"""
	if carrying_resource.is_empty() or not _is_at_stockpile():
		return

	_deposit_carried_resources()
	# After depositing, complete current task (which clears it) and get a new one
	if not current_task.is_empty():
		complete_current_task()
	# Force task update to get new work immediately
	update_work_task()

func move_to(destination: Vector2) -> void:
	target_position = destination
	set_state(State.WALKING)

func _physics_process(delta: float) -> void:
	var job_system = get_node_or_null("/root/JobSystem")

	# Update task timer
	task_timer += delta

	# Update villager needs
	update_needs(delta)
	
	# Check for stuck condition
	check_stuck(delta)
	
	# Poll for tasks when idle or carrying (carrying means we need to deposit)
	if (current_state == State.IDLE or current_state == State.CARRYING) and job_type != -1:
		# Priority: Eat if hungry before working
		if hunger < HUNGER_THRESHOLD_LOW:
			if not needs_food:
				needs_food = true
				create_eat_task()
			
			# If we tried to eat but no food available, reset flag and continue working
			if needs_food and current_task.is_empty():
				needs_food = false
				update_work_task()
			elif needs_food and not current_task.is_empty():
				execute_current_task()
				return  # Don't process work tasks while eating
		else:
			# Not hungry, reset food flag
			needs_food = false
		
		# Handle work tasks (only if not eating)
		if not needs_food:
			if current_task.is_empty():
				update_work_task()
			
			if not current_task.is_empty():
				execute_current_task()
			elif current_task.is_empty():
				# Debug: Check why no task was received (throttle logging)
				if randf() < 0.01:  # Only log 1% of the time to avoid spam
					if job_system:
						var job_type_str = job_system.get_villager_job(villager_id)
						if job_type_str.is_empty():
							print("[Villager ", villager_id, "] WARNING: Has job type but JobSystem reports no job assignment")
	
	match current_state:
		State.WALKING:
			handle_movement(delta)
		State.WORKING:
			handle_work(delta)
		State.DEPOSITING:
			handle_depositing(delta)

func handle_movement(_delta: float) -> void:
	"""Handle villager movement using pathfinding or direct movement"""
	if not current_path.is_empty():
		_handle_pathfinding_movement()
	else:
		_handle_direct_movement()

func handle_work(_delta: float) -> void:
	# Check if this is a farmer working at farm (no node needed)
	var resource_type = current_task.get("resource_type", "")
	
	if resource_type == "food" and target_node_id.is_empty():
		# Farmer producing food at farm
		var food_harvest_duration = FOOD_HARVEST_DURATION / work_speed_bonus  # Skill bonus: faster work
		if task_timer >= food_harvest_duration:
			var base_amount = current_task.get("amount", DEFAULT_FOOD_AMOUNT)
			# Apply seasonal food production modifier
			if SeasonalManager:
				var seasonal_modifier = SeasonalManager.get_resource_modifier("food")
				base_amount *= seasonal_modifier

			# Apply skill bonus: more production
			base_amount *= harvest_bonus

			# Produce food directly (no node harvesting needed)
			pickup_resource("food", base_amount)
			resource_gathered.emit("food", base_amount)
			complete_current_task()
			return
		return  # Still working, wait for timer
	
	# For lumberjacks/miners, harvest from resource node
	if target_node_id.is_empty():
		complete_current_task()
		return
	
	# Check if ResourceNodeManager is available
	if not ResourceNodeManager:
		push_error("[Villager ", villager_id, "] ResourceNodeManager not available")
		complete_current_task()
		return

	# Check if node still exists and is valid
	var node_data = ResourceNodeManager.get_node_data(target_node_id)
	if node_data.is_empty() or node_data.get("depleted", false):
		# Node is gone or depleted, release reservation and complete task
		ResourceNodeManager.release_node(target_node_id, villager_id)
		target_node_id = ""
		complete_current_task()
		return

	# Get resource type from node data (used in multiple places)
	var resource_type_from_node = node_data.get("resource_type", "wood")

	# Harvest duration (skill bonus: faster work)
	var harvest_duration = RESOURCE_HARVEST_DURATION / work_speed_bonus
	if task_timer >= harvest_duration:
		# Harvest the node (returns amount harvested as float)
		var base_harvest_amount = DEFAULT_HARVEST_AMOUNT
		# Apply seasonal resource modifiers
		if SeasonalManager:
			var seasonal_modifier = SeasonalManager.get_resource_modifier(resource_type_from_node)
			base_harvest_amount *= seasonal_modifier
		
		# Apply skill bonus: more resources per harvest
		base_harvest_amount *= harvest_bonus

		var harvested_amount = ResourceNodeManager.harvest_resource(target_node_id, base_harvest_amount)
		if harvested_amount <= 0.0:
			# Node depleted or invalid, release reservation and complete task
			if ResourceNodeManager:
				ResourceNodeManager.release_node(target_node_id, villager_id)
			target_node_id = ""
			complete_current_task()
			return
		
		if resource_type_from_node != "" and harvested_amount > 0.0:
			pickup_resource(resource_type_from_node, harvested_amount)
			resource_gathered.emit(resource_type_from_node, harvested_amount)

			# Update harvest time accumulator
			harvest_time_accumulator += harvest_duration

			# Check if we should deposit (full capacity OR time limit reached)
			if is_at_carrying_capacity() or harvest_time_accumulator >= MAX_HARVEST_TIME_BEFORE_DEPOSIT:
				# Go deposit resources
				if ResourceNodeManager:
					ResourceNodeManager.release_node(target_node_id, villager_id)
				target_node_id = ""
				harvest_time_accumulator = 0.0  # Reset timer
				complete_current_task()
				return
			else:
				# Not ready to deposit - try to harvest more from the same node
				if node_data and node_data.get("depleted", false) == false:
					# Node still has resources, continue harvesting
					set_state(State.WORKING)
					task_timer = harvest_duration  # Reset timer for next harvest
					return
				else:
					# Node depleted, release and complete task
					if ResourceNodeManager:
						ResourceNodeManager.release_node(target_node_id, villager_id)
					target_node_id = ""
					harvest_time_accumulator = 0.0  # Reset timer
					complete_current_task()
					return

		# No resources harvested, complete task
		if ResourceNodeManager:
			ResourceNodeManager.release_node(target_node_id, villager_id)
		target_node_id = ""
		complete_current_task()
		return

func handle_depositing(_delta: float) -> void:
	if carrying_resource.is_empty():
		# Nothing to deposit
		complete_current_task()
		return
	
	# Deposit duration (skill bonus: faster deposit)
	var deposit_duration = DEPOSIT_DURATION / work_speed_bonus
	if task_timer >= deposit_duration:
		# Deposit all carried resources
		var economy = GameServices.get_economy()
		if economy:
			for resource_type in carrying_resource:
				var amount = carrying_resource[resource_type]
				economy.add_resource(resource_type, amount)
		
		# Clear carried resources
		drop_resource()
		
		# Task complete
		complete_current_task()
		return

func start_work() -> void:
	set_state(State.WORKING)

func pickup_resource(resource_id: String, amount: float) -> void:
	# Check carrying capacity
	var current_total = get_total_carried()
	var available_capacity = max_carrying_capacity - current_total
	
	if available_capacity <= 0.0:
		print("[Villager ", villager_id, "] At carrying capacity, cannot pick up more")
		return
	
	# Only pick up what fits in capacity
	var amount_to_pickup = min(amount, available_capacity)
	carrying_resource[resource_id] = carrying_resource.get(resource_id, 0.0) + amount_to_pickup
	set_state(State.CARRYING)
	print("[Villager ", villager_id, "] Picked up ", amount_to_pickup, " ", resource_id, " (capacity: ", get_total_carried(), "/", max_carrying_capacity, ")")
	
	# If we couldn't pick up everything, we'll need to come back
	if amount_to_pickup < amount:
		print("[Villager ", villager_id, "] Could only carry ", amount_to_pickup, " of ", amount, " - will need another trip")
	
	# Update state label to show what's being carried
	if state_label:
		var resource_text = ""
		for res_id in carrying_resource:
			if resource_text != "":
				resource_text += ", "
			resource_text += str(int(carrying_resource[res_id])) + " " + res_id

		var capacity_percent = (get_total_carried() / max_carrying_capacity) * 100
		var status_indicator = "CARRYING"
		if capacity_percent >= 90:
			status_indicator = "FULL!"
		elif capacity_percent >= 60:
			status_indicator = "MOSTLY FULL"

		state_label.text = status_indicator + "\n" + resource_text + "\n(" + str(int(get_total_carried())) + "/" + str(int(max_carrying_capacity)) + ")"
	
	# After picking up, we should continue with the next task (deposit)
	# The task polling will handle this, but we need to make sure we're in a state that allows task polling

func get_total_carried() -> float:
	var total: float = 0.0
	for amount in carrying_resource.values():
		total += amount
	return total

func is_at_carrying_capacity() -> bool:
	return get_total_carried() >= max_carrying_capacity

func drop_resource() -> Dictionary:
	var resources = carrying_resource.duplicate()
	carrying_resource.clear()
	set_state(State.IDLE)
	return resources

func update_happiness_health(delta: float) -> void:
	"""Update happiness and health levels over time"""
	# Base decay rates
	var happiness_change = 0.0
	var health_change = -health_decay_rate * delta

	# Happiness based on hunger levels (original system)
	if hunger < HUNGER_THRESHOLD_LOW:
		happiness_change -= HAPPINESS_DECREASE_RATE * delta  # Unhappy when hungry
	elif hunger > HUNGER_THRESHOLD_HIGH:
		happiness_change += HAPPINESS_INCREASE_RATE * delta  # Happy when well-fed

	# Job satisfaction increases happiness
	var has_job = job_type >= 0
	if has_job:
		happiness_change += 0.3 * delta  # Small happiness boost from having work

	# Health affected by hunger
	var is_well_fed = hunger > HUNGER_THRESHOLD_LOW
	if is_well_fed:
		health_change += 0.1 * delta     # Health recovers when fed
	else:
		health_change -= 0.3 * delta     # Health decays when hungry

	# Apply building bonuses (from wells, shrines, etc.)
	var building_bonuses = calculate_building_bonuses()
	happiness_change += building_bonuses.happiness * delta
	health_change += building_bonuses.health * delta

	# Calculate extended happiness factors (Pixel Tribe inspired)
	var extended_happiness = calculate_extended_happiness_factors()

	# Combine all happiness factors
	var total_happiness_change = (
		happiness_change * HAPPINESS_FOOD_WEIGHT +  # Food status (original system)
		extended_happiness.housing * HAPPINESS_HOUSING_WEIGHT +  # Housing quality
		extended_happiness.job_satisfaction * HAPPINESS_JOB_WEIGHT +  # Job satisfaction
		extended_happiness.public_services * HAPPINESS_PUBLIC_WEIGHT +  # Public services
		extended_happiness.overcrowding * HAPPINESS_OVERCROWD_WEIGHT  # Overcrowding penalty
	)

	# Apply seasonal villager modifiers
	if SeasonalManager:
		var morale_modifier = SeasonalManager.get_villager_modifier("morale")
		var health_modifier = SeasonalManager.get_villager_modifier("health")

		# Morale affects happiness
		if morale_modifier != 1.0:
			total_happiness_change *= morale_modifier

		# Seasonal health effects
		if health_modifier != 1.0:
			health_change *= health_modifier

	# Update values (clamp to 0-100 range)
	happiness = clamp(happiness + total_happiness_change, 0.0, MAX_NEED_VALUE)
	health = clamp(health + health_change, 0.0, MAX_NEED_VALUE)

	# Update visual indicators if significant changes
	if abs(happiness_change) > 1.0 or abs(health_change) > 1.0:
		update_status_indicators()

func calculate_building_bonuses() -> Dictionary:
	"""Calculate bonuses from nearby buildings (wells, shrines, etc.)"""
	var bonuses = {
		"happiness": 0.0,
		"health": 0.0
	}

	# Check for nearby buildings that provide bonuses
	# This is a simplified version - in a full implementation, you'd check
	# buildings within a certain radius and apply their effects

	# For now, we'll apply global bonuses from buildings
	# TODO: Implement distance-based building effects

	# Check for Well buildings (happiness +10, health +5)
	var wells = BuildingManager.get_buildings_of_type("well")
	if wells.size() > 0:
		bonuses.happiness += 10.0 / 60.0  # Convert per-minute to per-second
		bonuses.health += 5.0 / 60.0

	# Check for Shrine buildings (morale +15, affects happiness)
	var shrines = BuildingManager.get_buildings_of_type("shrine")
	if shrines.size() > 0:
		bonuses.happiness += 15.0 / 60.0  # Morale boosts happiness

	return bonuses

func apply_seasonal_modifiers(delta: float) -> float:
	"""Apply seasonal modifiers to villager behavior and return modified delta"""
	if not SeasonalManager:
		return delta

	var modified_delta = delta

	# Apply movement speed modifier
	var movement_modifier = SeasonalManager.get_villager_modifier("movement")
	if movement_modifier != 1.0:
		modified_delta *= movement_modifier

	# Apply work efficiency modifier (affects work speed)
	var work_modifier = SeasonalManager.get_villager_modifier("work")
	if work_modifier != 1.0:
		modified_delta *= work_modifier

	return modified_delta

func update_status_indicators() -> void:
	"""Update visual status indicators based on happiness and health"""
	# This could be expanded to show visual effects like
	# sad faces when unhappy, health bars, etc.
	pass

# ===== Skill and Experience System =====
func _create_job_indicator(job_type: int) -> Polygon2D:
	"""Create a job indicator polygon based on job type"""
	var world = GameServices.get_world()
	if not world:
		return null

	var indicator = Polygon2D.new()

	match job_type:
		GameWorld.JobType.LUMBERJACK:
			indicator.color = Color(0.6, 0.4, 0.2)  # Brown axe handle
			indicator.polygon = PackedVector2Array([
				Vector2(-6, -10), Vector2(-2, -6), Vector2(-4, -4), Vector2(-8, -6)
			])

		GameWorld.JobType.MINER:
			indicator.color = Color(0.5, 0.5, 0.5)  # Gray pickaxe
			indicator.polygon = PackedVector2Array([
				Vector2(-7, -8), Vector2(-3, -8), Vector2(-3, -4), Vector2(-7, -4),
				Vector2(-7, 0), Vector2(-3, 0), Vector2(-3, 4), Vector2(-7, 4)
			])

		GameWorld.JobType.FARMER:
			indicator.color = Color(0.7, 0.6, 0.4)  # Tan tool
			var scythe_points = PackedVector2Array()
			scythe_points.append(Vector2(-8, -6))
			scythe_points.append(Vector2(-4, -8))
			scythe_points.append(Vector2(-2, -6))
			scythe_points.append(Vector2(-4, -2))
			scythe_points.append(Vector2(-6, -2))
			scythe_points.append(Vector2(-8, -4))
			indicator.polygon = scythe_points

		GameWorld.JobType.MILLER:
			indicator.color = Color(0.6, 0.5, 0.4)  # Brown mill
			var mill_points = PackedVector2Array()
			var mill_radius = 4.0
			for i in range(8):
				var angle = (i / 8.0) * TAU
				mill_points.append(Vector2(-5, -8) + Vector2(cos(angle), sin(angle)) * mill_radius)
			indicator.polygon = mill_points

		GameWorld.JobType.BREWER:
			indicator.color = Color(0.5, 0.3, 0.2)  # Brown barrel
			indicator.polygon = PackedVector2Array([
				Vector2(-6, -8), Vector2(-2, -8), Vector2(-1, -4),
				Vector2(-2, 0), Vector2(-6, 0), Vector2(-7, -4)
			])

		GameWorld.JobType.BLACKSMITH:
			indicator.color = Color(0.4, 0.4, 0.4)  # Gray hammer
			indicator.polygon = PackedVector2Array([
				Vector2(-7, -10), Vector2(-3, -10), Vector2(-3, -6),
				Vector2(-5, -6), Vector2(-5, 0), Vector2(-7, 0)
			])

		GameWorld.JobType.SMOKER:
			indicator.color = Color(0.5, 0.5, 0.5, 0.7)  # Gray smoke
			var smoke_points = PackedVector2Array()
			smoke_points.append(Vector2(-6, -6))
			smoke_points.append(Vector2(-2, -8))
			smoke_points.append(Vector2(0, -10))
			smoke_points.append(Vector2(-2, -12))
			smoke_points.append(Vector2(-4, -10))
			smoke_points.append(Vector2(-6, -8))
			indicator.polygon = smoke_points

		GameWorld.JobType.ENGINEER:
			indicator.color = Color(0.4, 0.5, 0.6)  # Steel blue
			indicator.polygon = PackedVector2Array([
				Vector2(-7, -8), Vector2(-3, -8), Vector2(-3, -4),
				Vector2(-1, -4), Vector2(-1, -2), Vector2(-3, -2),
				Vector2(-3, 2), Vector2(-7, 2), Vector2(-7, 0),
				Vector2(-5, 0), Vector2(-5, -2), Vector2(-7, -2)
			])

		_:
			return null

	return indicator

func _get_job_name(job: int) -> String:
	"""Convert job enum to string name"""
	var world = GameServices.get_world()
	if not world:
		return ""

	match job:
		GameWorld.JobType.LUMBERJACK:
			return "lumberjack"
		GameWorld.JobType.MINER:
			return "miner"
		GameWorld.JobType.FARMER:
			return "farmer"
		GameWorld.JobType.ENGINEER:
			return "engineer"
		_:
			return ""

func get_experience_for_level(level: int) -> float:
	"""Calculate total experience needed for a given level"""
	if level <= MIN_SKILL_LEVEL:
		return 0.0
	# Exponential growth: each level requires more exp
	# Level 2: 100, Level 3: 220, Level 4: 364, etc.
	var total_exp = BASE_EXP_FOR_LEVEL_2
	for i in range(3, level + 1):
		total_exp += BASE_EXP_FOR_LEVEL_2 * pow(EXP_MULTIPLIER_PER_LEVEL, i - 2)
	return total_exp

func calculate_level_from_experience(experience: float) -> int:
	"""Calculate skill level from total experience points"""
	var level = MIN_SKILL_LEVEL
	for check_level in range(MIN_SKILL_LEVEL + 1, MAX_SKILL_LEVEL + 1):
		var exp_needed = get_experience_for_level(check_level)
		if experience >= exp_needed:
			level = check_level
		else:
			break
	return level

func get_skill_level(job_name: String = "") -> int:
	"""Get current skill level for a job (defaults to current job)"""
	if job_name == "":
		job_name = _get_job_name(job_type)
	if job_name == "":
		return MIN_SKILL_LEVEL
	return skill_levels.get(job_name, MIN_SKILL_LEVEL)

func gain_experience(amount: float, job_name: String = "") -> void:
	"""Gain experience for a job and level up if needed"""
	if job_name == "":
		job_name = _get_job_name(job_type)
	if job_name == "":
		return
	
	# Initialize if needed
	if not experience_points.has(job_name):
		experience_points[job_name] = 0.0
	if not skill_levels.has(job_name):
		skill_levels[job_name] = MIN_SKILL_LEVEL
	
	# Add experience
	var old_level = skill_levels[job_name]
	experience_points[job_name] += amount
	
	# Check for level up
	var new_level = calculate_level_from_experience(experience_points[job_name])

	# Check housing level cap (Pixel Tribe inspired)
	var housing_level_cap = get_housing_level_cap()
	if new_level > housing_level_cap:
		new_level = housing_level_cap

	if new_level > old_level and new_level <= MAX_SKILL_LEVEL and new_level > skill_levels[job_name]:
		skill_levels[job_name] = new_level
		update_skill_bonuses()
		print("[Villager ", villager_id, "] Leveled up! ", job_name, " level ", old_level, " -> ", new_level, " (Housing cap: ", housing_level_cap, ")")
	
	# Update bonuses even if no level up (in case bonuses are exp-based)
	update_skill_bonuses()

func get_housing_level_cap() -> int:
	"""Get maximum villager level allowed by current housing (Pixel Tribe inspired)"""
	if not BuildingManager:
		return MAX_SKILL_LEVEL  # Default to max if no building manager

	# Find which building this villager is housed in
	for building_id in BuildingManager.placed_buildings.keys():
		var residents = BuildingManager.housing_residents.get(building_id, [])
		if villager_id in residents:
			return BuildingManager.get_max_villager_level_for_building(building_id)

	# No housing found, return default
	return 5

func calculate_extended_happiness_factors() -> Dictionary:
	"""Calculate extended happiness factors (Pixel Tribe inspired)"""
	var factors = {
		"housing": 0.0,
		"job_satisfaction": 0.0,
		"public_services": 0.0,
		"overcrowding": 0.0
	}

	# Housing Quality Factor
	factors.housing = calculate_housing_happiness()

	# Job Satisfaction Factor
	factors.job_satisfaction = calculate_job_satisfaction()

	# Public Services Factor
	factors.public_services = calculate_public_services_happiness()

	# Overcrowding Penalty
	factors.overcrowding = calculate_overcrowding_penalty()

	return factors

func calculate_housing_happiness() -> float:
	"""Calculate happiness bonus from housing quality"""
	if not BuildingManager:
		return BASE_HOUSING_HAPPINESS / 60.0  # Convert to per-second rate

	# Find villager's housing
	var housing_building_id = ""
	for building_id in BuildingManager.housing_residents.keys():
		var residents = BuildingManager.housing_residents[building_id]
		if villager_id in residents:
			housing_building_id = building_id
			break

	if housing_building_id.is_empty():
		# No housing - reduced happiness
		return (BASE_HOUSING_HAPPINESS * 0.3) / 60.0

	# Get housing quality bonuses
	var building_data = BuildingManager.placed_buildings[housing_building_id]
	var building_type = building_data.get("building_type", "")
	var base_data = BuildingManager.buildings_data_cache.get(building_type, {})

	var happiness_bonus = base_data.get("effects", {}).get("happiness_bonus", 0.0)

	# Add level-based bonuses
	var building_level = BuildingManager.get_building_level(housing_building_id)
	var level_multiplier = 1.0 + (building_level - 1) * 0.2  # 20% bonus per level

	return (BASE_HOUSING_HAPPINESS + happiness_bonus) * level_multiplier / 60.0

func calculate_job_satisfaction() -> float:
	"""Calculate happiness bonus from job satisfaction"""
	var has_job = job_type >= 0
	if not has_job:
		return -5.0 / 60.0  # Penalty for unemployment

	# Check if this is the villager's preferred job (based on highest skill)
	var current_job_name = _get_job_name(job_type)
	var highest_skill_job = ""
	var highest_skill_level = 0

	for job_name in skill_levels.keys():
		if skill_levels[job_name] > highest_skill_level:
			highest_skill_level = skill_levels[job_name]
			highest_skill_job = job_name

	var is_preferred_job = current_job_name == highest_skill_job
	var job_bonus = PREFERRED_JOB_BONUS if is_preferred_job else 5.0  # Small bonus even for non-preferred jobs

	return job_bonus / 60.0

func calculate_public_services_happiness() -> float:
	"""Calculate happiness bonus from nearby public services"""
	if not BuildingManager:
		return 0.0

	var total_bonus = 0.0
	var villager_position = global_position

	# Check all public buildings within range
	for building_id in BuildingManager.placed_buildings.keys():
		var building_data = BuildingManager.placed_buildings[building_id]
		var building_type = building_data.get("building_type", "")
		var base_data = BuildingManager.buildings_data_cache.get(building_type, {})

		# Check if it's a public building with happiness effects
		var effects = base_data.get("effects", {})
		if effects.has("happiness_bonus") or effects.has("morale_bonus"):
			var grid_pos = building_data.get("grid_position", Vector2i.ZERO)
			var building_world_pos = CityManager.grid_to_world(grid_pos)
			var distance = villager_position.distance_to(building_world_pos)

			if distance <= PUBLIC_SERVICE_RANGE:
				var happiness_effect = effects.get("happiness_bonus", 0.0)
				var morale_effect = effects.get("morale_bonus", 0.0)

				# Distance falloff (full effect at 0 distance, half at max range)
				var distance_factor = 1.0 - (distance / PUBLIC_SERVICE_RANGE) * 0.5
				total_bonus += (happiness_effect + morale_effect) * distance_factor

	return total_bonus / 60.0  # Convert to per-second rate

func calculate_overcrowding_penalty() -> float:
	"""Calculate happiness penalty from overcrowding"""
	if not BuildingManager:
		return 0.0

	# Find villager's housing
	var housing_building_id = ""
	for building_id in BuildingManager.housing_residents.keys():
		var residents = BuildingManager.housing_residents[building_id]
		if villager_id in residents:
			housing_building_id = building_id
			break

	if housing_building_id.is_empty():
		return -10.0 / 60.0  # Penalty for homelessness

	var building_data = BuildingManager.placed_buildings[housing_building_id]
	var building_type = building_data.get("building_type", "")
	var base_data = BuildingManager.buildings_data_cache.get(building_type, {})

	var housing_capacity = base_data.get("housing_capacity", 1)
	var current_residents = BuildingManager.get_housing_count(housing_building_id)

	if current_residents <= housing_capacity:
		return 0.0  # No overcrowding

	var overcrowd_count = current_residents - housing_capacity
	var penalty = -overcrowd_count * OVERCROWD_PENALTY_PER_PERSON

	return penalty / 60.0  # Convert to per-second rate

func update_skill_bonuses() -> void:
	"""Update all skill-based bonuses based on current job skill level and global village skills"""
	var current_job_name = _get_job_name(job_type)
	var skill_level = get_skill_level(current_job_name)

	# Individual villager skill bonuses (existing system)
	# Skill level 1 = no bonus (1.0x), level 10 = 2.0x bonus
	# Linear scaling: 1.0 + (level - 1) * 0.111...
	var skill_multiplier = 1.0 + ((skill_level - MIN_SKILL_LEVEL) * (1.0 / (MAX_SKILL_LEVEL - MIN_SKILL_LEVEL)))

	# Global village skill bonuses (Pixel Tribe inspired)
	var global_skill_bonus = 1.0
	if SkillManager:
		global_skill_bonus = SkillManager.get_task_time_modifier(job_type)

	# Combine individual and global bonuses
	# Work speed: Higher skill = faster work (1.0x to 2.0x), plus global village bonus
	var base_work_speed = skill_multiplier * global_skill_bonus

	# Happiness affects work efficiency (Pixel Tribe inspired)
	var happiness_efficiency = 0.7 + (happiness / 100.0) * 0.6  # 0.7x to 1.3x based on happiness

	work_speed_bonus = base_work_speed * happiness_efficiency

	# Harvest bonus: Higher skill = more resources (1.0x to 1.5x)
	# Individual skill bonus only (global skills don't affect harvest amounts)
	harvest_bonus = 1.0 + ((skill_level - MIN_SKILL_LEVEL) * (0.5 / (MAX_SKILL_LEVEL - MIN_SKILL_LEVEL)))

	# Movement speed: Higher skill = slightly faster movement (1.0x to 1.3x)
	# Individual skill bonus only
	movement_speed_bonus = 1.0 + ((skill_level - MIN_SKILL_LEVEL) * (0.3 / (MAX_SKILL_LEVEL - MIN_SKILL_LEVEL)))

	# Carrying capacity: Higher skill = can carry more (1.0x to 1.5x)
	# Individual skill bonus only
	carrying_capacity_bonus = 1.0 + ((skill_level - MIN_SKILL_LEVEL) * (0.5 / (MAX_SKILL_LEVEL - MIN_SKILL_LEVEL)))

	# Apply bonuses to actual values
	move_speed = DEFAULT_MOVE_SPEED * movement_speed_bonus
	max_carrying_capacity = DEFAULT_MAX_CARRYING_CAPACITY * carrying_capacity_bonus

# Task execution system
func update_work_task() -> void:
	var job_system = get_node_or_null("/root/JobSystem")
	if not job_system:
		return

	current_task = job_system.get_next_task(villager_id)
	if current_task.is_empty():
		return
	
	# Throttle logging
	if randf() < TASK_UPDATE_LOG_CHANCE:  # Only log 10% of task updates
		print("[Villager ", villager_id, "] Got new task: ", current_task.get("description", "unknown"))

func execute_current_task() -> void:
	var job_system = get_node_or_null("/root/JobSystem")

	if current_task.is_empty():
		return

	# Priority: If carrying resources, deposit them first regardless of assigned task
	if not carrying_resource.is_empty():
		execute_deposit_task()
		return

	var task_type = current_task.get("type", -1)
	if task_type == -1:
		return

	if job_system:
		match task_type:
			job_system.TaskType.MOVE_TO:
				execute_task_move_to()
			job_system.TaskType.HARVEST_RESOURCE:
				execute_task_harvest()
			job_system.TaskType.DEPOSIT_RESOURCE:
				execute_task_deposit()
			job_system.TaskType.RETURN_TO_WORKPLACE:
				execute_task_return()

func execute_deposit_task() -> void:
	"""Execute deposit task when carrying resources (smart gathering)"""
	# Find nearest stockpile to deposit resources
	var stockpile_buildings = BuildingManager.get_buildings_of_type("stockpile")
	if stockpile_buildings.is_empty():
		print("[Villager ", villager_id, "] No stockpiles available for depositing")
		# Drop resources on ground or wait
		return

	# Find closest stockpile
	var closest_stockpile_id = ""
	var closest_distance = INF
	var villager_pos = global_position

	for building_id in stockpile_buildings:
		var building = BuildingManager.get_building(building_id)
		if building:
			var building_grid_pos = building.get("grid_position", Vector2i.ZERO)
			var building_world_pos = CityManager.grid_to_world(building_grid_pos)
			var distance = villager_pos.distance_to(building_world_pos)
			if distance < closest_distance:
				closest_distance = distance
				closest_stockpile_id = building_id

	if closest_stockpile_id == "":
		print("[Villager ", villager_id, "] No valid stockpile found")
		return

	# Move to stockpile with pathfinding support
	var stockpile = BuildingManager.get_building(closest_stockpile_id)
	var stockpile_grid_pos = stockpile.get("grid_position", Vector2i.ZERO)
	var stockpile_world_pos = CityManager.grid_to_world(stockpile_grid_pos)
	
	# Check if already at stockpile
	var distance_to_stockpile = villager_pos.distance_to(stockpile_world_pos)
	if distance_to_stockpile < TARGET_ARRIVAL_DISTANCE:
		# Already at stockpile, deposit immediately
		_deposit_carried_resources()
		if not current_task.is_empty():
			complete_current_task()
		update_work_task()
		return
	
	# Optimize pathfinding: use direct movement for very short distances
	var tile_size = CityManager.TILE_SIZE
	
	if distance_to_stockpile < tile_size * DIRECT_MOVEMENT_THRESHOLD:
		# Very close, use direct movement
		target_position = stockpile_world_pos
		current_path = []
		current_waypoint_index = 0
		set_state(State.WALKING)
		print("[Villager ", villager_id, "] Moving directly to stockpile to deposit ", get_total_carried(), " resources")
		return
	
	# Get pathfinding path for longer distances
	var start_grid = get_current_grid_position()
	var end_grid = CityManager.world_to_grid(stockpile_world_pos)
	
	var path = CityManager.get_navigation_path(start_grid, end_grid)
	if path.is_empty():
		# Pathfinding failed, use direct movement
		target_position = stockpile_world_pos
		current_path = []
		current_waypoint_index = 0
	else:
		# Use pathfinding path
		current_path = path
		current_waypoint_index = 0
		if current_path.size() > 0:
			target_position = current_path[0]
	
	set_state(State.WALKING)
	print("[Villager ", villager_id, "] Moving to stockpile (pathfinding) to deposit ", get_total_carried(), " resources")

func _is_at_stockpile() -> bool:
	"""Check if villager is currently at a stockpile building"""
	if not BuildingManager or not CityManager:
		return false

	var stockpile_buildings = BuildingManager.get_buildings_of_type("stockpile")
	var villager_pos = global_position

	for building_id in stockpile_buildings:
		var building = BuildingManager.get_building(building_id)
		if building:
			var building_grid_pos = building.get("grid_position", Vector2i.ZERO)
			var building_world_pos = CityManager.grid_to_world(building_grid_pos)
			var distance = villager_pos.distance_to(building_world_pos)
			if distance < TARGET_ARRIVAL_DISTANCE * 2:  # Slightly larger radius for stockpiles
				return true

	return false

func _deposit_carried_resources() -> void:
	"""Deposit all carried resources to the nearest stockpile"""
	if carrying_resource.is_empty():
		print("[Villager ", villager_id, "] No resources to deposit")
		return

	# Add resources to economy storage
	var economy = GameServices.get_economy()
	if economy:
		for resource_id in carrying_resource:
			var amount = carrying_resource[resource_id]
			economy.add_resource(resource_id, amount)
			print("[Villager ", villager_id, "] Deposited ", amount, " ", resource_id)

	# Clear carried resources
	carrying_resource.clear()
	harvest_time_accumulator = 0.0  # Reset harvest timer
	set_state(State.IDLE)

	# Update visual
	if state_label:
		state_label.text = "IDLE"

	print("[Villager ", villager_id, "] Deposited all carried resources - ready for new tasks")

# Task execution handlers
func execute_task_move_to() -> void:
	var target_type = current_task.get("target_type", "")
	var target_pos: Vector2 = Vector2.ZERO
	
	# Find target based on type
	if target_type == "tree":
		var node_id = find_nearest_tree()
		if node_id.is_empty():
			# No trees available - handle retry with backoff
			handle_resource_not_found("tree")
			return
		
		# Reserve the node
		if not ResourceNodeManager.reserve_node(node_id, villager_id):
			# Node already reserved, find another
			node_id = find_nearest_tree()
			if node_id.is_empty() or not ResourceNodeManager.reserve_node(node_id, villager_id):
				handle_resource_not_found("tree")
				return
		
		target_node_id = node_id
		var node_data = ResourceNodeManager.get_node_data(node_id)
		if node_data.is_empty():
			ResourceNodeManager.release_node(node_id, villager_id)
			target_node_id = ""
			complete_current_task()
			return
		
		var grid_pos = node_data.get("grid_position", Vector2i.ZERO)
		target_pos = CityManager.grid_to_world(grid_pos)
		
		# Check if already at node
		if position.distance_to(target_pos) < NODE_ARRIVAL_DISTANCE:
			complete_current_task()
			return
	elif target_type == "stone":
		var node_id = find_nearest_stone()
		if node_id.is_empty():
			# No stone available - handle retry with backoff
			handle_resource_not_found("stone")
			return
		
		# Reserve the node
		if not ResourceNodeManager.reserve_node(node_id, villager_id):
			# Node already reserved, find another
			node_id = find_nearest_stone()
			if node_id.is_empty() or not ResourceNodeManager.reserve_node(node_id, villager_id):
				handle_resource_not_found("stone")
				return
		
		target_node_id = node_id
		var node_data = ResourceNodeManager.get_node_data(node_id)
		if node_data.is_empty():
			ResourceNodeManager.release_node(node_id, villager_id)
			target_node_id = ""
			complete_current_task()
			return
		
		var grid_pos = node_data.get("grid_position", Vector2i.ZERO)
		target_pos = CityManager.grid_to_world(grid_pos)
		
		# Check if already at node
		if position.distance_to(target_pos) < NODE_ARRIVAL_DISTANCE:
			complete_current_task()
			return
	elif target_type == "stockpile":
		var building_id = find_nearest_stockpile()
		if building_id.is_empty():
			# No stockpile available - complete task and retry next cycle
			print("[Villager ", villager_id, "] No stockpile available, completing task to retry next cycle")
			complete_current_task()
			return
		
		target_building_id = building_id
		var building = BuildingManager.get_building(building_id)
		if building.is_empty():
			print("[Villager ", villager_id, "] Stockpile building data is empty, completing task")
			complete_current_task()
			return
		
		var grid_pos = building.get("grid_position", Vector2i.ZERO)
		target_pos = CityManager.grid_to_world(grid_pos)
		
		# Check if already at stockpile
		if position.distance_to(target_pos) < BUILDING_ARRIVAL_DISTANCE:
			complete_current_task()
			return
	
	# Optimize pathfinding: use direct movement for very short distances
	var distance_to_target = position.distance_to(target_pos)
	var tile_size = CityManager.TILE_SIZE
	
	# If very close (less than 2 tiles), use direct movement
	if distance_to_target < tile_size * DIRECT_MOVEMENT_THRESHOLD:
		target_position = target_pos
		current_path = []
		current_waypoint_index = 0
		set_state(State.WALKING)
		return
	
	# Get pathfinding path for longer distances
	var start_grid = get_current_grid_position()
	var end_grid = CityManager.world_to_grid(target_pos)
	
	var path = CityManager.get_navigation_path(start_grid, end_grid)
	if path.is_empty():
		# Pathfinding failed, use direct movement
		target_position = target_pos
		current_path = []
		current_waypoint_index = 0
	else:
		# Use pathfinding path
		current_path = path
		current_waypoint_index = 0
		if current_path.size() > 0:
			target_position = current_path[0]
	
	set_state(State.WALKING)

func execute_task_harvest() -> void:
	# For farmers, harvest directly at workplace (farm)
	var resource_type = current_task.get("resource_type", "")
	if resource_type == "food" and target_node_id.is_empty():
		# Farmer harvesting at farm - no node needed
		var workplace_pos = get_workplace_position()
		if workplace_pos == Vector2.ZERO:
			# Workplace destroyed, unassign job
			var job_system = get_node_or_null("/root/JobSystem")
			if job_system:
				job_system.unassign_villager(villager_id)
			complete_current_task()
			return
		
		var workplace_distance = position.distance_to(workplace_pos)
		
		if workplace_distance > WORKPLACE_ARRIVAL_DISTANCE:  # Not at farm, move there
			var start_grid = get_current_grid_position()
			var workplace_grid = CityManager.world_to_grid(workplace_pos)
			var path = CityManager.get_navigation_path(start_grid, workplace_grid)
			if path.is_empty():
				target_position = workplace_pos
			else:
				current_path = path
				current_waypoint_index = 0
				target_position = current_path[0] if current_path.size() > 0 else workplace_pos
			set_state(State.WALKING)
			return
		
		# At farm, start working
		set_state(State.WORKING)
		task_timer = 0.0
		return
	
	# For lumberjacks/miners, harvest at resource node
	if target_node_id.is_empty():
		# Shouldn't happen, but find a node if we don't have one
		var resource = current_task.get("resource_type", "")
		if resource == "wood":
			target_node_id = find_nearest_tree()
			if not target_node_id.is_empty():
				ResourceNodeManager.reserve_node(target_node_id, villager_id)
		elif resource == "stone":
			target_node_id = find_nearest_stone()
			if not target_node_id.is_empty():
				ResourceNodeManager.reserve_node(target_node_id, villager_id)
		
		if target_node_id.is_empty():
			complete_current_task()
			return
	
	var node_data = ResourceNodeManager.get_node_data(target_node_id)
	if node_data.is_empty():
		ResourceNodeManager.release_node(target_node_id, villager_id)
		target_node_id = ""
		complete_current_task()
		return
	
	var node_grid_pos = node_data.get("grid_position", Vector2i.ZERO)
	var node_world_pos = CityManager.grid_to_world(node_grid_pos)
	var distance = position.distance_to(node_world_pos)
	
	if distance > NODE_ARRIVAL_DISTANCE:  # Not close enough, move to node first
		var start_grid = get_current_grid_position()
		var path = CityManager.get_navigation_path(start_grid, node_grid_pos)
		if path.is_empty():
			target_position = node_world_pos
		else:
			current_path = path
			current_waypoint_index = 0
			target_position = current_path[0] if current_path.size() > 0 else node_world_pos
		set_state(State.WALKING)
		return
	
	# At node, start harvesting
	set_state(State.WORKING)
	task_timer = 0.0

func execute_task_deposit() -> void:
	# If already deposited (no resources), complete task immediately
	if carrying_resource.is_empty():
		complete_current_task()
		return
	
	# Urgent task if at carrying capacity
	var is_urgent = is_at_carrying_capacity()
	
	# Check if we're at the stockpile
	if target_building_id.is_empty():
		# Find stockpile
		target_building_id = find_nearest_stockpile()
		if target_building_id.is_empty():
			complete_current_task()
			return
	
	var building = BuildingManager.get_building(target_building_id)
	if building.is_empty():
		complete_current_task()
		return
	
	var building_grid_pos = building.get("grid_position", Vector2i.ZERO)
	var building_world_pos = CityManager.grid_to_world(building_grid_pos)
	var distance = position.distance_to(building_world_pos)
	
	if distance > BUILDING_ARRIVAL_DISTANCE:  # Not close enough, move to stockpile first
		# Use optimized pathfinding
		var tile_size = CityManager.TILE_SIZE
		if distance < tile_size * DIRECT_MOVEMENT_THRESHOLD:
			# Very close, direct movement
			target_position = building_world_pos
			current_path = []
			current_waypoint_index = 0
		else:
			# Use pathfinding
			var start_grid = get_current_grid_position()
			var path = CityManager.get_navigation_path(start_grid, building_grid_pos)
			if path.is_empty():
				target_position = building_world_pos
				current_path = []
				current_waypoint_index = 0
			else:
				current_path = path
				current_waypoint_index = 0
				target_position = current_path[0] if current_path.size() > 0 else building_world_pos
		set_state(State.WALKING)
		return
	
	# At stockpile, start depositing
	set_state(State.DEPOSITING)
	task_timer = 0.0
	if is_urgent:
		print("[Villager ", villager_id, "] Urgent deposit: at carrying capacity")

func execute_task_return() -> void:
	var workplace_pos = get_workplace_position()
	if workplace_pos == Vector2.ZERO:
		# Workplace destroyed, unassign job
		var job_system = get_node_or_null("/root/JobSystem")
		if job_system:
			job_system.unassign_villager(villager_id)
		complete_current_task()
		return
	
	# Check if already at workplace
	var distance = position.distance_to(workplace_pos)
	if distance < WORKPLACE_ARRIVAL_DISTANCE:  # Already at workplace
		complete_current_task()
		return
	
	# Optimize pathfinding for return trip
	var tile_size = CityManager.TILE_SIZE
	if distance < tile_size * DIRECT_MOVEMENT_THRESHOLD:
		# Very close, direct movement
		target_position = workplace_pos
		current_path = []
		current_waypoint_index = 0
		set_state(State.WALKING)
		return
	
	# Get pathfinding path to workplace
	var start_grid = get_current_grid_position()
	var end_grid = CityManager.world_to_grid(workplace_pos)
	
	var path = CityManager.get_navigation_path(start_grid, end_grid)
	if path.is_empty():
		# Pathfinding failed, use direct movement
		target_position = workplace_pos
		current_path = []
		current_waypoint_index = 0
	else:
		# Use pathfinding path
		current_path = path
		current_waypoint_index = 0
		if current_path.size() > 0:
			target_position = current_path[0]
	
	set_state(State.WALKING)

func complete_current_task() -> void:
	var job_system = get_node_or_null("/root/JobSystem")

	# Release node reservation if we have one
	if target_node_id != "":
		ResourceNodeManager.release_node(target_node_id, villager_id)
		target_node_id = ""

	if not job_system:
		current_task = {}  # Clear task so we can get a new one
		return
	
	# Grant experience for work tasks before completing
	var task_type = current_task.get("type", -1)
	var task_desc = current_task.get("description", "unknown task")

	if job_system and task_type == job_system.TaskType.HARVEST_RESOURCE and job_type != -1:
		# Grant experience for completing harvest/work tasks
		gain_experience(BASE_EXP_PER_TASK)
		print("[Villager ", villager_id, "] Completed harvest task: ", task_desc)

	if job_system:
		job_system.complete_task(villager_id)

	# Show completion feedback
	if job_system and task_type == job_system.TaskType.HARVEST_RESOURCE:
		show_task_completion_effect("Harvest Complete!")
	elif job_system and task_type == job_system.TaskType.DEPOSIT_RESOURCE:
		show_task_completion_effect("Deposit Complete!")
	elif job_system and task_type == job_system.TaskType.RETURN_TO_WORKPLACE:
		show_task_completion_effect("Returned to Workplace")

	print("[Villager ", villager_id, "] Task completed: ", task_desc)

	# Clear current task so we can get a new one on next frame
	current_task = {}

	# Emit work completed signal if we had a job
	if job_type != -1:
		var world = GameServices.get_world()
		if world:
			var job_type_name = GameWorld.JobType.keys()[job_type].to_lower()
			work_completed.emit(job_type_name)
	
	task_timer = 0.0
	target_node_id = ""
	target_building_id = ""
	current_path = []
	current_waypoint_index = 0
	retry_count = 0  # Reset retry count on successful completion
	
	# If we're carrying resources, we should continue to deposit
	# Set state to IDLE so task polling can get the next task (deposit)
	if not carrying_resource.is_empty():
		set_state(State.IDLE)

# Helper functions
func get_current_grid_position() -> Vector2i:
	return CityManager.world_to_grid(position)

func get_workplace_position() -> Vector2:
	var job_system = get_node_or_null("/root/JobSystem")
	if not job_system:
		return Vector2.ZERO

	var building_id = job_system.job_assignments.get(villager_id, "")
	if building_id.is_empty():
		return Vector2.ZERO
	
	var building = BuildingManager.get_building(building_id)
	if building.is_empty():
		return Vector2.ZERO
	
	var grid_pos = building.get("grid_position", Vector2i.ZERO)
	return CityManager.grid_to_world(grid_pos)

func find_nearest_tree() -> String:
	if not ResourceNodeManager:
		return ""
	
	return ResourceNodeManager.get_nearest_available_node(
		position,
		ResourceNodeManager.ResourceNodeType.TREE,
		DEFAULT_SEARCH_DISTANCE
	)

func find_nearest_stone() -> String:
	if not ResourceNodeManager:
		return ""
	
	return ResourceNodeManager.get_nearest_available_node(
		position,
		ResourceNodeManager.ResourceNodeType.STONE,
		DEFAULT_SEARCH_DISTANCE
	)

func find_nearest_stockpile() -> String:
	if not BuildingManager or not CityManager:
		return ""
	
	var stockpiles = BuildingManager.get_buildings_of_type("stockpile")
	if stockpiles.is_empty():
		return ""
	
	var nearest_id: String = ""
	var nearest_distance: float = MAX_SEARCH_DISTANCE
	
	for building_id in stockpiles:
		var building = BuildingManager.get_building(building_id)
		if building.is_empty():
			continue
		
		var grid_pos = building.get("grid_position", Vector2i.ZERO)
		var world_pos = CityManager.grid_to_world(grid_pos)
		# Use distance_squared for performance (avoid sqrt calculation)
		var distance_sq = position.distance_squared_to(world_pos)
		
		if distance_sq < nearest_distance * nearest_distance:
			nearest_distance = sqrt(distance_sq)
			nearest_id = building_id
	
	return nearest_id

func update_needs(delta: float) -> void:
	# Decrease hunger over time
	hunger = max(0.0, hunger - hunger_rate * delta)

	# Check if starving
	if hunger <= 0.0 and not is_starving:
		is_starving = true
		print("[Villager ", villager_id, "] Is starving!")
		# Could trigger death or reduced efficiency here
	elif hunger > STARVING_RECOVERY_THRESHOLD and is_starving:
		is_starving = false

	# Update happiness and health based on hunger and building effects
	update_happiness_health(delta)

	# Update visual indicators
	update_state_visual()

	# Update work progress visual if working
	if current_state == State.WORKING and task_timer > 0:
		update_work_progress_visual()

func eat_food(amount: float = HUNGER_RECOVERY_AMOUNT) -> bool:
	# Villager consumes food to restore hunger
	var economy = GameServices.get_economy()
	if economy and economy.get_resource("food") >= amount:
		economy.consume_resource("food", amount)
		hunger = min(MAX_NEED_VALUE, hunger + amount)
		happiness = min(MAX_NEED_VALUE, happiness + HAPPINESS_FOOD_BONUS)
		print("[Villager ", villager_id, "] Ate food, hunger: ", hunger)
		return true
	return false

func get_needs_status() -> Dictionary:
	return {
		"hunger": hunger,
		"happiness": happiness,
		"health": health,
		"is_starving": is_starving
	}

func get_work_efficiency() -> float:
	"""Calculate work efficiency based on current needs (0.0 to 1.0)"""
	var efficiency = 1.0

	# Hunger penalty
	if hunger < HUNGER_THRESHOLD_LOW:
		var hunger_penalty = (hunger / HUNGER_THRESHOLD_LOW) * EFFICIENCY_HUNGER_PENALTY_MULTIPLIER
		efficiency *= (EFFICIENCY_HUNGER_PENALTY_MULTIPLIER + hunger_penalty)
	elif hunger < HUNGER_THRESHOLD_CRITICAL:
		efficiency *= EFFICIENCY_CRITICAL_HUNGER_PENALTY

	# Happiness bonus/penalty
	var happiness_factor = (happiness / MAX_NEED_VALUE - 0.5) * EFFICIENCY_HAPPINESS_MULTIPLIER
	efficiency *= (1.0 + happiness_factor)

	# Health penalty
	if health < EFFICIENCY_HEALTH_THRESHOLD:
		var health_penalty = (EFFICIENCY_HEALTH_THRESHOLD - health) / EFFICIENCY_HEALTH_THRESHOLD * EFFICIENCY_HEALTH_PENALTY_MULTIPLIER
		efficiency *= (1.0 - health_penalty)

	return clamp(efficiency, EFFICIENCY_MINIMUM, EFFICIENCY_MAXIMUM)

func update_task_visual_effects() -> void:
	"""Update visual effects based on current task"""
	var job_system = get_node_or_null("/root/JobSystem")

	# Use cached visual reference
	if not _cached_visual:
		_cached_visual = find_child("Visual", true, false)
	if not _cached_visual:
		return

	var visual = _cached_visual

	# Update state label with task information
	if state_label and current_task.has("description"):
		var task_desc = current_task.get("description", "")
		var task_type = current_task.get("type", -1)

		# Add resource type info for harvest tasks
		if job_system and task_type == job_system.TaskType.HARVEST_RESOURCE:
			var resource_type = current_task.get("resource_type", "")
			if resource_type != "":
				task_desc += " (" + resource_type + ")"

		state_label.text = task_desc
	else:
		# Default state display
		match current_state:
			State.IDLE:
				state_label.text = "Idle"
			State.WALKING:
				state_label.text = "Walking"
			State.WORKING:
				state_label.text = "Working"
			State.CARRYING:
				var carried = get_total_carried()
				if carried > 0:
					var resource_info = ""
					for resource_id in carrying_resource:
						if carrying_resource[resource_id] > 0:
							resource_info += str(carrying_resource[resource_id]) + " " + resource_id + " "
					state_label.text = "Carrying: " + resource_info
				else:
					state_label.text = "Carrying"
			State.DEPOSITING:
				state_label.text = "Depositing"

func update_work_progress_visual() -> void:
	"""Show work progress for current task"""
	var job_system = get_node_or_null("/root/JobSystem")

	if not current_task.has("type"):
		return

	var task_type = current_task.get("type", -1)
	var progress_text = ""

	if job_system:
		match task_type:
			job_system.TaskType.HARVEST_RESOURCE:
				var resource_type = current_task.get("resource_type", "")
				var total_duration = RESOURCE_HARVEST_DURATION / work_speed_bonus
				var progress = clamp(task_timer / total_duration, 0.0, 1.0)
				progress_text = "Harvesting " + resource_type + " (" + str(int(progress * 100)) + "%)"
			job_system.TaskType.DEPOSIT_RESOURCE:
				progress_text = "Depositing resources..."
			_:
				progress_text = "Working..."

	if state_label:
		state_label.text = progress_text

func show_task_completion_effect(message: String) -> void:
	"""Show a brief visual effect when a task is completed"""
	var ui = GameServices.get_ui()
	if ui and ui.has_method("show_toast"):
		ui.show_toast(message, "success", 2.0)

func check_stuck(delta: float) -> void:
	# Check if villager is stuck (hasn't moved in 3 seconds)
	if current_state == State.WALKING:
		if position.distance_to(last_position) < STUCK_DETECTION_DISTANCE:
			stuck_timer += delta
			if stuck_timer > STUCK_DETECTION_TIME:
				# Stuck! Try direct movement
				print("[Villager ", villager_id, "] Detected stuck, trying direct movement")
				current_path = []
				current_waypoint_index = 0
				stuck_timer = 0.0
		else:
			stuck_timer = 0.0
			last_position = position
	else:
		stuck_timer = 0.0
		last_position = position

func handle_resource_not_found(resource_type: String) -> void:
	retry_count += 1
	
	if retry_count > MAX_RETRY_COUNT:
		# Too many retries, complete task and let work cycle handle it
		print("[Villager ", villager_id, "] Too many retries for ", resource_type, ", completing task")
		complete_current_task()
		retry_count = 0
	else:
		# Complete task to retry on next cycle (exponential backoff handled by work cycle recreation)
		print("[Villager ", villager_id, "] ", resource_type, " not found, will retry (attempt ", retry_count, ")")
		complete_current_task()

func create_eat_task() -> void:
	# Simplified eating: just eat if food is available, no movement needed
	var economy = GameServices.get_economy()
	if economy and economy.get_resource("food") >= HUNGER_RECOVERY_AMOUNT:
		# Eat directly
		if eat_food(HUNGER_RECOVERY_AMOUNT):
			needs_food = false
			# Task complete, will resume work on next update
			current_task = {}
			return
	
	# No food available - don't set needs_food to false here, let the main loop handle it
	# This prevents infinite loops
	current_task = {}
