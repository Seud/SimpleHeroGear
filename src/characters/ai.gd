class_name AI
extends Object

const Stance = Global.Stance

var chaos : float
var spite : float
var reliability : float
var score_hp : float
var score_block : float
var score_defeated : float
var score_hp_opponent : float
var score_block_opponent : float
var score_defeated_opponent : float

var defended_last : bool = false

## Print AI debug data ?
const AI_DEBUG : bool = true

func random_stance() -> Stance:
	return Stance.values()[randi() % Stance.size()]

func analyze(me : Combatant, opponent : Combatant, defending) -> float:
	# Never defend twice in a row, prevents weak AI turtling
	if(defending and defended_last):
		return -1000000
	
	var score_me = score_defeated if (me.hp_p <= 0) else score_hp * me.hp_p * me.max_hp + score_block * me.block_p * Global.BATTLE_BASE_BLOCK
	var score_opponent = score_defeated_opponent if (opponent.hp_p <= 0) else score_hp_opponent * opponent.hp_p * opponent.max_hp + score_block_opponent * opponent.block_p * Global.BATTLE_BASE_BLOCK
	return score_me - score_opponent

func get_simulation_data(me_orig : Combatant, opponent_orig : Combatant) -> Dictionary:
	var data = {}
	var me = Combatant.new()
	var opponent = Combatant.new()
	
	var stance_count = Stance.size()
	
	var initial_score = analyze(me_orig, opponent_orig, false)
	data["avg"] = {}
	data["avg_opp"] = {}
	
	for ostance in Stance.keys():
		data[ostance] = {}
		
		for mstance in Stance.keys():
			me.stance = Stance[mstance]
			opponent.stance = Stance[ostance]
			
			me.fast_copy(me_orig)
			opponent.fast_copy(opponent_orig)
			
			if(not data["avg"].has(mstance)):
				data["avg"][mstance] = 0
			
			if(not data["avg_opp"].has(ostance)):
				data["avg_opp"][ostance] = 0
			
			await me.battle_round(opponent)
			
			var score = analyze(me, opponent, Stance[mstance] == Stance.DEFENSE) - initial_score
			debug("I think %s/%s is worth %+.1f" % [mstance, ostance, score])
			
			data["avg"][mstance] += score / stance_count
			data["avg_opp"][ostance] -= score / stance_count
			data[ostance][mstance] = score
	
	return data

func choose_stance(dict : Dictionary) -> String:
	var max_score
	debug("Considering dict %s" % str(dict))
	# Find the max score
	for target_stance in dict.keys():
		var score = dict[target_stance]
		if(not max_score or max_score < score):
			max_score = score
	debug("The max score is %+.1f" % max_score)
	
	# Convert scores to weights
	for target_stance in dict.keys():
		var score = dict[target_stance]
		var weight = pow(Global.get_mod(reliability), score - max_score)
		debug("Converting %+.1f to a weight of %.2f" % [score, weight])
		dict[target_stance] = weight
	
	var weight_array = Global.harmonize_array_weights(dict.values())
	debug("Final weights : %s" % str(weight_array))
	var chosen_index = Global.weighted_pick(weight_array)
	var target_stance = Stance.keys()[chosen_index]
	debug("Chosen stance : %s" % target_stance)
	return target_stance

func select_stance(me : Combatant, opponent : Combatant) -> String:
	# Simulate the possibility matrix
	var simulation_data = await get_simulation_data(me, opponent)
	
	if(randf() < spite):
		debug("I will try to counter my opponent")
		var opponent_stance = choose_stance(simulation_data["avg_opp"])
		return choose_stance(simulation_data[opponent_stance])
	else:
		debug("I will try to make the best move")
		return choose_stance(simulation_data["avg"])

func stance(me : Combatant, opponent : Combatant) -> Stance:
	
	var target_stance = Stance.ASSAULT
	# Choose a random stance
	if(randf() < chaos):
		debug("I will pick a random stance")
		target_stance = random_stance()
	else:
		debug("I will choose a stance")
		var raw_stance = await select_stance(me, opponent)
		target_stance = Stance[raw_stance]
	
	defended_last = target_stance == Stance.DEFENSE
	return target_stance

func load_data(ai_info : AIInfo):
	chaos = ai_info.chaos
	spite = ai_info.spite
	reliability = ai_info.reliability
	score_hp = ai_info.score_hp
	score_block = ai_info.score_block
	score_defeated = ai_info.score_defeated
	score_hp_opponent = ai_info.score_hp_opponent
	score_block_opponent = ai_info.score_block_opponent
	score_defeated_opponent = ai_info.score_defeated_opponent

func debug(text : String):
	if(AI_DEBUG):
		print("AI : %s" % text)
