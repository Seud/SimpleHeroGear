class_name Combatant
extends Object

const Stance = Global.Stance
const AttackType = Global.AttackType

signal event_logged(text : String)
signal updated(tmp_block_p : float, block_p : float, hp_p : float, max_hp : float)

## Fast combatants are used for simulations
var fast = false

## Character Info
var combatant_info : CombatantInfo

## Combatant AI
var ai : AI = AI.new()

## Strength stat
var strength : float = 1.0

## Dexterity stat
var dexterity : float = 1.0

## Intelligence stat
var intelligence : float = 1.0

## Vitality stat
var vitality : float = 1.0

## Max HP
var max_hp : float = 10.0

## Current HP
var hp_p: float = 1.00

## Current block
var block_p : float = 1.00

## Current temporary block
var tmp_block_p : float = 0.00

## Current stance
var stance : Stance = Stance.DEFENSE

func event(text : String):
	if(not fast):
		event_logged.emit(text)

func get_attack_power() -> float:
	return Combatant.calc_attack_power(stance, strength, dexterity, intelligence)

## Get the effective attack power
static func calc_attack_power(_stance : Stance, _strength : float, _dexterity : float, _intelligence : float) -> float:
	match(_stance):
		Stance.ASSAULT:
			return (max(_strength, _dexterity, _intelligence) + _strength + _dexterity + _intelligence ) / 4
		Stance.MELEE:
			return _strength
		Stance.RANGED:
			return _dexterity
		Stance.MAGIC:
			return _intelligence
		_:
			return 0

## Get the effective defense power
func get_defense_power(blocking : bool) -> float:
	return Combatant.calc_defense_power(blocking, stance, strength, dexterity, intelligence, vitality)

## Get the effective defense power
static func calc_defense_power(blocking : bool, _stance : Stance, _strength : float, _dexterity : float, _intelligence : float, _vitality : float) -> float:
	if(not blocking):
		return _vitality
	match(_stance):
		Stance.DEFENSE:
			return (max(_strength, _dexterity, _intelligence) + _strength + _dexterity + _intelligence ) / 4
		Stance.MELEE:
			return _strength
		Stance.RANGED:
			return _dexterity
		Stance.MAGIC:
			return _intelligence
		_:
			return 0

## Get the result of the attack for a given stance
static func get_attack_type(attacker_stance : Stance, defender_stance : Stance) -> AttackType:
	
	# Defensive deal no damage
	if(attacker_stance == Stance.DEFENSE):
		return AttackType.NONE
	
	# Aggressive take crit damage
	if(defender_stance == Stance.ASSAULT):
		return AttackType.CRIT
	
	# Aggressive deal strong damage
	if(attacker_stance == Stance.ASSAULT):
		return AttackType.STRONG
	
	# Defensive take normal damage
	if(defender_stance == Stance.DEFENSE):
		return AttackType.NORMAL
	
	# Equal stances deal normal damage
	if(attacker_stance == defender_stance):
		return AttackType.NORMAL
	
	# Advantaged stances deal crit damage
	if(
		attacker_stance == Stance.MELEE and defender_stance == Stance.RANGED or
		attacker_stance == Stance.RANGED and defender_stance == Stance.MAGIC or
		attacker_stance == Stance.MAGIC and defender_stance == Stance.MELEE
		):
		return AttackType.STRONG
	# Disadvantaged stances deal weak damage
	else:
		return AttackType.WEAK

static func _check_battle_continue(attacker : Combatant, defender : Combatant) -> bool:
	return (attacker.hp_p > 0) and (defender.hp_p > 0)

## Take damage to block and then HP.
## Crit attacks also deal additional damage to HP
## Weak attacks suffer from additional block
func take_damage(attack_power : float, attack_type : AttackType, name : String):
	if(attack_type == AttackType.NONE):
		return
	
	# Calculate raw damage
	var raw_damage_block = Global.BATTLE_BASE_DAMAGE
	var raw_damage_hp = 0
	
	# Weak attacks : Lower block damage
	if(attack_type == AttackType.WEAK):
		event("[color=#bbbbbb]The attack is weak...[/color]")
		raw_damage_block = Global.BATTLE_WEAK_DAMAGE
	# Strong attacks : Add health damage
	elif(attack_type == AttackType.STRONG):
		event("[color=#bbddbb]The attack is strong.[/color]")
		raw_damage_hp = Global.BATTLE_STRONG_DAMAGE_HP
	# Crit attacks : As strong but block is ignored
	elif(attack_type == AttackType.CRIT):
		event("[color=#dd4444]Critical hit ![/color]")
		raw_damage_block = 0
		raw_damage_hp = Global.BATTLE_CRIT_DAMAGE_HP
	
	# Calculate power factors
	var factor_block = attack_power / get_defense_power(true)
	var factor_hp = attack_power / get_defense_power(false)
	
	# Attempt to block damage
	var damage_block = raw_damage_block * factor_block
	
	# Temporary block
	if(damage_block > 0 and tmp_block_p > 0):
		var block_tmp = tmp_block_p * Global.BATTLE_BASE_BLOCK
		if(damage_block <= block_tmp):
			event("%s ignored [color=#dddd88]%.2f[/color] damage.[/color]" % [name, damage_block])
			block_tmp -= damage_block
			damage_block = 0
		else:
			event("%s ignored [color=#dddd88]%.2f[/color] damage.[/color]" % [name, block_tmp])
			damage_block -= block_tmp
			block_tmp = 0
		tmp_block_p = block_tmp / Global.BATTLE_BASE_BLOCK
	
	# Normal block
	if(damage_block > 0 and block_p > 0):
		var block = block_p * Global.BATTLE_BASE_BLOCK
		if(damage_block <= block):
			event("%s blocked [color=#8888dd]%.2f[/color] damage.[/color]" % [name, damage_block])
			block -= damage_block
			damage_block = 0
		else:
			event("%s blocked [color=#8888dd]%.2f[/color] damage.[/color]" % [name, block])
			damage_block -= block
			block = 0
		block_p = block / Global.BATTLE_BASE_BLOCK
	
	# Add remaining damage to HP
	if(damage_block > 0):
		raw_damage_hp += damage_block / factor_block
	
	var damage_hp = raw_damage_hp * factor_hp
	
	# Take HP damage
	if(damage_hp > 0):
		hp_p -= damage_hp / max_hp
		event("%s took [color=#dd8888]%.2f[/color] damage ![/color]" % [name, damage_hp])
	
	if(hp_p < 0):
		hp_p = 0
	
	signal_ui()
	if(not fast):
		await Global.get_tree().create_timer(Global.BATTLE_TIMER).timeout

func defend(name : String):
	if(block_p > 0):
		event("%s will ignore [color=#dddd88]%.2f[/color] damage this round.[/color]" % [name, block_p * Global.BATTLE_BASE_BLOCK])
	
	tmp_block_p = block_p
	block_p = 1.00
	
	signal_ui()
	if(not fast):
		await Global.get_tree().create_timer(Global.BATTLE_TIMER).timeout

func battle_round(defender : Combatant) -> bool:
	var attacker = self
	
	var attack_type = Combatant.get_attack_type(attacker.stance, defender.stance)
	var cattack_type = Combatant.get_attack_type(defender.stance, attacker.stance)
	
	event("[color=#bbbbdd]Your stance is %s[/color]" % Stance.keys()[attacker.stance])
	event("[color=#ddbbbb]Your enemy's stance is %s[/color]" % Stance.keys()[defender.stance])
	
	if(attacker.stance == Stance.ASSAULT):
		event("[color=#bbbbdd]You are charging up a powerful attack...[/color]")
	if(defender.stance == Stance.ASSAULT):
		event("[color=#ddbbbb]Your enemy is charging up a powerful attack...[/color]")
	
	if(attacker.stance == Stance.DEFENSE):
		event("[color=#bbbbdd]You are defending. All block recovered.[/color]")
		await attacker.defend("[color=#bbbbdd]You")
	if(defender.stance == Stance.DEFENSE):
		event("[color=#ddbbbb]Your enemy is defending. All block recovered.[/color]")
		await defender.defend("[color=#ddbbbb]Your enemy")
	
	if(attacker.stance != Stance.ASSAULT and attack_type != AttackType.NONE):
		event("[color=#bbbbdd]You are attacking.[/color]")
		await defender.take_damage(attacker.get_attack_power(), attack_type, "[color=#bbbbdd]Your enemy")
	if(defender.stance != Stance.ASSAULT and cattack_type != AttackType.NONE):
		event("[color=#ddbbbb]Your enemy is attacking.[/color]")
		await attacker.take_damage(defender.get_attack_power(), cattack_type, "[color=#ddbbbb]You")
	
	if not Combatant._check_battle_continue(attacker, defender):
		return false
	
	if(attacker.stance == Stance.ASSAULT):
		event("[color=#bbbbdd]You are unleashing your attack ![/color]")
		await defender.take_damage(attacker.get_attack_power(), attack_type, "[color=#bbbbdd]Your enemy")
	if(defender.stance == Stance.ASSAULT):
		event("[color=#ddbbbb]Your enemy is unleashing their attack ![/color]")
		await attacker.take_damage(defender.get_attack_power(), cattack_type, "[color=#ddbbbb]You")
	
	return Combatant._check_battle_continue(attacker, defender)

func signal_ui():
	updated.emit(tmp_block_p, block_p, hp_p, max_hp)

func ai_stance(opponent : Combatant):
	stance = await ai.stance(self, opponent)

func initialize(character_info : CharacterInfo, stats : Array):
	combatant_info = character_info.combatant_info
	
	ai.load_data(character_info.ai_info)
	block_p = 1.00
	hp_p = 1.00
	max_hp = combatant_info.base_hp
	
	reset_stats(stats)

func reset_stats(stats : Array):
	strength = combatant_info.base_strength * stats[0]
	dexterity = combatant_info.base_dexterity * stats[1]
	intelligence = combatant_info.base_intelligence * stats[2]
	vitality = combatant_info.base_vitality * stats[3]

func fast_copy(original : Combatant):
	if(not fast):
		strength = original.strength
		dexterity = original.dexterity
		intelligence = original.intelligence
		vitality = original.vitality
		max_hp = original.max_hp
		fast = true
	hp_p = original.hp_p
	block_p = original.block_p
	tmp_block_p = 0.00
