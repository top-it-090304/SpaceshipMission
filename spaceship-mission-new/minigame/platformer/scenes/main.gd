extends Node

signal game_won

var stump_scene: PackedScene = preload("res://minigame/platformer/scenes/stump.tscn")
var obstacle_types := [stump_scene]
var obstacles: Array = []

const DINO_START_POS := Vector2i(150, 485)
const CAM_START_POS  := Vector2i(577, 323)
const GROUND_Y       := 416
const SCREEN_W       := 1280

var score_float: float = 0.0
var score: int = 0
var difficulty: int = 0

const MAX_DIFFICULTY  := 2
const SCORE_MODIFIER  := 10
const START_SPEED     := 10.0
const MAX_SPEED       := 25
const SPEED_MODIFIER  := 5000.0

var speed: float = START_SPEED
var game_running: bool = false
var last_obs = null

func _ready() -> void:
	$GameOver.get_node("Button").pressed.connect(new_game)
	new_game()

func new_game() -> void:
	score_float = 0.0
	score = 0
	speed = START_SPEED
	difficulty = 0
	game_running = false
	last_obs = null

	for obs in obstacles:
		if is_instance_valid(obs):
			obs.queue_free()
	obstacles.clear()

	$Player.position = DINO_START_POS
	$Player.velocity = Vector2(0, 0)
	$Camera2D.position = CAM_START_POS
	$Ground.position = Vector2(0, 0)

	$HUD.get_node("StartLabel").show()
	$GameOver.hide()
	$Win.hide()
	show_score()

func _process(_delta: float) -> void:
	if game_running:
		speed = START_SPEED + score_float / SPEED_MODIFIER
		if speed > MAX_SPEED:
			speed = MAX_SPEED

		adjust_difficulty()
		generate_obs()

		$Player.position.x += speed
		$Camera2D.position.x += speed

		score_float += speed
		score = int(score_float)
		show_score()

		if score >= 10000:
			win()
			return

		# двигаем землю за камерой
		if $Camera2D.position.x - $Ground.position.x > SCREEN_W * 1.5:
			$Ground.position.x += SCREEN_W

		# удаляем препятствия позади камеры
		for obs in obstacles.duplicate():
			if is_instance_valid(obs) and obs.position.x < ($Camera2D.position.x - SCREEN_W):
				remove_obs(obs)
	else:
		if Input.is_action_pressed("ui_accept"):
			game_running = true
			$HUD.get_node("StartLabel").hide()

func generate_obs() -> void:
	if obstacles.is_empty() or (is_instance_valid(last_obs) and last_obs.position.x < $Camera2D.position.x + randi_range(300, 500)):
		var obs_type = obstacle_types[randi() % obstacle_types.size()]
		var max_obs = difficulty + 1
		for i in range(randi() % max_obs + 1):
			var obs = obs_type.instantiate()
			var sprite = obs.get_node("Sprite2D")
			var obs_height: float = sprite.texture.get_height() * sprite.scale.y
			var obs_x: int = int($Camera2D.position.x) + SCREEN_W / 2 + 100 + i * 80
			var obs_y: int = GROUND_Y - int(obs_height / 2.0)
			last_obs = obs
			add_obs(obs, obs_x, obs_y)

func add_obs(obs, x: int, y: int) -> void:
	obs.position = Vector2(x, y)
	obs.body_entered.connect(hit_obs)
	add_child(obs)
	obstacles.append(obs)

func remove_obs(obs) -> void:
	obstacles.erase(obs)
	obs.queue_free()

func hit_obs(body) -> void:
	if body.name == "Player":
		game_over()

func show_score() -> void:
	$HUD.get_node("ScoreLabel").text = "СЧЕТ: " + str(score / SCORE_MODIFIER)

func adjust_difficulty() -> void:
	difficulty = score / SCORE_MODIFIER
	if difficulty > MAX_DIFFICULTY:
		difficulty = MAX_DIFFICULTY

func game_over() -> void:
	game_running = false
	$GameOver.show()

func win() -> void:
	game_running = false
	$Win.show()
	$Win.get_node("Label").text = "ПОБЕДА!"
	emit_signal("game_won")
