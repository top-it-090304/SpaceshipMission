extends Control

const MAX_SLOTS := 7

var items: Array[String] = []
var item_textures := {
	"key": preload("res://items/battery.png"),
	"card": preload("res://items/screwdriver.png"),
}

@onready var slots := [
	$Slots/Slot1,
	$Slots/Slot2,
	$Slots/Slot3,
	$Slots/Slot4,
	$Slots/Slot5,
	$Slots/Slot6,
	$Slots/Slot7,
]

func add_item(id: String) -> void:
	if items.size() >= MAX_SLOTS or id in items:
		return
	items.append(id)
	_update_slots()

func remove_item(id: String) -> void:
	if id in items:
		items.erase(id)
		_update_slots()

func has_item(id: String) -> bool:
	return id in items

func _update_slots() -> void:
	for i in range(slots.size()):
		var slot := slots[i] as TextureRect
		if i < items.size():
			var id := items[i]
			slot.texture = item_textures.get(id, null)
			slot.visible = true
		else:
			slot.texture = null
			slot.visible = false
