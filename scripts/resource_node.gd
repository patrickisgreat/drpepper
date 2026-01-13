# Resource Node - Harvestable Objects in the World
#
# Resource nodes are objects like ore deposits, chemical vents, etc.
# that players can interact with to gather materials.
#
# This script extends StaticBody2D because the nodes don't move but do
# have collision (so the player can't walk through them).

extends StaticBody2D

# ============================================================================
# EXPORTED VARIABLES
# ============================================================================

@export var resource_type: String = "Iron"  # What resource this node gives
@export var resource_amount: int = 3  # How much resource per harvest
@export var max_health: int = 100  # How much damage before depleted
@export var respawn_time: float = 30.0  # Seconds until node respawns

# ============================================================================
# PRIVATE VARIABLES
# ============================================================================

var current_health: int
var is_depleted: bool = false
var respawn_timer: Timer

# Node references (will be set in _ready)
var sprite: Sprite2D
var label: Label
var collision_shape: CollisionShape2D

# ============================================================================
# GODOT LIFECYCLE
# ============================================================================

func _ready():
	# Add this node to the "interactable" group so the player can find it
	add_to_group("interactable")

	current_health = max_health

	# Set up collision layers
	collision_layer = 16  # Layer 5 (Resources)
	collision_mask = 0  # Resources don't collide with anything

	# Create visual representation
	setup_visual()

	# Set up respawn timer
	respawn_timer = Timer.new()
	respawn_timer.one_shot = true
	respawn_timer.timeout.connect(_on_respawn_timer_timeout)
	add_child(respawn_timer)

	print("Resource node spawned: ", resource_type, " at ", global_position)


# ============================================================================
# VISUAL SETUP
# ============================================================================

func setup_visual():
	# Create a sprite to represent the resource
	sprite = Sprite2D.new()
	sprite.scale = Vector2(40, 40)
	add_child(sprite)

	# Create collision shape
	collision_shape = CollisionShape2D.new()
	var shape = CircleShape2D.new()
	shape.radius = 30.0
	collision_shape.shape = shape
	add_child(collision_shape)

	# Create label showing resource type
	label = Label.new()
	label.text = resource_type
	label.position = Vector2(-40, -50)
	label.add_theme_font_size_override("font_size", 14)
	add_child(label)

	# Color the node based on resource type
	update_color()


func update_color():
	"""Update sprite color based on resource type and health"""
	if sprite:
		var base_color = Inventory.get_resource_color(resource_type)

		if is_depleted:
			# Darkened when depleted
			sprite.modulate = base_color * 0.3
		else:
			# Fade based on health
			var health_percent = float(current_health) / float(max_health)
			sprite.modulate = base_color * (0.5 + health_percent * 0.5)


# ============================================================================
# INTERACTION SYSTEM
# ============================================================================

func interact():
	"""Called when player presses interact key near this node"""
	if is_depleted:
		print("This resource is depleted! Wait for respawn...")
		return

	harvest()


func harvest():
	"""Harvest resources from this node"""
	if is_depleted:
		return

	# Deal damage to the node
	var harvest_damage = 25  # Each harvest takes 25% of max health
	current_health -= harvest_damage

	# Give player resources
	Inventory.add_resource(resource_type, resource_amount)

	# Visual feedback
	update_color()
	create_harvest_effect()

	# Check if depleted
	if current_health <= 0:
		deplete()


func deplete():
	"""Node is depleted, start respawn timer"""
	is_depleted = true
	current_health = 0
	update_color()

	if label:
		label.text = resource_type + " (depleted)"

	# Start respawn timer
	respawn_timer.start(respawn_time)

	print(resource_type, " node depleted! Respawning in ", respawn_time, " seconds")


func _on_respawn_timer_timeout():
	"""Called when respawn timer finishes"""
	respawn()


func respawn():
	"""Restore the resource node"""
	is_depleted = false
	current_health = max_health
	update_color()

	if label:
		label.text = resource_type

	print(resource_type, " node respawned!")


# ============================================================================
# VISUAL EFFECTS
# ============================================================================

func create_harvest_effect():
	"""Create a visual effect when harvesting"""
	# Create a temporary label that floats up
	var effect_label = Label.new()
	effect_label.text = "+" + str(resource_amount) + " " + resource_type
	effect_label.position = Vector2(-50, -70)
	effect_label.modulate = Inventory.get_resource_color(resource_type)
	effect_label.add_theme_font_size_override("font_size", 18)
	add_child(effect_label)

	# Animate it floating up and fading out
	var tween = create_tween()
	tween.set_parallel(true)
	tween.tween_property(effect_label, "position:y", effect_label.position.y - 30, 1.0)
	tween.tween_property(effect_label, "modulate:a", 0.0, 1.0)
	tween.finished.connect(func(): effect_label.queue_free())


# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

func get_info_text() -> String:
	"""Returns info about this resource node (for UI tooltips)"""
	if is_depleted:
		var time_remaining = int(respawn_timer.time_left)
		return resource_type + " (respawns in " + str(time_remaining) + "s)"
	else:
		return resource_type + " (" + str(current_health) + "/" + str(max_health) + " HP)"
