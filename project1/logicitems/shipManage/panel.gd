extends Node2D

const CORRECT_LEFT: int = 160
const CORRECT_RIGHT: int = 70
const STEP: int = 10
const MIN_VAL: int = 0
const MAX_VAL: int = 180

var left_value: int = 0
var right_value: int = 0

@onready var left_screen: ColorRect = $LeftScreen
@onready var left_label: Label = $LeftLabel
@onready var left_plus: TextureButton = $LeftPlus
@onready var left_minus: TextureButton = $LeftMinus

@onready var right_screen: ColorRect = $RightScreen
@onready var right_label: Label = $RightLabel
@onready var right_plus: TextureButton = $RightPlus
@onready var right_minus: TextureButton = $RightMinus

@onready var back_button: TextureButton = $BackButton

func _ready() -> void:
	left_plus.pressed.connect(_on_left_plus)
	left_minus.pressed.connect(_on_left_minus)
	right_plus.pressed.connect(_on_right_plus)
	right_minus.pressed.connect(_on_right_minus)
	back_button.pressed.connect(_on_back_pressed)

	left_screen.visible = false
	right_screen.visible = false

	_update_labels()

func _on_left_plus() -> void:
	left_value = (left_value + STEP) % (MAX_VAL + STEP)
	_update_labels()
	_check_win()

func _on_left_minus() -> void:
	left_value = (left_value - STEP + MAX_VAL + STEP) % (MAX_VAL + STEP)
	_update_labels()
	_check_win()

func _on_right_plus() -> void:
	right_value = (right_value + STEP) % (MAX_VAL + STEP)
	_update_labels()
	_check_win()

func _on_right_minus() -> void:
	right_value = (right_value - STEP + MAX_VAL + STEP) % (MAX_VAL + STEP)
	_update_labels()
	_check_win()

func _update_labels() -> void:
	left_label.text = str(left_value)
	right_label.text = str(right_value)

func _check_win() -> void:
	if left_value == CORRECT_LEFT and right_value == CORRECT_RIGHT:
		left_screen.visible = true
		right_screen.visible = true
		left_screen.color = Color(0.0, 0.8, 0.2, 0.6)
		right_screen.color = Color(0.0, 0.8, 0.2, 0.6)
		GameState.panel_solved = true

func _on_back_pressed() -> void:
	var main_game := get_tree().get_first_node_in_group("MainGame")
	if main_game:
		main_game.close_panel()
