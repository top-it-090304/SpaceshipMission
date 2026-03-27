extends Node

signal game_won

var stump_scene: PackedScene = preload("res://minigame/platformergame/scenes/stump.tscn")
var obstacle_types := [stump_scene]
var obstacles: Array = []

const DINO_START_POS := Vector2i(150, 485)
const CAM_START_POS  := Vector2i(577, 323)

# Верхний край земли берём из ground.tscn: позиция Y=532, полувысота коллизии=116 → 532-116=416
const GROUND_Y : int = 416

var score: int
var difficulty: int
const MAX_DIFFICULTY : int = 2
const SCORE_MODIFIER: int = 10
var speed: float
const START_SPEED: float = 10.0
const MAX_SPEED: int = 25
const SPEED_MODIFIER: int = 5000

const SCREEN_W : int = 1280
const SCREEN_H : int = 720

var game_running: bool
var last_obs
var score_float: float = 0.0

func _ready():
	$GameOver.get_node("Button").pressed.connect(new_game)
	new_game()

func new_game():
	score = 0
	score_float = 0.0
	show_score()
	game_running = false
	for obs in obstacles:
		if is_instance_valid(obs):
			obs.queue_free()
	obstacles.clear()
	last_obs = null
	difficulty = 0

	$Player.position = DINO_START_POS
	$Player.velocity = Vector2i(0, 0)
	$Camera2D.position = CAM_START_POS
	$Ground.position = Vector2i(0, 0)

	$HUD.get_node("StartLabel").show()
	$GameOver.hide()
	$Win.hide()

func _process(_delta):
	if game_running:
		speed = START_SPEED + score / SPEED_MODIFIER
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

		if $Camera2D.position.x - $Ground.position.x > SCREEN_W * 1.5:
			$Ground.position.x += SCREEN_W

		for obs in obstacles.duplicate():
			if obs.position.x < ($Camera2D.position.x - SCREEN_W):
				remove_obs(obs)
	else:
		if Input.is_action_pressed("ui_accept"):
			game_running = true
			$HUD.get_node("StartLabel").hide()

func generate_obs():
	if obstacles.is_empty() or last_obs.position.x < $Camera2D.position.x + randi_range(300, 500):
		var obs_type = obstacle_types[randi() % obstacle_types.size()]
		var max_obs = difficulty + 1
		for i in range(randi() % max_obs + 1):
			var obs = obs_type.instantiate()
			var sprite = obs.get_node("Sprite2D")
			var obs_height = sprite.texture.get_height() * sprite.scale.y
			var obs_x : int = int($Camera2D.position.x) + SCREEN_W / 2 + 100 + (i * 80)
			var obs_y : int = GROUND_Y - int(obs_height / 2.0)
			last_obs = obs
			add_obs(obs, obs_x, obs_y)

func add_obs(obs, x, y):
	obs.position = Vector2(x, y)
	obs.body_entered.connect(hit_obs)
	add_child(obs)
	obstacles.append(obs)

func remove_obs(obs):
	obstacles.erase(obs)
	obs.queue_free()

func hit_obs(body):
	if body.name == "Player":
		game_over()

func show_score():
	$HUD.get_node("ScoreLabel").text = "СЧЕТ: " + str(score / SCORE_MODIFIER)

func adjust_difficulty():
	difficulty = score / SCORE_MODIFIER
	if difficulty > MAX_DIFFICULTY:
		difficulty = MAX_DIFFICULTY

func game_over():
	game_running = false
	$GameOver.show()

func win():
	game_running = false
	$Win.show()
	$Win.get_node("Label").text = "ПОБЕДА!"
	emit_signal("game_won")
