extends Node2D

var current_room: Node2D

func _ready() -> void:
	current_room = $FirstRoom
	_show_only(current_room)

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
