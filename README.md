# Dr. Pepper and the Billionaire's Assassin Death Squad

A 2D top-down factory-builder / tower-defense hybrid built in Godot 4.5.

## Story

You are Dr. Pepper, a rogue chemist racing to save humanity from impending destruction. A shadowy billionaire has sent his private death squad to stop you. You've discovered that arranging quantum dot crystals in a specific configuration can summon "The Great Light"—pure energy from the universe's core that's humanity's only hope.

## How to Run the Game

### 1. Install Godot 4.5

#### Linux (Fedora)
```bash
# Install from official repositories (may need to check version)
sudo dnf install godot

# OR download latest Godot 4.5 from godotengine.org
wget https://github.com/godotengine/godot/releases/download/4.5-stable/Godot_v4.5-stable_linux.x86_64.zip
unzip Godot_v4.5-stable_linux.x86_64.zip
chmod +x Godot_v4.5-stable_linux.x86_64
```

#### Other Platforms
Download Godot 4.5+ from: https://godotengine.org/download

### 2. Open the Project

1. Launch Godot
2. Click "Import"
3. Navigate to this `drpepper` folder
4. Select `project.godot`
5. Click "Import & Edit"

### 3. Run the Game

- Click the Play button (▶) in the top-right corner of the Godot editor
- OR press F5

## How to Play

### Core Gameplay Loop

1. **Gather Resources** - Walk to resource nodes and press `E` to harvest materials
2. **Build Structures** - Press `B` to enter build mode, then place labs, refineries, and synthesizers
3. **Craft Items** - Interact with buildings (`E`) to automatically start crafting available recipes
4. **Defend** - Survive waves of the billionaire's goons
5. **Solve Puzzle** - Craft quantum dot crystals and arrange them correctly to win

### Controls

| Key | Action |
|-----|--------|
| `WASD` / Arrow Keys | Move Dr. Pepper |
| `E` | Interact with resource nodes and buildings |
| `B` | Enter/exit build mode |
| `1` / `2` / `3` | Select building type (in build mode) |
| Left Click | Place building (in build mode) |
| `P` | Open crystal puzzle UI |
| `I` | Print detailed inventory to console |

### Building Types

1. **Lab Station** (Cost: 5 Iron, 3 Carbon)
   - Crafts basic compounds: Steel, Glass, Acid
   - Crafts weapons: Capsaicin Ammo, Acid Bombs, Smoke Bombs

2. **Refinery** (Cost: 8 Iron, 4 Copper)
   - Crafts quantum dot precursors
   - Required for making crystals

3. **Synthesis Chamber** (Cost: 10 Iron, 5 Silica, 3 Copper)
   - Synthesizes quantum dot crystals
   - The final step to victory!

### Crafting Chain Example

To create a Red Quantum Dot:

1. Gather: Iron, Sulfur, Silica
2. Use Refinery: Iron + Sulfur + Silica → Red Precursor
3. Use Lab Station: Silica → Glass
4. Use Synthesis Chamber: Red Precursor + Glass → Red Quantum Dot

### Resource Types

**Raw Materials:**
- Iron (gray) - Found in ore deposits
- Sulfur (yellow) - Found in sulfur vents
- Carbon (black) - Found in carbon deposits
- Silica (light blue) - Found in silica deposits
- Copper (orange) - Found in copper deposits
- Lithium (light purple) - Found in lithium deposits

**Quantum Dot Colors:**
- Red
- Blue
- Green
- Yellow
- Purple

### Winning the Game

1. Craft all required quantum dot types
2. Press `P` to open the crystal puzzle
3. Place crystals in the 3x3 grid in the correct pattern
4. The solution is:
   ```
   Red    Blue   Red
   Green  Yellow Green
   Red    Blue   Red
   ```
5. When complete, you'll summon The Great Light and save humanity!

### Combat Tips

- Enemies spawn in waves every 30 seconds
- They attack both you and your buildings
- Waves get progressively harder
- More grunts and armored enemies appear as you progress
- Focus on building and crafting quickly in the early game

## Project Structure

```
drpepper/
├── project.godot           # Main project configuration
├── scenes/                 # All game scenes
│   ├── main.tscn          # Main game scene
│   ├── player/
│   ├── resources/
│   ├── buildings/
│   ├── enemies/
│   └── ui/
├── scripts/                # All GDScript files
│   ├── player.gd          # Player movement and interaction
│   ├── inventory.gd       # Global inventory system (autoload)
│   ├── crafting_system.gd # Recipe definitions (autoload)
│   ├── game_manager.gd    # Game state and win condition (autoload)
│   ├── resource_node.gd   # Harvestable resources
│   ├── building.gd        # Building base class
│   ├── build_manager.gd   # Building placement system
│   ├── enemy.gd           # Enemy AI
│   ├── wave_manager.gd    # Enemy wave spawning
│   ├── crystal_puzzle.gd  # Crystal puzzle UI
│   └── hud.gd            # HUD display
└── assets/                # Game assets (sprites, sounds)
```

## Learning Godot Through This Project

This game demonstrates many core Godot concepts:

### Key Godot Features Used

1. **Scenes & Nodes** - Everything is a scene (player, enemies, buildings, UI)
2. **Autoload Singletons** - Global systems (Inventory, CraftingSystem, GameManager)
3. **Signals** - Event system for communication between nodes
4. **CharacterBody2D** - Physics-based movement for player and enemies
5. **CollisionShapes** - Detecting interactions and placement validity
6. **UI System** - CanvasLayer, Control nodes, dynamic UI creation
7. **Timers** - Wave spawning, crafting progress, respawn delays
8. **Tweens** - Smooth animations and visual effects
9. **Groups** - Finding nodes dynamically (enemies, buildings, player)

### Code Organization Patterns

- **Autoloads for global state** - Inventory, crafting recipes, game progression
- **Signal-driven architecture** - Loose coupling between systems
- **Export variables** - Tune gameplay without changing code
- **Clear comments** - Every major function explains what it does and why

### Next Steps to Expand

Want to keep building? Here are ideas:

- **Multi-site logistics** - Transport crystals between multiple hidden labs
- **More enemy types** - Drones, saboteurs that target equipment
- **Advanced recipes** - Temperature control, timing-based chemistry
- **Turret buildings** - Automated defense structures
- **Story elements** - Cutscenes, narrative progression
- **Sound & music** - Audio feedback for actions
- **Particle effects** - Visual effects for crafting, attacks
- **Save/load system** - Persist game progress
- **Procedural maps** - Randomly generated worlds

## Troubleshooting

**Game won't run:**
- Make sure you have Godot 4.5+ installed (not Godot 3.x)
- Check that all files are in the correct directories
- Look at the console output for error messages

**Can't interact with things:**
- Make sure you're close enough (within interaction range)
- Check that the object is in view
- Resource nodes need to be harvested with `E`

**Can't place buildings:**
- You need enough resources in your inventory
- Buildings can't overlap with other objects
- Buildings need to be placed on valid ground

**Crafting not working:**
- Check you have the right resources
- Make sure you're using the correct building type
- Lab Station ≠ Refinery ≠ Synthesis Chamber

## Credits

Created with Godot 4.5
Built for learning and fun!

## License

Feel free to use this project for learning, modifying, and sharing!
