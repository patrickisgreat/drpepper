# Crafting System - Recipe Definitions
#
# This autoload singleton defines all craftable recipes in the game.
# Buildings access this system to process recipes.

extends Node

# ============================================================================
# SIGNALS
# ============================================================================

signal recipe_started(recipe_id: String, building: Node)
signal recipe_completed(recipe_id: String, building: Node)

# ============================================================================
# RECIPE DATABASE
# Each recipe has:
# - inputs: resources consumed
# - outputs: resources produced
# - time: crafting time in seconds
# - category: type of recipe (for building restrictions)
# ============================================================================

var recipes: Dictionary = {}

func _ready():
	initialize_recipes()
	print("Crafting System initialized with ", recipes.size(), " recipes")


func initialize_recipes():
	"""Define all recipes in the game"""

	# ========================================================================
	# BASIC COMPOUNDS (Lab Station / Refinery)
	# ========================================================================

	recipes["steel"] = {
		"name": "Steel",
		"inputs": {"Iron": 2, "Carbon": 1},
		"outputs": {"Steel": 1},
		"time": 3.0,
		"category": "compound",
		"description": "Combine iron and carbon to create strong steel"
	}

	recipes["glass"] = {
		"name": "Glass",
		"inputs": {"Silica": 3},
		"outputs": {"Glass": 1},
		"time": 2.0,
		"category": "compound",
		"description": "Heat silica to create transparent glass"
	}

	recipes["acid"] = {
		"name": "Acid",
		"inputs": {"Sulfur": 2, "Carbon": 1},
		"outputs": {"Acid": 1},
		"time": 4.0,
		"category": "compound",
		"description": "Dangerous acid for weapons or synthesis"
	}

	recipes["copper_wire"] = {
		"name": "Copper Wire",
		"inputs": {"Copper": 2},
		"outputs": {"CopperWire": 1},
		"time": 2.0,
		"category": "compound",
		"description": "Refined copper for electronics"
	}

	# ========================================================================
	# QUANTUM DOT PRECURSORS (Refinery)
	# ========================================================================

	recipes["red_precursor"] = {
		"name": "Red Quantum Precursor",
		"inputs": {"Iron": 1, "Sulfur": 1, "Silica": 2},
		"outputs": {"RedPrecursor": 1},
		"time": 5.0,
		"category": "refined",
		"description": "Precursor compound for red quantum dots"
	}

	recipes["blue_precursor"] = {
		"name": "Blue Quantum Precursor",
		"inputs": {"Copper": 2, "Silica": 2},
		"outputs": {"BluePrecursor": 1},
		"time": 5.0,
		"category": "refined",
		"description": "Precursor compound for blue quantum dots"
	}

	recipes["green_precursor"] = {
		"name": "Green Quantum Precursor",
		"inputs": {"Carbon": 2, "Lithium": 1, "Silica": 2},
		"outputs": {"GreenPrecursor": 1},
		"time": 5.0,
		"category": "refined",
		"description": "Precursor compound for green quantum dots"
	}

	recipes["yellow_precursor"] = {
		"name": "Yellow Quantum Precursor",
		"inputs": {"Sulfur": 2, "Lithium": 1, "Silica": 2},
		"outputs": {"YellowPrecursor": 1},
		"time": 5.0,
		"category": "refined",
		"description": "Precursor compound for yellow quantum dots"
	}

	recipes["purple_precursor"] = {
		"name": "Purple Quantum Precursor",
		"inputs": {"Iron": 1, "Copper": 1, "Lithium": 1, "Silica": 2},
		"outputs": {"PurplePrecursor": 1},
		"time": 6.0,
		"category": "refined",
		"description": "Rare precursor for purple quantum dots"
	}

	# ========================================================================
	# QUANTUM DOTS - THE CRYSTALS (Synthesis Chamber)
	# ========================================================================

	recipes["quantum_dot_red"] = {
		"name": "Red Quantum Dot",
		"inputs": {"RedPrecursor": 1, "Glass": 1},
		"outputs": {"QuantumDot_Red": 1},
		"time": 8.0,
		"category": "crystal",
		"description": "Synthesize a red quantum dot crystal"
	}

	recipes["quantum_dot_blue"] = {
		"name": "Blue Quantum Dot",
		"inputs": {"BluePrecursor": 1, "Glass": 1},
		"outputs": {"QuantumDot_Blue": 1},
		"time": 8.0,
		"category": "crystal",
		"description": "Synthesize a blue quantum dot crystal"
	}

	recipes["quantum_dot_green"] = {
		"name": "Green Quantum Dot",
		"inputs": {"GreenPrecursor": 1, "Glass": 1},
		"outputs": {"QuantumDot_Green": 1},
		"time": 8.0,
		"category": "crystal",
		"description": "Synthesize a green quantum dot crystal"
	}

	recipes["quantum_dot_yellow"] = {
		"name": "Yellow Quantum Dot",
		"inputs": {"YellowPrecursor": 1, "Glass": 1},
		"outputs": {"QuantumDot_Yellow": 1},
		"time": 8.0,
		"category": "crystal",
		"description": "Synthesize a yellow quantum dot crystal"
	}

	recipes["quantum_dot_purple"] = {
		"name": "Purple Quantum Dot",
		"inputs": {"PurplePrecursor": 1, "Glass": 1},
		"outputs": {"QuantumDot_Purple": 1},
		"time": 10.0,
		"category": "crystal",
		"description": "Synthesize a rare purple quantum dot crystal"
	}

	# ========================================================================
	# WEAPONS & DEFENSE (Lab Station)
	# ========================================================================

	recipes["capsaicin_cannon_ammo"] = {
		"name": "Capsaicin Ammo",
		"inputs": {"Carbon": 2, "Acid": 1},
		"outputs": {"CapsaicinAmmo": 5},
		"time": 3.0,
		"category": "weapon",
		"description": "Spicy ammunition for capsaicin cannons"
	}

	recipes["acid_bomb"] = {
		"name": "Acid Bomb",
		"inputs": {"Acid": 2, "Glass": 1},
		"outputs": {"AcidBomb": 3},
		"time": 4.0,
		"category": "weapon",
		"description": "Throwable acid bombs"
	}

	recipes["smoke_bomb"] = {
		"name": "Smoke Bomb",
		"inputs": {"Carbon": 3, "Sulfur": 1},
		"outputs": {"SmokeBomb": 5},
		"time": 2.0,
		"category": "weapon",
		"description": "Smoke screens to confuse enemies"
	}


# ============================================================================
# RECIPE QUERY FUNCTIONS
# ============================================================================

func get_recipe(recipe_id: String) -> Dictionary:
	"""Get a recipe by its ID"""
	if recipe_id in recipes:
		return recipes[recipe_id]
	return {}


func get_all_recipes() -> Dictionary:
	"""Get all recipes"""
	return recipes


func get_recipes_by_category(category: String) -> Array:
	"""Get all recipes of a specific category"""
	var result = []
	for recipe_id in recipes:
		if recipes[recipe_id]["category"] == category:
			result.append(recipe_id)
	return result


func get_craftable_recipes() -> Array:
	"""Get all recipes that can currently be crafted (player has ingredients)"""
	var result = []
	for recipe_id in recipes:
		var recipe = recipes[recipe_id]
		if Inventory.has_resources_for_recipe(recipe["inputs"]):
			result.append(recipe_id)
	return result


func can_craft(recipe_id: String) -> bool:
	"""Check if a specific recipe can be crafted"""
	if not recipe_id in recipes:
		return false

	var recipe = recipes[recipe_id]
	return Inventory.has_resources_for_recipe(recipe["inputs"])


# ============================================================================
# HELPER FUNCTIONS
# ============================================================================

func get_recipe_info(recipe_id: String) -> String:
	"""Get a formatted string describing a recipe"""
	if not recipe_id in recipes:
		return "Unknown recipe"

	var recipe = recipes[recipe_id]
	var info = recipe["name"] + "\n"
	info += recipe["description"] + "\n\n"

	info += "Inputs:\n"
	for resource in recipe["inputs"]:
		info += "  " + resource + " x" + str(recipe["inputs"][resource]) + "\n"

	info += "\nOutputs:\n"
	for resource in recipe["outputs"]:
		info += "  " + resource + " x" + str(recipe["outputs"][resource]) + "\n"

	info += "\nTime: " + str(recipe["time"]) + " seconds"

	return info


func print_all_recipes():
	"""Debug function to print all recipes"""
	print("\n=== ALL RECIPES ===")
	for recipe_id in recipes:
		print("\n", recipe_id, ":")
		print(get_recipe_info(recipe_id))
	print("\n==================\n")


func print_craftable_recipes():
	"""Debug function to print currently craftable recipes"""
	print("\n=== CRAFTABLE RECIPES ===")
	var craftable = get_craftable_recipes()
	if craftable.size() == 0:
		print("No recipes can be crafted right now")
	else:
		for recipe_id in craftable:
			print("  - ", recipes[recipe_id]["name"])
	print("========================\n")
