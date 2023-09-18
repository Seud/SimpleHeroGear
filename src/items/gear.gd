class_name Gear
extends Control

## Available gear slots
const Slots = Global.GearSlots

## Gear slot
var slot : Slots = Slots.ANY

## Level of the Gear
## If -1, slot is empty
var tier : int = -1

## Bias of the gear. Higher is Lawful, lower is Chaotic.
## Lawful gear has higher power but a stat penalty
## Chaotic gear has a stat boost but lower power
var bias : float = 0

## Power of the gear
## Affected by tier and bias
var power : float = 1

## Boost for the corresponding stat
## Affected by bias
var stat_boost : float = 1

## Get an array of weights for a given bonus
static func get_gen_weights(bonus_p: float, tierup_max : int) -> Array:
	var weights = []
	
	var tierup_chance = 1 / (1 / Global.GEARGEN_TIERUP_CHANCE - 1)
	
	# Base chance is one, lowered by bonus_p
	weights.append(1 - bonus_p)
	
	# For every normal tier, weight is equal to chance upped
	for i in range(1, tierup_max + 1):
		weights.append(pow(tierup_chance, i))
	
	# Add one last tier based on bonus_p
	weights.append(pow(tierup_chance, tierup_max + 1) * bonus_p)
	
	weights = Global.harmonize_array_weights(weights)
	
	return weights

## Generate the gear randomly
func generate(bonus: float, tierup_max : int):
	
	# *** Generate the tier ***
	var bonus_prob = fmod(bonus, 1.0)
	
	# Get the base weights
	var weights = Gear.get_gen_weights(bonus_prob, tierup_max)
	
	# Get the tier bonus from chance
	var tier_chance = Global.weighted_pick(weights)
	
	# Final tier equals base plus bonus chance
	tier = floori(bonus) + tier_chance
	
	# *** Generate the slot ***
	if(randf() < Global.GEARGEN_SLOT_ANY_CHANCE):
		slot = Slots.ANY
	else:
		slot = Slots.values()[randi_range(1, Slots.size() - 1)]
	
	# *** Generate the bias ***
	# Use a random number between -1 and +1 using a triangular distribution
	bias = randf() - randf()
	
	# *** Calculate the remaining stats ***
	calc_gear()

### Initialize base gear for a given slot
func init_base(_slot : Slots):
	slot = _slot
	
	calc_gear()

## Calculate gear stats
func calc_gear():
	power = Global.POWER_BASE * pow(Global.POWER_GEAR_TIER_EXPBASE, tier) * Global.get_mod(bias)
	stat_boost = Global.get_mod(-bias)
	
	var color = get_gear_color()
	$Tile.update_tile("%s %s\n%+.2f" % [Slots.keys()[slot], tier, bias * 100], color)

func get_value() -> float:
	return Global.GEAR_VALUE_BASE * pow(Global.GEAR_TIER_VALUE_EXPBASE, tier)

func get_gear_color():
	return Gear.calc_gear_color(tier, bias)

## Returns the generated color of the gear
static func calc_gear_color(_tier : int, _bias : float) -> Color:
	var hue = fmod(0.3 + _tier / Global.GEAR_TIER_COLOR_LOOP, 1.0)
	var sat = clampf(0.4 + 0.2 * floori(_tier / Global.GEAR_TIER_COLOR_LOOP), 0, 1)
	var val = 0.6 + 0.3 * _bias
	return Color.from_hsv(hue, sat, val)

func _ready():
	if get_parent() != get_tree().root: return
	
	generate(1, 1)
