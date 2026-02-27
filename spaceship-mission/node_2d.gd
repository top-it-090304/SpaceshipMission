extends Node2D

var current_room: Node2D

#inventoryroots
var tex_key_1 := preload("res://items/key_1.png")
var tex_battery := preload("res://items/battery.png")
var tex_paintbrush := preload("res://items/paint-brush.png")
var tex_screwdriver := preload("res://items/screwdriver.png")




func _ready() -> void:
	current_room = $FirstRoom
	_show_only(current_room)
	_update_slots()
	
	
	if GlobalState.return_to_second_room:
		go_to_second_room()
		GlobalState.return_to_second_room = false

func _show_only(room: Node2D) -> void:
	for child in get_children():
		if child is Node2D:
			child.visible = (child == room)

func go_to_first_room() -> void:
	current_room = $FirstRoom
	_show_only(current_room)

func go_to_second_room() -> void:
	current_room = $SecondRoom
	_show_only(current_room)

func go_to_third_room() -> void:
	current_room = $ThirdRoom
	_show_only(current_room)

func go_to_fourth_room() -> void:
	current_room = $FourthRoom
	_show_only(current_room)
	
# FirstRoom
func _on_first_room_left_arrow_pressed() -> void:
	go_to_fourth_room()

func _on_first_room_right_arrow_pressed() -> void:
	go_to_second_room()

# SecondRoom
func _on_second_room_left_arrow_pressed() -> void:
	go_to_first_room()

func _on_second_room_right_arrow_pressed() -> void:
	go_to_third_room()

# ThirdRoom
func _on_third_room_left_arrow_pressed() -> void:
	go_to_second_room()

func _on_third_room_right_arrow_pressed() -> void:
	go_to_fourth_room()

# FourthRoom
func _on_fourth_room_left_arrow_pressed() -> void:
	go_to_third_room()

func _on_fourth_room_right_arrow_pressed() -> void:
	go_to_first_room()
	
	
@onready var slots_container: Control = $UILayer/InventoryRoot/Slots

var items: Array = []          # здесь храним предметы
var max_slots: int = 7         # столько слотов ты нарисовала
var selected_index: int = -1   # какой слот выбран (-1 = ничего)
func _update_slots() -> void:
	# проходим по дочкам HBoxContainer — слоты
	for i in range(slots_container.get_child_count()):
		var slot = slots_container.get_child(i)

		if not (slot is TextureButton):
			continue

		# если для этого слота есть предмет
		if i < items.size():
			var item = items[i]
			slot.texture_normal = item.icon      # иконка предмета
			slot.disabled = false
		else:
			slot.texture_normal = null
			slot.disabled = true

		# простая подсветка выбранного слота (можно заменить скином)
		if i == selected_index:
			slot.modulate = Color(0.6, 1.0, 1.0)  # бирюзовый оттенок
		else:
			slot.modulate = Color(1, 1, 1)
			
			
func add_item(item) -> void:
	if items.size() >= max_slots:
		print("Инвентарь полон")
		return

	items.append(item)
	_update_slots()
	


func _on_slot_pressed(index: int) -> void:
	if index >= items.size():
		return

	if selected_index == index:
		# повторное нажатие снимает выбор
		selected_index = -1
	else:
		selected_index = index

	_update_slots()


func _on_slot_1_pressed() -> void:
	_on_slot_pressed(0)
	
func _on_slot_2_pressed() -> void:
	_on_slot_pressed(1)

func _on_slot_3_pressed() -> void:
	_on_slot_pressed(2)

func _on_slot_4_pressed() -> void:
	_on_slot_pressed(3)

func _on_slot_5_pressed() -> void:
	_on_slot_pressed(4)

func _on_slot_6_pressed() -> void:
	_on_slot_pressed(5)

func _on_slot_7_pressed() -> void:
	_on_slot_pressed(6)
