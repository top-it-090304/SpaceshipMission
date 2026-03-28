extends Node2D

@onready var inventory := $UILayer/InventoryRoot as Control
@onready var fade_rect := $UILayer/FadeRect

var current_room: Node2D = null
var room_index: int = 1

const FADE_DURATION: float = 0.25


# platformer
var platformer_scene := preload("res://minigame/platformer/scenes/main.tscn")
var platformer_instance: Node = null
var platformer_solved: bool = false
# 15puzzle
var board_scene := preload("res://minigame/15puzzle/Board.tscn")
var board_instance: Node = null
var puzzle_solved_15: bool = false

# FlaskPuzzel
var flask_scene := preload("res://minigame/FlaskPuzzel/FlaskPuzzel.tscn")
var flask_instance: Node = null
var flask_solved: bool = false

# massage
var message4_scene := preload("res://scenes/MainMassage.tscn")
var message4_instance: Node = null

# box 1
var chest1_scene := preload("res://logicitems/box1InSecondRoom/Box1.tscn")
var chest1_instance: Node = null
var chest1_opened: bool = false

# box 2
var chest2_scene := preload("res://logicitems/box2InSecondRoom/Box2.tscn")
var chest2_instance: Node = null
var chest2_opened: bool = false

var collected_items: Array[String] = []

func _ready() -> void:
	fade_rect.modulate.a = 0.0
	_load_room(room_index)

func mark_item_collected(id: String) -> void:
	if id in collected_items:
		return
	collected_items.append(id)

func is_item_collected(id: String) -> bool:
	return id in collected_items

# --- Смена комнаты с fade ---
func _go_to_room(index: int) -> void:
	room_index = index
	var tween := create_tween()
	# Плавно темнеем
	tween.tween_property(fade_rect, "modulate:a", 1.0, FADE_DURATION)
	# В момент полного затемнения — грузим комнату
	tween.tween_callback(_load_room.bind(room_index))
	# Плавно светлеем
	tween.tween_property(fade_rect, "modulate:a", 0.0, FADE_DURATION)

func _load_room(index: int) -> void:
	if current_room:
		current_room.queue_free()
		current_room = null

	var path := ""
	match index:
		1: path = "res://scenes/Room1.tscn"
		2: path = "res://scenes/Room2.tscn"
		3: path = "res://scenes/Room3.tscn"
		4: path = "res://scenes/Room4.tscn"

	var packed := load(path)
	current_room = packed.instantiate()
	$RoomsRoot.add_child(current_room)

	if current_room.has_signal("go_left"):
		current_room.connect("go_left", Callable(self, "_on_room_go_left"))
	if current_room.has_signal("go_right"):
		current_room.connect("go_right", Callable(self, "_on_room_go_right"))

	if index == 3 and puzzle_solved_15 and current_room:
		var banner15 := current_room.get_node_or_null("SolvedBanner15")
		if banner15:
			banner15.visible = true

	if index == 3 and flask_solved and current_room:
		var banner_flask := current_room.get_node_or_null("SolvedBannerFlask")
		if banner_flask:
			banner_flask.visible = true

	if index == 3 and platformer_solved and current_room:
		var banner_plat := current_room.get_node_or_null("SolvedBannerPlatformer")
		if banner_plat:
			banner_plat.visible = true

func _on_room_go_left() -> void:
	var next := room_index - 1
	if next < 1:
		next = 4
	_go_to_room(next)

func _on_room_go_right() -> void:
	var next := room_index + 1
	if next > 4:
		next = 1
	_go_to_room(next)

# -------- 15puzzle --------
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
		var banner := current_room.get_node_or_null("SolvedBanner15")
		if banner:
			banner.visible = true

func on_board_solved() -> void:
	puzzle_solved_15 = true
	if current_room and current_room.name == "Room3":
		var banner := current_room.get_node_or_null("SolvedBanner15")
		if banner:
			banner.visible = true

# -------- FlaskPuzzel --------
func open_flask() -> void:
	if flask_instance != null:
		return
	flask_instance = flask_scene.instantiate()
	flask_instance.connect("puzzle_solved", Callable(self, "on_flask_solved"))
	$MiniGameLayer.add_child(flask_instance)

func close_flask() -> void:
	if flask_instance:
		flask_instance.queue_free()
		flask_instance = null
	room_index = 3
	_load_room(room_index)
	if flask_solved and current_room:
		var banner := current_room.get_node_or_null("SolvedBannerFlask")
		if banner:
			banner.visible = true

func on_flask_solved() -> void:
	flask_solved = true
	close_flask()

# -------- massage --------
func open_message4() -> void:
	if message4_instance:
		return
	message4_instance = message4_scene.instantiate()
	$MiniGameLayer.add_child(message4_instance)

func close_message4() -> void:
	if message4_instance:
		message4_instance.queue_free()
		message4_instance = null
	room_index = 4
	_load_room(room_index)

# -------- chest 1 --------
func open_chest1() -> void:
	if chest1_instance != null:
		return
	chest1_instance = chest1_scene.instantiate()
	$MiniGameLayer.add_child(chest1_instance)

func close_chest1() -> void:
	if chest1_instance:
		chest1_instance.queue_free()
		chest1_instance = null
	room_index = 2
	_load_room(room_index)

func on_chest1_solved() -> void:
	chest1_opened = true

# -------- chest 2 --------
func open_chest2() -> void:
	if chest2_instance != null:
		return
	chest2_instance = chest2_scene.instantiate()
	$MiniGameLayer.add_child(chest2_instance)

func close_chest2() -> void:
	if chest2_instance:
		chest2_instance.queue_free()
		chest2_instance = null
	room_index = 2
	_load_room(room_index)

func on_chest2_solved() -> void:
	chest2_opened = true

# -------- platformer --------
func open_platformer() -> void:
	if platformer_instance != null:
		return
	platformer_instance = platformer_scene.instantiate()
	platformer_instance.connect("game_won", Callable(self, "on_platformer_solved"))
	$MiniGameLayer.add_child(platformer_instance)
	$UILayer.visible = false

func close_platformer() -> void:
	if platformer_instance:
		platformer_instance.queue_free()
		platformer_instance = null
	get_tree().paused = false
	$UILayer.visible = true
	room_index = 3
	_load_room(room_index)

func on_platformer_solved() -> void:
	platformer_solved = true
	close_platformer()
