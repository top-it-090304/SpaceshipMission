extends Node2D


var current_room: Node = null

func _ready() -> void:
	current_room = $Room1
	_show_only(current_room)

func _show_only(room: Node) -> void:
	for child in get_children():
		if child is Node:
			child.visible = (child == room)

func go_to_room1() -> void:
	current_room = $Room1
	_show_only(current_room)

func go_to_room2() -> void:
	current_room = $Room2
	_show_only(current_room)

func go_to_room3() -> void:
	current_room = $Room3
	_show_only(current_room)

func go_to_room4() -> void:
	current_room = $Room4
	_show_only(current_room)
