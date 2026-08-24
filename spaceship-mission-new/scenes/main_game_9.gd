extends Node2D

@onready var inventory := $UILayer/InventoryRoot as Control
@onready var fade_rect := $UILayer/FadeRect
@onready var dialog_box := $UILayer/DialogBox
@onready var menu_button: TextureButton = $UILayer/MenuButton
@onready var input_blocker := $InputBlocker

var pause_menu_scene := preload("res://scenes/PauseMenu.tscn")

var current_room: Node2D = null
var room_index: int = 1

const FADE_DURATION: float = 0.4

# platformer
var platformer_scene: PackedScene = null
var platformer_instance: Node = null
var platformer_solved: bool = false

# jumper
var jumper_scene: PackedScene = null
var jumper_instance: Node = null
var jumper_solved: bool = false

# LaserMirror
var laser_mirror_scene: PackedScene = null
var laser_mirror_instance: Node = null
var laser_mirror_solved: bool = false

# PipeGame
var pipe_game_scene: PackedScene = null
var pipe_game_instance: Node = null
var pipe_game_solved: bool = false

# 15puzzle
var board_scene: PackedScene = null
var board_instance: Node = null
var puzzle_solved_15: bool = false

# FlaskPuzzel
var flask_scene: PackedScene = null
var flask_instance: Node = null
var flask_solved: bool = false

# massage
var message4_scene: PackedScene = null
var message4_instance: Node = null

# box 1
var chest1_scene: PackedScene = null
var chest1_instance: Node = null
var chest1_opened: bool = false

# box 2
var chest2_scene: PackedScene = null
var chest2_instance: Node = null
var chest2_opened: bool = false

# ShellGame
var shell_game_scene: PackedScene = null
var shell_game_instance: Node = null
var shell_game_solved: bool = false

# ball
var ball_scene: PackedScene = null
var ball_instance: Node = null

var collected_items: Array[String] = []
var screen_unlocked: bool = false

func _ready() -> void:
	menu_button.texture_normal = preload("res://items/setting.png")
	if not menu_button.pressed.is_connected(_on_menu_button_pressed):
		menu_button.pressed.connect(_on_menu_button_pressed)

	# Загружаем состояние мини-игр из GameState
	puzzle_solved_15    = GameState.puzzle_solved_15
	flask_solved        = GameState.flask_solved
	platformer_solved   = GameState.platformer_solved
	jumper_solved       = GameState.jumper_solved
	laser_mirror_solved = GameState.laser_mirror_solved
	pipe_game_solved    = GameState.pipe_game_solved
	shell_game_solved   = GameState.shell_game_solved
	flow_connect_solved = GameState.flow_connect_solved
	chest1_opened       = GameState.chest1_opened
	chest2_opened       = GameState.chest2_opened
	screen_unlocked     = GameState.screen_unlocked
	collected_items.assign(GameState.collected_items)
	room_index          = GameState.current_room

	# Восстанавливаем инвентарь
	var inv := $UILayer/InventoryRoot
	for item_id in GameState.inventory_items:
		inv.add_item(item_id)

	if GameState.intro_finished:
		fade_rect.modulate.a = 0.0
		input_blocker.visible = false
		_load_room(room_index)
	else:
		fade_rect.modulate.a = 1.0
		_load_room(room_index)
		_set_room1_arrows_visible(false)
		$UILayer/InventoryRoot/ToggleButton.visible = false
		input_blocker.visible = true
		_play_wakeup_blink()
		dialog_box.dialog_finished.connect(_on_intro_dialog_finished)

# --- Эффект пробуждения ---
func _play_wakeup_blink() -> void:
	var tween := create_tween()
	tween.set_ease(Tween.EASE_IN_OUT)
	tween.set_trans(Tween.TRANS_SINE)

	var blinks := [
		[0.15, 0.10],
		[0.18, 0.10],
		[0.25, 0.15],
		[0.40, 0.25],
		[0.60, 0.45],
		[0.80, 0.0],
	]

	for blink in blinks:
		var close_time: float = blink[0]
		var open_time: float  = blink[1]
		tween.tween_property(fade_rect, "modulate:a", 1.0, close_time)
		if open_time > 0.0:
			tween.tween_property(fade_rect, "modulate:a", 0.0, open_time)

	tween.tween_property(fade_rect, "modulate:a", 0.0, 0.5)
	tween.tween_callback(dialog_box.start)

func _input(event: InputEvent) -> void:
	if event.is_action_pressed("ui_cancel"):
		var existing_menu := $UILayer.get_node_or_null("PauseMenu")
		if existing_menu == null:
			_on_menu_button_pressed()

func _on_menu_button_pressed() -> void:
	var existing_menu := $UILayer.get_node_or_null("PauseMenu")
	if existing_menu != null:
		return
	var menu := pause_menu_scene.instantiate()
	$UILayer.add_child(menu)

func _on_intro_dialog_finished() -> void:
	GameState.intro_finished = true
	_set_room1_arrows_visible(true)
	$UILayer/InventoryRoot/ToggleButton.visible = true
	input_blocker.visible = false

func _set_room1_arrows_visible(value: bool) -> void:
	if current_room == null:
		return
	var left = current_room.get_node_or_null("LeftArrow")
	var right = current_room.get_node_or_null("RightArrow")
	if left:
		left.visible = value
	if right:
		right.visible = value

func mark_item_collected(id: String) -> void:
	if id in collected_items:
		return
	collected_items.append(id)
	GameState.collected_items = collected_items.duplicate()

func is_item_collected(id: String) -> bool:
	return id in collected_items

# --- Смена комнаты с fade ---
func _go_to_room(index: int) -> void:
	room_index = index
	GameState.current_room = index
	PycoLog.log_event_by_type("room_enter", {"room": index})
	var tween := create_tween()
	tween.tween_property(fade_rect, "modulate:a", 1.0, FADE_DURATION)
	tween.tween_callback(_load_room.bind(room_index))
	tween.tween_property(fade_rect, "modulate:a", 0.0, FADE_DURATION)

func _hide_current_room() -> void:
	if current_room:
		current_room.visible = false
		current_room.process_mode = Node.PROCESS_MODE_DISABLED

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

	if index == 3 and jumper_solved and current_room:
		var banner_jumper := current_room.get_node_or_null("SolvedBannerJumper")
		if banner_jumper:
			banner_jumper.visible = true

	if index == 3 and pipe_game_solved and current_room:
		var banner_pipe := current_room.get_node_or_null("SolvedBannerPipeGame")
		if banner_pipe:
			banner_pipe.visible = true

	if index == 3 and laser_mirror_solved and current_room:
		var banner_laser := current_room.get_node_or_null("SolvedBannerLaserMirror")
		if banner_laser:
			banner_laser.visible = true

	if index == 3 and flow_connect_solved and current_room:
		var banner_fc := current_room.get_node_or_null("SolvedBannerFlowConnect")
		if banner_fc:
			banner_fc.visible = true

	if index == 3 and shell_game_solved and current_room:
		var banner_sg := current_room.get_node_or_null("SolvedBannerShellGame")
		if banner_sg:
			banner_sg.visible = true

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
	if board_scene == null:
		board_scene = load("res://minigame/15puzzle/Board.tscn")
	board_instance = board_scene.instantiate()
	$MiniGameLayer.add_child(board_instance)
	_hide_current_room()

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
	GameState.puzzle_solved_15 = true
	PycoLog.log_event_by_type("minigame_solved", {"name": "puzzle15"})
	_check_power_solved()
	if current_room and current_room.name == "Room3":
		var banner := current_room.get_node_or_null("SolvedBanner15")
		if banner:
			banner.visible = true

# -------- FlaskPuzzel --------
func open_flask() -> void:
	if flask_instance != null:
		return
	if flask_scene == null:
		flask_scene = load("res://minigame/FlaskPuzzel/FlaskPuzzel.tscn")
	flask_instance = flask_scene.instantiate()
	flask_instance.connect("puzzle_solved", Callable(self, "on_flask_solved"))
	$MiniGameLayer.add_child(flask_instance)
	_hide_current_room()

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
	GameState.flask_solved = true
	PycoLog.log_event_by_type("minigame_solved", {"name": "flask"})
	_check_power_solved()
	close_flask()

# -------- massage --------
func open_message4() -> void:
	if message4_instance:
		return
	if message4_scene == null:
		message4_scene = load("res://scenes/MainMassage.tscn")
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
	if chest1_scene == null:
		chest1_scene = load("res://logicitems/box1InSecondRoom/Box1.tscn")
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
	GameState.chest1_opened = true
	PycoLog.log_event_by_type("chest_opened", {"chest": 1})

# -------- chest 2 --------
func open_chest2() -> void:
	if chest2_instance != null:
		return
	if chest2_scene == null:
		chest2_scene = load("res://logicitems/box2InSecondRoom/Box2.tscn")
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
	GameState.chest2_opened = true
	PycoLog.log_event_by_type("chest_opened", {"chest": 2})

# -------- platformer --------
func open_platformer() -> void:
	if platformer_instance != null:
		return
	if platformer_scene == null:
		platformer_scene = load("res://minigame/jumper/scenes/main.tscn")
	platformer_instance = platformer_scene.instantiate()
	platformer_instance.connect("game_won", Callable(self, "on_platformer_solved"))
	platformer_instance.connect("game_exit", Callable(self, "close_platformer"))
	$MiniGameLayer.add_child(platformer_instance)
	$UILayer.visible = false
	_hide_current_room()

func close_platformer() -> void:
	if is_instance_valid(platformer_instance):
		$MiniGameLayer.remove_child(platformer_instance)
		platformer_instance.queue_free()
		platformer_instance = null
	get_tree().paused = false
	$UILayer.visible = true
	room_index = 3
	_load_room(room_index)

func on_platformer_solved() -> void:
	platformer_solved = true
	GameState.platformer_solved = true
	PycoLog.log_event_by_type("minigame_solved", {"name": "platformer"})
	_check_power_solved()
	close_platformer()

# -------- ball --------
func open_ball() -> void:
	if ball_instance != null:
		return
	if ball_scene == null:
		ball_scene = load("res://logicitems/Ball/Ball.tscn")
	# Показываем ToggleButton инвентаря
	$UILayer/InventoryRoot/ToggleButton.visible = true
	ball_instance = ball_scene.instantiate()
	$MiniGameLayer.add_child(ball_instance)

func close_ball() -> void:
	if ball_instance:
		ball_instance.queue_free()
		ball_instance = null
	# Просто скрываем мини-игру — Room4 остаётся нетронутой
	# Закрываем инвентарь если он был открыт через Ball
	var inv = $UILayer/InventoryRoot
	if inv.is_open:
		inv._on_toggle_button_pressed()
# -------- MeetTeam (финальная сцена встречи с командой) --------
# Загружаем как инстанс в MiniGameLayer — точно так же, как мини-игры.
# change_scene_to_file на мобилке (AuroraOS) после входа во вторую сцену
# ломает обработку инпута, тапы перестают доходить до Button'ов.
# Работа в виде инстанса внутри MainGame этой проблемы не имеет —
# все мини-игры уже доказали, что инпут так доходит надёжно.
var meet_team_scene: PackedScene = null
var meet_team_instance: Node = null

func open_meet_team() -> void:
	if meet_team_instance != null:
		return
	if meet_team_scene == null:
		meet_team_scene = load("res://scenes/MeetTeam.tscn")
	meet_team_instance = meet_team_scene.instantiate()
	$MiniGameLayer.add_child(meet_team_instance)
	$UILayer.visible = false
	_hide_current_room()

func close_meet_team() -> void:
	if is_instance_valid(meet_team_instance):
		$MiniGameLayer.remove_child(meet_team_instance)
		meet_team_instance.queue_free()
		meet_team_instance = null
	$UILayer.visible = true

# -------- ship panel (Room1) --------
var panel_scene: PackedScene = null
var panel_instance: Node = null

func open_panel() -> void:
	if panel_instance != null:
		return
	if panel_scene == null:
		panel_scene = load("res://logicitems/shipManage/Panel.tscn")
	panel_instance = panel_scene.instantiate()
	$MiniGameLayer.add_child(panel_instance)

func close_panel() -> void:
	if panel_instance:
		panel_instance.queue_free()
		panel_instance = null
	room_index = 1
	_load_room(room_index)

# -------- PipeGame --------
func open_pipe_game() -> void:
	if pipe_game_instance != null:
		return
	if pipe_game_scene == null:
		pipe_game_scene = load("res://minigame/PipeGame/PipeGame.tscn")
	pipe_game_instance = pipe_game_scene.instantiate()
	pipe_game_instance.connect("puzzle_solved", Callable(self, "on_pipe_game_solved"))
	pipe_game_instance.connect("puzzle_exit", Callable(self, "close_pipe_game"))
	$MiniGameLayer.add_child(pipe_game_instance)
	$UILayer.visible = false
	_hide_current_room()

func close_pipe_game() -> void:
	if is_instance_valid(pipe_game_instance):
		$MiniGameLayer.remove_child(pipe_game_instance)
		pipe_game_instance.queue_free()
		pipe_game_instance = null
	get_tree().paused = false
	$UILayer.visible = true
	room_index = 3
	_load_room(room_index)

func on_pipe_game_solved() -> void:
	pipe_game_solved = true
	GameState.pipe_game_solved = true
	PycoLog.log_event_by_type("minigame_solved", {"name": "pipe"})
	_check_power_solved()
	close_pipe_game()

# -------- jumper --------
func open_jumper() -> void:
	if jumper_instance != null:
		return
	if jumper_scene == null:
		jumper_scene = load("res://minigame/jumper/scenes/main.tscn")
	jumper_instance = jumper_scene.instantiate()
	jumper_instance.connect("game_won", Callable(self, "on_jumper_solved"))
	jumper_instance.connect("game_exit", Callable(self, "close_jumper"))
	$MiniGameLayer.add_child(jumper_instance)
	$UILayer.visible = false
	_hide_current_room()

func close_jumper() -> void:
	if is_instance_valid(jumper_instance):
		$MiniGameLayer.remove_child(jumper_instance)
		jumper_instance.queue_free()
		jumper_instance = null
	get_tree().paused = false
	$UILayer.visible = true
	room_index = 3
	_load_room(room_index)

func on_jumper_solved() -> void:
	jumper_solved = true
	GameState.jumper_solved = true
	PycoLog.log_event_by_type("minigame_solved", {"name": "jumper"})
	_check_power_solved()
	close_jumper()

# -------- LaserMirror --------
func open_laser_mirror() -> void:
	if laser_mirror_instance != null:
		return
	if laser_mirror_scene == null:
		laser_mirror_scene = load("res://minigame/LaserMirror/LaserMirror.tscn")
	laser_mirror_instance = laser_mirror_scene.instantiate()
	laser_mirror_instance.connect("puzzle_solved", Callable(self, "on_laser_mirror_solved"))
	laser_mirror_instance.connect("minigame_closed", Callable(self, "close_laser_mirror"))
	$MiniGameLayer.add_child(laser_mirror_instance)
	$UILayer.visible = false
	_hide_current_room()

func close_laser_mirror() -> void:
	if is_instance_valid(laser_mirror_instance):
		$MiniGameLayer.remove_child(laser_mirror_instance)
		laser_mirror_instance.queue_free()
		laser_mirror_instance = null
	get_tree().paused = false
	$UILayer.visible = true
	room_index = 3
	_load_room(room_index)

func on_laser_mirror_solved() -> void:
	laser_mirror_solved = true
	GameState.laser_mirror_solved = true
	PycoLog.log_event_by_type("minigame_solved", {"name": "laser_mirror"})
	_check_power_solved()
	close_laser_mirror()

func _check_power_solved() -> void:
	if puzzle_solved_15 and flask_solved and pipe_game_solved and laser_mirror_solved and (jumper_solved or platformer_solved):
		GameState.power_solved = true
		if GameState.reactor_installed and GameState.ship_fully_solved:
			GameState.door_unlocked = true

# -------- ShellGame --------
func open_shell_game() -> void:
	if shell_game_instance != null:
		return
	if shell_game_scene == null:
		shell_game_scene = load("res://minigame/shell_game/ShellGame.tscn")
	shell_game_instance = shell_game_scene.instantiate()
	shell_game_instance.connect("minigame_completed", Callable(self, "on_shell_game_completed"))
	shell_game_instance.connect("minigame_cancelled", Callable(self, "close_shell_game"))
	$MiniGameLayer.add_child(shell_game_instance)
	$UILayer.visible = false
	_hide_current_room()

func close_shell_game() -> void:
	if is_instance_valid(shell_game_instance):
		$MiniGameLayer.remove_child(shell_game_instance)
		shell_game_instance.queue_free()
		shell_game_instance = null
	$UILayer.visible = true
	room_index = 3
	_load_room(room_index)

func on_shell_game_completed(success: bool, _difficulty: int) -> void:
	if success:
		shell_game_solved = true
		GameState.shell_game_solved = true
		PycoLog.log_event_by_type("minigame_solved", {"name": "shell"})

# -------- FlowConnect --------
var flow_connect_instance: Node = null
var flow_connect_solved: bool = false

func open_flow_connect() -> void:
	if flow_connect_instance != null:
		return
	var script : GDScript = load("res://minigame/FlowConnect/FlowConnect.gd") as GDScript
	if script == null:
		push_error("FlowConnect.gd not found")
		return
	flow_connect_instance = Node2D.new()
	flow_connect_instance.set_script(script)
	flow_connect_instance.connect("puzzle_solved", Callable(self, "on_flow_connect_solved"))
	flow_connect_instance.connect("puzzle_exit",   Callable(self, "close_flow_connect"))
	$MiniGameLayer.add_child(flow_connect_instance)
	$UILayer.visible = false
	_hide_current_room()

func close_flow_connect() -> void:
	if is_instance_valid(flow_connect_instance):
		$MiniGameLayer.remove_child(flow_connect_instance)
		flow_connect_instance.queue_free()
		flow_connect_instance = null
	$UILayer.visible = true
	room_index = 3
	_load_room(room_index)

func on_flow_connect_solved() -> void:
	flow_connect_solved = true
	GameState.flow_connect_solved = true
	PycoLog.log_event_by_type("minigame_solved", {"name": "flow_connect"})
	close_flow_connect()
	if current_room:
		var banner := current_room.get_node_or_null("SolvedBannerFlowConnect")
		if banner:
			banner.visible = true
