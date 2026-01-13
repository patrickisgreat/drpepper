# Global Inventory System
#
# This is an AUTOLOAD (singleton) script, meaning there's only one instance
# that exists throughout the entire game. You can access it from anywhere
# using: Inventory.add_resource("Iron", 5)
#
# Autoloads are defined in project.godot under [autoload]
#
# Learn more: https://docs.godotengine.org/en/stable/tutorials/scripting/singletons_autoload.html

extends Node

# ============================================================================
# SIGNALS
# Signals are Godot's way of notifying other parts of the game about events.
# Any script can connect to these signals to react when inventory changes.
# ============================================================================

signal inventory_changed(resource_type: String, new_amount: int)
signal resource_added(resource_type: String, amount: int)
signal resource_removed(resource_type: String, amount: int)

# ============================================================================
# RESOURCE STORAGE
# Dictionary stores resource_name -> quantity
# Example: {"Iron": 10, "Sulfur": 5, "Carbon": 3}
# ============================================================================

var resources: Dictionary = {}

# ============================================================================
# RESOURCE DEFINITIONS
# Defines what resources exist in the game and their properties
# ============================================================================

# List of all valid resource types
const RESOURCE_TYPES = {
	"Iron": {"color": Color(0.7, 0.7, 0.7), "category": "metal"},
	"Sulfur": {"color": Color(1.0, 1.0, 0.0), "category": "chemical"},
	"Carbon": {"color": Color(0.2, 0.2, 0.2), "category": "chemical"},
	"Silica": {"color": Color(0.8, 0.8, 1.0), "category": "mineral"},
	"Copper": {"color": Color(0.9, 0.5, 0.2), "category": "metal"},
	"Lithium": {"color": Color(0.7, 0.7, 0.9), "category": "chemical"},

	# Intermediate compounds (crafted from raw materials)
	"Steel": {"color": Color(0.5, 0.5, 0.6), "category": "compound"},
	"Glass": {"color": Color(0.9, 0.9, 1.0), "category": "compound"},
	"Acid": {"color": Color(0.0, 1.0, 0.0), "category": "compound"},
	"CopperWire": {"color": Color(0.8, 0.4, 0.1), "category": "compound"},

	# Quantum dot precursors
	"RedPrecursor": {"color": Color(0.8, 0.2, 0.2), "category": "precursor"},
	"BluePrecursor": {"color": Color(0.2, 0.2, 0.8), "category": "precursor"},
	"GreenPrecursor": {"color": Color(0.2, 0.8, 0.2), "category": "precursor"},
	"YellowPrecursor": {"color": Color(0.8, 0.8, 0.2), "category": "precursor"},
	"PurplePrecursor": {"color": Color(0.6, 0.2, 0.6), "category": "precursor"},

	# Quantum dots (final products)
	"QuantumDot_Red": {"color": Color(1.0, 0.0, 0.0), "category": "crystal"},
	"QuantumDot_Blue": {"color": Color(0.0, 0.0, 1.0), "category": "crystal"},
	"QuantumDot_Green": {"color": Color(0.0, 1.0, 0.0), "category": "crystal"},
	"QuantumDot_Yellow": {"color": Color(1.0, 1.0, 0.0), "category": "crystal"},
	"QuantumDot_Purple": {"color": Color(0.5, 0.0, 0.5), "category": "crystal"},

	# Weapons and ammo
	"CapsaicinAmmo": {"color": Color(1.0, 0.3, 0.0), "category": "weapon"},
	"AcidBomb": {"color": Color(0.2, 0.8, 0.2), "category": "weapon"},
	"SmokeBomb": {"color": Color(0.5, 0.5, 0.5), "category": "weapon"},
}

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready():
	# Initialize all resources to 0
	for resource_type in RESOURCE_TYPES.keys():
		resources[resource_type] = 0

	# Give player some starting resources for testing
	add_resource("Iron", 10)
	add_resource("Sulfur", 5)
	add_resource("Carbon", 5)

	print("Inventory system initialized")


# ============================================================================
# PUBLIC API FUNCTIONS
# These are the functions other scripts will call to interact with inventory
# ============================================================================

func add_resource(resource_type: String, amount: int) -> void:
	"""Add resources to inventory"""
	if not resource_type in RESOURCE_TYPES:
		push_error("Unknown resource type: " + resource_type)
		return

	resources[resource_type] += amount

	# Emit signals to notify listeners
	resource_added.emit(resource_type, amount)
	inventory_changed.emit(resource_type, resources[resource_type])

	print("Added ", amount, " ", resource_type, " (Total: ", resources[resource_type], ")")


func remove_resource(resource_type: String, amount: int) -> bool:
	"""Remove resources from inventory. Returns true if successful."""
	if not has_resource(resource_type, amount):
		return false

	resources[resource_type] -= amount

	# Emit signals
	resource_removed.emit(resource_type, amount)
	inventory_changed.emit(resource_type, resources[resource_type])

	print("Removed ", amount, " ", resource_type, " (Remaining: ", resources[resource_type], ")")
	return true


func has_resource(resource_type: String, amount: int) -> bool:
	"""Check if inventory has at least 'amount' of resource_type"""
	if not resource_type in resources:
		return false
	return resources[resource_type] >= amount


func get_resource_amount(resource_type: String) -> int:
	"""Get the current amount of a specific resource"""
	if resource_type in resources:
		return resources[resource_type]
	return 0


func get_all_resources() -> Dictionary:
	"""Returns a copy of the entire inventory"""
	return resources.duplicate()


func has_resources_for_recipe(recipe_requirements: Dictionary) -> bool:
	"""
	Check if player has all resources needed for a recipe.
	recipe_requirements format: {"Iron": 2, "Carbon": 1}
	"""
	for resource_type in recipe_requirements:
		var required_amount = recipe_requirements[resource_type]
		if not has_resource(resource_type, required_amount):
			return false
	return true


func consume_resources_for_recipe(recipe_requirements: Dictionary) -> bool:
	"""
	Remove all resources required for a recipe.
	Returns true if successful, false if insufficient resources.
	"""
	# First check if we have everything
	if not has_resources_for_recipe(recipe_requirements):
		return false

	# Then remove everything
	for resource_type in recipe_requirements:
		var required_amount = recipe_requirements[resource_type]
		remove_resource(resource_type, required_amount)

	return true


func get_resource_color(resource_type: String) -> Color:
	"""Get the color associated with a resource type"""
	if resource_type in RESOURCE_TYPES:
		return RESOURCE_TYPES[resource_type]["color"]
	return Color.WHITE


func is_crystal(resource_type: String) -> bool:
	"""Check if a resource is a quantum dot crystal"""
	if resource_type in RESOURCE_TYPES:
		return RESOURCE_TYPES[resource_type]["category"] == "crystal"
	return false


# ============================================================================
# DEBUG FUNCTIONS
# ============================================================================

func print_inventory():
	"""Print the entire inventory to console (useful for debugging)"""
	print("\n=== INVENTORY ===")
	for resource_type in resources:
		var amount = resources[resource_type]
		if amount > 0:
			print("  ", resource_type, ": ", amount)
	print("=================\n")
