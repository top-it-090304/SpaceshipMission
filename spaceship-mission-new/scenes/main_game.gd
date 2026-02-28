extends Node2D

var current_room: Node2D = null
var room_index: int = 1   # начинаем с Room1

func _ready() -> void:
	_load_room(room_index)

func _load_room(index: int) -> void:
	if current_room:
		current_room.queue_free()
		current_room = null

	var path := ""
	match index:
		1:
			path = "res://scenes/Room1.tscn"
		2:
			path = "res://scenes/Room2.tscn"
		3:
			path = "res://scenes/Room3.tscn"
		4:
			path = "res://scenes/Room4.tscn"

	var packed := load(path)
	current_room = packed.instantiate()
	$RoomsRoot.add_child(current_room)

	# подписка на сигналы комнат
	if current_room.has_signal("go_left"):
		current_room.connect("go_left", Callable(self, "_on_room_go_left"))
	if current_room.has_signal("go_right"):
		current_room.connect("go_right", Callable(self, "_on_room_go_right"))
		
func _on_room_go_left() -> void:
	room_index -= 1
	if room_index < 1:
		room_index = 4          # с 1 комнаты уходим в 4
	_load_room(room_index)

func _on_room_go_right() -> void:
	room_index += 1
	if room_index > 4:
		room_index = 1          # с 4 комнаты уходим в 1
	_load_room(room_index)
