extends Control

signal choice_made(choice : int)

var ui_choice1_tooltip : String = "a"
var ui_choice2_tooltip : String = "b"
var ui_choice3_tooltip : String = "c"

func _on_event_choice_1_mouse_entered():
	Tooltip.text(ui_choice1_tooltip)

func _on_event_choice_2_mouse_entered():
	Tooltip.text(ui_choice2_tooltip)

func _on_event_choice_3_mouse_entered():
	Tooltip.text(ui_choice3_tooltip)

func _on_event_choice_1_pressed():
	choice_made.emit(1)

func _on_event_choice_2_pressed():
	choice_made.emit(2)

func _on_event_choice_3_pressed():
	choice_made.emit(3)

func _general_mouse_exited():
	Tooltip.dismiss()
