
extends Control

@onready var story_label: RichTextLabel = $TextStart

var full_text: String = "СТАТУС КОРАБЛЯ: КРИТИЧЕСКИЙ
Ядро - отказ ❌
Питание - отключено ❌
Дверь блока - заблокирована ❌
Навигация - сбита ❌
Последняя запись бортового дневника была сохранена в памяти робота ARIA ✅"
var char_index: int = 0
var type_speed: float = 0.02

func _ready() -> void:
	start_typing()

func start_typing() -> void:
	story_label.text = ""
	char_index = 0
	_type_next_char()
	
	

func _type_next_char() -> void:
	if char_index > full_text.length():
		return

	story_label.text = full_text.substr(0, char_index)
	char_index += 1

	if char_index <= full_text.length():
		await get_tree().create_timer(type_speed).timeout
		_type_next_char()
func _close_message() -> void:
	var main_game := get_tree().get_first_node_in_group("MainGame")
	if main_game:
		main_game.close_message4()

func _on_BackButton_pressed() -> void:
	_close_message()
