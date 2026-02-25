extends Control

signal code_entered_correctly
const CORRECT_CODE := "2387"  # нужный код

var current_code: String = ""

@onready var code_display: Label = $CodeDisplay
@onready var bg_closed: TextureRect = $BackgroundBoxClose
@onready var bg_open: TextureRect = $BackgroundBoxOpen
@onready var keypad: Control = $Keypad
@onready var btn_clear: Button = $ButtonClear
@onready var btn_check: Button = $ButtonCheak

func _ready() -> void:

	btn_clear.pressed.connect(_on_clear_pressed)
	btn_check.pressed.connect(_on_check_pressed)
	
	_update_display()
func _on_digit_pressed(digit: String) -> void:
	if current_code.length() >= 4:
		return
	current_code += digit
	_update_display()


func _on_clear_pressed() -> void:
	current_code = ""
	_update_display()


func _update_display() -> void:
	code_display.text = current_code

func _on_check_pressed() -> void:
	if current_code == CORRECT_CODE:
		_open_chest()
	else:
		_wrong_code_feedback()
func _open_chest() -> void:
	
	bg_open.show()
	
	
	bg_closed.hide()
	code_display.hide()
	keypad.hide()
	btn_clear.hide()
	btn_check.hide()
	
func _wrong_code_feedback() -> void:
	var original_pos := code_display.position
	var tween := create_tween()
	
	tween.tween_property(code_display, "position", original_pos + Vector2(-5, 0), 0.05)
	tween.tween_property(code_display, "position", original_pos + Vector2(5, 0), 0.05)
	tween.tween_property(code_display, "position", original_pos, 0.05)
	
	await get_tree().create_timer(0.2).timeout
	current_code = ""
	_update_display()
	
func _on_Btn0_pressed() -> void:
	_on_digit_pressed("0")
func _on_Btn1_pressed() -> void:
	_on_digit_pressed("1")
func _on_Btn2_pressed() -> void:
	_on_digit_pressed("2")
func _on_Btn3_pressed() -> void:
	_on_digit_pressed("3")
func _on_Btn4_pressed() -> void:
	_on_digit_pressed("4")
func _on_Btn5_pressed() -> void:
	_on_digit_pressed("5")
func _on_Btn6_pressed() -> void:
	_on_digit_pressed("6")
func _on_Btn7_pressed() -> void:
	_on_digit_pressed("7")
func _on_Btn8_pressed() -> void:
	_on_digit_pressed("8")
func _on_Btn9_pressed() -> void:
	_on_digit_pressed("9")
	
func _on_BackButton_pressed() -> void:
	GlobalState.return_to_second_room = true
	get_tree().change_scene_to_file("res://Game.tscn")
	
func _on_correct_code_entered() -> void:
	get_tree().change_scene_to_file("res://Game.tscn")	
	
