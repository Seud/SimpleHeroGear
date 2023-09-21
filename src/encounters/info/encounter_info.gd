class_name EncounterInfo
extends Resource

@export var id : String = "encounter"
@export var name : String = "Encounter"
@export_multiline var description : String = "A very generic encounter"

@export var choices : int = 1
@export_multiline var encounter_text : String = "Something is happening"

@export var choice1_name : String = "Do something"
@export_multiline var choice1_description : String = "You will feel different afterwards"
@export_multiline var choice1_text : String = "You did something, and now you feel different."

@export var choice2_name : String = ""
@export_multiline var choice2_description : String = ""
@export_multiline var choice2_text : String = ""

@export var choice3_name : String = ""
@export_multiline var choice3_description : String = ""
@export_multiline var choice3_text : String = ""
