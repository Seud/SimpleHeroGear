class_name UnitUI
extends Control

const Stance = Global.Stance

signal stance_changed(stance : Stance)
signal forward_pressed

var ui_str : float = 1
var ui_dex : float = 1
var ui_int : float = 1
var ui_vit : float = 1
var ui_stance : Stance = Stance.DEFENSE

var ui_block_tmp : float = 0
var ui_block : float = 0
var ui_hp : float = 0

func update_stats(stats: Array):
	ui_str = stats[0]
	ui_dex = stats[1]
	ui_int = stats[2]
	ui_vit = stats[3]
	%StrValue.text = Global.format_sci(ui_str, true)
	%DexValue.text = Global.format_sci(ui_dex, true)
	%IntValue.text = Global.format_sci(ui_int, true)
	%VitValue.text = Global.format_sci(ui_vit, true)
	
	update_preview()

func update_preview():
	var attack = Combatant.calc_attack_power(ui_stance, ui_str, ui_dex, ui_int)
	var defense = Combatant.calc_defense_power(true, ui_stance, ui_str, ui_dex, ui_int, ui_vit)
	%AtkValue.text = Global.format_sci(attack, true)
	%DefValue.text = Global.format_sci(defense, true)

func update_bars(tmp_block_p : float, block_p : float, hp_p : float, max_hp : float):
	Global.mod_resource((tmp_block_p - ui_block_tmp + block_p - ui_block) * Global.BATTLE_BASE_BLOCK, (tmp_block_p + block_p) * Global.BATTLE_BASE_BLOCK, %BlockValue, %BlockMod, "block_%d" % get_instance_id())
	Global.mod_resource((hp_p - ui_hp) * max_hp, max_hp * hp_p, %HPValue, %HPMod, "hp_%d" % get_instance_id())
	
	%BlockMaxValue.text = "%d" % Global.BATTLE_BASE_BLOCK
	%HPMaxValue.text = "%d" % max_hp
	
	var bar_instant = %BlockBar
	var bar_delayed = %BlockBarDamage
	
	if(block_p > ui_block):
		bar_instant = %BlockBarDamage
		bar_delayed = %BlockBar
	
	bar_instant.value = block_p
	var tween = create_tween()
	tween.tween_property(bar_delayed, "value", block_p, 0.25).set_trans(Tween.TRANS_LINEAR)
	
	var tween2 = create_tween()
	tween2.tween_property(%BlockBarGuard, "value", tmp_block_p, 0.25).set_trans(Tween.TRANS_LINEAR)
	
	bar_instant = %HPBar
	bar_delayed = %HPBarDamage
	
	if(hp_p > ui_hp):
		bar_instant = %HPBarDamage
		bar_delayed = %HPBar
	
	bar_instant.value = hp_p
	var tween3 = create_tween()
	tween3.tween_property(bar_delayed, "value", hp_p, 0.25).set_trans(Tween.TRANS_LINEAR)
	
	ui_block_tmp = tmp_block_p
	ui_block = block_p
	ui_hp = hp_p

func toggle_player_controls(enabled : bool):
	if(enabled):
		Global.fadein_element(%PlayerControls, Global.BASE_ANIMATION_LENGTH, "controls")
	else:
		Global.fadeout_element(%PlayerControls, Global.BASE_ANIMATION_LENGTH, "controls")

func init_player(maxhp : float):
	update_stats(Equipment.calc_equipment([]))
	update_bars(0, 1, 1, maxhp)

func init_enemy(data : Combatant):
	update_stats([data.strength, data.dexterity, data.intelligence, data.vitality])
	update_bars(0, 1, 1, data.max_hp)

func _on_button_strong_pressed():
	stance_changed.emit(Stance.MELEE)

func _on_button_agile_pressed():
	stance_changed.emit(Stance.RANGED)

func _on_button_magic_pressed():
	stance_changed.emit(Stance.MAGIC)

func _on_button_attack_pressed():
	stance_changed.emit(Stance.ASSAULT)

func _on_button_defend_pressed():
	stance_changed.emit(Stance.DEFENSE)

func _on_stance_changed(stance):
	ui_stance = stance
	update_preview()

func _on_forward_button_pressed():
	forward_pressed.emit()

func set_forward_button(active : bool):
	if(active):
		%ForwardButton.disabled = false
		%ForwardButton.text = "➡️   GO !   ⬅️"
	else:
		%ForwardButton.disabled = true
		%ForwardButton.text = "..."

# Called when the node enters the scene tree for the first time.
func _ready():
	Tooltip.add_basic_tooltip(%BlockContainer, "TOOLTIP_BLOCK_BAR")
	Tooltip.add_basic_tooltip(%BlockBar, "TOOLTIP_BLOCK_BAR")
	Tooltip.add_basic_tooltip(%HPContainer, "TOOLTIP_HP_BAR")
	Tooltip.add_basic_tooltip(%HPBar, "TOOLTIP_HP_BAR")
	Tooltip.add_basic_tooltip(%StatsContainer, "TOOLTIP_STATS")
	Tooltip.add_basic_tooltip(%PreviewContainer, "TOOLTIP_PREVIEW")
	Tooltip.add_basic_tooltip(%StanceLabel, "TOOLTIP_STANCE")
