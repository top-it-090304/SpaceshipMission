extends Control

@onready var story_label1: RichTextLabel = $RobotText

var full_text: String = "Привет! Я твой робот-ассистент и я готов помочь тебе с выполнением твоей миссии! Какая проблема у тебя возникла?"
var char_index: int = 0
var type_speed: float = 0.02

func start_typing() -> void:
	story_label1.text = ""
	char_index = 0
	_type_next_char()

func _type_next_char() -> void:
	if char_index > full_text.length():
		return

	story_label1.text = full_text.substr(0, char_index)
	char_index += 1

	if char_index <= full_text.length():
		await get_tree().create_timer(type_speed).timeout
		_type_next_char()
