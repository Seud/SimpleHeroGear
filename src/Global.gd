extends Node

signal event_logged(text : String)

## Available gear slots
enum GearSlots {ANY, SWORD, BOW, WAND, ARMOR}

## Stances
enum Stance {ASSAULT, MELEE, RANGED, MAGIC, DEFENSE}

## Attack types
enum AttackType {CRIT, STRONG, NORMAL, WEAK, NONE}

# *** Battle ***

@export var BATTLE_BASE_BLOCK : float = 10.0
@export var BATTLE_BASE_DAMAGE : float = 5.0

@export var BATTLE_WEAK_DAMAGE : float = 2.5
@export var BATTLE_STRONG_DAMAGE_HP : float = 2.5
@export var BATTLE_CRIT_DAMAGE_HP : float = 7.5

## Time between attacks, in seconds
@export var BATTLE_TIMER : float = 1.0

## Base power of everyone
@export var POWER_BASE = 10

## Exponential base used to calculate enemy power
@export var POWER_ENEMY_EXPBASE : float = 3

# Enemy stat variation - minimum
@export var ENEMY_MIN_VARIATION = 0.9

# Enemy stat variation - maximum
@export var ENEMY_MAX_VARIATION = 1.1

# *** Economy ***
## Base gear droprate of enemies
@export var ENEMY_DROPRATE : float = 0.1

## Scrap salvage value
@export var SCRAP_VALUE_BASE : float = 1

## Base used to calculate the value of gear
@export var GEAR_VALUE_BASE : float = 10

## Exponential base used to calculate the value of gear
@export var GEAR_TIER_VALUE_EXPBASE : float = 2

## Exponential base used to calculate the amount of XP required to reach a certain bonus level
@export var REQ_LEVEL_EXPBASE : float = 10

## Base used to calculate the amount of XP required to reach a certain bonus level
@export var REQ_LEVEL_BASE : float = 10

# *** Gear ***
## Exponential base used to calculate the power of gear
@export var POWER_GEAR_TIER_EXPBASE : float = 2

## Number of pouch slots
@export var GEAR_POUCH_SLOTS : int = 4

## Number of backpack slots
@export var GEAR_BACKPACK_SLOTS : int = 16

## Loop size for gear color hues
@export var GEAR_TIER_COLOR_LOOP : float = 10

# *** Gear generation **
## Chance for gear to tier up during generation
@export var GEARGEN_TIERUP_CHANCE : float = 0.25

## Chance to generate a "wild" gear during generation
@export var GEARGEN_SLOT_ANY_CHANCE : float = 0.04

# *** Animations ***

## Duration of default animations
@export var BASE_ANIMATION_LENGTH : float = 1

## Duration of catchup timeout - should be equal to the highest animation length
@export var CATCHUP_ANIMATION_LENGTH : float = 1

## Duration of pouch/backpack move
@export var BACKPACK_ANIMATION_LENGTH : float = 0.75

## Duration of enemy show/hide
@export var ENEMY_ANIMATION_LENGTH : float = 1

## Duration of +/- changes display
@export var MOD_ANIMATION_LENGTH : float = 2

## Duration of battle actions
@export var BATTLE_ACTION_LENGTH : float = 1

## Mod tween directory
var tweens : Dictionary

## Get the modifier from a standard bonus/malus total
func get_mod(f: float):
	if(f >= 0):
		return 1 + f
	else:
		return 1 / (1 - f)

## Animates a resource difference using a tween
func mod_resource(diff : float, new_value : float, node_total : Control, node_mod : Control, tween : String, integer : bool = false):
	if(diff == 0):
		return
	
	var _sign = "+"
	var color = Color.hex(0x44dd44ff)
	
	if(diff < 0):
		_sign = "-"
		color = Color.hex(0xdd4444ff)
		diff = -diff
	
	if(tweens.has(tween)):
		tweens[tween].kill()
	tweens[tween] = create_tween()
	
	node_total.text = format_sci(new_value, integer)
	node_mod.modulate = color
	node_mod.text = _sign + Global.format_sci(diff, integer)
	tweens[tween].tween_property(node_mod, "modulate:a", 0, MOD_ANIMATION_LENGTH).set_trans(Tween.TRANS_QUAD)

func catch_up():
	await get_tree().create_timer(CATCHUP_ANIMATION_LENGTH).timeout

## Shows an element using a tween
func fadein_element(element : CanvasItem, duration : float, tween : String):
	Tooltip.dismiss()
	element.modulate.a = 0
	element.show()
	
	if(tweens.has(tween)):
		tweens[tween].kill()
	tweens[tween] = create_tween()
	
	tweens[tween].tween_property(element, "modulate:a", 1, duration)

## Hides an element using a tween
func fadeout_element(element : CanvasItem, duration : float, tween : String):
	element.modulate.a = 1
	
	if(tweens.has(tween)):
		tweens[tween].kill()
	tweens[tween] = create_tween()
	
	tweens[tween].tween_property(element, "modulate:a", 0, duration)
	await tweens[tween].finished
	
	element.hide()
	Tooltip.dismiss()

## Harmonize array weights to ensure the sum of elements is equal to mod
## Ignores negative weights
func harmonize_array_weights(a : Array, mod : float = 1.0) -> Array:
	# Calculate total weights
	var total = 0
	
	for i in a:
		if(i >= 0):
			total += i
	
	if(total == 0):
		return []
	
	# Harmonize weights so their total is equal to one
	return a.map(func(i): return (mod * i / total) if i >= 0 else 0)

## Pick a random index in an array of weights
## The totals in the Array must equal one
## Use harmonize_array_weights to ensure this is the case
func weighted_pick(a : Array) -> int:
	var r = randf()
	
	for i in a.size():
		if(r <= a[i]):
			return i
		else:
			r -= a[i]
	
	assert(false, "A weighted_pick was requested but could not be found. Is the array harmonized ?")
	return -1

func format_sci(n : float, integer : bool = false) -> String:
	if n == 0:
		return "0"
	
	if(n < 1000):
		return ("%d" if integer else "%.2f") % n
	
	var n_sign = sign(n)
	n = abs(n)
	
	var n_exp = floori(log(n) / log(10))
	var n_mant = n / pow(10, n_exp)
	
	return "%.2fe%d" % [n_sign * n_mant, n_exp]

func get_ci(res : String) -> CharacterInfo:
	assert($CharacterInfoPreloader.has_resource(res), "Tried to load invalid CharacterInfo resource %s" % res)
	return $CharacterInfoPreloader.get_resource(res)

func get_ei(res : String) -> EncounterInfo:
	assert($EncounterInfoPreloader.has_resource(res), "Tried to load invalid EncounterInfo resource %s" % res)
	return $EncounterInfoPreloader.get_resource(res)

func log_text(text : String):
	event_logged.emit(text)
