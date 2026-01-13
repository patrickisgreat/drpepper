# Enemy - The Billionaire's Goon
#
# AI-controlled enemy that attacks the player and buildings.
# Uses Godot's navigation system for pathfinding.

extends CharacterBody2D

# ============================================================================
# ENEMY TYPE ENUM
# ============================================================================

enum EnemyType {
	GRUNT,          # Basic melee enemy
	ARMORED_GRUNT,  # Tougher version with more health
	DRONE          # Ranged flying enemy (future)
}

# ============================================================================
# EXPORTED VARIABLES
# ============================================================================

@export var enemy_type: EnemyType = EnemyType.GRUNT
@export var max_health: int = 50
@export var speed: float = 150.0
@export var damage: int = 10
@export var attack_cooldown: float = 1.0  # Time between attacks
@export var detection_range: float = 500.0  # How far enemy can see
@export var attack_range: float = 40.0  # How close to be to attack

# ============================================================================
# PRIVATE VARIABLES
# ============================================================================

var current_health: int
var target: Node = null  # What we're attacking (player or building)
var can_attack: bool = true
var attack_timer: float = 0.0

# Visual components
var sprite: Sprite2D
var label: Label
var health_bar: ProgressBar

# ============================================================================
# GODOT LIFECYCLE
# ============================================================================

func _ready():
	add_to_group("enemies")

	current_health = max_health

	# Set collision layers
	collision_layer = 4  # Layer 3 (Enemies)
	collision_mask = 1 + 2 + 8  # Collide with World(1), Player(2), Buildings(4)

	# Apply wave difficulty scaling
	if GameManager:
		var difficulty = GameManager.get_wave_difficulty()
		max_health = int(max_health * difficulty)
		current_health = max_health
		speed = speed * (1.0 + (difficulty - 1.0) * 0.1)  # Speed increases slower
		damage = int(damage * difficulty)

	setup_visual()

	print("Enemy spawned: ", get_enemy_name())


func _physics_process(delta: float):
	if not GameManager.is_game_active():
		return

	# Update attack cooldown
	if not can_attack:
		attack_timer += delta
		if attack_timer >= attack_cooldown:
			can_attack = true
			attack_timer = 0.0

	# Find target if we don't have one
	if not target or not is_instance_valid(target):
		find_target()

	# Move toward target
	if target:
		move_toward_target(delta)
		try_attack()


# ============================================================================
# VISUAL SETUP
# ============================================================================

func setup_visual():
	"""Create visual representation"""
	# Create sprite
	sprite = Sprite2D.new()
	sprite.scale = Vector2(30, 30)
	add_child(sprite)

	# Create collision shape
	var collision_shape = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 15.0
	collision_shape.shape = shape
	add_child(collision_shape)

	# Create health bar
	health_bar = ProgressBar.new()
	health_bar.position = Vector2(-20, -30)
	health_bar.size = Vector2(40, 4)
	health_bar.max_value = max_health
	health_bar.value = current_health
	add_child(health_bar)

	# Create label
	label = Label.new()
	label.text = get_enemy_name()
	label.position = Vector2(-30, -45)
	label.add_theme_font_size_override("font_size", 10)
	add_child(label)

	update_color()


func update_color():
	"""Update sprite color based on enemy type and health"""
	if not sprite:
		return

	var base_color: Color
	match enemy_type:
		EnemyType.GRUNT:
			base_color = Color(0.8, 0.1, 0.1)  # Red
		EnemyType.ARMORED_GRUNT:
			base_color = Color(0.5, 0.1, 0.1)  # Dark red
		EnemyType.DRONE:
			base_color = Color(0.3, 0.3, 0.3)  # Gray

	# Fade based on health
	var health_percent = float(current_health) / float(max_health)
	sprite.modulate = base_color * (0.6 + health_percent * 0.4)


func get_enemy_name() -> String:
	"""Get display name for this enemy type"""
	match enemy_type:
		EnemyType.GRUNT:
			return "Grunt"
		EnemyType.ARMORED_GRUNT:
			return "Armored"
		EnemyType.DRONE:
			return "Drone"
	return "Enemy"


# ============================================================================
# TARGET ACQUISITION
# ============================================================================

func find_target():
	"""Find the nearest player or building to attack"""
	var closest_distance = detection_range
	target = null

	# First priority: player
	var player = get_tree().get_first_node_in_group("player")
	if player:
		var distance = global_position.distance_to(player.global_position)
		if distance < closest_distance:
			closest_distance = distance
			target = player

	# Second priority: buildings
	for building in get_tree().get_nodes_in_group("buildings"):
		var distance = global_position.distance_to(building.global_position)
		if distance < closest_distance:
			closest_distance = distance
			target = building


# ============================================================================
# MOVEMENT & COMBAT
# ============================================================================

func move_toward_target(delta: float):
	"""Move toward the current target"""
	if not target or not is_instance_valid(target):
		return

	var direction = (target.global_position - global_position).normalized()
	var distance = global_position.distance_to(target.global_position)

	# Only move if not in attack range
	if distance > attack_range:
		velocity = direction * speed
		move_and_slide()

		# Rotate to face target
		rotation = velocity.angle()
	else:
		velocity = Vector2.ZERO


func try_attack():
	"""Try to attack the target if in range"""
	if not target or not is_instance_valid(target):
		return

	if not can_attack:
		return

	var distance = global_position.distance_to(target.global_position)

	if distance <= attack_range:
		attack()


func attack():
	"""Attack the target"""
	if not target or not is_instance_valid(target):
		return

	can_attack = false

	# Deal damage
	if target.has_method("take_damage"):
		target.take_damage(damage)
		print(get_enemy_name(), " attacked ", target.name, " for ", damage, " damage!")

	# Visual feedback
	if sprite:
		# Quick flash
		var original_scale = sprite.scale
		sprite.scale = original_scale * 1.3
		await get_tree().create_timer(0.1).timeout
		if sprite:  # Check if still valid
			sprite.scale = original_scale


# ============================================================================
# DAMAGE & DEATH
# ============================================================================

func take_damage(amount: int):
	"""Called when enemy is hit"""
	current_health -= amount
	current_health = max(0, current_health)

	# Update health bar
	if health_bar:
		health_bar.value = current_health

	update_color()

	# Create damage number
	show_damage_number(amount)

	if current_health <= 0:
		die()


func show_damage_number(amount: int):
	"""Show floating damage number"""
	var damage_label = Label.new()
	damage_label.text = "-" + str(amount)
	damage_label.position = Vector2(-10, -60)
	damage_label.modulate = Color(1, 1, 0)
	damage_label.add_theme_font_size_override("font_size", 16)
	add_child(damage_label)

	# Animate
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(damage_label, "position:y", damage_label.position.y - 30, 0.5)
	tween.tween_property(damage_label, "modulate:a", 0.0, 0.5)
	tween.finished.connect(func(): damage_label.queue_free())


func die():
	"""Enemy is defeated"""
	print(get_enemy_name(), " defeated!")

	# TODO: Drop resources or rewards

	queue_free()


# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

static func get_enemy_stats(type: EnemyType, wave: int) -> Dictionary:
	"""Static function to get enemy stats for a given type and wave"""
	var stats = {}

	match type:
		EnemyType.GRUNT:
			stats = {
				"max_health": 50,
				"speed": 150.0,
				"damage": 10,
				"attack_cooldown": 1.0
			}
		EnemyType.ARMORED_GRUNT:
			stats = {
				"max_health": 100,
				"speed": 120.0,
				"damage": 15,
				"attack_cooldown": 1.2
			}
		EnemyType.DRONE:
			stats = {
				"max_health": 40,
				"speed": 200.0,
				"damage": 8,
				"attack_cooldown": 0.8
			}

	return stats
