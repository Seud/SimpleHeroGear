extends Node2D

signal choice_made(choice : int)

var encounter_info : EncounterInfo

func load_data(id : String):
	var ei = Global.get_ei(id)
	encounter_info = ei

func _on_encounter_hover_mouse_entered():
	Tooltip.text(encounter_info.description)

func _on_encounter_choice_1_mouse_entered():
	Tooltip.text(encounter_info.choice1_description)

func _on_encounter_choice_2_mouse_entered():
	Tooltip.text(encounter_info.choice2_description)

func _on_encounter_choice_3_mouse_entered():
	Tooltip.text(encounter_info.choice3_description)

func _general_mouse_exited():
	Tooltip.dismiss()

func _on_encounter_choice_1_pressed():
	choice_made.emit(1)

func _on_encounter_choice_2_pressed():
	choice_made.emit(2)

func _on_encounter_choice_3_pressed():
	choice_made.emit(3)
