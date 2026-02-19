extends Control

@onready var title_label: RichTextLabel = $GameName

var full_title: String = "SPACESHIP MISSION"
var char_index: int = 0
var type_speed: float = 0.15  # скорость появления букв

func _ready() -> void:
	title_label.text = ""
	char_index = 0

	_type_next_char()             # запускаем печать букв
	$AnimationPlayer.play("wiggle")  # вибрация кнопки, если есть анимация


func _type_next_char() -> void:
	if char_index > full_title.length():
		return

	title_label.text = full_title.substr(0, char_index)
	char_index += 1

	if char_index <= full_title.length():
		await get_tree().create_timer(type_speed).timeout
		_type_next_char()


func _on_start_button_pressed() -> void:
	get_tree().change_scene_to_file("res://Game.tscn")  # твоя игровая сцена


func _on_quit_button_pressed() -> void:
	get_tree().quit()
