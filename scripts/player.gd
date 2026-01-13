# Player Controller for Dr. Pepper
#
# This script controls the player character's movement in a top-down 2D game.
# extends CharacterBody2D means this script adds behavior to a CharacterBody2D node,
# which is Godot's built-in node type for characters that move with physics.
#
# Learn more: https://docs.godotengine.org/en/stable/classes/class_characterbody2d.html

extends CharacterBody2D

# ============================================================================
# EXPORTED VARIABLES
# @export makes variables editable in the Godot editor's Inspector panel.
# This lets you tune values without changing code!
# ============================================================================

@export var speed: float = 300.0  # How fast the player moves (pixels per second)
@export var interaction_range: float = 80.0  # How close player must be to interact with objects

# ============================================================================
# PRIVATE VARIABLES
# Variables without @export are only used internally in this script
# ============================================================================

var nearest_interactable: Node = null  # Stores the closest object we can interact with

# ============================================================================
# GODOT LIFECYCLE FUNCTIONS
# These are special functions that Godot calls automatically:
# - _ready() runs once when the scene loads
# - _physics_process(delta) runs every physics frame (usually 60 times per second)
# ============================================================================

func _ready():
	# Called when the node enters the scene tree
	# Add to player group so other scripts can find us
	add_to_group("player")

	# Set up the player's collision layer and mask
	# Layer 2 = Player (this is what WE are)
	# Mask = World(1), Enemies(3), Buildings(4), Resources(5)
	collision_layer = 2  # We are on layer 2 (Player)
	collision_mask = 1 + 4 + 8 + 16  # We collide with layers 1, 3, 4, 5

	print("Dr. Pepper is ready to save humanity!")


func _physics_process(delta: float):
	# delta is the time elapsed since the last frame (in seconds)
	# This function runs every physics frame, handling movement and interactions

	handle_movement(delta)
	find_nearest_interactable()
	handle_interaction()


# ============================================================================
# MOVEMENT SYSTEM
# ============================================================================

func handle_movement(_delta: float):
	# Get input from the player
	# Input.get_axis returns -1, 0, or 1 based on which keys are pressed
	# For example: A=-1, D=+1, both pressed=0, neither pressed=0
	var input_dir = Vector2(
		Input.get_axis("move_left", "move_right"),  # Horizontal (-1 to 1)
		Input.get_axis("move_up", "move_down")      # Vertical (-1 to 1)
	)

	# Normalize the direction vector so diagonal movement isn't faster
	# Without normalize: moving diagonally would be speed * 1.414
	# With normalize: all directions move at the same speed
	if input_dir.length() > 0:
		input_dir = input_dir.normalized()

	# Set the velocity (speed and direction)
	# velocity is a built-in property of CharacterBody2D
	velocity = input_dir * speed

	# move_and_slide() is a CharacterBody2D function that:
	# 1. Moves the character
	# 2. Handles collisions automatically
	# 3. Slides along walls instead of stopping
	move_and_slide()

	# Optional: Rotate player to face movement direction
	if velocity.length() > 0:
		rotation = velocity.angle()


# ============================================================================
# INTERACTION SYSTEM
# ============================================================================

func find_nearest_interactable():
	# This function finds the closest object the player can interact with
	# (resource nodes, buildings, etc.)

	nearest_interactable = null
	var closest_distance = interaction_range

	# Check for resource nodes
	for node in get_tree().get_nodes_in_group("interactable"):
		var distance = global_position.distance_to(node.global_position)
		if distance < closest_distance:
			closest_distance = distance
			nearest_interactable = node


func handle_interaction():
	# When player presses the interact key (E), interact with nearest object
	if Input.is_action_just_pressed("interact"):
		if nearest_interactable and nearest_interactable.has_method("interact"):
			nearest_interactable.interact()
			print("Interacting with: ", nearest_interactable.name)


# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

func take_damage(amount: int):
	# Called when player is hit by enemies
	# TODO: Implement health system and game over
	print("Dr. Pepper took ", amount, " damage!")


func get_interaction_position() -> Vector2:
	# Returns position slightly in front of the player
	# Useful for placing buildings or projectiles
	var offset = Vector2(50, 0).rotated(rotation)
	return global_position + offset
