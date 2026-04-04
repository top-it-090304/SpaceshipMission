extends Node

signal game_won
signal game_exit

const WIN_SCORE: int = 500
const BASE_SPEED: float = 300.0
const MAX_SPEED: float = 600.0
const SPAWN_MIN: float = 0.8
const SPAWN_MAX: float = 2.2

var obstacle_scene := preload("res://minigame/jumper/scenes/obstacle.tscn")
var score_float: float = 0.0
var score: int = 0
var game_running: bool = false
var spawn_timer: float = 0.0
var next_spawn: float = 1.5
var obstacles: Array = []
var _flag_spawned: bool = false
var _flag_node: Node = null

@onready var player := $Player
@onready var score_label := $HUD/ScoreLabel
@onready var start_label := $HUD/StartLabel
@onready var game_over_node := $GameOver
@onready var win_node := $Win

func _ready() -> void:
	print('Ready')
	print($GameOver/RetryButton)
	$GameOver/RetryButton.pressed.connect(_restart_game)
	new_game()

func new_game() -> void:
	score_float = 0.0
	score = 0
	game_running = false
	spawn_timer = 0.0
	next_spawn = 1.5
	_flag_spawned = false
	if is_instance_valid(_flag_node):
		_flag_node.queue_free()
	_flag_node = null
	for obs in obstacles:
		if is_instance_valid(obs):
			if obs.body_entered.is_connected(_on_obstacle_hit):
				obs.body_entered.disconnect(_on_obstacle_hit)
			obs.queue_free()
	obstacles.clear()
	player.reset()
	game_over_node.hide()
	win_node.hide()
	start_label.show()
	_update_score()
	var btn: Button = $GameOver/RetryButton
	btn.button_down.connect(_restart_game)

func _get_current_speed() -> float:
	var t := float(score) / float(WIN_SCORE)
	return lerp(BASE_SPEED, MAX_SPEED, t)

func _process(delta: float) -> void:
	if not game_running:
		return
	if not _flag_spawned:
		score_float += delta * 10.0
		score = int(score_float)
		_update_score()
	if not _flag_spawned and score >= WIN_SCORE:
		_spawn_flag()
	spawn_timer += delta
	if spawn_timer >= next_spawn:
		if randi() % 2 == 0:
			_spawn_obstacle_group()
		else:
			_spawn_obstacle()
		spawn_timer = 0.0
		next_spawn = randf_range(SPAWN_MIN, SPAWN_MAX)
	var spd := _get_current_speed()
	for obs in obstacles.duplicate():
		if is_instance_valid(obs):
			obs.position.x -= spd * delta
			if obs.position.x < -150:
				obs.queue_free()
				obstacles.erase(obs)
	if is_instance_valid(_flag_node):
		_flag_node.position.x -= spd * delta

func _unhandled_input(event: InputEvent) -> void:
	if event is InputEventMouseButton and event.pressed and event.button_index == MOUSE_BUTTON_LEFT:
		if not game_running and start_label.visible:
			_start_game()
		elif game_running:
			player.jump()
	elif event.is_action_pressed("ui_accept") and not event.is_echo():
		if not game_running and start_label.visible:
			_start_game()
		elif game_running:
			player.jump()

func _start_game() -> void:
	game_running = true
	start_label.hide()

func _restart_game() -> void:
	print('Restart')
	new_game()
	call_deferred("_start_game")

func _spawn_obstacle() -> void:
	var obs = obstacle_scene.instantiate()
	obs.position = Vector2(1400, 585)
	obs.body_entered.connect(_on_obstacle_hit)
	add_child(obs)
	obstacles.append(obs)

func _spawn_obstacle_group() -> void:
	var count := randi_range(1, 3)
	for i in count:
		var obs = obstacle_scene.instantiate()
		obs.position = Vector2(1400 + i * 45.0, 585)
		obs.body_entered.connect(_on_obstacle_hit)
		add_child(obs)
		obstacles.append(obs)

func _on_obstacle_hit(body: Node) -> void:
	if body == player:
		_game_over()

func _game_over() -> void:
	game_running = false
	game_over_node.show()

func _spawn_flag() -> void:
	_flag_spawned = true
	var flag := Area2D.new()

	var sprite := Sprite2D.new()
	sprite.texture = load("res://minigame/jumper/images/flag.png")
	sprite.texture_filter = CanvasItem.TEXTURE_FILTER_NEAREST
	sprite.scale = Vector2(0.22, 0.22)
	# anchor bottom of sprite to ground (y=600); sprite is centered so offset up by half its scaled height
	sprite.position = Vector2(0, -sprite.texture.get_height() * 0.22 / 2.0)
	flag.add_child(sprite)

	var shape := CollisionShape2D.new()
	var rect := RectangleShape2D.new()
	rect.size = Vector2(30, 55)
	shape.shape = rect
	shape.position = Vector2(0, -27.5)
	flag.add_child(shape)

	flag.position = Vector2(1400, 612)
	flag.body_entered.connect(_on_flag_reached)
	add_child(flag)
	_flag_node = flag

func _on_flag_reached(body: Node) -> void:
	if body != player:
		return
	game_running = false
	win_node.show()
	await get_tree().create_timer(2.5).timeout
	emit_signal("game_won")

func _win() -> void:
	game_running = false
	win_node.show()
	emit_signal("game_won")

func _update_score() -> void:
	score_label.text = "СЧЕТ: " + str(score)

func _on_close() -> void:
	var main_game := get_tree().get_first_node_in_group("MainGame")
	if main_game:
		main_game.close_jumper()
		
func _exit_button_pressed() -> void:
	game_running = false
	emit_signal("game_exit")
