# HUD - Heads-Up Display
#
# Shows important game information:
# - Current inventory
# - Game time
# - Wave number
# - Quick instructions

extends CanvasLayer

# ============================================================================
# NODE REFERENCES
# ============================================================================

var inventory_panel: Panel
var inventory_label: RichTextLabel
var game_info_label: Label
var instructions_label: Label
var wave_label: Label

# ============================================================================
# GODOT LIFECYCLE
# ============================================================================

func _ready():
	setup_hud()

	# Connect to signals
	if Inventory:
		Inventory.inventory_changed.connect(_on_inventory_changed)

	if GameManager:
		GameManager.wave_started.connect(_on_wave_started)


func _process(_delta: float):
	update_game_info()


# ============================================================================
# HUD SETUP
# ============================================================================

func setup_hud():
	"""Create the HUD elements"""

	# ========================================================================
	# INVENTORY PANEL (Top-left)
	# ========================================================================

	inventory_panel = Panel.new()
	inventory_panel.offset_left = 10
	inventory_panel.offset_top = 10
	inventory_panel.offset_right = 250
	inventory_panel.offset_bottom = 300
	add_child(inventory_panel)

	var inv_vbox = VBoxContainer.new()
	inv_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	inv_vbox.add_theme_constant_override("separation", 5)
	inventory_panel.add_child(inv_vbox)

	var inv_title = Label.new()
	inv_title.text = "=== INVENTORY ==="
	inv_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	inv_title.add_theme_font_size_override("font_size", 14)
	inv_vbox.add_child(inv_title)

	inventory_label = RichTextLabel.new()
	inventory_label.bbcode_enabled = true
	inventory_label.fit_content = true
	inventory_label.scroll_active = false
	inv_vbox.add_child(inventory_label)

	# ========================================================================
	# GAME INFO (Top-right)
	# ========================================================================

	var info_panel = Panel.new()
	info_panel.anchor_left = 1.0
	info_panel.anchor_right = 1.0
	info_panel.offset_left = -210
	info_panel.offset_top = 10
	info_panel.offset_right = -10
	info_panel.offset_bottom = 150
	add_child(info_panel)

	var info_vbox = VBoxContainer.new()
	info_vbox.set_anchors_preset(Control.PRESET_FULL_RECT)
	info_vbox.add_theme_constant_override("separation", 5)
	info_panel.add_child(info_vbox)

	var info_title = Label.new()
	info_title.text = "=== GAME STATUS ==="
	info_title.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_title.add_theme_font_size_override("font_size", 14)
	info_vbox.add_child(info_title)

	game_info_label = Label.new()
	game_info_label.add_theme_font_size_override("font_size", 12)
	info_vbox.add_child(game_info_label)

	wave_label = Label.new()
	wave_label.text = "Wave: 0"
	wave_label.add_theme_font_size_override("font_size", 16)
	wave_label.horizontal_alignment = HORIZONTAL_ALIGNMENT_CENTER
	info_vbox.add_child(wave_label)

	# ========================================================================
	# INSTRUCTIONS (Bottom)
	# ========================================================================

	instructions_label = Label.new()
	instructions_label.anchor_top = 1.0
	instructions_label.anchor_bottom = 1.0
	instructions_label.offset_left = 10
	instructions_label.offset_top = -60
	instructions_label.offset_right = 600
	instructions_label.offset_bottom = -10
	instructions_label.text = "[E] Interact | [B] Build Mode | [1/2/3] Select Building | [P] Crystal Puzzle | [I] Inventory"
	instructions_label.add_theme_font_size_override("font_size", 12)
	instructions_label.modulate = Color(0.8, 0.8, 0.8)
	add_child(instructions_label)

	# Initial update
	update_inventory_display()
	update_game_info()


# ============================================================================
# UPDATE FUNCTIONS
# ============================================================================

func update_inventory_display():
	"""Update the inventory display"""
	if not inventory_label:
		return

	var resources = Inventory.get_all_resources()

	# Group resources by category
	var categories = {
		"Raw Materials": [],
		"Compounds": [],
		"Precursors": [],
		"Crystals": [],
		"Weapons": []
	}

	for resource_type in resources:
		var amount = resources[resource_type]
		if amount == 0:
			continue  # Skip resources with 0

		var category = Inventory.RESOURCE_TYPES[resource_type]["category"]
		var color = Inventory.get_resource_color(resource_type)
		var color_hex = color.to_html(false)

		var line = "[color=#" + color_hex + "]" + resource_type + ": " + str(amount) + "[/color]"

		match category:
			"metal", "chemical", "mineral":
				categories["Raw Materials"].append(line)
			"compound":
				categories["Compounds"].append(line)
			"precursor":
				categories["Precursors"].append(line)
			"crystal":
				categories["Crystals"].append(line)
			"weapon":
				categories["Weapons"].append(line)

	# Build display text
	var text = ""

	for category_name in categories:
		var items = categories[category_name]
		if items.size() > 0:
			text += "[b]" + category_name + "[/b]\\n"
			for item in items:
				text += "  " + item + "\\n"
			text += "\\n"

	if text == "":
		text = "No resources yet!\\nGather materials with [E]"

	inventory_label.text = text


func update_game_info():
	"""Update game status info"""
	if not game_info_label or not GameManager:
		return

	var text = ""
	text += "Time: " + GameManager.get_game_time_string() + "\\n"

	# Count enemies
	var enemy_count = get_tree().get_nodes_in_group("enemies").size()
	text += "Enemies: " + str(enemy_count) + "\\n"

	# Count buildings
	var building_count = get_tree().get_nodes_in_group("buildings").size()
	text += "Buildings: " + str(building_count) + "\\n"

	game_info_label.text = text

	# Update wave label
	if wave_label:
		wave_label.text = "Wave: " + str(GameManager.current_wave)


# ============================================================================
# SIGNAL HANDLERS
# ============================================================================

func _on_inventory_changed(_resource_type: String, _new_amount: int):
	"""Called when inventory changes"""
	update_inventory_display()


func _on_wave_started(wave_number: int):
	"""Called when a new wave starts"""
	if wave_label:
		wave_label.text = "Wave: " + str(wave_number)

		# Flash the wave label
		var tween = create_tween()
		tween.tween_property(wave_label, "modulate", Color(1, 0, 0), 0.2)
		tween.tween_property(wave_label, "modulate", Color(1, 1, 1), 0.2)
		tween.set_loops(3)


# ============================================================================
# TOGGLE INVENTORY (DETAILED VIEW)
# ============================================================================

func _input(event: InputEvent):
	# Press I to print detailed inventory to console
	if event is InputEventKey and event.pressed and event.keycode == KEY_I:
		Inventory.print_inventory()
		CraftingSystem.print_craftable_recipes()
