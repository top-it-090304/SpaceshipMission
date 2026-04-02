extends Node2D

@onready var dialog_box: Panel = $DialogBox
@onready var dialog_label: RichTextLabel = $DialogBox/DialogLabel
@onready var next_button: TextureButton = $DialogBox/NextButton

const TYPE_SPEED: float = 0.035
var dialog_messages: Array[String] = [
	"Навигация корабля сбита",
	"Придеться откалибровать полет вручную...",
]
var dialog_index: int = 0
var is_typing: bool = false
var full_text: String = ""


# --- Константы первой мини-игры (экраны) ---
const CORRECT_LEFT: int = 160
const CORRECT_RIGHT: int = 70
const STEP: int = 10
const MAX_VAL: int = 180

# --- Константы второй мини-игры ---
const SCREEN_LEFT: float = 455.0
const SCREEN_TOP: float = 130.0
const SCREEN_WIDTH: float = 490.0
const SCREEN_HEIGHT: float = 400.0

const ARROW_SPEED: float = 200.0
const DOT_SPEED_START: float = 150.0
const DOT_SPEED_STEP: float = 80.0
const CATCH_DISTANCE: float = 28.0
const GRID_COLS: int = 8
const GRID_ROWS: int = 6

# --- Состояние первой игры ---
var left_value: int = 0
var right_value: int = 0

# --- Состояние второй игры ---
var joystick_active: bool = false
var arrow_pos: Vector2 = Vector2.ZERO
var dot_pos: Vector2 = Vector2.ZERO
var dot_dir: Vector2 = Vector2.ZERO
var dot_speed: float = DOT_SPEED_START
var catch_count: int = 0
var game_won: bool = false
var joy_input: Vector2 = Vector2.ZERO
var chaos_timer: float = 0.0

# --- Ноды первой игры ---
@onready var left_screen: ColorRect = $LeftScreen
@onready var left_label: Label = $LeftLabel
@onready var left_plus: TextureButton = $LeftPlus
@onready var left_minus: TextureButton = $LeftMinus
@onready var right_screen: ColorRect = $RightScreen
@onready var right_label: Label = $RightLabel
@onready var right_plus: TextureButton = $RightPlus
@onready var right_minus: TextureButton = $RightMinus
@onready var back_button: TextureButton = $BackButton

# --- Ноды второй игры ---
@onready var joystick: Node2D = $Joystick
@onready var joy_up: TextureButton = $Joystick/JoyUp
@onready var joy_down: TextureButton = $Joystick/JoyDown
@onready var joy_left: TextureButton = $Joystick/JoyLeft
@onready var joy_right: TextureButton = $Joystick/JoyRight
@onready var screen_area: Node2D = $ScreenArea
@onready var screen_bg: ColorRect = $ScreenArea/ScreenBg
@onready var arrow: Sprite2D = $ScreenArea/Arrow
@onready var dot: Sprite2D = $ScreenArea/Dot
@onready var grid: Node2D = $ScreenArea/Grid

func _ready() -> void:
	left_plus.pressed.connect(_on_left_plus)
	left_minus.pressed.connect(_on_left_minus)
	right_plus.pressed.connect(_on_right_plus)
	right_minus.pressed.connect(_on_right_minus)
	back_button.pressed.connect(_on_back_pressed)
	left_screen.visible = false
	right_screen.visible = false
	_update_labels()

	joystick.visible = false
	screen_area.visible = false
	screen_bg.visible = false

	joy_up.button_down.connect(func(): joy_input.y = -1)
	joy_up.button_up.connect(func(): if joy_input.y < 0: joy_input.y = 0)
	joy_down.button_down.connect(func(): joy_input.y = 1)
	joy_down.button_up.connect(func(): if joy_input.y > 0: joy_input.y = 0)
	joy_left.button_down.connect(func(): joy_input.x = -1)
	joy_left.button_up.connect(func(): if joy_input.x < 0: joy_input.x = 0)
	joy_right.button_down.connect(func(): joy_input.x = 1)
	joy_right.button_up.connect(func(): if joy_input.x > 0: joy_input.x = 0)
	
	if GameState.ship_fully_solved:
		left_screen.visible = true
		right_screen.visible = true
		left_screen.color = Color(0.0, 0.8, 0.2, 0.6)
		right_screen.color = Color(0.0, 0.8, 0.2, 0.6)
		screen_bg.visible = true
		screen_bg.color = Color(0.0, 1.0, 0.1, 0.3)
		game_won = true
		dialog_box.visible = false
		return  # ← диалог не показываем, игра не запускается заново
	next_button.pressed.connect(_on_dialog_next)
	next_button.visible = false
	dialog_label.text = ""
	dialog_box.visible = true
	_show_dialog_message(0)

func _process(delta: float) -> void:
	if not joystick_active or game_won:
		return

	# Двигаем стрелочку
	if joy_input != Vector2.ZERO:
		arrow_pos += joy_input.normalized() * ARROW_SPEED * delta
		arrow_pos.x = clamp(arrow_pos.x, SCREEN_LEFT, SCREEN_LEFT + SCREEN_WIDTH)
		arrow_pos.y = clamp(arrow_pos.y, SCREEN_TOP, SCREEN_TOP + SCREEN_HEIGHT)
		arrow.position = arrow_pos

	# Хаотичное движение точки — меняет направление каждые 0.3-0.8 сек
	chaos_timer -= delta
	if chaos_timer <= 0.0:
		dot_dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		chaos_timer = randf_range(0.2, 0.6)

	dot_pos += dot_dir * dot_speed * delta

	# Отскок от границ
	if dot_pos.x <= SCREEN_LEFT:
		dot_dir.x = abs(dot_dir.x)
		dot_pos.x = SCREEN_LEFT
		chaos_timer = 0.0
	elif dot_pos.x >= SCREEN_LEFT + SCREEN_WIDTH:
		dot_dir.x = -abs(dot_dir.x)
		dot_pos.x = SCREEN_LEFT + SCREEN_WIDTH
		chaos_timer = 0.0

	if dot_pos.y <= SCREEN_TOP:
		dot_dir.y = abs(dot_dir.y)
		dot_pos.y = SCREEN_TOP
		chaos_timer = 0.0
	elif dot_pos.y >= SCREEN_TOP + SCREEN_HEIGHT:
		dot_dir.y = -abs(dot_dir.y)
		dot_pos.y = SCREEN_TOP + SCREEN_HEIGHT
		chaos_timer = 0.0

	dot.position = dot_pos

	# Проверка касания
	if arrow_pos.distance_to(dot_pos) < CATCH_DISTANCE:
		catch_count += 1
		dot_speed += DOT_SPEED_STEP
		dot_pos = _random_far_pos(arrow_pos)
		dot_dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
		chaos_timer = 0.0

		if catch_count >= 3:
			_on_game_won()

# --- Первая игра ---
func _on_left_plus() -> void:
	left_value = (left_value + STEP) % (MAX_VAL + STEP)
	_update_labels()
	_check_screens_win()

func _on_left_minus() -> void:
	left_value = (left_value - STEP + MAX_VAL + STEP) % (MAX_VAL + STEP)
	_update_labels()
	_check_screens_win()

func _on_right_plus() -> void:
	right_value = (right_value + STEP) % (MAX_VAL + STEP)
	_update_labels()
	_check_screens_win()

func _on_right_minus() -> void:
	right_value = (right_value - STEP + MAX_VAL + STEP) % (MAX_VAL + STEP)
	_update_labels()
	_check_screens_win()

func _update_labels() -> void:
	left_label.text = str(left_value)
	right_label.text = str(right_value)

func _check_screens_win() -> void:
	if left_value == CORRECT_LEFT and right_value == CORRECT_RIGHT:
		left_screen.visible = true
		right_screen.visible = true
		left_screen.color = Color(0.0, 0.8, 0.2, 0.6)
		right_screen.color = Color(0.0, 0.8, 0.2, 0.6)
		GameState.panel_solved = true
		_start_joystick_game()

func _start_joystick_game() -> void:
	joystick.visible = true
	screen_area.visible = true
	joystick_active = true

	var center := Vector2(SCREEN_LEFT + SCREEN_WIDTH / 2.0, SCREEN_TOP + SCREEN_HEIGHT / 2.0)
	arrow_pos = center
	arrow.position = arrow_pos

	dot_pos = _random_far_pos(center)
	dot_dir = Vector2(randf_range(-1, 1), randf_range(-1, 1)).normalized()
	dot.position = dot_pos
	dot_speed = DOT_SPEED_START
	chaos_timer = 0.0

func _on_game_won() -> void:
	game_won = true
	joystick_active = false
	joy_input = Vector2.ZERO

	var center := Vector2(SCREEN_LEFT + SCREEN_WIDTH / 2.0, SCREEN_TOP + SCREEN_HEIGHT / 2.0)
	arrow_pos = center
	dot_pos = center
	arrow.position = center
	dot.position = center

	screen_bg.visible = true
	screen_bg.color = Color(0.0, 1.0, 0.1, 0.3)
	GameState.panel_game_won = true
	GameState.ship_fully_solved = true

func _random_far_pos(from: Vector2) -> Vector2:
	var pos: Vector2
	for _i in range(20):
		pos = Vector2(
			randf_range(SCREEN_LEFT + 40, SCREEN_LEFT + SCREEN_WIDTH - 40),
			randf_range(SCREEN_TOP + 40, SCREEN_TOP + SCREEN_HEIGHT - 40)
		)
		if pos.distance_to(from) > 150:
			return pos
	return pos

func _on_back_pressed() -> void:
	var main_game := get_tree().get_first_node_in_group("MainGame")
	if main_game:
		main_game.close_panel()
		
		
func _show_dialog_message(index: int) -> void:
	full_text = dialog_messages[index]
	dialog_label.text = ""
	next_button.visible = false
	is_typing = true
	_type_next_char(0)

func _type_next_char(char_idx: int) -> void:
	if char_idx > full_text.length():
		is_typing = false
		next_button.visible = true
		return
	dialog_label.text = full_text.substr(0, char_idx)
	await get_tree().create_timer(TYPE_SPEED).timeout
	_type_next_char(char_idx + 1)

func _on_dialog_next() -> void:
	if is_typing:
		is_typing = false
		dialog_label.text = full_text
		next_button.visible = true
		return
	dialog_index += 1
	if dialog_index >= dialog_messages.size():
		dialog_box.visible = false
		return
	_show_dialog_message(dialog_index)
