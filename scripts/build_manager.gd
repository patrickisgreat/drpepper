# Build Manager
#
# Manages the building placement system. Handles:
# - Ghost preview of buildings
# - Placement validation (collision, resources)
# - Building construction

extends Node2D

# ============================================================================
# EXPORTED VARIABLES
# ============================================================================

@export var grid_size: int = 32  # Snap buildings to grid

# ============================================================================
# BUILDING SCENES
# These are preloaded so we can instance them quickly
# ============================================================================

var building_scenes: Dictionary = {}

# ============================================================================
# STATE
# ============================================================================

var build_mode_active: bool = false
var current_building_type: int = 0  # Building.BuildingType enum value
var ghost_building: Node2D = null
var can_place: bool = false

# Reference to player
var player: Node = null

# ============================================================================
# GODOT LIFECYCLE
# ============================================================================

func _ready():
	# Preload building scenes
	building_scenes[0] = preload("res://scenes/buildings/lab_station.tscn")
	building_scenes[1] = preload("res://scenes/buildings/refinery.tscn")
	building_scenes[2] = preload("res://scenes/buildings/synthesis_chamber.tscn")

	# Find player (will be set when player enters tree)
	await get_tree().process_frame
	player = get_tree().get_first_node_in_group("player")
	if not player:
		# If player doesn't have a group, try finding by type
		for node in get_tree().root.get_children():
			var players = node.find_children("*", "CharacterBody2D")
			if players.size() > 0:
				player = players[0]
				break

func _input(event: InputEvent):
	# Toggle build mode with B key
	if event.is_action_pressed("build_mode"):
		toggle_build_mode()

	# In build mode, handle building selection and placement
	if build_mode_active:
		if event.is_action_pressed("ui_accept") or event is InputEventMouseButton:
			if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
				try_place_building()

		# Number keys to select building type
		if event is InputEventKey and event.pressed:
			if event.keycode == KEY_1:
				select_building_type(0)  # Lab Station
			elif event.keycode == KEY_2:
				select_building_type(1)  # Refinery
			elif event.keycode == KEY_3:
				select_building_type(2)  # Synthesizer


func _process(_delta: float):
	if build_mode_active and ghost_building:
		update_ghost_position()
		check_placement_validity()


# ============================================================================
# BUILD MODE CONTROL
# ============================================================================

func toggle_build_mode():
	"""Enter or exit build mode"""
	build_mode_active = not build_mode_active

	if build_mode_active:
		enter_build_mode()
	else:
		exit_build_mode()


func enter_build_mode():
	"""Enter build mode"""
	print("\n=== BUILD MODE ACTIVE ===")
	print("Press 1, 2, 3 to select building type")
	print("Click to place building")
	print("Press B again to exit")
	print("=========================\n")

	select_building_type(0)  # Start with Lab Station


func exit_build_mode():
	"""Exit build mode"""
	print("Build mode deactivated")

	if ghost_building:
		ghost_building.queue_free()
		ghost_building = null


# ============================================================================
# BUILDING SELECTION
# ============================================================================

func select_building_type(type: int):
	"""Select which building type to place"""
	current_building_type = type

	# Remove old ghost
	if ghost_building:
		ghost_building.queue_free()

	# Create new ghost
	if type in building_scenes:
		ghost_building = building_scenes[type].instantiate()
		add_child(ghost_building)

		# Make it semi-transparent
		ghost_building.modulate = Color(1, 1, 1, 0.5)

		# Get the building name
		var building_name = get_building_name(type)
		print("Selected: ", building_name)

		# Show cost
		var cost = get_building_cost(type)
		var cost_str = "Cost: "
		for resource in cost:
			cost_str += resource + " x" + str(cost[resource]) + "  "
		print(cost_str)


func get_building_name(type: int) -> String:
	"""Get building name from type"""
	match type:
		0: return "Lab Station"
		1: return "Refinery"
		2: return "Synthesis Chamber"
	return "Unknown"


func get_building_cost(type: int) -> Dictionary:
	"""Get building cost from type"""
	# Import the Building script to access static function
	var Building = preload("res://scripts/building.gd")
	return Building.get_build_cost(type)


# ============================================================================
# GHOST PREVIEW
# ============================================================================

func update_ghost_position():
	"""Update ghost building position to follow mouse"""
	if not ghost_building:
		return

	# Get mouse position in world coordinates
	var mouse_pos = get_global_mouse_position()

	# Snap to grid
	mouse_pos = snap_to_grid(mouse_pos)

	ghost_building.global_position = mouse_pos


func snap_to_grid(pos: Vector2) -> Vector2:
	"""Snap a position to the building grid"""
	return Vector2(
		floor(pos.x / grid_size) * grid_size + grid_size / 2,
		floor(pos.y / grid_size) * grid_size + grid_size / 2
	)


func check_placement_validity():
	"""Check if current ghost position is valid for placement"""
	if not ghost_building:
		return

	can_place = true

	# Check collision with other buildings/objects
	var space_state = get_world_2d().direct_space_state
	var query = PhysicsShapeQueryParameters2D.new()

	# Create a shape for the query
	var shape = RectangleShape2D.new()
	shape.size = Vector2(60, 60)
	query.shape = shape
	query.transform = Transform2D(0, ghost_building.global_position)
	query.collision_mask = 8 + 16  # Buildings and Resources layers

	var result = space_state.intersect_shape(query)

	if result.size() > 0:
		can_place = false

	# Check if player has resources
	var cost = get_building_cost(current_building_type)
	if not Inventory.has_resources_for_recipe(cost):
		can_place = false

	# Update ghost color based on validity
	if can_place:
		ghost_building.modulate = Color(0.5, 1.0, 0.5, 0.7)  # Green = valid
	else:
		ghost_building.modulate = Color(1.0, 0.3, 0.3, 0.7)  # Red = invalid


# ============================================================================
# BUILDING PLACEMENT
# ============================================================================

func try_place_building():
	"""Attempt to place the current building"""
	if not can_place or not ghost_building:
		print("Cannot place building here!")
		return

	var cost = get_building_cost(current_building_type)

	# Deduct resources
	if not Inventory.consume_resources_for_recipe(cost):
		print("Not enough resources!")
		return

	# Create the actual building
	var building = building_scenes[current_building_type].instantiate()
	building.global_position = ghost_building.global_position

	# Add to scene
	get_parent().add_child(building)

	print("Building placed!")

	# Reset ghost position to create another
	update_ghost_position()
