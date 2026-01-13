# Game Manager - Global Game State
#
# This autoload manages overall game state like wave progression,
# game time, win/lose conditions, etc.

extends Node

# ============================================================================
# SIGNALS
# ============================================================================

signal game_started
signal game_over
signal game_won
signal wave_started(wave_number: int)
signal wave_completed(wave_number: int)

# ============================================================================
# GAME STATE
# ============================================================================

var game_time: float = 0.0
var current_wave: int = 0
var game_active: bool = false
var is_paused: bool = false

# Crystal puzzle state
var crystals_placed: Dictionary = {}  # position -> crystal_type
var required_crystals: Array = ["QuantumDot_Red", "QuantumDot_Blue", "QuantumDot_Green", "QuantumDot_Yellow"]

# The solution to the crystal puzzle (3x3 grid)
# This is the pattern players need to discover
var puzzle_solution: Array = [
	["QuantumDot_Red", "QuantumDot_Blue", "QuantumDot_Red"],
	["QuantumDot_Green", "QuantumDot_Yellow", "QuantumDot_Green"],
	["QuantumDot_Red", "QuantumDot_Blue", "QuantumDot_Red"]
]

# ============================================================================
# INITIALIZATION
# ============================================================================

func _ready():
	print("Game Manager initialized")
	start_game()


func _process(delta: float):
	if game_active and not is_paused:
		game_time += delta


# ============================================================================
# GAME FLOW
# ============================================================================

func start_game():
	"""Start a new game"""
	game_time = 0.0
	current_wave = 0
	game_active = true
	crystals_placed.clear()

	game_started.emit()
	print("\n=== GAME STARTED ===\n")


func pause_game():
	"""Pause the game"""
	is_paused = true


func resume_game():
	"""Resume the game"""
	is_paused = false


func end_game(won: bool):
	"""End the game (win or lose)"""
	game_active = false

	if won:
		game_won.emit()
		print("\n=== VICTORY! ===")
		print("Dr. Pepper has summoned The Great Light!")
		print("Humanity is saved!")
		print("=================\n")
	else:
		game_over.emit()
		print("\n=== GAME OVER ===")
		print("The Billionaire's death squad has prevailed...")
		print("=================\n")


# ============================================================================
# WAVE SYSTEM
# ============================================================================

func start_next_wave():
	"""Start the next enemy wave"""
	current_wave += 1
	wave_started.emit(current_wave)
	print("\n>>> WAVE ", current_wave, " STARTING <<<\n")


func complete_wave():
	"""Called when all enemies in current wave are defeated"""
	wave_completed.emit(current_wave)
	print("\n>>> WAVE ", current_wave, " COMPLETED <<<\n")


func get_wave_difficulty() -> float:
	"""Returns a multiplier for enemy stats based on wave number"""
	return 1.0 + (current_wave * 0.2)


# ============================================================================
# CRYSTAL PUZZLE SYSTEM
# ============================================================================

func place_crystal(grid_pos: Vector2i, crystal_type: String) -> bool:
	"""Place a crystal on the puzzle grid"""
	if not Inventory.is_crystal(crystal_type):
		return false

	# Remove crystal from inventory
	if not Inventory.remove_resource(crystal_type, 1):
		return false

	# Place on grid
	crystals_placed[grid_pos] = crystal_type

	print("Crystal placed at ", grid_pos, ": ", crystal_type)

	# Check if puzzle is solved
	check_puzzle_solution()

	return true


func remove_crystal(grid_pos: Vector2i) -> bool:
	"""Remove a crystal from the puzzle grid"""
	if not grid_pos in crystals_placed:
		return false

	var crystal_type = crystals_placed[grid_pos]
	crystals_placed.erase(grid_pos)

	# Return crystal to inventory
	Inventory.add_resource(crystal_type, 1)

	print("Crystal removed from ", grid_pos)
	return true


func check_puzzle_solution() -> bool:
	"""Check if the current crystal configuration matches the solution"""
	# First check if we have all 9 crystals placed
	if crystals_placed.size() != 9:
		return false

	# Check each position
	for y in range(3):
		for x in range(3):
			var pos = Vector2i(x, y)
			if not pos in crystals_placed:
				return false

			var placed_crystal = crystals_placed[pos]
			var expected_crystal = puzzle_solution[y][x]

			if placed_crystal != expected_crystal:
				return false

	# Puzzle solved!
	print("\n>>> CRYSTAL PUZZLE SOLVED! <<<\n")
	end_game(true)
	return true


func get_crystal_at(grid_pos: Vector2i) -> String:
	"""Get the crystal type at a grid position (or empty string if none)"""
	if grid_pos in crystals_placed:
		return crystals_placed[grid_pos]
	return ""


# ============================================================================
# UTILITY FUNCTIONS
# ============================================================================

func get_game_time_string() -> String:
	"""Returns formatted game time as MM:SS"""
	var minutes = int(game_time) / 60
	var seconds = int(game_time) % 60
	return "%02d:%02d" % [minutes, seconds]


func is_game_active() -> bool:
	return game_active and not is_paused
