# Building Base Class
#
# Base script for all buildings (labs, refineries, synthesis chambers, turrets)
# Handles common building functionality like health, damage, and crafting

extends StaticBody2D

# ============================================================================
# BUILDING TYPE ENUM
# ============================================================================

enum BuildingType {
	LAB_STATION,      # Basic chemistry station
	REFINERY,         # Processes raw materials into compounds
	SYNTHESIZER,      # Creates quantum dot crystals
	TURRET           # Defensive structure
}

# ============================================================================
# EXPORTED VARIABLES
# ============================================================================

@export var building_type: BuildingType = BuildingType.LAB_STATION
@export var building_name: String = "Lab Station"
@export var max_health: int = 200
@export var build_cost: Dictionary = {"Iron": 5, "Carbon": 3}

# ============================================================================
# PRIVATE VARIABLES
# ============================================================================

var current_health: int
var is_active: bool = true
var current_recipe: Dictionary = {}  # The recipe currently being processed
var crafting_progress: float = 0.0  # 0.0 to 1.0
var is_crafting: bool = false

# Node references
var sprite: Sprite2D
var label: Label
var progress_bar: ProgressBar
var collision_shape: CollisionShape2D

# ============================================================================
# GODOT LIFECYCLE
# ============================================================================

func _ready():
	add_to_group("buildings")
	add_to_group("interactable")

	current_health = max_health

	# Set collision layers
	collision_layer = 8  # Layer 4 (Buildings)
	collision_mask = 0

	setup_visual()

	print(building_name, " built at ", global_position)


func _process(delta: float):
	if is_crafting and is_active:
		process_recipe(delta)


# ============================================================================
# VISUAL SETUP
# ============================================================================

func setup_visual():
	"""Create the visual representation of the building"""
	# Create sprite
	sprite = Sprite2D.new()
	sprite.scale = Vector2(60, 60)
	add_child(sprite)

	# Create collision shape
	collision_shape = CollisionShape2D.new()
	var shape = RectangleShape2D.new()
	shape.size = Vector2(60, 60)
	collision_shape.shape = shape
	add_child(collision_shape)

	# Create label
	label = Label.new()
	label.text = building_name
	label.position = Vector2(-60, -80)
	label.add_theme_font_size_override("font_size", 14)
	add_child(label)

	# Create progress bar for crafting
	progress_bar = ProgressBar.new()
	progress_bar.position = Vector2(-40, 40)
	progress_bar.size = Vector2(80, 8)
	progress_bar.max_value = 1.0
	progress_bar.value = 0.0
	progress_bar.visible = false
	add_child(progress_bar)

	update_color()


func update_color():
	"""Update sprite color based on building type and status"""
	if not sprite:
		return

	var color: Color
	match building_type:
		BuildingType.LAB_STATION:
			color = Color(0.3, 0.7, 1.0)  # Blue
		BuildingType.REFINERY:
			color = Color(1.0, 0.5, 0.0)  # Orange
		BuildingType.SYNTHESIZER:
			color = Color(0.8, 0.0, 0.8)  # Purple
		BuildingType.TURRET:
			color = Color(1.0, 0.2, 0.2)  # Red

	# Darken if damaged
	if current_health < max_health:
		var health_percent = float(current_health) / float(max_health)
		color = color * (0.5 + health_percent * 0.5)

	sprite.modulate = color


# ============================================================================
# CRAFTING SYSTEM
# ============================================================================

func start_recipe(recipe: Dictionary) -> bool:
	"""
	Start crafting a recipe.
	Recipe format: {
		"inputs": {"Iron": 2, "Carbon": 1},
		"outputs": {"Steel": 1},
		"time": 5.0
	}
	"""
	if is_crafting:
		print("Already crafting!")
		return false

	# Check if we have the ingredients
	if not Inventory.has_resources_for_recipe(recipe["inputs"]):
		print("Not enough resources for recipe!")
		return false

	# Check if this building can craft this recipe
	if not can_craft_recipe(recipe):
		print(building_name, " cannot craft this recipe!")
		return false

	# Consume the ingredients
	Inventory.consume_resources_for_recipe(recipe["inputs"])

	# Start crafting
	current_recipe = recipe
	is_crafting = true
	crafting_progress = 0.0
	progress_bar.visible = true

	print(building_name, " started crafting!")
	return true


func process_recipe(delta: float):
	"""Process the current recipe over time"""
	if not is_crafting:
		return

	# Progress based on time
	var recipe_time = current_recipe.get("time", 5.0)
	crafting_progress += delta / recipe_time

	# Update progress bar
	progress_bar.value = crafting_progress

	# Check if complete
	if crafting_progress >= 1.0:
		complete_recipe()


func complete_recipe():
	"""Called when recipe is finished"""
	is_crafting = false
	progress_bar.visible = false

	# Give player the outputs
	var outputs = current_recipe.get("outputs", {})
	for resource_type in outputs:
		var amount = outputs[resource_type]
		Inventory.add_resource(resource_type, amount)

	print(building_name, " completed crafting!")

	current_recipe = {}
	crafting_progress = 0.0


func can_craft_recipe(recipe: Dictionary) -> bool:
	"""Check if this building type can craft the given recipe"""
	# For now, any building can craft any recipe
	# In a more complex system, you'd restrict certain recipes to certain buildings
	var recipe_category = recipe.get("category", "basic")

	match building_type:
		BuildingType.LAB_STATION:
			return recipe_category in ["basic", "compound"]
		BuildingType.REFINERY:
			return recipe_category in ["compound", "refined"]
		BuildingType.SYNTHESIZER:
			return recipe_category in ["crystal", "compound"]
		BuildingType.TURRET:
			return false  # Turrets don't craft

	return false


# ============================================================================
# INTERACTION SYSTEM
# ============================================================================

func interact():
	"""Called when player interacts with this building"""
	print("Interacting with ", building_name)

	# Show crafting menu (will be implemented in UI phase)
	if is_crafting:
		var time_left = (1.0 - crafting_progress) * current_recipe.get("time", 5.0)
		print("Crafting in progress... ", int(time_left), " seconds remaining")
	else:
		print("Press C to open crafting menu (coming soon!)")


# ============================================================================
# DAMAGE SYSTEM
# ============================================================================

func take_damage(amount: int):
	"""Called when building is attacked"""
	current_health -= amount
	current_health = max(0, current_health)

	update_color()

	if label:
		label.text = building_name + " (" + str(current_health) + "/" + str(max_health) + ")"

	if current_health <= 0:
		destroy()


func destroy():
	"""Building is destroyed"""
	print(building_name, " destroyed!")
	queue_free()


# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

func get_info_text() -> String:
	"""Returns info about this building"""
	var text = building_name + " (" + str(current_health) + "/" + str(max_health) + ")"
	if is_crafting:
		text += "\nCrafting: " + str(int(crafting_progress * 100)) + "%"
	return text


static func get_build_cost(type: BuildingType) -> Dictionary:
	"""Static function to get build cost for a building type"""
	match type:
		BuildingType.LAB_STATION:
			return {"Iron": 5, "Carbon": 3}
		BuildingType.REFINERY:
			return {"Iron": 8, "Copper": 4}
		BuildingType.SYNTHESIZER:
			return {"Iron": 10, "Silica": 5, "Copper": 3}
		BuildingType.TURRET:
			return {"Iron": 6, "Steel": 2}
	return {}
