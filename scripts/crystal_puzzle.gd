# Crystal Puzzle UI
#
# Displays the 3x3 grid where players place quantum dot crystals
# to summon The Great Light and win the game.

extends Control

# ============================================================================
# GRID CONFIGURATION
# ============================================================================

const GRID_SIZE = 3
const CELL_SIZE = 80
const CELL_PADDING = 10

# ============================================================================
# STATE
# ============================================================================

var grid_buttons: Array = []  # 2D array of buttons
var selected_crystal: String = ""  # Currently selected crystal type for placement

# ============================================================================
# NODE REFERENCES
# ============================================================================

var grid_container: GridContainer
var crystal_selection_panel: HBoxContainer
var info_label: Label
var close_button: Button

# ============================================================================
# GODOT LIFECYCLE
# ============================================================================

func _ready():
	# Start hidden
	visible = false

	setup_ui()

	# Connect to game manager signals
	if GameManager:
		GameManager.game_won.connect(_on_game_won)


func _input(event: InputEvent):
	# Press P to toggle puzzle UI
	if event is InputEventKey and event.pressed and event.keycode == KEY_P:
		toggle_visibility()


# ============================================================================
# UI SETUP
# ============================================================================

func setup_ui():
	"""Create the puzzle UI"""
	# Set up control
	anchor_left = 0.5
	anchor_top = 0.5
	anchor_right = 0.5
	anchor_bottom = 0.5
	offset_left = -250
	offset_top = -250
	offset_right = 250
	offset_bottom = 250

	# Background panel
	var panel = Panel.new()
	panel.set_anchors_preset(Control.PRESET_FULL_RECT)
	add_child(panel)

	# Main container
	var vbox = VBoxContainer.new()
	vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	vbox.add_theme_constant_override("separation", 10)
	add_child(vbox)

	# Title
	var title = Label.new()
	title.text = "QUANTUM DOT CRYSTAL PUZZLE"
	title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	title.add_theme_font_size_override("font_size", 20)
	vbox.add_child(title)

	# Info label
	info_label = Label.new()
	info_label.text = "Place quantum dots in the correct pattern to summon The Great Light!"
	info_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_label.add_theme_font_size_override("font_size", 12)
	vbox.add_child(info_label)

	# Grid container
	grid_container = GridContainer.new()
	grid_container.columns = GRID_SIZE
	grid_container.add_theme_constant_override("h_separation", CELL_PADDING)
	grid_container.add_theme_constant_override("v_separation", CELL_PADDING)
	vbox.add_child(grid_container)

	# Create grid cells
	create_grid()

	# Crystal selection panel
	var selection_label = Label.new()
	selection_label.text = "Select Crystal to Place:"
	selection_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	vbox.add_child(selection_label)

	crystal_selection_panel = HBoxContainer.new()
	crystal_selection_panel.alignment = BoxContainer.ALIGNMENT_CENTER
	vbox.add_child(crystal_selection_panel)

	create_crystal_selection_buttons()

	# Close button
	close_button = Button.new()
	close_button.text = "Close (P)"
	close_button.pressed.connect(toggle_visibility)
	vbox.add_child(close_button)


func create_grid():
	"""Create the 3x3 grid of buttons"""
	grid_buttons = []

	for y in range(GRID_SIZE):
		var row = []
		for x in range(GRID_SIZE):
			var button = Button.new()
			button.custom_minimum_size = Vector2(CELL_SIZE, CELL_SIZE)
			button.text = "Empty"
			button.pressed.connect(_on_grid_cell_pressed.bind(Vector2i(x, y)))

			grid_container.add_child(button)
			row.append(button)

		grid_buttons.append(row)

	# Update grid to show current state
	refresh_grid()


func create_crystal_selection_buttons():
	"""Create buttons for selecting which crystal to place"""
	var crystal_types = ["QuantumDot_Red", "QuantumDot_Blue", "QuantumDot_Green", "QuantumDot_Yellow", "QuantumDot_Purple"]

	for crystal_type in crystal_types:
		var button = Button.new()
		button.custom_minimum_size = Vector2(60, 40)

		# Get display name (e.g., "Red" from "QuantumDot_Red")
		var display_name = crystal_type.replace("QuantumDot_", "")
		button.text = display_name

		# Color the button
		var color = Inventory.get_resource_color(crystal_type)
		button.modulate = color

		# Show count
		var count = Inventory.get_resource_amount(crystal_type)
		if count > 0:
			button.text = display_name + " (" + str(count) + ")"
		else:
			button.text = display_name + " (0)"
			button.disabled = true

		button.pressed.connect(_on_crystal_selected.bind(crystal_type))

		crystal_selection_panel.add_child(button)


# ============================================================================
# INTERACTION
# ============================================================================

func _on_grid_cell_pressed(grid_pos: Vector2i):
	"""Called when a grid cell is clicked"""
	# Check if there's already a crystal here
	var existing = GameManager.get_crystal_at(grid_pos)

	if existing != "":
		# Remove crystal
		GameManager.remove_crystal(grid_pos)
		info_label.text = "Crystal removed from [" + str(grid_pos.x) + ", " + str(grid_pos.y) + "]"
	else:
		# Place crystal (if one is selected)
		if selected_crystal == "":
			info_label.text = "Select a crystal type first!"
			return

		if GameManager.place_crystal(grid_pos, selected_crystal):
			info_label.text = "Placed " + selected_crystal + " at [" + str(grid_pos.x) + ", " + str(grid_pos.y) + "]"
		else:
			info_label.text = "Cannot place crystal - do you have one?"

	# Refresh display
	refresh_grid()
	refresh_crystal_buttons()


func _on_crystal_selected(crystal_type: String):
	"""Called when a crystal type is selected"""
	selected_crystal = crystal_type
	info_label.text = "Selected: " + crystal_type.replace("QuantumDot_", "") + " - Click a grid cell to place"


func toggle_visibility():
	"""Show/hide the puzzle UI"""
	visible = not visible

	if visible:
		refresh_grid()
		refresh_crystal_buttons()
		GameManager.pause_game()
	else:
		GameManager.resume_game()


# ============================================================================
# UI UPDATES
# ============================================================================

func refresh_grid():
	"""Update grid to show current crystal placement"""
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var grid_pos = Vector2i(x, y)
			var crystal = GameManager.get_crystal_at(grid_pos)
			var button = grid_buttons[y][x]

			if crystal != "":
				# Show crystal
				var display_name = crystal.replace("QuantumDot_", "")
				button.text = display_name
				button.modulate = Inventory.get_resource_color(crystal)
			else:
				# Empty cell
				button.text = "Empty"
				button.modulate = Color(1, 1, 1)


func refresh_crystal_buttons():
	"""Update crystal selection buttons to show current counts"""
	# Clear and recreate
	for child in crystal_selection_panel.get_children():
		child.queue_free()

	await get_tree().process_frame

	create_crystal_selection_buttons()


# ============================================================================
# WIN CONDITION
# ============================================================================

func _on_game_won():
	"""Called when the puzzle is solved"""
	info_label.text = "PUZZLE SOLVED! THE GREAT LIGHT HAS BEEN SUMMONED!"
	info_label.modulate = Color(1, 1, 0)  # Yellow text

	# Flash the grid
	flash_grid()


func flash_grid():
	"""Visual effect when puzzle is solved"""
	for y in range(GRID_SIZE):
		for x in range(GRID_SIZE):
			var button = grid_buttons[y][x]
			var tween = create_tween()
			tween.set_loops(5)
			tween.tween_property(button, "modulate:a", 0.3, 0.2)
			tween.tween_property(button, "modulate:a", 1.0, 0.2)
