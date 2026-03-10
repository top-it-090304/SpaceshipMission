extends Node

# сцена препятствия
var stump_scene: PackedScene = preload("res://scenes/stump.tscn")
var obstacle_types := [stump_scene]
var obstacles: Array = []

# game variables
const DINO_START_POS := Vector2i(150, 485)
const CAM_START_POS := Vector2i(577, 323)
var score: int
var difficulty
const MAX_DIFFICULTY : int = 2
const SCORE_MODIFIER: int = 10
var speed: float
const START_SPEED: float = 10.0
const MAX_SPEED: int = 25
const SPEED_MODIFIER: int = 5000
var screen_size: Vector2i
var game_running: bool
var last_obs
var ground_height : int = 70

func _ready():
	screen_size = get_window().size
	$GameOver.get_node("Button").pressed.connect(new_game)
	new_game()

func new_game():
	# reset variables
	score = 0
	show_score()
	game_running = false
	get_tree().paused = false
	obstacles.clear()
	last_obs = null
	difficulty = 0
	
	# reset the nodes
	$Player.position = DINO_START_POS
	$Player.velocity = Vector2i(0, 0)
	$Camera2D.position = CAM_START_POS
	$Ground.position = Vector2i(0, 0)
	
	# reset hud
	$HUD.get_node("StartLabel").show()
	$GameOver.hide()

func _process(delta):
	if game_running:
		speed = START_SPEED + score / SPEED_MODIFIER
		if speed > MAX_SPEED:
			speed = MAX_SPEED
		adjust_difficulty()
		generate_obs()
		
		# move dino and camera
		$Player.position.x += speed
		$Camera2D.position.x += speed
		
		# update score
		score += speed
		show_score()
		
		# Update ground position
		if $Camera2D.position.x - $Ground.position.x > screen_size.x * 1.5:
			$Ground.position.x += screen_size.x
			
			for obs in obstacles:
				if obs.position.x < ($Camera2D.position.x - screen_size.x):
					remove_obs(obs)
	else:
		if Input.is_action_pressed("ui_accept"):
			game_running = true
			$HUD.get_node("StartLabel").hide()

func generate_obs():
	#generate ground obstacles
	if obstacles.is_empty() or last_obs.position.x < score + randi_range(300, 500):
		var obs_type = obstacle_types[randi() % obstacle_types.size()]
		var obs
		var max_obs = difficulty + 1
		for i in range(randi() % max_obs + 1):
			obs = obs_type.instantiate()
			var obs_height = obs.get_node("Sprite2D").texture.get_height()
			var obs_scale = obs.get_node("Sprite2D").scale
			var obs_x : int = screen_size.x + score + 100 + (i * 40)
			var obs_y : int = screen_size.y - ground_height - (obs_height * obs_scale.y / 2)
			last_obs = obs
			add_obs(obs, obs_x, obs_y)


func add_obs(obs, x, y):
	obs.position = Vector2(x, y)
	obs.body_entered.connect(hit_obs)
	add_child(obs)
	obstacles.append(obs)
	
func remove_obs(obs):
	obs.queue_free()
	obstacles.erase(obs)

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
	get_tree().paused = true
	game_running = false
	$GameOver.show() 
