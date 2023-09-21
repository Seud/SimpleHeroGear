extends Node

const Stance = Global.Stance

var hero : Combatant
var enemy : Combatant

func adventure_start():
	$Player.adventure_start()
	$Encounter.adventure_start()
	await get_tree().create_timer(Global.BASE_ANIMATION_LENGTH).timeout

func encounter_start():
	$Player.encounter_start()
	$Encounter.encounter_start()
	await get_tree().create_timer(Global.ENCOUNTER_ANIMATION_LENGTH).timeout

func battle_start():
	$Player.battle_start()
	$Encounter.battle_start()
	await get_tree().create_timer(Global.ENEMY_ANIMATION_LENGTH).timeout

func round_start():
	$Player.round_start()
	$Encounter.round_start()

func round_end():
	$Player.round_end()
	$Encounter.round_end()

func battle_end():
	$Player.battle_end()
	$Encounter.battle_end()
	await get_tree().create_timer(Global.ENEMY_ANIMATION_LENGTH).timeout

func encounter_end():
	$Player.encounter_end()
	$Encounter.encounter_end()
	await get_tree().create_timer(Global.ENCOUNTER_ANIMATION_LENGTH).timeout

func adventure_end():
	$Player.adventure_end()
	$Encounter.adventure_end()
	await get_tree().create_timer(Global.BASE_ANIMATION_LENGTH).timeout

func encounter_battle(id : String, level : float):
	$Encounter.load_battle_data(id, level)
	await battle_start()
	
	var battle = true
	var round_count = 0
	
	while(battle):
		round_count += 1
		
		log_text("ROUND %d" % round_count)
		$Player.set_forward_button(true)
		await $Player.forward_pressed
		$Player.set_forward_button(false)
		
		await round_start()
		
		# Set enemy stance
		await enemy.ai_stance(hero)
		
		battle = await hero.battle_round(enemy)
		
		await round_end()
	
	await battle_end()

func log_text(text : String):
	$GameLog.log_text(text)

# Called when the node enters the scene tree for the first time.
func _ready():
	Global.connect("event_logged", log_text)
	
	hero = $Player.player_combatant
	enemy = $Encounter.enemy_combatant
	
	hero.connect("event_logged", $GameLog.log_text)
	enemy.connect("event_logged", $GameLog.log_text)
	
	if get_parent() != get_tree().root: return
	
	await adventure_start()
	await get_tree().create_timer(1).timeout
	
	var enemy_count = 1
	
	while(hero.hp_p > 0):
		log_text("Enemy %d is approaching !" % enemy_count)
		await encounter_battle("test", log(2) / log(3))
		
		if(enemy.hp_p <= 0):
			log_text("Enemy defeated !")
			enemy_count += 1
			# Victory
	
	log_text("You have fallen...")
	log_text("You have defeated %d enemies." % (enemy_count - 1))
	
	await adventure_end()
