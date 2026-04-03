
extends Control

@onready var story_label: RichTextLabel = $TextStart

var full_text: String = ""
var char_index: int = 0
var type_speed: float = 0.02

func _ready() -> void:
	# Собираем текст динамически на основе прогресса
	var nav = "Навигация - настроена ✅" if GameState.ship_fully_solved else "Навигация - сбита ❌"

	full_text = (
		"СТАТУС КОРАБЛЯ: КРИТИЧЕСКИЙ\n" +
		"Ядро - отказ ❌\n" +
		"Питание - отключено ❌\n" +
		"Дверь блока - заблокирована ❌\n" +
		nav + "\n" +
		"Последняя запись бортового дневника была сохранена в памяти робота ARIA ✅"
	)
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
