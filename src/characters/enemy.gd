extends Node2D

const Stance = Global.Stance

var enemy_info : CharacterInfo = preload("res://src/characters/info/enemy.tres")

var enemy_combatant : Combatant = Combatant.new()

func adventure_start():
	await Global.fadein_element(self, Global.ENEMY_ANIMATION_LENGTH, "enemy")

func battle_start():
	await Global.fadein_element($EnemyUI, Global.ENEMY_ANIMATION_LENGTH, "enemy_ui")

func round_start():
	pass

func round_end():
	enemy_combatant.tmp_block_p = 0.00
	enemy_combatant.signal_ui()

func battle_end():
	await Global.fadeout_element($EnemyUI, Global.ENEMY_ANIMATION_LENGTH, "enemy_ui")

func adventure_end():
	await Global.fadeout_element(self, Global.ENEMY_ANIMATION_LENGTH, "enemy")

func load_data(id : String, level : float):
	var ci = Global.get_ci(id)
	var power = floor(Global.POWER_BASE * pow(Global.POWER_ENEMY_EXPBASE, level))
	var stats = [0, 0, 0, 0]
	
	for i in stats.size():
		stats[i] = power * (Global.ENEMY_MIN_VARIATION + randf() * (Global.ENEMY_MAX_VARIATION - Global.ENEMY_MIN_VARIATION))
	
	enemy_combatant.initialize(ci, stats)
	$EnemyUI.init_enemy(enemy_combatant)
	enemy_combatant.signal_ui()

func _on_enemy_hover_mouse_entered():
	Tooltip.text(enemy_info.description)

func _on_enemy_hover_mouse_exited():
	Tooltip.dismiss()

func _ready():
	enemy_combatant.connect("updated", $EnemyUI.update_bars)
	
	if get_parent() != get_tree().root: return
	
	load_data("test", 3)
