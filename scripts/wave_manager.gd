# Wave Manager - Enemy Spawning System
#
# Manages wave-based enemy spawning, increasing difficulty over time.
# This creates the "tower defense" aspect of the game.

extends Node2D

# ============================================================================
# EXPORTED VARIABLES
# ============================================================================

@export var time_between_waves: float = 30.0  # Seconds between waves
@export var auto_start_waves: bool = true  # Automatically start next wave

# ============================================================================
# SPAWN CONFIGURATION
# ============================================================================

# Define spawn positions around the map
var spawn_positions: Array[Vector2] = [
	Vector2(200, 200),
	Vector2(1100, 200),
	Vector2(200, 600),
	Vector2(1100, 600),
	Vector2(650, 100),
	Vector2(650, 700),
]

# Preload enemy scenes
var enemy_scenes: Dictionary = {}

# ============================================================================
# STATE
# ============================================================================

var wave_timer: float = 0.0
var waiting_for_wave: bool = false
var enemies_remaining: int = 0

# ============================================================================
# GODOT LIFECYCLE
# ============================================================================

func _ready():
	# Preload enemy scenes
	enemy_scenes[0] = preload("res://scenes/enemies/grunt.tscn")  # Grunt

	print("Wave Manager initialized")

	# Start first wave after a delay
	if auto_start_waves:
		wave_timer = 10.0  # 10 second grace period at start
		waiting_for_wave = true


func _process(delta: float):
	if not GameManager.is_game_active():
		return

	# Wave timer
	if waiting_for_wave:
		wave_timer -= delta

		if wave_timer <= 0:
			start_wave()


# ============================================================================
# WAVE MANAGEMENT
# ============================================================================

func start_wave():
	"""Start a new wave of enemies"""
	waiting_for_wave = false

	GameManager.start_next_wave()

	var wave_num = GameManager.current_wave

	# Determine wave composition
	var wave_enemies = get_wave_composition(wave_num)

	# Spawn enemies
	spawn_wave(wave_enemies)

	print("\nWave ", wave_num, " started with ", enemies_remaining, " enemies!")


func get_wave_composition(wave: int) -> Array:
	"""
	Returns an array of enemy types to spawn for this wave.
	Gets progressively harder with each wave.
	"""
	var enemies = []

	# Basic formula: more enemies and tougher types as waves progress
	var grunt_count = 3 + (wave * 2)  # Starts with 5 grunts, +2 each wave
	var armored_count = max(0, wave - 2)  # Armored grunts appear from wave 3

	# Add grunts
	for i in range(grunt_count):
		enemies.append(0)  # EnemyType.GRUNT

	# Add armored grunts
	for i in range(armored_count):
		enemies.append(1)  # EnemyType.ARMORED_GRUNT

	return enemies


func spawn_wave(enemies: Array):
	"""Spawn all enemies for the wave"""
	enemies_remaining = enemies.size()

	for i in range(enemies.size()):
		var enemy_type = enemies[i]

		# Spawn with delay between enemies
		await get_tree().create_timer(0.5 * (i + 1)).timeout

		spawn_enemy(enemy_type)


func spawn_enemy(enemy_type: int):
	"""Spawn a single enemy"""
	if enemy_type not in enemy_scenes:
		print("Unknown enemy type: ", enemy_type)
		return

	# Create enemy
	var enemy = enemy_scenes[enemy_type].instantiate()

	# Choose random spawn position
	var spawn_pos = spawn_positions[randi() % spawn_positions.size()]
	enemy.global_position = spawn_pos

	# Set enemy type
	enemy.enemy_type = enemy_type

	# Connect death signal
	enemy.tree_exiting.connect(_on_enemy_died)

	# Add to scene
	get_parent().add_child(enemy)


func _on_enemy_died():
	"""Called when an enemy dies"""
	enemies_remaining -= 1

	if enemies_remaining <= 0:
		complete_wave()


func complete_wave():
	"""Wave is complete, all enemies defeated"""
	GameManager.complete_wave()

	# Start timer for next wave
	waiting_for_wave = true
	wave_timer = time_between_waves

	print("Next wave in ", time_between_waves, " seconds...")


# ============================================================================
# MANUAL CONTROL
# ============================================================================

func trigger_next_wave():
	"""Manually trigger the next wave (for testing or player-initiated)"""
	if not waiting_for_wave:
		print("Wave already in progress!")
		return

	wave_timer = 0.0  # This will trigger start_wave on next frame


func get_time_until_next_wave() -> float:
	"""Returns seconds until next wave"""
	if waiting_for_wave:
		return wave_timer
	return 0.0
