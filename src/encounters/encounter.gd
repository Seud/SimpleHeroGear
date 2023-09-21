extends Node2D

signal choice_made(choice : int)

var encounter_info : EncounterInfo = preload("res://src/encounters/info/default.tres")

const Stance = Global.Stance

var enemy_info : CharacterInfo = preload("res://src/characters/info/enemy.tres")
var enemy_combatant : Combatant = Combatant.new()

func load_encounter_data(id : String):
	var ei = Global.get_ei(id)
	encounter_info = ei

func adventure_start():
	pass

func encounter_start():
	Global.fadein_element(self, Global.ENCOUNTER_ANIMATION_LENGTH, "event")

func battle_start():
	Global.fadeout_element(%EventUI, Global.ENEMY_ANIMATION_LENGTH, "event")
	Global.fadein_element(%EnemyUI, Global.ENEMY_ANIMATION_LENGTH, "enemy")

func round_start():
	pass

func round_end():
	enemy_combatant.tmp_block_p = 0.00
	enemy_combatant.signal_ui()

func battle_end():
	Global.fadeout_element(%EnemyUI, Global.ENEMY_ANIMATION_LENGTH, "enemy")
	Global.fadein_element(%EventUI, Global.ENEMY_ANIMATION_LENGTH, "event")

func encounter_end():
	Global.fadeout_element(self, Global.ENCOUNTER_ANIMATION_LENGTH, "enemy")

func adventure_end():
	pass

func load_battle_data(id : String, level : float):
	var ci = Global.get_ci(id)
	var power = floor(Global.POWER_BASE * pow(Global.POWER_ENEMY_EXPBASE, level))
	var stats = [0, 0, 0, 0]
	
	for i in stats.size():
		stats[i] = power * (Global.ENEMY_MIN_VARIATION + randf() * (Global.ENEMY_MAX_VARIATION - Global.ENEMY_MIN_VARIATION))
	
	enemy_combatant.initialize(ci, stats)
	%EnemyUI.init_enemy(enemy_combatant)
	enemy_combatant.signal_ui()

func _on_encounter_hover_mouse_entered():
	Tooltip.text(encounter_info.description)

func _general_mouse_exited():
	Tooltip.dismiss()

func _ready():
	enemy_combatant.connect("updated", %EnemyUI.update_bars)
	
	if get_parent() != get_tree().root: return
	
	load_battle_data("test", 3)

func _on_event_ui_choice_made(choice):
	choice_made.emit(choice)
