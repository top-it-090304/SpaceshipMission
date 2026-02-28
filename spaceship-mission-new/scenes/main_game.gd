extends Node2D

var current_room: Node2D = null
var room_index: int = 1   # начинаем с Room1
var board_scene := preload("res://minigame/15puzzle/Board.tscn")
var board_instance: Node = null

	
	
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
	
	
func open_board() -> void:
	if board_instance:
		return
	board_instance = board_scene.instantiate()
	$MiniGameLayer.add_child(board_instance)
	board_instance.connect("puzzle_closed", Callable(self, "_on_board_closed"))
	board_instance.connect("puzzle_solved", Callable(self, "_on_board_solved"))

func _on_board_closed() -> void:
	print("BOARD CLOSED")
	if board_instance:
		board_instance.queue_free()
		board_instance = null

func _on_board_solved() -> void:
	print("15-puzzle solved, grant reward")
