extends CanvasLayer

@export var offset_x : float
@export var offset_y : float
@export var padding_x : float
@export var padding_y : float

@onready var tooltip_offset: Vector2 = Vector2(offset_x, offset_y)
@onready var padding: Vector2 = Vector2(padding_x, padding_y)
@onready var tooltip : RichTextLabel = %TooltipText

func add_basic_tooltip(control : Control, _text : String):
	control.mouse_entered.connect(text.bind(tr(_text)))
	control.mouse_exited.connect(dismiss)

func equipment(new_slot : ItemSlot, gear_slots : Array):
	var tooltip_text = Equipment.generate_tooltip_gear_text(new_slot, gear_slots)
	text(tooltip_text)

func loot_level(ll : float, tierup_max : int):
	var tooltip_text = Equipment.generate_tooltip_ll_text(ll, tierup_max)
	text(tooltip_text)

func text(tooltip_text : String):
	tooltip.clear()
	tooltip.append_text(tooltip_text)
	tooltip.size.y = tooltip.get_content_height()
	tooltip.show()

func dismiss():
	tooltip.hide()

func _ready():
	tooltip.hide()

func _process(_delta):
	if not tooltip.visible: return
	
	var border = Vector2(get_viewport().size) - padding
	var extents = tooltip.size
	var base_pos = Vector2(get_viewport().get_mouse_position())
	
	# test if need to display to the left
	var final_x = base_pos.x + tooltip_offset.x
	if final_x + extents.x > border.x:
		final_x = base_pos.x - tooltip_offset.x - extents.x
		
	# test if need to display below
	var final_y = base_pos.y + tooltip_offset.y
	if final_y + extents.y > border.y:
		final_y = base_pos.y - tooltip_offset.y - extents.y
		
	tooltip.position = Vector2(final_x, final_y)
