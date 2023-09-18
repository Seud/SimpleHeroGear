class_name Equipment
extends Control

signal equipment_changed(stats : Array)
signal lootlevel_hovered

const Slots = Global.GearSlots

var slot_scene := preload("res://src/items/item_slot.tscn")
static var selected_slot : Slots = Slots.SWORD

var crystals : float = 0

var lootlevel : float = 0
var lootlevel_add : float = 0
var tierup_max : int = 1

@onready var base_pouch_position = %PouchSection.position
@onready var base_backpack_position = %BackpackSection.position

static func calc_equipment(gear_slots : Array, slot_compare : Slots = Slots.ANY) -> Array:
	var gear_power_base = Global.POWER_BASE / Global.POWER_GEAR_TIER_EXPBASE
	var gear_power = 4 * gear_power_base
	var str_mod : float = 1
	var dex_mod : float = 1
	var int_mod : float = 1
	var vit_mod : float = 1

	for slot in gear_slots:
		var gear = slot.get_gear()
		if(gear != null):
			gear_power += gear.power - gear_power_base
			var slot_type = slot.type if slot.type != Slots.ANY else slot_compare
			match(slot_type):
				Slots.SWORD:
					str_mod = gear.stat_boost
				Slots.BOW:
					dex_mod = gear.stat_boost
				Slots.WAND:
					int_mod = gear.stat_boost
				Slots.ARMOR:
					vit_mod = gear.stat_boost
	
	str_mod *= gear_power
	dex_mod *= gear_power
	int_mod *= gear_power
	vit_mod *= gear_power
	
	return [str_mod, dex_mod, int_mod, vit_mod]

static func get_compare_data(new_slot : ItemSlot, gear_slots : Array, slot : Slots):
	# Calculate current equipment data
	var old_data = Equipment.calc_equipment(gear_slots)
	var new_gear_slots = gear_slots.duplicate()
	
	# Find which gear to replace
	var gear_index = -1
	for i in gear_slots.size():
		if(gear_slots[i].type == slot):
			gear_index = i
	
	assert(gear_index >= 0, "No candidate for comparison detected !")
	new_gear_slots[gear_index] = new_slot
	
	# Calculate new stats with new equipment
	var new_data = Equipment.calc_equipment(new_gear_slots, slot)
	for i in old_data.size():
		new_data[i] /= old_data[i]
	
	# Return the ratio
	return new_data

static func _generate_tooltip_comparison_text(stat_name : String, value : float) -> String:
	var percent = (value - 1) * 100
	
	var color = "#bbbbdd"
	
	if(value > 1):
		var rb_hex = lerp(0xbb, 0x44, clamp(value - 1, 0, 1))
		color = "%xdd%x" % [rb_hex, rb_hex]
	if(value < 1):
		var gb_hex = lerp(0xbb, 0x44, clamp((1 / value) - 1, 0, 1))
		color = "dd%x%x" % [gb_hex, gb_hex]
	
	return "%s : [color=%s]%+.2f %%[/color]
" % [stat_name, color, clamp(percent, -99.99, 999.99)]

static func generate_tooltip_gear_text(new_slot : ItemSlot, gear_slots : Array) -> String:
	if(new_slot.is_empty()):
		return ""
	
	var gear = new_slot.get_gear()
	var compare = (not gear_slots.is_empty() and not gear_slots.has(new_slot))
	
	# Base tooltip
	var tooltip = "Level %d %s
Power : %s
Stat efficiency : %.2f %%
[color=gray]Salvage value : %s[/color]
" % [gear.tier, Slots.keys()[gear.slot], Global.format_sci(gear.power), gear.stat_boost * 100, Global.format_sci(gear.get_value(), true)]
	
	# Comparison
	if(compare):
		tooltip += "\n"
		var compare_slot = new_slot.get_gear().slot
		if(compare_slot == Slots.ANY):
			tooltip += "[color=gray]Click on an equip slot to change target[/color]\n"
			compare_slot = selected_slot
		
		var compare_data = Equipment.get_compare_data(new_slot, gear_slots, compare_slot)
		
		tooltip += "Compared to current %s :
" % Slots.keys()[compare_slot]
		tooltip += _generate_tooltip_comparison_text("Strength", compare_data[0])
		tooltip += _generate_tooltip_comparison_text("Dexterity", compare_data[1])
		tooltip += _generate_tooltip_comparison_text("Intelligence", compare_data[2])
		tooltip += _generate_tooltip_comparison_text("Vitality", compare_data[3])
	
	return tooltip

static func generate_tooltip_ll_text(ll : float, _tierup_max : int):
	var tooltip = Global.tr("TOOLTIP_LOOTLEVEL") + "\n"
	
	var weights_raw = Gear.get_gen_weights(fmod(ll, 1.0), _tierup_max)
	var weights = Global.harmonize_array_weights(weights_raw)
	
	var gearlevel = floori(ll)
	for w in weights:
		if(w > 0):
			tooltip += "[color=%s]Tier %d : %.2f %%[/color]\n" % [Gear.calc_gear_color(gearlevel, 1).to_html(false), gearlevel, w * 100]
		gearlevel += 1
	
	tooltip += "\n[color=gray]Scrap value :[/color] %s" % Global.format_sci(Equipment.get_scrap_value(ll), true)
	
	return tooltip

func get_equipped() -> Array:
	return %Equipped.get_children()

func generate_gear(amount: int):
	# Attempt to find empty slot in pouch
	var pouch_slots = %Pouch.get_children()
	for slot in pouch_slots:
		if(slot.is_empty()):
			slot.generate(lootlevel + lootlevel_add, tierup_max)
			amount -= 1
			if(amount == 0):
				return 0
	
	var backpack_slots = %Backpack.get_children()
	# Ditto, backpack
	for slot in backpack_slots:
		if(slot.is_empty()):
			slot.generate(lootlevel + lootlevel_add, tierup_max)
			amount -= 1
			if(amount == 0):
				return 0
	
	var autosalvage = 0
	for i in amount:
		var slot = slot_scene.instantiate()
		slot.generate(lootlevel + lootlevel_add, tierup_max)
		autosalvage += slot.salvage()
	
	add_crystals(autosalvage)

func salvage_backpack():
	var backpack_slots = %Backpack.get_children()
	var total = 0
	for slot in backpack_slots:
		var value = slot.salvage()
		total += value
	
	add_crystals(total)

static func get_scrap_value(ll : float) -> float:
	return Global.SCRAP_VALUE_BASE * pow(Global.GEAR_TIER_VALUE_EXPBASE, ll)

func add_crystals(crystals_add : float):
	crystals += crystals_add
	Global.mod_resource(crystals_add, crystals, %CrystalValue, %CrystalMod, "crystals", true)
	update_lootlevel()

func remove_crystals(crystals_rem : float):
	crystals -= crystals_rem
	assert(crystals > 0, "No negative crystals please")
	Global.mod_resource(-crystals_rem, crystals, %CrystalValue, %CrystalMod, "crystals", true)
	update_lootlevel()

func update_lootlevel():
	var old_ll = lootlevel
	lootlevel = log(1 + crystals / Global.REQ_LEVEL_BASE) / log(Global.REQ_LEVEL_EXPBASE)
	
	Global.mod_resource(lootlevel - old_ll, lootlevel + lootlevel_add, %LootLevelValue, %LootLevelMod, "loot_level")

func update_level_bonus(new_add : float, new_tierup : int):
	lootlevel_add = new_add
	tierup_max = new_tierup
	%LootLevelValue.text = Global.format_sci(lootlevel + lootlevel_add)

func hide_backpack():
	lock(%Backpack, true)
	
	Global.fadeout_element(%BackpackSection, Global.BACKPACK_ANIMATION_LENGTH, "backpack")
	
	var backpack_tween = get_tree().create_tween()
	backpack_tween.tween_property(%PouchSection, "position", base_backpack_position, Global.BACKPACK_ANIMATION_LENGTH).set_trans(Tween.TRANS_QUAD)
	
func show_backpack():
	var backpack_tween = get_tree().create_tween()
	backpack_tween.tween_property(%PouchSection, "position", base_pouch_position, Global.BACKPACK_ANIMATION_LENGTH).set_trans(Tween.TRANS_QUAD)
	
	await Global.fadein_element(%BackpackSection, Global.BACKPACK_ANIMATION_LENGTH, "backpack")

	lock(%Backpack, false)

func lock_pouch(_lock : bool):
	lock(%Pouch, _lock)

func lock(element : Control, _lock : bool):
	element.modulate.a = 0.5 if _lock else 1.0
	for s in element.get_children():
		s.locked = _lock

func _on_slot_selected(slot : Slots):
	selected_slot = slot

func _on_equipment_changed():
	var stats = Equipment.calc_equipment(get_equipped())
	equipment_changed.emit(stats)

func _on_equipment_hovered(slot : ItemSlot):
	var equipped = get_equipped()
	Tooltip.equipment(slot, equipped)

func _on_loot_level_container_mouse_entered():
	Tooltip.loot_level(lootlevel + lootlevel_add, tierup_max)

func _on_loot_level_container_mouse_exited():
	Tooltip.dismiss()

func _on_equipment_double_clicked(slot : ItemSlot):
	if(slot.locked or slot.is_empty()):
		return
	var gear = slot.get_gear()
	var target_slot = gear.slot if gear.slot != Slots.ANY else selected_slot
	
	for equip in get_equipped():
		if(equip.type == target_slot):
			assert(equip.can_swap(slot), "Equipment should be swappable !")
			equip.swap(slot)
			return

# Called when the node enters the scene tree for the first time.
func _ready():
	
	for i in Global.GEAR_POUCH_SLOTS:
		var slot = slot_scene.instantiate()
		slot.connect("equipment_double_clicked", _on_equipment_double_clicked)
		slot.connect("equipment_hovered", _on_equipment_hovered)
		%Pouch.add_child(slot)
	
	for i in Global.GEAR_BACKPACK_SLOTS:
		var slot = slot_scene.instantiate()
		slot.connect("equipment_double_clicked", _on_equipment_double_clicked)
		slot.connect("equipment_hovered", _on_equipment_hovered)
		%Backpack.add_child(slot)
	
	Tooltip.add_basic_tooltip(%EquippedLabel, "TOOLTIP_EQUIPPED")
	Tooltip.add_basic_tooltip(%PouchLabel, "TOOLTIP_POUCH")
	Tooltip.add_basic_tooltip(%BackpackLabel, "TOOLTIP_BACKPACK")
	Tooltip.add_basic_tooltip(%CrystalContainer, "TOOLTIP_CRYSTAL")
	Tooltip.add_basic_tooltip(%ScrapContainer, "TOOLTIP_SCRAP_COUNT")
	Tooltip.add_basic_tooltip(%LootContainer, "TOOLTIP_LOOT_COUNT")
	Tooltip.add_basic_tooltip(%SalvageButton, "TOOLTIP_SALVAGE")
	
	%CrystalValue.text = "0"
	%LootLevelValue.text = "0"
	
	if get_parent() != get_tree().root: return
	
	update_level_bonus(1, 5)
	
	generate_gear(20)
	await get_tree().create_timer(1).timeout
	add_crystals(Global.REQ_LEVEL_BASE * Global.REQ_LEVEL_EXPBASE)
	await get_tree().create_timer(1).timeout
	remove_crystals(Global.REQ_LEVEL_EXPBASE)
	await hide_backpack()
	await get_tree().create_timer(3).timeout
	await show_backpack()
