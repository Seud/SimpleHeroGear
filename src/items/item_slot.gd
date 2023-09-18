class_name ItemSlot
extends ColorRect

signal equipment_changed
signal equipment_double_clicked(slot : ItemSlot)
signal equipment_hovered(slot : ItemSlot)
signal slot_selected(slot : Slots)

const Slots = Global.GearSlots

@export var type : Slots = Slots.ANY

var locked : bool = false

var gear_scene := preload("res://src/items/gear.tscn")

func is_empty() -> bool:
	return get_child_count() == 0

func get_gear() -> Gear:
	if not is_empty():
		return get_child(0)
	else:
		return null

func can_equip(slot : ItemSlot) -> bool:
	var gear = slot.get_gear()
	return not locked and (gear == null or type == Slots.ANY or gear.slot == Slots.ANY or type == gear.slot)

func can_swap(slot : ItemSlot) -> bool:
	return can_equip(slot) and slot.can_equip(self)

func generate(bonus : float, tierup_max : int):
	init_base()
	get_gear().generate(bonus, tierup_max)

func init_base():
	if is_empty():
		var gear = gear_scene.instantiate()
		add_child(gear)
	
	get_gear().init_base(type)

func salvage() -> float:
	var value = 0
	
	if not is_empty():
		var gear = get_gear()
		value = gear.get_value()
		gear.queue_free()
	
	return value

func swap(slot : ItemSlot):
	var gear1 = get_gear()
	var gear2 = slot.get_gear()
	
	if(gear1 != null):
		remove_child(gear1)
		slot.add_child(gear1)
	
	if(gear2 != null):
		slot.remove_child(gear2)
		add_child(gear2)
	
	equipment_changed.emit()
	slot.equipment_changed.emit()

func _on_mouse_entered():
	equipment_hovered.emit(self)

func _on_mouse_exited():
	$"/root/Tooltip".dismiss()

func _gui_input(event):
	if not event is InputEventMouseButton:
		return
	if (
			type != Slots.ANY and
			event.pressed and
			event.button_index == MouseButton.MOUSE_BUTTON_LEFT
	):
		# Attempt slot selection
		slot_selected.emit(type)
	elif (
			type == Slots.ANY and
			event.pressed and
			event.button_index == MouseButton.MOUSE_BUTTON_LEFT
			and event.double_click
	):
		# Attempt to equip slot
		equipment_double_clicked.emit(self)

func _get_drag_data(_at_position):
	if(not locked and not is_empty()):
		return self

func _can_drop_data(_at_position, data):
	return can_swap(data)

func _drop_data(_at_position, data):
	swap(data)
	_on_mouse_entered()

func _ready():
	custom_minimum_size = Vector2(80, 80)
	
	if get_parent() != get_tree().root: return
	
	type = Slots.WAND
	init_base()
	
	var slot = ItemSlot.new()
	slot.type = Slots.ARMOR
	slot.init_base()
	
	assert(not can_swap(slot), "Armor and Wand should not be compatible")
	
	slot.type = Slots.WAND
	
	while not can_swap(slot):
		print("I cannot equip a gear of type %s, trying again" % Slots.keys()[slot.get_gear().slot])
		slot.generate(0, 1)
	
	print("I can equip a gear of type %s." % Slots.keys()[slot.get_gear().slot])
	
	print("Swapping helmets")
	
	swap(slot)
	
	var gear1 = get_gear()
	var gear2 = slot.get_gear()
	
	assert(gear1 is Gear)
	assert(gear2 is Gear)
	
	print("I am worth %d" % gear1.power)
	print("The other is worth %d" % gear2.power)
	
	var slot2 = ItemSlot.new()
	swap(slot2)
	
	gear1 = get_gear()
	gear2 = slot2.get_gear()
	
	assert(is_empty())
	assert(not slot2.is_empty())
	
	swap(slot2)
