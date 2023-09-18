extends Node2D

signal forward_pressed

const Stance = Global.Stance

var player_info : CharacterInfo = preload("res://src/characters/info/hero.tres")

var player_combatant : Combatant = Combatant.new()

var locked_stance = false

var target_stance = Stance.DEFENSE

func _on_player_ui_stance_changed(_stance):
	target_stance = _stance
	if(not locked_stance):
		player_combatant.stance = _stance

func _on_player_ui_forward_pressed():
	forward_pressed.emit()

func _on_equipment_equipment_changed(stats):
	player_combatant.reset_stats(stats)

func adventure_start():
	$Equipment.hide_backpack()

func battle_start():
	$Equipment.lock_pouch(true)
	$PlayerUI.toggle_player_controls(true)

func round_start():
	locked_stance = true

func round_end():
	locked_stance = false
	player_combatant.stance = target_stance
	player_combatant.tmp_block_p = 0.00
	player_combatant.signal_ui()

func battle_end():
	player_combatant.block_p = 1.00
	player_combatant.signal_ui()
	$PlayerUI.toggle_player_controls(false)
	$PlayerUI.set_forward_button(false)
	$Equipment.lock_pouch(false)

func adventure_end():
	$Equipment.show_backpack()

func set_forward_button(state : bool):
	$PlayerUI.set_forward_button(state)

func _ready():
	player_combatant.initialize(player_info, Equipment.calc_equipment([]))
	player_combatant.connect("updated", $PlayerUI.update_bars)
	
	$PlayerUI.init_player(player_combatant.max_hp)
	
	if get_parent() != get_tree().root: return
	
	for i in 20:
		$Equipment.generate_gear(1)

	player_combatant.test()
