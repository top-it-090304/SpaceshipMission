extends Node2D

var current_room: Node2D = null
var room_index: int = 1   # начинаем с Room1
var board_scene := preload("res://minigame/15puzzle/Board.tscn")
var board_instance: Node = null
var puzzle_solved_15: bool = false
	
	
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

	# показать зелёный прямоугольник, если пятнашки уже решены
	if index == 3 and puzzle_solved_15 and current_room:
		var banner := current_room.get_node_or_null("SolvedBanner")
		if banner:
			banner.visible = true
func _on_room_go_left() -> void:
	room_index -= 1
	if room_index < 1:
		room_index = 4          
	_load_room(room_index)

func _on_room_go_right() -> void:
	room_index += 1
	if room_index > 4:
		room_index = 1        
	_load_room(room_index)
	
	
func open_board() -> void:
	
	if board_instance != null:
		
		return
	board_instance = board_scene.instantiate()
	$MiniGameLayer.add_child(board_instance)
	
	
func close_board() -> void:
	if board_instance:
		board_instance.queue_free()
		board_instance = null

	room_index = 3
	_load_room(room_index)
	if puzzle_solved_15 and current_room:
		var banner := current_room.get_node_or_null("SolvedBanner")
		if banner:
			banner.visible = true
	
func on_board_solved() -> void:
	puzzle_solved_15 = true
	if current_room and current_room.name == "Room3":
		var banner := current_room.get_node_or_null("SolvedBanner")
		if banner:
			banner.visible = true
