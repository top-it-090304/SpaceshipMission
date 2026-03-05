extends Control

const MAX_SLOTS := 7

var items: Array[String] = []
var item_textures := {
	"key": preload("res://items/battery.png"),
	"card": preload("res://items/screwdriver.png"),
	"screwdriver": preload("res://items/screwdriver.png"),
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

var selected_index: int = -1

func _ready() -> void:
	for i in range(slots.size()):
		var idx := i
		var slot := slots[i] as TextureRect
		# Важно: у TextureRect должен быть включён "Mouse > Filter = Stop"
		slot.gui_input.connect(func(event):
			_on_slot_gui_input(idx, event)
		)
	_update_slots()

func add_item(id: String) -> void:
	if items.size() >= MAX_SLOTS or id in items:
		return
	items.append(id)
	# если раньше ничего не было выбрано — выберем первый добавленный предмет
	if selected_index == -1:
		selected_index = items.size() - 1
	_update_slots()

func remove_item(id: String) -> void:
	if id in items:
		var idx := items.find(id)
		items.erase(id)
		# поправляем выбранный индекс
		if selected_index == idx:
			selected_index = -1
		elif selected_index > idx:
			selected_index -= 1
		_update_slots()

func has_item(id: String) -> bool:
	return id in items

func get_selected_item_id() -> String:
	if selected_index < 0 or selected_index >= items.size():
		return ""
	return items[selected_index]

func clear_selection() -> void:
	selected_index = -1
	_update_slots()

func _on_slot_gui_input(idx: int, event: InputEvent) -> void:
	if event is InputEventMouseButton and event.button_index == MOUSE_BUTTON_LEFT and event.pressed:
		if idx >= items.size():
			return
		# если клик по уже выбранному — снимаем выбор
		if selected_index == idx:
			selected_index = -1
		else:
			selected_index = idx
		_update_slots()

func _update_slots() -> void:
	for i in range(slots.size()):
		var slot := slots[i] as TextureRect
		if i < items.size():
			var id := items[i]
			slot.texture = item_textures.get(id, null)
			slot.visible = true
			# подсветка выбранного
			if i == selected_index:
				slot.modulate = Color(0.5, 1.0, 0.5) # зелёный оттенок
			else:
				slot.modulate = Color(1, 1, 1)
		else:
			slot.texture = null
			slot.visible = false
			slot.modulate = Color(1, 1, 1)
