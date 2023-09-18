class_name CharacterInfo
extends Resource

@export var id : String = "character"
@export var name : String = "Character"
@export_multiline var description : String = "A very generic character"
@export var value : float = 1.0

@export var ai_info : AIInfo = preload("res://src/characters/ai/ai_default.tres")
@export var combatant_info : CombatantInfo = preload("res://src/characters/combat/ci_default.tres")
